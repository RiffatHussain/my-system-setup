# Incident Command Walkthrough — LiteLLM Cryptominer

> **Server:** static | **Date:** July 8, 2026
> **Summary:** Internet-exposed LiteLLM container (0.0.0.0:4000) compromised ~June 19; two cryptominers ran as root inside the container. Miners killed, container recreated from clean image, port restricted to localhost.

---

## Phase 1: Detection & Identification

### 1.1 Find zombie processes

```bash
ps -eo pid,ppid,stat,cmd | grep 'Z' | grep -v grep
```

- **Purpose:** List all processes showing PID, parent PID, state, and command — filter only zombie (`Z`) state ones
- **Resolved:** Revealed 33 zombies with suspicious names (`gmon`, `xmon`, `kthreadm`) — the first clue something was wrong

### 1.2 Inspect the zombie parents

```bash
ps -p 2339756,2339648,2339713 -o pid,ppid,user,lstart,etime,%cpu,%mem,cmd
```

- **Purpose:** Inspect the specific parent PIDs of the zombies — who they are, when started, resource usage
- **Resolved:** Identified the zombie parents as litellm, node, and next-server — legitimate apps, so zombies came through them

### 1.3 Verify the real binary behind a process

```bash
ls -l /proc/2339756/exe /proc/2339756/cwd
```

- **Purpose:** Show the real binary a process is running (`exe`) and its working directory (`cwd`) — cannot be faked by process name
- **Resolved:** Confirmed litellm was a genuine python process, not malware in disguise

### 1.4 Read the full startup command

```bash
cat /proc/2339756/cmdline | tr '\0' ' '; echo
```

- **Purpose:** Print the full command a process was started with (kernel stores args with null separators; `tr` makes it readable)
- **Resolved:** Verified litellm's startup arguments matched a normal deployment

### 1.5 System snapshot

```bash
top -b -n1 | head -20
```

- **Purpose:** One snapshot of system health sorted by CPU (batch mode, non-interactive)
- **Resolved:** **THE key discovery** — exposed miner `XXNs22Rr` at 572% CPU and `gmon` at 44%, system at 94.7% CPU, load 9.35

---

## Phase 2: Tracing the Compromise

### 2.1 Which container does the miner live in?

```bash
cat /proc/2113586/cgroup
```

- **Purpose:** Show which control group (container) a process belongs to
- **Resolved:** Proved both miners lived inside the litellm Docker container — host itself not breached

### 2.2 Map cgroup to container

```bash
docker ps
```

- **Purpose:** List all running containers with images, ports, status
- **Resolved:** Mapped cgroup ID `4c2bb4da` → litellm container; also exposed the root cause: **0.0.0.0:4000 open to internet**

### 2.3 Locate the malware binaries

```bash
ls -l /proc/2113586/exe /proc/2113586/cwd
ls -l /proc/2534041/exe /proc/2534041/cwd
```

- **Purpose:** Locate the miner's actual binary on disk
- **Resolved:** Found malware dropped at `/tmp/XXNs22Rr` and `/tmp/.dbus-cache/mon/gmon` (deleted = self-hiding) — textbook miner behavior

### 2.4 Who spawned the miners?

```bash
ps -o pid,ppid,lstart,cmd -p 2113586,2534041
```

- **Purpose:** Show the miners' parent and start dates
- **Resolved:** PPID 2339756 = **litellm spawned them** → entry was through the LiteLLM app; two infection dates (Jun 19, Jun 29)

### 2.5 Host persistence check

```bash
crontab -l
ls -la /etc/cron.d/ /var/spool/cron/
cat /root/.ssh/authorized_keys
systemctl list-timers --all
```

- **Purpose:** Check the three classic persistence spots: cron jobs, planted SSH keys, systemd timers
- **Resolved:** All clean — attacker had no foothold on the host, compromise contained to the container

---

## Phase 3: Kill & Reap

### 3.1 Kill the miners

```bash
kill -9 2113586 2534041
```

- **Purpose:** Force-kill (SIGKILL, uncatchable) both miner processes
- **Resolved:** CPU dropped 94.7% → 0.7%, load 9.35 → 0.83, ~6GB memory freed

### 3.2 Try to reap zombies

```bash
kill -CHLD 2339756
```

- **Purpose:** Nudge the parent to reap its zombie children (zombies can't be killed directly — only reaped by parent)
- **Resolved:** Didn't work (litellm doesn't reap) — confirmed a parent restart was the only way to clear zombies

### 3.3 Zombie counter

```bash
ps -eo stat | grep -c Z
```

- **Purpose:** Count zombies system-wide (list all process states, count lines containing `Z`)
- **Resolved:** Tracked progress: 33 → 35 (killed miners became zombies too) → 0 after recreate

---

## Phase 4: Pre-Restart Verification

### 4.1 Restart policy

```bash
docker inspect litellm --format '{{.HostConfig.RestartPolicy.Name}}'
```

- **Purpose:** Check if the container auto-restarts after being stopped/killed
- **Resolved:** `unless-stopped` — safe to restart, it comes back on its own

### 4.2 Mounts

```bash
docker inspect litellm --format '{{json .Mounts}}' | python3 -m json.tool
```

- **Purpose:** Show what host files/folders are mounted into the container
- **Resolved:** `config.yaml` is a host bind-mount → survives any restart/recreate

### 4.3 Activity check

```bash
docker logs litellm --since 5m --tail 20
```

- **Purpose:** Check recent activity to pick a safe restart moment
- **Resolved:** Empty = nobody using it = zero-impact window; later, full logs also revealed internet IPs probing it (proof of exposure)

---

## Phase 5: Diagnose the Crash Loop

### 5.1 Restart revealed hidden damage

```bash
docker restart litellm
docker logs litellm --tail 50
```

- **Purpose:** Restart the container to reap zombies; read logs when it crash-looped
- **Resolved:** Exposed pre-existing damage: `exec docker/prod_entrypoint.sh: no such file or directory` — attacker broke the container's startup script; restart didn't cause it, it revealed it

### 5.2 Verify the image is intact

```bash
docker run --rm --entrypoint ls ghcr.io/berriai/litellm:main-latest -la docker/
```

- **Purpose:** Spin up a throwaway copy of the image, list its `docker/` folder, auto-delete — verifies the master image is intact
- **Resolved:** `prod_entrypoint.sh` present in the image → recreate guaranteed to fix the crash

### 5.3 Backup and inspect config

```bash
cp /home/sysadmin/openclaw-infra/litellm/config.yaml /root/litellm-config.yaml.bak
cp /home/sysadmin/openclaw-infra/litellm/.env /root/litellm-env.bak
cat /home/sysadmin/openclaw-infra/litellm/config.yaml
ls -l /home/sysadmin/openclaw-infra/litellm/
```

- **Purpose:** Backup then inspect the config content and modification date
- **Resolved:** Config clean, mtime Apr 4 (before compromise) — attacker never touched it, keys referenced via env not hardcoded

### 5.4 Confirm the Docker network exists

```bash
docker network ls | grep openclaw-net
```

- **Purpose:** Confirm the external Docker network in the compose file actually exists
- **Resolved:** It exists — compose recreate won't fail on a missing network

---

## Phase 6: Fix & Harden

### 6.1 Close the internet exposure

Edit `docker-compose.yml`:

```yaml
# Before (attack vector):
ports:
  - "4000:4000"

# After (localhost only):
ports:
  - "127.0.0.1:4000:4000"
```

- **Purpose:** Bind port 4000 to localhost only instead of all interfaces
- **Resolved:** Internet can no longer reach litellm; internal containers unaffected (they use openclaw-net by container name) — **entry vector closed**

### 6.2 Recreate the container from clean image

```bash
cd /home/sysadmin/openclaw-infra/litellm/
docker compose up -d --force-recreate litellm
```

- **Purpose:** Destroy the damaged container and build a fresh one from the clean read-only image, reapplying compose config
- **Resolved:** Crash loop ended, clean entrypoint restored, all 35 zombies reaped by systemd in the same moment

---

## Phase 7: Verify

### 7.1 Container state

```bash
docker ps | grep litellm
```

- **Purpose:** Confirm container state and port binding
- **Resolved:** "Up 25 seconds", ports `127.0.0.1:4000->4000` — running and locked down

### 7.2 Watch startup

```bash
docker logs litellm -f    # Ctrl+C stops watching, NOT the container
```

- **Purpose:** Watch startup live (viewer only)
- **Resolved:** Clean boot: migrations applied, "Application startup complete" — service fully restored

---

## Post-Remediation Metrics

| Metric | Before | After |
|---|---|---|
| CPU usage | 94.7% | 0.7% |
| Load average | 9.35 | 0.83 |
| Zombie processes | 33 | 0 |
| Free memory | 841 MB | 5.9 GB |
| Port 4000 exposure | 0.0.0.0 (internet) | 127.0.0.1 (localhost) |

## Pending (Dev Team)

- [ ] Rotate `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LITELLM_MASTER_KEY` (19+ days of dwell time — assume stolen)
- [ ] Pin litellm image to a stable version instead of `main-latest`
- [ ] Monitor CPU + zombie count for the next few days

---

**The investigation arc:** zombies → `top` → miner → `/proc` → container → PPID → entry vector → logs → proof → compose → fix.