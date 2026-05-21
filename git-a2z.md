# Git Versioning & Rollback - Complete Reference for IT

## 1️⃣ TRACKING & CHANGE HISTORY

### View Commit History
```bash
git log                           # Full commit history
git log --oneline                 # Compact view (hash + message)
git log -n 10                      # Last 10 commits
git log --graph --all --decorate  # Visual branch tree
git log -p                         # With full diff
git log --stat                     # Files changed + stats
git log --author="Name"            # By author
git log --since="2 weeks ago"      # By date range
git log --grep="bug"               # Search messages
```

### Inspect Specific Commits
```bash
git show abc1234                   # Full commit details
git show abc1234:path/to/file.js   # File at specific commit
git blame path/to/file.js          # Who changed each line
git diff abc1234 def5678           # Compare commits
git diff abc1234 def5678 -- file.js # Specific file
git diff HEAD~1                    # Last commit vs current
git diff --staged                  # Staged vs committed
git diff                           # Working tree vs staged
```

### Find Regressions
```bash
git bisect start                   # Start binary search
git bisect bad HEAD                # Mark current as bad
git bisect good v1.0               # Mark known-good commit
git bisect bad                     # Mark current as bad (testing)
git bisect good                    # Mark current as good
git bisect reset                   # Exit bisect
```

---

## 2️⃣ RESET VS REVERT - CHOOSE WISELY

### ⏮️ RESET (Rewrites History - NEVER on public branches!)

| Command | Effect | Use Case |
|---------|--------|----------|
| `git reset --soft HEAD~1` | Undo commit, keep changes staged | Re-commit with better message |
| `git reset --mixed HEAD~1` | Undo commit, keep changes unstaged | Review changes before re-commit |
| `git reset --hard HEAD~1` | **Delete commit + all changes** | Only if certain! Destructive! |
| `git reset --hard HEAD~3` | Go back 3 commits | Complete cleanup (unpushed only) |
| `git reset HEAD file.js` | Unstage file | Remove from commit |

**Golden Rule:** Only reset commits YOU haven't pushed yet!

```bash
# SAFE: You just committed to local, want to fix message
git reset --soft HEAD~1
git commit -m "Better message"

# DANGER: Committed bad code to shared branch
# DO NOT: git reset --hard origin/main
# DO USE: git revert HEAD instead!
```

### ↩️ REVERT (Creates new commit - Safe for public!)

```bash
git revert HEAD                    # Undo last commit (creates new commit)
git revert abc1234                 # Undo specific commit
git revert --no-edit HEAD          # Auto-confirm, skip editor
git revert HEAD~2..HEAD            # Undo last 2 commits
```

**When to use:** Code already pushed to shared branch. Creates NEW commit that undoes changes. History preserved.

---

## 3️⃣ RESTORE - TARGETED FILE RECOVERY

```bash
git restore file.js                # Discard changes in working tree
git restore --staged file.js       # Unstage file
git restore --source=abc1234 file.js # Restore from specific commit
git checkout HEAD -- file.js       # Old syntax (works same)
```

---

## 4️⃣ REFLOG - YOUR SAFETY NET

```bash
git reflog                         # Show all HEAD movements
git reflog --all                   # All branches
git reset --hard abc1234           # Jump to any reflog entry

# RESCUE: Accidentally did git reset --hard?
git reflog                         # Find the old HEAD hash
git reset --hard abc1234           # Get it back!
```

**Remember:** Reflog keeps recovery available for ~30 days

---

## 5️⃣ CHERRY-PICK - TARGETED COMMITS

```bash
git cherry-pick abc1234            # Apply specific commit
git cherry-pick abc1234 def5678    # Multiple commits
git cherry-pick abc1234..def5678   # Range (exclusive of abc1234)
git cherry-pick --continue         # After resolving conflicts
git cherry-pick --abort            # Cancel cherry-pick
```

**Use case:** Backport hotfix to stable branch without full merge

---

## 6️⃣ REBASE - REPLAY COMMITS (Advanced!)

### Interactive Rebase
```bash
git rebase -i HEAD~3               # Edit last 3 commits
git rebase -i origin/main          # Rebase onto main
```

**In editor:**
- `pick` - Keep commit as-is
- `reword` - Change commit message
- `squash` (s) - Combine with previous
- `fixup` (f) - Squash + discard message
- `edit` - Pause for modifications
- `drop` - Delete commit
- Reorder lines to change order!

**Example: Squash 3 commits into 1**
```bash
git rebase -i HEAD~3

# In editor:
pick abc1234 First commit
squash def5678 Fix typo
squash ghi9012 Add tests

# Save, editor shows combined message
# Edit message, save again
```

### Linear History
```bash
git rebase main                    # Replay current branch onto main
git pull --rebase                  # Pull with rebase instead of merge
```

**⚠️ WARNING:** Never rebase pushed commits! Only local work.

---

## 7️⃣ STASH - TEMPORARY STORAGE

```bash
git stash                          # Save changes temporarily
git stash save "WIP: message"      # With description
git stash list                     # Show all stashes
git stash show stash@{0}           # Show changes in stash
git stash pop                      # Apply + delete
git stash apply                    # Apply (keep stash)
git stash apply stash@{2}          # Apply specific
git stash drop stash@{0}           # Delete
git stash clear                    # Delete all
```

**Workflow:** 
1. Working on feature, urgent bug appears
2. `git stash` - Save work
3. `git checkout main` - Switch branch
4. Fix and merge bug
5. `git checkout feature` - Back to feature
6. `git stash pop` - Resume work

---

## 8️⃣ TAGS & RELEASES

```bash
git tag v1.0.0                     # Lightweight tag
git tag -a v1.0.0 -m "Release 1.0"  # Annotated (preferred)
git tag -l                         # List tags
git tag -l "v1.*"                  # Pattern matching
git show v1.0.0                    # Show tag details
git checkout v1.0.0                # Checkout to tag
git push origin --tags             # Push all tags
git push origin v1.0.0             # Push specific tag
```

---

## 9️⃣ ADVANCED: LOG FILTERING

```bash
# Find commits touching a string
git log -p --all -S "functionName"

# Find commits adding/removing lines
git log -p -U0 --all -G "pattern"

# By commit message
git log --grep="fix.*auth"

# By file path
git log -- src/components/

# Show changes to specific range
git log -L 10,20:file.js           # Lines 10-20 of file.js

# Exclude branches
git log --all --not --decorate main  # All except main

# Pretty format
git log --pretty=format:"%h - %an - %s"

# Stats by author
git log --pretty=format:"%an" | sort | uniq -c
```

---

## 🔟 REAL-WORLD SCENARIOS

### 🚨 Critical Bug in Production
```bash
# 1. Find bad commit
git log --oneline -20

# 2. Revert it (safe - doesn't erase history)
git revert abc1234 --no-edit

# 3. Push to production
git push origin main

# 4. Alert team, investigate root cause
```

### 🔧 Committed to Wrong Branch
```bash
# 1. Find commits
git log --oneline -5

# 2. Create correct branch with those commits
git checkout -b feature/new-api

# 3. Go back to main
git checkout main

# 4. Reset main to before those commits
git reset --hard origin/main

# 5. Force push (ONLY if not shared!)
git push origin main -f
```

### 📌 Deploy Specific Hotfix
```bash
# 1. Find hotfix in develop
git log develop --oneline | grep "hotfix"

# 2. Switch to release branch
git checkout release/1.2.3

# 3. Cherry-pick the hotfix
git cherry-pick abc1234

# 4. Push and deploy
git push origin release/1.2.3
```

### 🎯 Clean Commit History Before PR
```bash
# 1. Interactive rebase from main
git rebase -i origin/main

# 2. In editor, squash all to one:
# pick abc1234 Initial feature
# s def5678 Fix typo
# s ghi9012 Add tests

# 3. Edit message, save

# 4. Force push feature branch
git push origin feature/name -f
```

### 🔍 Find When Function Was Deleted
```bash
# 1. Search deleted content
git log -p --all -S "functionName" -- src/

# 2. Find the commit that removed it
# (check the - lines in diff)

# 3. View before/after
git show abc1234^:src/file.js    # Before deletion
git show abc1234:src/file.js     # After deletion

# 4. Recover if needed
git show abc1234^:src/file.js > recovered.js
```

---

## 💡 PRO TIPS FOR IT ENVIRONMENTS

### Useful Aliases
```bash
# Add to ~/.gitconfig or run:
git config --global alias.log-tree "log --graph --all --decorate --oneline"
git config --global alias.unstage "restore --staged"
git config --global alias.last "log -1 HEAD"
git config --global alias.changed "status -s"
git config --global alias.amend "commit --amend --no-edit"

# Usage:
git log-tree              # Beautiful branch visualization
git unstage file.js       # Clear unstaging
git amend                 # Add to last commit
```

### One-Liners for Debugging
```bash
# Total commits in repo
git rev-list --all --count

# Contributors ranking
git shortlog -s -n

# Most changed files
git log --pretty=format: --name-only | sort | uniq -c | sort -rn | head -10

# Commits per day last 30 days
git log --since="30 days ago" --pretty=format:"%ad" --date=short | sort | uniq -c

# Size of repo
git count-objects -v
```

### Safe Defaults for Teams
```bash
# Prevent accidental force push to main
git config --global receive.denyForcePush true

# Auto-squash enabled
git config --global rebase.autoSquash true

# Require PR reviews
# (Set in GitHub/GitLab settings, not git config)

# Default to rebase on pull (cleaner history)
git config --global pull.rebase true
```

---

## ❓ DECISION FLOWCHART

```
Did you push the code?
  ├─ NO, and you want to erase commits
  │   └─→ Use git reset --hard (if not shared)
  │
  ├─ NO, and you want to fix last commit
  │   └─→ Use git reset --soft HEAD~1, then re-commit
  │
  └─ YES, code is public
      ├─ Minor fix?
      │   └─→ Use git revert (creates new commit)
      │
      ├─ Need to backport to another branch?
      │   └─→ Use git cherry-pick
      │
      └─ Need to clean history?
          └─→ Use git rebase -i (but never push after!)
```

---

## 🔐 CRITICAL SAFETY RULES

1. **Never reset public history** - Use revert instead
2. **Always revert published code** - Preserve causality for team
3. **Test cherry-picks** - Different context = new bugs
4. **Squash only unpushed commits** - Rewrite history carefully
5. **Use reflog recovery** - You have 30 days to undo reset
6. **Tag releases** - Makes rollback trackable and reproducible
7. **Document incident** - Why was code reverted? For audit trail

---

## QUICK REFERENCE TABLE

| Need | Command | Safety |
|------|---------|--------|
| View history | `git log --oneline` | ✓ Safe |
| Undo unstaged | `git restore file.js` | ⚠️ Destructive |
| Undo staged | `git restore --staged file.js` | ✓ Safe |
| Undo last commit (unpushed) | `git reset --soft HEAD~1` | ✓ Safe |
| Undo published commit | `git revert HEAD` | ✓ Safe |
| Erase commits (unpushed) | `git reset --hard HEAD~3` | ⚠️ Destructive |
| Cherry-pick commit | `git cherry-pick abc1234` | ✓ Safe |
| Clean history (unpushed) | `git rebase -i HEAD~5` | ✓ Safe |
| Find deleted code | `git log -p -S "code"` | ✓ Safe |
| Recover from reset | `git reflog` → `git reset --hard` | ✓ Safe |

---

**Remember:** In git, nothing is ever truly lost if you know where to look. When in doubt, check reflog first!
