# Git Worktree Guide: Multi-Agent Workflow Solution

**Date:** 2025-12-24  
**Purpose:** Complete guide to using git worktree for isolated multi-agent development  
**Use Case:** Viewing and working with remote branch content without affecting main working directory

---

## Overview

Git worktree allows you to check out multiple branches of the same repository in separate directories. Each worktree has its own working directory but shares the same `.git` repository. This is perfect for scenarios where multiple agents need to work on different branches simultaneously without conflicts.

---

## What is Git Worktree?

### Concept

`git worktree` lets you check out multiple branches of the same repository in separate directories. Each worktree has its own working directory but shares the same `.git` repository.

### How It Works

```
Main Repository:
/Users/lblackb/data/lblackb/git/react2shell-server/
├── .git/                    # Shared repository
├── [current files]          # feature/implement-lint-job (other agent)
└── .git/worktrees/          # Worktree metadata (created automatically)

Worktree (new):
/Users/lblackb/data/lblackb/git/react2shell-server-readme-analysis/
├── [linked to same .git]    # feature/readme-analysis-review
└── [separate working files]
```

---

## Requirements

### Git Version
- **Minimum:** Git 2.5+ (released 2015)
- **Your Version:** Git 2.50.1 ✅ (fully supported)

### Disk Space
- Each worktree uses disk space for working files (not a full clone)
- Much more efficient than cloning the entire repository multiple times
- Shared object database saves significant space

### Configuration
- **No special config needed** - works out of the box
- No repository modifications required
- Standard git installation is sufficient

---

## What Gets Shared vs. Separate

### Shared (Same `.git` Repository)

- ✅ Repository history (all commits)
- ✅ Branches, tags, remotes
- ✅ Git configuration
- ✅ Object database (blobs, trees, commits)
- ✅ Refs (branch pointers, tags)

### Separate (Per Worktree)

- ✅ Working directory files
- ✅ Current branch/HEAD
- ✅ Index (staging area)
- ✅ Git hooks (can be per-worktree)
- ✅ `.git` file (pointer to main repository)

---

## Benefits for Multi-Agent Scenarios

### 1. Complete Isolation
- **Other agent:** Works on `feature/implement-lint-job` in main directory
- **You:** Work on `feature/readme-analysis-review` in worktree
- **Result:** Zero conflicts, no interference

### 2. No Interference
- Separate working directories
- Can work simultaneously
- No need to stash/commit before switching
- No risk of overwriting each other work

### 3. Full Functionality
- Browse files normally
- Edit files with any editor
- Run commands (make, npm, etc.)
- Commit changes independently
- Push/pull independently

### 4. Easy Cleanup
- Remove worktree when done
- No impact on main repository
- No leftover files or config

---

## Usage Examples

### Basic Workflow

```bash
# 1. On remote server: Push the branch first
ssh lblackb@k2-s0.local
cd ~/start/git/react2shell-server
git checkout -b feature/readme-analysis-review
git add docs/analysis/README_ANALYSIS_2025-12-24.md
git commit -m "docs: Add README analysis report"
git push -u origin feature/readme-analysis-review

# 2. On local machine: Fetch and create worktree
cd /Users/lblackb/data/lblackb/git/react2shell-server
git fetch origin feature/readme-analysis-review

# 3. Create worktree (outside main directory)
git worktree add ../react2shell-server-readme-analysis feature/readme-analysis-review

# 4. Use the worktree
cd ../react2shell-server-readme-analysis
cat docs/analysis/README_ANALYSIS_2025-12-24.md
# Browse, edit, commit, etc.

# 5. When done, remove it
cd /Users/lblackb/data/lblackb/git/react2shell-server
git worktree remove ../react2shell-server-readme-analysis
```

---

## Git Worktree Commands

### List All Worktrees
```bash
git worktree list
```

### Add New Worktree
```bash
# Create worktree and checkout existing branch
git worktree add <path> <branch>

# Create worktree and create new branch
git worktree add <path> -b <new-branch>

# Create worktree with detached HEAD
git worktree add <path> --detach <commit>
```

### Remove Worktree
```bash
git worktree remove <path>
```

### Lock Worktree
```bash
git worktree lock <path> --reason "Long-term analysis work"
git worktree unlock <path>
```

### Prune Stale Worktree Entries
```bash
git worktree prune
```

---

## Complete Workflow: Multi-Agent Scenario

### Step-by-Step Workflow

#### Step 1: Remote Server - Create Branch and Commit
```bash
ssh lblackb@k2-s0.local
cd ~/start/git/react2shell-server
git checkout -b feature/readme-analysis-review
# ... work happens ...
git add docs/analysis/README_ANALYSIS_2025-12-24.md
git commit -m "docs: Add README analysis report"
git push -u origin feature/readme-analysis-review
```

#### Step 2: Local Machine - Fetch Branch
```bash
cd /Users/lblackb/data/lblackb/git/react2shell-server
git fetch origin feature/readme-analysis-review
```

#### Step 3: Local Machine - Create Worktree
```bash
git worktree add ../react2shell-server-readme-analysis feature/readme-analysis-review
```

#### Step 4: Local Machine - Use Worktree
```bash
cd ../react2shell-server-readme-analysis
ls -la docs/analysis/
cat docs/analysis/README_ANALYSIS_2025-12-24.md
```

#### Step 5: Local Machine - Cleanup
```bash
cd /Users/lblackb/data/lblackb/git/react2shell-server
git worktree remove ../react2shell-server-readme-analysis
```

---

## Summary

### When to Use Git Worktree

✅ **Perfect For:**
- Multiple agents working on different branches
- Viewing remote branch content without affecting main directory
- Long-running work on separate branches
- Testing changes without affecting main work

### Key Benefits

1. **Complete Isolation:** No conflicts with other work
2. **Full Functionality:** Full git and file system access
3. **Easy Management:** Simple add/remove commands
4. **Efficient:** Shared repository, minimal overhead
5. **Standard Git:** Built-in feature, no special tools

### Quick Reference

```bash
# Create worktree
git worktree add <path> <branch>

# List worktrees
git worktree list

# Remove worktree
git worktree remove <path>
```

---

**Last Updated:** 2025-12-24  
**Status:** Active Reference Guide
