# Design Proposal: Make `test-nextjs-startup` Work Out of the Box

**Date:** 2025-12-22  
**Status:** ✅ **SELECTED AND IMPLEMENTED**  
**Author:** AI Assistant

---

## Executive Summary

### Problem
The `make test-nextjs-startup` target fails on fresh systems because it requires Next.js dependencies to be installed, but there's no Makefile target that ensures this happens automatically.

### Root Cause
The `ensure_node_version` function tries to use `semver` from `frameworks/nextjs/node_modules/semver`, but on a fresh clone, `node_modules` doesn't exist yet, causing version checks to fail before dependencies can be installed.

### ✅ Recommended Solution (Full Implementation) - **SELECTED**

**Create an `install-nextjs-deps` target** that ensures initial Next.js dependencies are installed, following the make-templates pattern. This target will:

1. **Depend on `use-nextjs`** - Ensures framework mode is set to Next.js
2. **Depend on `install-node`** - Ensures Node.js is available (which ensures nvm is installed)
3. **Install initial dependencies** - Runs `npm install --legacy-peer-deps` in `frameworks/nextjs` if `node_modules` doesn't exist

**Then update three locations:**

1. **`test-nextjs-startup` target** - Add `install-nextjs-deps` as a dependency
2. **`ensure_node_version` function** - Call `install-nextjs-deps` at the start to ensure semver is available
3. **`switch_nextjs_version` function** - Call `install-nextjs-deps` after ensuring node is installed

### Expected Outcome
After implementation, `make test-nextjs-startup` will work out of the box on a fresh system, automatically installing all prerequisites and passing all 11 version tests.

### Implementation Complexity
- **Low** - Follows existing patterns, all changes are additive
- **Estimated Changes:** 4 locations in Makefile
- **Risk:** Low - All operations are idempotent

---

## Problem Statement

The `make test-nextjs-startup` target currently fails on a fresh system because it requires several prerequisites that are not automatically installed:

1. **Next.js framework mode must be set** - The test script handles this, but it's better to have it as a Makefile dependency
2. **Initial dependencies must be installed** - `frameworks/nextjs/node_modules` must exist for the semver check in `ensure_node_version` to work
3. **Node.js/nvm must be available** - Already handled by switch targets, but needs to be verified

### Current Behavior

From the test output:
- ✅ 1 version succeeded (16.0.6) - worked after some dependencies were installed
- ❌ 10 versions failed (14.0.0, 14.1.0, 15.0.4, 15.1.8, 15.2.5, 15.3.5, 15.4.7, 15.5.6, 14.0.1, 14.1.1) - failed during switch

The failures occur because:
1. The `ensure_node_version` function tries to use `semver` from `frameworks/nextjs/node_modules/semver`
2. If `node_modules` doesn't exist, the semver check fails
3. The switch targets fail before they can install dependencies

---

## Root Cause Analysis

### Issue 1: Missing Initial Dependencies

**Location:** `Makefile` line 86 in `ensure_node_version` function

```makefile
CHECK_RESULT=$$$$(cd frameworks/nextjs && node -e "const semver=require('semver');process.exit(semver.satisfies(process.version, '>=$$$$REQUIRED') ? 0 : 1)" 2>&1);
```

**Problem:** This requires `frameworks/nextjs/node_modules/semver` to exist, but on a fresh clone, `node_modules` doesn't exist yet.

**Impact:** The version check fails, causing the switch to fail before it can install dependencies.

### Issue 2: Missing Framework Mode Dependency

**Location:** `Makefile` line 926 in `test-nextjs-startup` target

```makefile
test-nextjs-startup: jq
```

**Problem:** Only depends on `jq`, but doesn't ensure:
- Next.js framework mode is set (`.framework-mode` file contains "nextjs")
- Initial Next.js dependencies are installed

**Impact:** The test script handles framework mode, but if the Makefile doesn't ensure it, there's a race condition.

### Issue 3: No Target for Initial Next.js Dependencies

**Problem:** There's no Makefile target that ensures initial Next.js dependencies are installed before version switching.

**Impact:** Version switching targets can't work on a fresh system because they need `node_modules` to exist for the semver check.

---

## Recommended Solution (Full Implementation)

> **⭐ This is the recommended approach for a complete solution**

The solution follows the make-templates pattern of declaring dependencies and installing them automatically. It requires creating one new target and updating three existing locations.

### Step 1: Create `install-nextjs-deps` Target

**Pattern:** Follow make-templates pattern where dependencies are installed as needed.

**Implementation:**
```makefile
.PHONY: install-nextjs-deps
install-nextjs-deps: use-nextjs install-node ## install initial Next.js dependencies
	@if [ -f frameworks/nextjs/package.json ]; then \
		if [ -d frameworks/nextjs/node_modules ]; then \
			echo "✓ Next.js dependencies already installed, skipping"; \
		else \
			echo "Installing initial Next.js dependencies..."; \
			cd frameworks/nextjs && npm install --legacy-peer-deps && echo "✓ Next.js dependencies installed"; \
		fi; \
	else \
		echo "⚠️  frameworks/nextjs/package.json not found, skipping"; \
	fi
```

**Dependencies:**
- `use-nextjs` - Ensures framework mode is set
- `install-node` - Ensures Node.js is available (which ensures nvm is installed)

**Benefits:**
- Idempotent (can be run multiple times safely)
- Follows make-templates pattern
- Ensures all prerequisites are met

### Step 2: Update `ensure_node_version` Function

**Current Code:** Line 86 tries to use semver, fails if node_modules doesn't exist.

**Proposed Change:**
```makefile
define ensure_node_version
	@# First ensure node is installed (which ensures nvm is installed)
	@$(MAKE) -s install-node > /dev/null 2>&1 || true; \
	CURRENT_NODE=$$$$(node -v 2>/dev/null | sed 's/v//' || echo "unknown"); \
	REQUIRED="$(1)"; \
	if ! command -v node >/dev/null 2>&1; then \
		echo "❌ Error: Node.js not found. Installing..."; \
		$(MAKE) -s install-node; \
	fi; \
	# Check if semver is available, if not, use basic version comparison
	if [ -d "frameworks/nextjs/node_modules/semver" ]; then \
		CHECK_RESULT=$$$$(cd frameworks/nextjs && node -e "const semver=require('semver');process.exit(semver.satisfies(process.version, '>=$$$$REQUIRED') ? 0 : 1)" 2>&1); \
		CHECK_EXIT=$$$$?; \
	else \
		# Fallback: basic version comparison using node's built-in capabilities
		CHECK_RESULT=$$$$(node -e "const [major, minor, patch] = process.version.slice(1).split('.').map(Number); const [reqMajor, reqMinor, reqPatch] = '$$$$REQUIRED'.split('.').map(Number); const satisfies = major > reqMajor || (major === reqMajor && (minor > reqMinor || (minor === reqMinor && patch >= reqPatch))); process.exit(satisfies ? 0 : 1)" 2>&1); \
		CHECK_EXIT=$$$$?; \
	fi; \
	# ... rest of function
endef
```

**Implementation:** Use the simpler approach - ensure dependencies are installed first by calling `install-nextjs-deps` at the start of the function.

**Code Change:**
```makefile
define ensure_node_version
	@# Ensure Next.js dependencies are installed (needed for semver check)
	@$(MAKE) -s install-nextjs-deps > /dev/null 2>&1 || true; \
	# ... existing code continues ...
endef
```

### Step 3: Update `switch_nextjs_version` Function

**Current:** Line 152 ensures node is installed, but doesn't ensure Next.js dependencies.

**Proposed:**
```makefile
define switch_nextjs_version
	@if ! grep -q '^nextjs' .framework-mode 2>/dev/null; then \
		echo "⚠️  Error: Next.js version switching only available in Next.js mode"; \
		echo "   Run 'make use-nextjs' first to switch to Next.js mode"; \
		exit 1; \
	fi
	@# Ensure node is installed (which ensures nvm is installed)
	@$(MAKE) -s install-node > /dev/null 2>&1 || true
	@# Ensure initial Next.js dependencies are installed (needed for semver check)
	@$(MAKE) -s install-nextjs-deps > /dev/null 2>&1 || true
	@# Get required Node.js version and ensure it's active
	@$(call ensure_node_version,$(call get_node_version,$(1)))
	# ... rest of function
endef
```

**Benefits:**
- Ensures dependencies exist before trying to use semver
- Makes version switching work even on fresh systems
- Follows dependency pattern

### Step 4: Update `test-nextjs-startup` Target

**Current:**
```makefile
test-nextjs-startup: jq
```

**Proposed:**
```makefile
test-nextjs-startup: jq install-nextjs-deps
```

**Benefits:**
- Ensures all prerequisites are met before running the test
- Follows make-templates pattern of declaring dependencies
- Makes the target work out of the box

---

## Complete Implementation Plan

### Implementation Checklist

- [ ] **Step 1:** Create `install-nextjs-deps` target
  - Add target after `install-node` target (around line 456)
  - Make it depend on `use-nextjs` and `install-node`
  - Check if `node_modules` exists, install if not
  - Add to `.PHONY` declaration

- [ ] **Step 2:** Update `ensure_node_version` function
  - Add call to `install-nextjs-deps` at the start of the function (before semver check)
  - This ensures semver is available before the version check

- [ ] **Step 3:** Update `switch_nextjs_version` function
  - Add call to `install-nextjs-deps` after `install-node` call
  - This ensures dependencies exist before version switching

- [ ] **Step 4:** Update `test-nextjs-startup` target
  - Add `install-nextjs-deps` as a dependency (after `jq`)
  - This ensures everything is ready before the test runs

- [ ] **Step 5:** (Optional) Update help text
  - Add `install-nextjs-deps` to help output if desired (can be internal target)
  - Update `test-nextjs-startup` description if needed

---

## Expected Behavior After Changes

### Fresh System (No Dependencies Installed)

```bash
$ make test-nextjs-startup
```

**What happens:**
1. `test-nextjs-startup` depends on `jq` → installs jq if needed
2. `test-nextjs-startup` depends on `install-nextjs-deps` → triggers:
   - `install-nextjs-deps` depends on `use-nextjs` → sets framework mode
   - `install-nextjs-deps` depends on `install-node` → installs nvm and Node.js
   - `install-nextjs-deps` installs initial Next.js dependencies
3. Test script runs and calls `make nextjs-14.0.0`:
   - `switch_nextjs_version` ensures node and dependencies are installed
   - `ensure_node_version` can use semver (dependencies exist)
   - Version switch succeeds
   - Server starts successfully
   - Test passes

**Result:** All 11 versions should pass on a fresh system.

---

## Alternative Approaches Considered

### Alternative 1: Make semver check optional

**Approach:** Use basic version comparison if semver is not available.

**Rejected because:**
- Less accurate than semver
- Adds complexity to version checking logic
- Doesn't solve the root problem (dependencies should be installed)

### Alternative 2: Install dependencies in test script

**Approach:** Have the test script install dependencies before running.

**Rejected because:**
- Violates make-templates pattern (dependencies should be Makefile targets)
- Makes the test script more complex
- Doesn't help other targets that need dependencies

### Alternative 3: Make setup a dependency

**Approach:** Make `test-nextjs-startup` depend on `setup`.

**Rejected because:**
- `setup` installs all dependencies (server, vite, nextjs) which is overkill
- We only need Next.js dependencies for this test
- Doesn't follow the pattern of installing only what's needed

---

## Testing Plan

### Test Case 1: Fresh System
1. Remove `.framework-mode`, `node_modules` directories, uninstall nvm
2. Run `make test-nextjs-startup`
3. **Expected:** All 11 versions pass

### Test Case 2: Partial Setup
1. Have nvm/node installed, but no Next.js dependencies
2. Run `make test-nextjs-startup`
3. **Expected:** Dependencies install automatically, all versions pass

### Test Case 3: Full Setup
1. Everything already installed
2. Run `make test-nextjs-startup`
3. **Expected:** No redundant installations, all versions pass

### Test Case 4: Individual Version Switch
1. Fresh system
2. Run `make nextjs-14.0.0`
3. **Expected:** Dependencies install automatically, switch succeeds

---

## Risk Assessment

### Low Risk
- Changes follow existing patterns (make-templates)
- All changes are additive (no breaking changes)
- Idempotent operations (safe to run multiple times)

### Medium Risk
- `install-nextjs-deps` might install dependencies that aren't needed for all use cases
  - **Mitigation:** Only installs if `node_modules` doesn't exist
  - **Mitigation:** Uses `--legacy-peer-deps` flag (already used elsewhere)

### No Risk
- Changes are internal to Makefile
- No API changes
- Backward compatible

---

## Summary

### Recommended Solution Overview

The **recommended full solution** follows the make-templates pattern of declaring dependencies and installing them automatically. By creating an `install-nextjs-deps` target and integrating it into the dependency chain, we ensure that:

1. ✅ All prerequisites are installed automatically
2. ✅ The test works out of the box on a fresh system
3. ✅ The pattern is consistent with other targets
4. ✅ No manual setup steps are required

### Key Changes Required

1. **Create `install-nextjs-deps` target** - Installs initial Next.js dependencies, depends on `use-nextjs` and `install-node`
2. **Update `ensure_node_version` function** - Call `install-nextjs-deps` at start to ensure semver is available
3. **Update `switch_nextjs_version` function** - Call `install-nextjs-deps` after `install-node` to ensure dependencies exist
4. **Update `test-nextjs-startup` target** - Add `install-nextjs-deps` as a dependency

### Expected Impact

- ✅ **Fixes 10 failing test cases** - All 11 Next.js versions will pass on fresh systems
- ✅ **Makes `test-nextjs-startup` work out of the box** - No manual setup required
- ✅ **Makes individual version switches work on fresh systems** - `make nextjs-14.0.0` etc. will work automatically
- ✅ **Follows established patterns** - Consistent with make-templates dependency pattern
- ✅ **Low risk** - All operations are idempotent, no breaking changes

---

## Implementation Status

**Status:** ✅ **IMPLEMENTED**  
**Implementation Date:** 2025-12-22

### Changes Made

1. ✅ Created `install-nextjs-deps-internal` target (depends on `use-nextjs` and `install-node`)
2. ✅ Created `install-nextjs-deps` convenience target
3. ✅ Updated `ensure_node_version` function to call `install-nextjs-deps-internal` at start
4. ✅ Updated `switch_nextjs_version` function to call `install-nextjs-deps-internal` after `install-node`
5. ✅ Updated `test-nextjs-startup` target to depend on `install-nextjs-deps-internal`
6. ✅ Updated `.PHONY` declaration to include new targets

### Verification

After implementation, `make test-nextjs-startup` should work out of the box on a fresh system.
