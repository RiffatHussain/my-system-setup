Incident Command Walkthrough — LiteLLM Cryptominer
Phase 1: Detection & Identification
cmd: ps -eo pid,ppid,stat,cmd | grep 'Z' | grep -v grep
purpose: List all processes showing PID, parent PID, state, and command — filter only zombie (Z) state ones
resolved: Revealed 33 zombies with suspicious names (gmon, xmon, kthreadm) — the first clue something was wrong
cmd: ps -p 2339756,2339648,2339713 -o pid,ppid,user,lstart,etime,%cpu,%mem,cmd
purpose: Inspect the specific parent PIDs of the zombies — who they are, when started, resource usage
resolved: Identified the zombie parents as litellm, node, and next-server — legitimate apps, so zombies came through them
cmd: ls -l /proc/2339756/exe /proc/2339756/cwd
purpose: Show the real binary a process is running (exe) and its working directory (cwd) — cannot be faked by process name
resolved: Confirmed litellm was a genuine python process, not malware in disguise
cmd: cat /proc/2339756/cmdline | tr '\0' ' '; echo
purpose: Print the full command a process was started with (kernel stores args with null separators; tr makes it readable)
resolved: Verified litellm's startup arguments matched a normal deployment
cmd: top -b -n1 | head -20
purpose: One snapshot of system health sorted by CPU (batch mode, non-interactive)
resolved: THE key discovery — exposed miner XXNs22Rr at 572% CPU and gmon at 44%, system at 94.7% CPU, load 9.35
Phase 2: Tracing the Compromise
cmd: cat /proc/2113586/cgroup
purpose: Show which control group (container) a process belongs to
resolved: Proved both miners lived inside the litellm Docker container — host itself not breached
cmd: docker ps
purpose: List all running containers with images, ports, status
resolved: Mapped cgroup ID 4c2bb4da → litellm container; also exposed the root cause: 0.0.0.0:4000 open to internet
cmd: ls -l /proc/2113586/exe /proc/2113586/cwd
purpose: Locate the miner's actual binary on disk
resolved: Found malware dropped at /tmp/XXNs22Rr and /tmp/.dbus-cache/mon/gmon (deleted = self-hiding) — textbook miner behavior
cmd: ps -o pid,ppid,lstart,cmd -p 2113586,2534041
purpose: Show the miners' parent and start dates
resolved: PPID 2339756 = litellm spawned them → entry was through the LiteLLM app; two infection dates (Jun 19, Jun 29)
cmd: crontab -l; ls -la /etc/cron.d/ /var/spool/cron/ + cat /root/.ssh/authorized_keys + systemctl list-timers --all
purpose: Check the three classic persistence spots: cron jobs, planted SSH keys, systemd timers
resolved: All clean — attacker had no foothold on the host, compromise contained to the container
Phase 3: Kill & Reap
cmd: kill -9 2113586 2534041
purpose: Force-kill (SIGKILL, uncatchable) both miner processes
resolved: CPU dropped 94.7% → 0.7%, load 9.35 → 0.83, ~6GB memory freed
cmd: kill -CHLD 2339756
purpose: Nudge the parent to reap its zombie children (zombies can't be killed directly — only reaped by parent)
resolved: Didn't work (litellm doesn't reap) — confirmed a parent restart was the only way to clear zombies
cmd: ps -eo stat | grep -c Z
purpose: Count zombies system-wide (list all process states, count lines containing Z)
resolved: Tracked progress: 33 → 35 (killed miners became zombies too) → 0 after recreate
Phase 4: Pre-Restart Verification
cmd: docker inspect litellm --format '{{.HostConfig.RestartPolicy.Name}}'
purpose: Check if the container auto-restarts after being stopped/killed
resolved: "unless-stopped" — safe to restart, it comes back on its own
cmd: docker inspect litellm --format '{{json .Mounts}}' | python3 -m json.tool
purpose: Show what host files/folders are mounted into the container
resolved: config.yaml is a host bind-mount → survives any restart/recreate
cmd: docker logs litellm --since 5m --tail 20
purpose: Check recent activity to pick a safe restart moment
resolved: Empty = nobody using it = zero-impact window; later, full logs also revealed internet IPs probing it (proof of exposure)
Phase 5: Diagnose the Crash Loop
cmd: docker restart litellm → then docker logs litellm --tail 50
purpose: Restart the container to reap zombies; read logs when it crash-looped
resolved: Exposed pre-existing damage: "exec docker/prod_entrypoint.sh: no such file" — attacker broke the container's startup script; restart didn't cause it, it revealed it
cmd: docker run --rm --entrypoint ls ghcr.io/berriai/litellm:main-latest -la docker/
purpose: Spin up a throwaway copy of the image, list its docker/ folder, auto-delete — verifies the master image is intact
resolved: prod_entrypoint.sh present in the image → recreate guaranteed to fix the crash
cmd: cp config.yaml /root/litellm-config.yaml.bak + cat config.yaml + ls -l
purpose: Backup then inspect the config content and modification date
resolved: Config clean, mtime Apr 4 (before compromise) — attacker never touched it, keys referenced via env not hardcoded
cmd: docker network ls | grep openclaw-net
purpose: Confirm the external Docker network in the compose file actually exists
resolved: It exists — compose recreate won't fail on a missing network
Phase 6: Fix & Harden
cmd: (edit) docker-compose.yml: "4000:4000" → "127.0.0.1:4000:4000"
purpose: Bind port 4000 to localhost only instead of all interfaces
resolved: Internet can no longer reach litellm; internal containers unaffected (they use openclaw-net by container name) — entry vector closed
cmd: docker compose up -d --force-recreate litellm
purpose: Destroy the damaged container and build a fresh one from the clean read-only image, reapplying compose config
resolved: Crash loop ended, clean entrypoint restored, all 35 zombies reaped by systemd in the same moment
Phase 7: Verify
cmd: docker ps | grep litellm
purpose: Confirm container state and port binding
resolved: "Up 25 seconds", ports 127.0.0.1:4000->4000 — running and locked down
cmd: docker logs litellm -f
purpose: Watch startup live (viewer only — Ctrl+C stops watching, not the container)
resolved: Clean boot: migrations applied, "Application startup complete" — service fully restored