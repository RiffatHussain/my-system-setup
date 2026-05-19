# Git Versioning for IT Operations - Incident & Deployment Playbook

## Table of Contents
1. [Incident Response Procedures](#incident-response)
2. [Deployment Strategies](#deployment-strategies)
3. [Team Coordination](#team-coordination)
4. [Monitoring & Auditing](#monitoring--auditing)
5. [Emergency Recovery](#emergency-recovery)
6. [CI/CD Integration](#cicd-integration)

---

## INCIDENT RESPONSE

### 🚨 LEVEL 1: Critical Bug in Production (Immediate Rollback)

**Detection Time:** Monitoring alert or user report  
**Goal:** Restore service in < 5 minutes  
**Team:** On-call engineer + Team lead

#### STEP 1: Gather Information (2 minutes)
```bash
# Check what's currently deployed
git log main --oneline -1                    # Current production commit
git log --all --grep="deploy" --oneline -5  # Recent deployments
git tag -l | sort -V | tail -5               # Recent versions

# Verify it's actually deployed
git describe --tags $(git rev-parse HEAD)    # Current version tag
```

#### STEP 2: Identify Bad Commit (1 minute)
```bash
# Find when bug was introduced
git log --oneline -20                        # Recent commits
git show abc1234                             # View specific commit

# Search git history for the problematic code
git log -p -S "bad_function" --all          # Find references
git blame path/to/broken_file                # Who changed it
```

#### STEP 3: Emergency Rollback (1 minute)
```bash
# Option A: Previous version exists (FASTEST)
git checkout v1.2.1                          # Tested, stable tag
git tag v1.2.2-rollback -m "Emergency rollback to v1.2.1"
git push origin main v1.2.2-rollback
# Trigger deployment via CI/CD

# Option B: Revert specific commit (if multiple commits)
git revert abc1234 --no-edit
git tag v1.2.2 -m "Rollback commit abc1234"
git push origin main v1.2.2
# Trigger deployment

# Option C: Hard reset (ONLY if no one has pulled yet!)
git reset --hard origin/main~1
git tag v1.2.2-hotfix
git push origin main --force-with-lease
# ⚠️ Notify team immediately
```

#### STEP 4: Verify Rollback (1 minute)
```bash
# Confirm deployment
git log main --oneline -3
git diff v1.2.1 main --stat                  # Should show no changes

# Monitoring check
# (automated by CI/CD: health checks, error rates, performance metrics)
```

#### STEP 5: Post-Incident (After recovery)
```bash
# Create incident ticket
TICKET_ID="INC-2024-001"

# Find root cause
git log --all -p -S "bad_code" --since="2024-01-15"

# Review code review
git show abc1234                             # Check PR/review status

# Prepare documentation
cat > incident_${TICKET_ID}.md << 'EOF'
# Incident Report INC-2024-001

## Timeline
- 14:23 UTC: Alert triggered
- 14:24 UTC: On-call acknowledged
- 14:25 UTC: Rollback deployed
- 14:26 UTC: Service restored

## Root Cause
Commit abc1234 introduced race condition in auth module.
No test coverage for concurrent requests.

## Reverted Commit
abc1234 - feat: new auth check (bad logic)

## Prevention
- Add concurrent test cases
- Require load testing before merge
- Code review checklist item
EOF

git add incident_${TICKET_ID}.md
git commit -m "docs: incident $TICKET_ID postmortem"
```

---

### LEVEL 2: Data Corruption (Partial Rollback)

**Scenario:** Feature A is fine, Feature B corrupted data  
**Goal:** Keep A, remove B  
**Strategy:** Cherry-pick safe commits

```bash
# Branches at time of incident:
# main (v1.2.0): has Features A, B, C
# Feature A working: commit abc1234
# Feature B broken: commit def5678, ghi9012
# Feature C untested: commit jkl3456

# Current main:
# main → (jkl: C) → (ghi: B) → (def: B) → (abc: A) → (old code)

# Solution: Reset to before B, cherry-pick A and C only

git log main --oneline -10                   # Inspect

# Option 1: Interactive rebase
git rebase -i HEAD~5
# keep: abc1234 (A)
# drop: def5678, ghi9012 (B)
# keep: jkl3456 (C)

git tag v1.2.1-patched
git push origin main

# Option 2: Manual reset + cherry-pick
git reset --hard abc1234                     # Back before B
git cherry-pick jkl3456                      # Add C
git tag v1.2.1-patched
git push origin main
```

---

### LEVEL 3: Deployment Failed (Rollback During Deploy)

**Scenario:** Deploy in progress, tests failing  
**Goal:** Stop deployment, revert changes  

```bash
# During CI/CD pipeline

# If tests detected issue:
git log --oneline HEAD~5..HEAD               # What's being deployed

# Cancel deployment
# (Implementation depends on your CI system)

# Revert to last known-good
git revert --no-edit HEAD                    # Creates undo commit
git push origin main

# OR: Reset if not yet in production
git reset --hard origin/main~1
git push origin main --force-with-lease
```

---

## DEPLOYMENT STRATEGIES

### Strategy 1: Tag-Based Releases (Recommended for IT Ops)

**Advantage:** Exact version reproducibility, easy rollback, audit trail  
**Tools:** Git tags + deployment automation

```bash
# Release workflow

# 1. Prepare release (on develop branch)
git checkout develop
git log --oneline -10
# Confirm code is ready

# 2. Create release branch
git checkout -b release/v1.3.0 develop

# 3. Update version numbers (in files)
sed -i 's/VERSION=1.2.0/VERSION=1.3.0/g' VERSION.txt
git add VERSION.txt
git commit -m "chore: bump version to 1.3.0"

# 4. Create annotated tag
git tag -a v1.3.0 -m "Release v1.3.0 - features A, B, C"

# 5. Merge to main
git checkout main
git merge --no-ff release/v1.3.0 -m "Merge release v1.3.0"

# 6. Back-merge to develop
git checkout develop
git merge release/v1.3.0

# 7. Clean up
git branch -d release/v1.3.0

# 8. Push everything
git push origin main develop v1.3.0

# 9. Deploy via CI/CD
# (triggered by tag push)
```

#### Rollback from Tag
```bash
# Identify good tag
git tag -l | sort -V | tail -10

# Create rollback tag pointing to known-good
git tag v1.3.1-rollback v1.2.5               # Point to v1.2.5

# Update main to that version
git checkout main
git reset --hard v1.2.5
git push origin main

# OR: Revert specific commits
git revert v1.3.0^..HEAD                     # Revert everything since 1.3.0
git push origin main
```

---

### Strategy 2: Blue-Green Deployment (Zero Downtime)

**Setup:** Two production environments (blue=current, green=new)

```bash
# Deploy to green environment
git checkout green-environment
git pull origin main                         # Get latest code
git log --oneline -3

# Run tests on green
./run-tests.sh
# If success:

# Switch traffic
# (done via load balancer, DNS, etc.)
git tag v1.3.0-live -m "Live on green"

# Make green the new blue
git branch -M blue-environment green-environment
git push origin blue-environment
```

---

### Strategy 3: Canary Deployment (Gradual Rollout)

```bash
# Deploy to 5% of users first
git tag v1.3.0-canary -m "5% rollout"

# Monitor metrics
git log --oneline main -1
# Check: error rates, performance, user feedback

# If problems, rollback immediately
git revert v1.3.0^..HEAD

# If good, increase percentage
git tag v1.3.0-25pct
git tag v1.3.0-50pct
git tag v1.3.0-100pct

# Finally mark as stable
git tag v1.3.0-stable
```

---

## TEAM COORDINATION

### Branching Strategy: Git Flow

```
main (production)
  ├─ v1.0.0 (tag)
  ├─ v1.1.0 (tag) ← Always stable, tagged
  └─ v1.2.0 (tag)

develop (next release)
  ├─ feature/auth-2fa (developer A)
  ├─ feature/api-v2 (developer B)
  └─ bugfix/memory-leak (developer C)

release/v1.3.0 (release prep)
  └─ Compiled, tested, ready to main

hotfix/critical-bug (emergency)
  └─ Direct from main tag, fast-tracked
```

#### Workflow
```bash
# Developer: Start new feature
git checkout -b feature/user-dashboard develop
# ... work ...
git commit -m "feat: user dashboard"
git push origin feature/user-dashboard
# Create PR → Code review → Merge to develop

# Release Manager: Prepare release
git checkout -b release/v1.3.0 develop
git log --oneline develop | head -20     # What's going in?
# ... update docs, version ...
git commit -m "chore: prepare v1.3.0"
git push origin release/v1.3.0

# Testing team: Run tests on release branch
git checkout release/v1.3.0
./run-full-test-suite.sh                 # 2+ hours
# If issues: git commit bug fix to release branch

# Release Manager: Tag and merge
git checkout release/v1.3.0
git log --oneline -10
git tag -a v1.3.0 -m "Release v1.3.0"
git checkout main
git merge --no-ff release/v1.3.0
git push origin main v1.3.0
# Triggers deployment

# Emergency Hotfix
git checkout -b hotfix/critical-auth main
# ... fix bug ...
git commit -m "fix: auth token expiry"
git checkout main
git merge --no-ff hotfix/critical-auth
git tag v1.2.1-hotfix
git push origin main v1.2.1-hotfix
git checkout develop
git merge hotfix/critical-auth
git push origin develop
git branch -d hotfix/critical-auth
```

---

### Code Review Checklist

```bash
# Reviewer workflow
git log --oneline main..feature/branch      # What changed?
git show feature/branch                     # Latest commit
git diff main feature/branch --stat         # File impact
git diff main feature/branch                # Full diff

# Check for common issues
git log feature/branch -p -S "TODO"         # Incomplete work
git log feature/branch -p -S "FIXME"        # Known issues
git log feature/branch | grep -i "revert"   # Reverted code

# Approve
git log feature/branch --oneline
# ✓ Code quality OK
# ✓ Tests pass
# ✓ No secrets committed
# ✓ Documentation updated

# Merge
git checkout develop
git merge --no-ff feature/branch -m "Merge feature/branch (TICKET-123)"
git push origin develop
```

---

## MONITORING & AUDITING

### Commit Audit Trail

```bash
# Who changed what, when?
git log --author="Alice" --since="2024-01-01" --oneline

# All deletions
git log -p -S "important_function" --all | grep "^-"

# Large files added
git log --diff-filter=A --find-object=<hash>

# Commits by hour (for forensics)
git log --pretty=format:"%ad %h %s" --date=short | sort

# Total commits per author
git shortlog -s -n

# Files most frequently changed
git log --pretty=format: --name-only --all | sort | uniq -c | sort -rn | head -20
```

### Automated Monitoring
```bash
#!/bin/bash
# git_audit.sh - Run daily

REPO="/path/to/repo"
cd $REPO

# Check for uncommitted secrets
git log -p --all -S "password" | head -20
git log -p --all -S "api_key" | head -20
git log -p --all -S "secret" | head -20

# Check for suspicious commits
git log --since="24 hours ago" --oneline

# Size check (repo shouldn't grow > 1GB)
du -sh .git

# Tag verification (releases must be tagged)
git log --oneline $(git describe --tags)~10..$(git describe --tags) | wc -l

# Notify if issues found
if git log -p --all -S "PASSWORD" | grep -q .; then
    echo "⚠️ ALERT: Potential secret in repo!"
    # Escalate to security team
fi
```

---

## EMERGENCY RECOVERY

### Scenario: Accidentally Committed Secrets

```bash
# Step 1: IMMEDIATELY rotate the secret
# (credentials, API keys, passwords)
# This is priority #1 - don't waste time on git cleanup first!

# Step 2: Remove from git history (AFTER rotation)
# Option A: BFG Repo-Cleaner (recommended)
bfg --delete-files id_secret /path/to/repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Option B: git filter-branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secrets.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Step 3: Force push (warn team!)
git push origin --all --force
git push origin --tags --force

# Step 4: Notify
# Email to team: "Secrets rotated. Force-pulled new code. Re-sync your repos."
# Team action: git fetch origin; git reset --hard origin/main

# Step 5: Audit
git log -p --all -S "secret_key_123" | head -5  # Verify it's gone
```

### Scenario: Corrupted Repository

```bash
# Symptoms: Can't push, weird merge conflicts, objects missing

# Step 1: Verify integrity
git fsck --full                              # Check object database
git log -1                                   # Can we still read?

# Step 2: Full backup (if possible)
cp -r .git .git.backup

# Step 3: Repair
git gc --aggressive                          # Repack objects
git reflog expire --expire=now --all         # Cleanup reflog
git gc --prune=now                           # Final cleanup

# Step 4: Rebuild index
rm .git/index                                # Delete index
git reset                                    # Rebuild from HEAD

# Step 5: Verify
git log --oneline -1
git status

# Step 6: If still broken
# Reset to remote (loose all local commits, but repo is clean)
git fetch origin
git reset --hard origin/main
```

### Scenario: Accidentally Did Hard Reset

```bash
# PANIC? Don't! Reflog saves you.

# Step 1: Find the lost commit
git reflog                                   # Shows all HEAD movements
# Should see: abc1234 HEAD@{0}: reset: moving to HEAD~5
#             def5678 HEAD@{1}: commit: lost feature
#             ghi9012 HEAD@{2}: commit: important work

# Step 2: Recover
git reset --hard def5678                    # Jump back to before reset

# Step 3: Verify
git log --oneline -5

# Safety: Reflog kept for ~30 days by default
git config core.logAllRefUpdates true       # Enable for safety
git reflog expire --expire=never             # Keep forever (if paranoid)
```

---

## CI/CD INTEGRATION

### GitLab CI Pipeline with Git Versioning

```yaml
# .gitlab-ci.yml

stages:
  - build
  - test
  - release
  - deploy

variables:
  VERSION_FILE: "VERSION"

build:
  stage: build
  script:
    - VERSION=$(cat $VERSION_FILE)
    - echo "Building version $VERSION"
    - docker build -t myapp:$VERSION .
  only:
    - main
    - develop

test:
  stage: test
  script:
    - npm test
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

release:
  stage: release
  script:
    - VERSION=$(cat $VERSION_FILE)
    - echo "Creating release tag v$VERSION"
    - git tag -a v$VERSION -m "Release v$VERSION"
    - git push origin v$VERSION
  only:
    - main
  when: manual

deploy_production:
  stage: deploy
  script:
    - VERSION=$(git describe --tags --abbrev=0)
    - echo "Deploying $VERSION to production"
    - ./deploy.sh $VERSION
  environment:
    name: production
    url: https://example.com
  only:
    - tags
  when: manual

deploy_rollback:
  stage: deploy
  script:
    - PREV_TAG=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1))
    - echo "Rolling back to $PREV_TAG"
    - ./deploy.sh $PREV_TAG
    - git tag v$(cat VERSION)-rollback
    - git push origin v$(cat VERSION)-rollback
  environment:
    name: production
    action: rollback
  when: manual
  only:
    - main
```

### GitHub Actions with Rollback

```yaml
# .github/workflows/deploy.yml

name: Deploy & Rollback

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:
    inputs:
      action:
        description: 'Deploy or Rollback'
        required: true
        default: 'deploy'
        type: choice
        options:
          - deploy
          - rollback

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action != 'rollback' }}
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Get version
        run: |
          VERSION=$(git describe --tags --abbrev=0 || echo "0.1.0")
          echo "DEPLOY_VERSION=$VERSION" >> $GITHUB_ENV
      
      - name: Deploy
        run: ./scripts/deploy.sh ${{ env.DEPLOY_VERSION }}
      
      - name: Health check
        run: |
          curl -f https://api.example.com/health || exit 1
          echo "✓ Deployment successful"
      
      - name: Notify
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Deployed to production'
            })

  rollback:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'rollback' }}
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Find last good version
        run: |
          # Get tag before current
          PREV_TAG=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1))
          echo "ROLLBACK_TO=$PREV_TAG" >> $GITHUB_ENV
      
      - name: Rollback
        run: ./scripts/deploy.sh ${{ env.ROLLBACK_TO }}
      
      - name: Create incident tag
        run: |
          git tag v$(date +%s)-rollback
          git push origin v$(date +%s)-rollback
```

---

## CHECKLISTS FOR IT OPS

### Pre-Release Checklist
- [ ] All features merged and tested on develop
- [ ] Version number updated in VERSION file
- [ ] CHANGELOG updated with new features
- [ ] Release notes prepared
- [ ] Tag created: `git tag -a vX.Y.Z`
- [ ] All tests passing in CI
- [ ] Security scan completed
- [ ] Performance benchmarks met
- [ ] Rollback plan documented
- [ ] On-call engineer ready

### Post-Deployment Checklist
- [ ] Version tag exists and correct
- [ ] Deployment artifacts created
- [ ] Health checks passing
- [ ] Metrics normal (latency, error rate, CPU)
- [ ] Team notified
- [ ] Monitoring alerts configured
- [ ] Rollback procedure documented and tested
- [ ] Release notes published

### Incident Response Checklist
- [ ] Alert acknowledged and assigned
- [ ] Slack/PagerDuty notification sent
- [ ] Issue scope confirmed
- [ ] Root cause identified (if obvious)
- [ ] Rollback decision made (within 5min)
- [ ] Rollback executed
- [ ] Deployment confirmation
- [ ] Health checks verified
- [ ] Incident ticket created
- [ ] Postmortem scheduled

---

## QUICK COMMANDS FOR DAILY USE

```bash
# Daily checks
git log --since="24 hours ago" --oneline     # What deployed?
git tag -l | sort -V | tail -5               # Recent versions
git status                                    # Any uncommitted work?

# Weekly review
git log --since="7 days ago" --pretty=format:"%h %an %s" | head -20
git shortlog -s -n --since="7 days ago"      # Top contributors

# Monthly audit
git log --since="30 days ago" --all | wc -l  # Total changes
git log --all -p -S "password\|secret" | head -20  # Security audit

# Emergency checks
git reflog                                    # Can we recover?
git describe --tags                          # Current version
git diff main origin/main                    # Any local changes?
```

---

**Remember:** Git is your version control AND your audit trail. Use it well, and it saves you in emergencies!
