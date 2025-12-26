# Setup Work Branch Merge Plan - December 26, 2025 14:38:21 EST

**Date Created:** December 26, 2025 14:38:21 EST  
**Source Branch:** `setup-work-attempt-20251209-130112`  
**Target Branch:** `feature/merge-setup-work-improvements` (new branch)  
**Status:** Ready to Execute

---

## Executive Summary

This plan merges selected improvements from `setup-work-attempt-20251209-130112` branch:
1. **Setup Targets** - Unique automation for scanner and dependency setup
2. **verify_scanner.sh Changes** - Enhanced debugging output

**Excluded:**
- Wrapper scripts (main has better approaches)
- Makefile version switching changes (obsolete)
- Makefile server startup changes (redundant)

---

## Branch Strategy

### New Branch Creation

**Branch Name:** `feature/merge-setup-work-improvements`  
**Base:** `main`  
**Purpose:** Merge selected improvements from setup-work branch

**Rationale:**
- Keeps changes isolated
- Allows testing before merging to main
- Follows feature branch workflow

---

## Files to Merge

### 1. Setup Targets (Makefile)

**Source:** `setup-work-attempt-20251209-130112:Makefile`  
**Target:** `Makefile`  
**Changes:**
- Add `setup-scanner` target
- Add `setup-deps` target
- Add `setup-all` target
- Add `setup` target (aliases to setup-all)
- Add help text for setup targets
- Add setup targets to `.PHONY`

**Location in Makefile:**
- After `clean` target (around line 250)
- Before server startup targets

**Lines to Add:** ~124 lines

### 2. verify_scanner.sh Changes

**Source:** `setup-work-attempt-20251209-130112:scripts/verify_scanner.sh`  
**Target:** `scripts/verify_scanner.sh`  
**Changes:**
- Always show switch output (unless quiet mode)
- Show output on errors (not just verbose mode)
- Show make start/stop output (not redirect to /dev/null)

**Lines Changed:** ~21 insertions, ~17 deletions

---

## Merge Steps

### Step 1: Create New Branch and Save Untracked Files

```bash
# Create new branch from main
git checkout main
git pull origin main
git checkout -b feature/merge-setup-work-improvements

# Save current untracked files
git add docs/ci-cd/BRANCH_CLEANUP_ANALYSIS_2025-12-26_141219.md
git add docs/ci-cd/SETUP_WORK_BRANCH_REVIEW_2025-12-26_141831.md
git add docs/ci-cd/SETUP_WORK_COMPARISON_REPORT_2025-12-26_142045.md
git add docs/ci-cd/SETUP_WORK_MERGE_PLAN_2025-12-26_143821.md
git commit -m "docs: Add setup work branch analysis and comparison reports

- Branch cleanup analysis
- Setup work branch review
- Comparison report (wrapper scripts vs. functions)
- Merge plan for selected improvements"
```

### Step 2: Extract Setup Targets from Makefile

**Method:** Manual extraction (cherry-pick may include unwanted changes)

**Process:**
1. View setup targets from branch:
   ```bash
   git show setup-work-attempt-20251209-130112:Makefile | grep -A 100 "setup-scanner:"
   ```

2. Copy setup targets section to Makefile
3. Add to `.PHONY` line
4. Add help text to `help:` target

**Setup Targets to Add:**

```makefile
# ============================================================================
# Setup Targets
# ============================================================================

# Scanner configuration
SCANNER_PATH := /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner
SCANNER_REPO := https://github.com/assetnote/react2shell-scanner.git
SCANNER_SCRIPT := $(SCANNER_PATH)/scanner.py

# Set up the scanner (clone if needed, install dependencies)
setup-scanner:
	@echo "Setting up react2shell-scanner..."
	@if [ ! -d "$(SCANNER_PATH)" ]; then \
		echo "Scanner not found. Creating directory structure..."; \
		mkdir -p "$(dir $(SCANNER_PATH))"; \
		echo "Cloning scanner repository..."; \
		git clone "$(SCANNER_REPO)" "$(SCANNER_PATH)" || { \
			echo "❌ Failed to clone scanner repository"; \
			echo "   Make sure you have git access to $(SCANNER_REPO)"; \
			exit 1; \
		}; \
		echo "✓ Scanner cloned"; \
	else \
		echo "Scanner directory exists. Checking if it's a git repository..."; \
		if [ -d "$(SCANNER_PATH)/.git" ]; then \
			echo "Updating scanner repository..."; \
			cd "$(SCANNER_PATH)" && git pull || echo "⚠️  Could not update scanner (continuing anyway)"; \
		else \
			echo "⚠️  Directory exists but is not a git repository"; \
		fi; \
	fi
	@if [ ! -f "$(SCANNER_SCRIPT)" ]; then \
		echo "❌ Scanner script not found at $(SCANNER_SCRIPT)"; \
		exit 1; \
	fi
	@echo "Installing scanner Python dependencies..."
	@if [ -f "$(SCANNER_PATH)/requirements.txt" ]; then \
		python3 -m pip install --user -q -r "$(SCANNER_PATH)/requirements.txt" || { \
			echo "⚠️  Failed to install scanner dependencies with --user flag, trying without..."; \
			python3 -m pip install -q -r "$(SCANNER_PATH)/requirements.txt" || { \
				echo "❌ Failed to install scanner dependencies"; \
				echo "   Try installing manually: pip install -r $(SCANNER_PATH)/requirements.txt"; \
				exit 1; \
			}; \
		}; \
		echo "✓ Scanner dependencies installed"; \
	else \
		echo "⚠️  No requirements.txt found in scanner directory"; \
	fi
	@echo "✓ Scanner setup complete!"
	@echo "  Scanner location: $(SCANNER_PATH)"
	@echo "  Scanner script: $(SCANNER_SCRIPT)"

# Install npm dependencies for all frameworks
setup-deps:
	@bash -c '\
	set -e; \
	echo "Installing npm dependencies..."; \
	echo "Checking for Node.js/npm..."; \
	if ! command -v npm >/dev/null 2>&1 || [ -f ~/.nvm/nvm.sh ]; then \
		if [ -f ~/.nvm/nvm.sh ]; then \
			echo "Found nvm. Sourcing nvm..."; \
			. ~/.nvm/nvm.sh; \
			# Prefer Node 18+ for Next.js compatibility, fall back to default \
			if nvm list 18 2>/dev/null | grep -q "v18"; then \
				echo "Using Node.js 18 for Next.js compatibility..."; \
				nvm use 18 2>/dev/null || true; \
			elif nvm list 20 2>/dev/null | grep -q "v20"; then \
				echo "Using Node.js 20 for Next.js compatibility..."; \
				nvm use 20 2>/dev/null || true; \
			else \
				echo "Using default Node.js version..."; \
				nvm use default 2>/dev/null || nvm use node 2>/dev/null || true; \
			fi; \
		else \
			if ! command -v npm >/dev/null 2>&1; then \
				echo "❌ npm not found and nvm not available"; \
				echo "   Please install Node.js/npm or nvm"; \
				exit 1; \
			fi; \
		fi; \
	fi; \
	echo "Using Node.js: $$(node --version)"; \
	echo "Using npm: $$(npm --version)"; \
	echo "Installing root dependencies..."; \
	npm install --legacy-peer-deps || { \
		echo "❌ Failed to install root dependencies"; \
		exit 1; \
	}; \
	echo "Installing Vite framework dependencies..."; \
	cd frameworks/vite-react && npm install && cd ../.. || { \
		echo "❌ Failed to install Vite dependencies"; \
		exit 1; \
	}; \
	echo "Installing Next.js framework dependencies..."; \
	cd frameworks/nextjs && npm install --legacy-peer-deps || { \
		echo "❌ Failed to install Next.js dependencies"; \
		exit 1; \
	}; \
	echo "✓ All npm dependencies installed"'

# Complete setup (scanner + deps + test environment)
setup-all: setup-scanner setup-deps test-setup
	@echo ""
	@echo "=========================================="
	@echo "✓ Complete setup finished!"
	@echo "=========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  1. Switch to Next.js mode: make use-nextjs"
	@echo "  2. Start the server: make start"
	@echo "  3. Run scanner verification: ./scripts/verify_scanner.sh"

# Main setup target (sets up everything needed)
setup: setup-all
	@echo ""
	@echo "✓ Setup complete! Project is ready to use."
```

**Update `.PHONY` line:**
Add: `setup setup-scanner setup-deps setup-all`

**Update `help:` target:**
Add help text for setup targets (after "Clean:" section, before "Framework Switching:")

### Step 3: Merge verify_scanner.sh Changes

**Method:** Apply diff manually or use patch

**Changes to Apply:**

1. **Always show switch output** (unless quiet mode):
   ```bash
   # After: switch_output=$(make "nextjs-${version}" 2>&1) || true
   # Add:
   # Always show switch output for debugging (unless quiet mode)
   if [ "${QUIET}" != true ]; then
       echo "$switch_output"
   fi
   ```

2. **Show output on errors** (replace verbose checks):
   ```bash
   # Change from: ${VERBOSE} && echo "$switch_output" >&2
   # To: echo "$switch_output" >&2
   ```
   (Apply to all error output locations)

3. **Show make start/stop output**:
   ```bash
   # Change from: make start > /dev/null 2>&1
   # To: make start 2>&1
   ```
   (Apply to all make start/stop calls)

**Specific Locations:**
- After `switch_output=$(make "nextjs-${version}" 2>&1) || true` - Add output display
- Replace `${VERBOSE} && echo "$switch_output" >&2` with `echo "$switch_output" >&2` (3 locations)
- Replace `make start > /dev/null 2>&1` with `make start 2>&1` (3 locations)
- Replace `make stop > /dev/null 2>&1` with `make stop 2>&1` (2 locations)

### Step 4: Test Changes

```bash
# Test setup targets
make setup-scanner
make setup-deps
make setup-all
make setup

# Test verify_scanner.sh changes
./scripts/verify_scanner.sh --help
# Run a quick test to verify output is shown
```

### Step 5: Commit Changes

```bash
git add Makefile
git add scripts/verify_scanner.sh
git commit -m "feat: Add setup targets and improve verify_scanner.sh debugging

Setup Targets:
- Add setup-scanner target (clone and setup scanner repository)
- Add setup-deps target (install npm dependencies for all frameworks)
- Add setup-all target (complete setup: scanner + deps + test environment)
- Add setup target (main setup command, aliases to setup-all)
- Improve out-of-box experience with single 'make setup' command

verify_scanner.sh Improvements:
- Always show switch output (unless quiet mode) for better debugging
- Show output on errors (not just verbose mode)
- Show make start/stop output (not redirect to /dev/null)
- Enhanced visibility into version switching and server operations

These changes improve the setup experience and debugging capabilities
without adding unnecessary complexity.

Related: docs/ci-cd/SETUP_WORK_COMPARISON_REPORT_2025-12-26_142045.md"
```

### Step 6: Test Locally

```bash
# Full test sequence
make clean
make setup
make use-nextjs
make start
make status
# Test version switching
make nextjs-15.0.4
make stop
```

### Step 7: Create PR

```bash
git push origin feature/merge-setup-work-improvements
# Create PR via GitHub CLI or web interface
```

---

## Detailed Change Specifications

### Makefile Changes

**Location:** After `clean:` target (around line 250)

**Add Setup Section:**
- Scanner configuration variables
- `setup-scanner:` target (~50 lines)
- `setup-deps:` target (~50 lines)
- `setup-all:` target (~10 lines)
- `setup:` target (~3 lines)

**Update `.PHONY` line:**
- Add: `setup setup-scanner setup-deps setup-all`

**Update `help:` target:**
- Add "Setup:" section with all setup target descriptions

### verify_scanner.sh Changes

**File:** `scripts/verify_scanner.sh`

**Change 1: Always show switch output**
- **Location:** After line ~214 (after `switch_output=$(make "nextjs-${version}" 2>&1) || true`)
- **Add:**
  ```bash
  # Always show switch output for debugging (unless quiet mode)
  if [ "${QUIET}" != true ]; then
      echo "$switch_output"
  fi
  ```

**Change 2: Show output on errors (3 locations)**
- **Location 1:** Line ~231 (after "next binary still not found")
  - **Change:** `echo "$switch_output" >&2` (remove `${VERBOSE} &&`)
- **Location 2:** Line ~238 (after "Failed to switch")
  - **Change:** `echo "$switch_output" >&2` (remove `${VERBOSE} &&`)
- **Location 3:** Line ~238 (duplicate, check context)

**Change 3: Show make start/stop output (5 locations)**
- **Location 1:** Line ~391 (make start)
  - **Change:** `make start 2>&1` (remove `> /dev/null 2>&1`)
- **Location 2:** Line ~448 (make stop)
  - **Change:** `make stop 2>&1` (remove `> /dev/null 2>&1`)
- **Location 3:** Line ~449 (make start)
  - **Change:** `make start 2>&1` (remove `> /dev/null 2>&1`)
- **Location 4:** Line ~502 (make stop)
  - **Change:** `make stop 2>&1` (remove `> /dev/null 2>&1`)
- **Location 5:** Line ~503 (make start)
  - **Change:** `make start 2>&1` (remove `> /dev/null 2>&1`)

---

## Conflict Resolution

### Potential Conflicts

**Makefile:**
- May conflict if main has added targets after `clean:`
- Resolution: Place setup targets after `clean:` and before server startup targets
- May conflict with `.PHONY` line if main has added targets
- Resolution: Add setup targets to existing `.PHONY` line

**verify_scanner.sh:**
- May conflict if main has modified same lines
- Resolution: Apply changes manually, review main's current version first

### Conflict Resolution Strategy

1. **Review main's current state:**
   ```bash
   git show main:Makefile | grep -A 5 "clean:"
   git show main:scripts/verify_scanner.sh | grep -A 5 "switch_output"
   ```

2. **Apply changes manually:**
   - Copy setup targets to appropriate location
   - Apply verify_scanner.sh changes line by line
   - Test after each change

3. **If conflicts occur:**
   - Keep main's structure
   - Add branch's improvements
   - Test thoroughly

---

## Testing Checklist

### Setup Targets Testing

- [ ] `make setup-scanner` - Clones scanner if not present
- [ ] `make setup-scanner` - Updates scanner if present
- [ ] `make setup-scanner` - Installs Python dependencies
- [ ] `make setup-deps` - Sources nvm correctly
- [ ] `make setup-deps` - Installs root dependencies
- [ ] `make setup-deps` - Installs Vite dependencies
- [ ] `make setup-deps` - Installs Next.js dependencies
- [ ] `make setup-all` - Runs all setup steps
- [ ] `make setup` - Completes successfully
- [ ] Help text shows setup targets

### verify_scanner.sh Testing

- [ ] Switch output shown (unless quiet mode)
- [ ] Error output shown (not just verbose)
- [ ] make start output shown
- [ ] make stop output shown
- [ ] Quiet mode still works
- [ ] Script runs successfully

### Integration Testing

- [ ] Full setup works: `make setup`
- [ ] Server starts after setup: `make start`
- [ ] Version switching works: `make nextjs-15.0.4`
- [ ] Scanner verification works: `./scripts/verify_scanner.sh`

---

## Success Criteria

### Setup Targets

- ✅ All setup targets work correctly
- ✅ Scanner setup automates manual steps
- ✅ Dependency setup works for all frameworks
- ✅ Single `make setup` command completes all setup
- ✅ Help text is clear and accurate

### verify_scanner.sh

- ✅ Output is visible for debugging
- ✅ Errors show output (not just verbose mode)
- ✅ make start/stop output is visible
- ✅ Quiet mode still suppresses output
- ✅ Script functionality unchanged (only output visibility improved)

---

## Rollback Plan

If issues are discovered:

```bash
# Revert to main
git checkout main
git branch -D feature/merge-setup-work-improvements

# Or revert specific commits
git revert <commit-hash>
```

---

## Related Documentation

- [Setup Work Branch Review](SETUP_WORK_BRANCH_REVIEW_2025-12-26_141831.md) - Full branch analysis
- [Setup Work Comparison Report](SETUP_WORK_COMPARISON_REPORT_2025-12-26_142045.md) - Detailed comparison
- [Branch Cleanup Analysis](BRANCH_CLEANUP_ANALYSIS_2025-12-26_141219.md) - Branch status

---

## Execution Status

- [ ] Step 1: Create branch and save untracked files
- [ ] Step 2: Extract setup targets
- [ ] Step 3: Merge verify_scanner.sh changes
- [ ] Step 4: Test changes
- [ ] Step 5: Commit changes
- [ ] Step 6: Test locally
- [ ] Step 7: Create PR

---

**Date:** December 26, 2025 14:38:21 EST  
**Status:** Ready to Execute  
**Estimated Time:** 30-60 minutes
