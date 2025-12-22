# Next.js 16.0.6 Version Configuration Issue

**Date:** 2025-12-21  
**Issue:** Next.js 16.0.6 does not work with current Node.js version

---

## Problem

Next.js 16.0.6 fails to start when running `simple-run-check.sh`. The server starts but immediately exits with an error.

**Root Cause:**
- Next.js 16.0.6 requires **Node.js >= 20.9.0**
- Current system is running **Node.js v18.20.8**
- Next.js 16.0.6 refuses to run and exits with: `You are using Node.js 18.20.8. For Next.js, Node.js version ">=20.9.0" is required.`

---

## Version Requirements Comparison

| Next.js Version | Node.js Requirements | Works with v18.20.8? |
|----------------|---------------------|---------------------|
| 15.5.6 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | ✅ Yes (18.20.8 >= 18.18.0) |
| 16.0.6 | `>=20.9.0` | ❌ No (18.20.8 < 20.9.0) |

---

## Current Makefile Configuration

**Line 88 in Makefile:**
```makefile
15.0.4|15.1.8|15.2.5|15.3.5|15.4.7|15.5.6|16.0.6) \
    echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
    cd frameworks/nextjs && node -e "..." && npm install --legacy-peer-deps && \
    echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;;
```

**Problem:** Next.js 16.0.6 is grouped with 15.x versions, but it has different Node.js requirements. The Makefile doesn't check Node.js version before switching.

---

## Evidence

### Server Log Output:
```
You are using Node.js 18.20.8. For Next.js, Node.js version ">=20.9.0" is required.
```

### npm Engine Check:
```bash
$ npm view next@16.0.6 engines
{ node: '>=20.9.0' }

$ npm view next@15.5.6 engines
{ node: '^18.18.0 || ^19.8.0 || >= 20.0.0' }
```

### simple-run-check.sh Behavior:
- All versions 14.0.0 through 15.5.6: ✅ Work correctly
- Version 16.0.6: ❌ Server starts but exits immediately, curl returns empty

---

## Solution Options

### Option 1: Add Node.js Version Check (Recommended)
Add a check in the Makefile to verify Node.js version before switching to 16.0.6:

```makefile
16.0.6) \
    @NODE_VERSION=$$(node -v | sed 's/v//'); \
    REQUIRED_VERSION="20.9.0"; \
    if [ "$$(printf '%s\n' "$$REQUIRED_VERSION" "$$NODE_VERSION" | sort -V | head -n1)" != "$$REQUIRED_VERSION" ]; then \
        echo "❌ Error: Next.js 16.0.6 requires Node.js >= 20.9.0"; \
        echo "   Current Node.js version: $$NODE_VERSION"; \
        echo "   Please upgrade Node.js or skip this version"; \
        exit 1; \
    fi; \
    echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
    cd frameworks/nextjs && node -e "..." && npm install --legacy-peer-deps && \
    echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;;
```

### Option 2: Separate 16.0.6 Case with Warning
Separate 16.0.6 into its own case and add a warning, but allow it to proceed:

```makefile
16.0.6) \
    echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
    echo "⚠️  Warning: Next.js 16.0.6 requires Node.js >= 20.9.0"; \
    echo "   Current Node.js version: $$(node -v)"; \
    echo "   Server may not start if Node.js version is too old"; \
    cd frameworks/nextjs && node -e "..." && npm install --legacy-peer-deps && \
    echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;;
```

### Option 3: Remove 16.0.6 from Test Suite
If Node.js 20.9.0+ is not available, remove 16.0.6 from the test suite or document it as requiring a newer Node.js version.

---

## Solution Implemented

**Option 1 was implemented** - Added a Node.js version check in the Makefile that prevents switching to 16.0.6 if the Node.js version is too old.

**Makefile Changes (Line 92-101):**
- Separated 16.0.6 from the 15.x versions case
- Added Node.js version check using `$$$$(node -v | cut -d. -f1 | sed 's/v//')` to extract major version
- Checks if Node.js major version is less than 20
- Shows clear error message and exits if version requirement not met

**Note:** Uses `$$$$` (four dollar signs) in Makefile to properly escape `$` for shell command substitution.

---

## Impact

- **Before Fix:** Next.js 16.0.6 silently fails in `simple-run-check.sh` (server starts but exits immediately, curl returns empty)
- **After Fix:** Next.js 16.0.6 now:
  - ✅ Shows clear error message if Node.js < 20.9.0: "❌ Error: Next.js 16.0.6 requires Node.js >= 20.9.0"
  - ✅ Prevents version switch if Node.js version is too old
  - ✅ Will work correctly when Node.js >= 20.9.0 is available

**Test Results:**
- ✅ `make nextjs-16.0.6` with Node.js 18.20.8: Shows error and exits
- ✅ `make nextjs-15.5.6` with Node.js 18.20.8: Works correctly
- ✅ Other versions continue to work as expected

---

**Report Generated:** 2025-12-21  
**Status:** ✅ Issue identified and fixed
