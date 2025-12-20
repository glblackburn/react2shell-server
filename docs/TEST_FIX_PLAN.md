# Test Fix Plan: `make test` - Iterative Fix Loop

**Date:** 2025-12-19  
**Last Updated:** 2025-12-20  
**Status:** Active - Iterative Fix Loop in Progress  
**Goal:** Fix `make test` to run and pass consistently by fixing one error at a time

---

## Executive Summary

This document outlines the **iterative fix loop** approach to fix `make test`. The process is simple: **Run test → Stop at first error → Analyze → Fix → Test again → Repeat** until all tests pass.

**Target:** `make test`  
**Command:** `./scripts/run_make_test_stop_on_error.sh`  
**Scope:** This plan focuses ONLY on `make test`. Other test targets will be addressed after `make test` is working.

**Key Principle:** Fix ONE error at a time. Stop immediately at the first error. Do not continue past the first failure.

---

## The Iterative Fix Loop Process

**This is the ONLY process we follow. All fixes follow this loop.**

### The 7-Step Loop

1. **Run Test (Stop at First Error)**
   ```bash
   ./scripts/run_make_test_stop_on_error.sh
   ```
   - Script uses pytest `-x` flag to stop immediately at first failure
   - Script exits with code 1 if error detected, code 0 if all pass
   - All output saved to `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/`

2. **Stop at First Error** (Automatic)
   - Pytest's `-x` flag stops immediately when first test fails
   - No more tests run after first failure
   - Script exits with code 1

3. **Analyze the Error**
   - Review error message and stack trace from `output/make-test-live.txt`
   - Check server logs: `logs/server.log`, `logs/vite.log`
   - Check port status: `netstat -an | grep LISTEN | grep -E "\.300[0-9]|\.5173"`
   - Check process status: `files-after/processes-after.txt`
   - Identify root cause
   - Document in `iterations/iteration-N/error-analysis.txt`

4. **Devise Fix**
   - Based on root cause analysis
   - Plan code changes needed
   - Consider edge cases
   - Document fix plan

5. **Apply Fix**
   - Make code changes
   - Ensure fix addresses root cause
   - Document in `iterations/iteration-N/fix-applied.txt`:
     - Files changed
     - What was changed
     - Why it fixes the error

6. **Test Fix**
   ```bash
   ./scripts/run_make_test_stop_on_error.sh
   ```
   - Exit code 0: ✅ Success! All tests pass.
   - Exit code 1: ❌ New error detected. Go to step 3 (analyze new error).

7. **Repeat**
   - Continue until script exits with code 0
   - Each iteration fixes ONE error
   - Track all errors and fixes in summary files

### Key Principles

1. **ONE error at a time** - Fix the first error, test, then move to next
2. **Stop immediately** - Pytest `-x` flag ensures this automatically
3. **Analyze completely** - Understand root cause before fixing
4. **Test after each fix** - Verify fix works before moving on
5. **Document everything** - Save all output, analysis, fixes

---

## How to Run Tests

### Recommended: Use the Stop-on-First-Error Script

**Script:** `scripts/run_make_test_stop_on_error.sh`

**Usage:**
```bash
# Clean state
make stop

# Run test (stops at first error automatically)
./scripts/run_make_test_stop_on_error.sh
```

**What it does:**
1. Captures initial state (processes, ports, framework mode)
2. Stops any running servers
3. Starts servers if needed (framework-aware)
4. Runs `pytest tests/ -v -x --tb=short --maxfail=1`
   - `-x`: Stop at first failure
   - `--maxfail=1`: Stop after 1 failure (explicit)
   - `-v`: Verbose output
   - `--tb=short`: Shorter traceback format
5. **Stops immediately** when pytest detects first failure
6. Captures final state and logs
7. Exits with code 0 (success) or 1 (error detected)

**Output Location:**
- `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/` (or specified directory)
- Live output: `output/make-test-live.txt`
- Exit code: `output/make-test-exitcode.txt`
- Duration: `output/make-test-duration.txt`
- Before/after state: `files-before/`, `files-after/`
- Server logs: `logs/`

**Exit Codes:**
- `0` - All tests passed
- `1` - Error or failure detected (stopped at first error)

### Alternative: Manual Run

```bash
# Clean state
make stop

# Start servers if needed
make start

# Run pytest directly with -x flag (stops at first failure)
venv/bin/pytest tests/ -v -x --tb=short
```

---

## Output Capture

**All output must be captured for analysis.** The script handles this automatically, but here's what gets captured:

### Directory Structure

```
/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/
├── output/                    # Test execution output
│   ├── make-test-live.txt     # Live output (stdout/stderr)
│   ├── make-test-exitcode.txt # Exit code (0 or 1)
│   ├── make-test-duration.txt # Execution time
│   └── test-metadata.txt      # Environment info
├── files-before/              # System state before test
│   ├── processes-before.txt
│   ├── ports-before.txt
│   ├── framework-mode-before.txt
│   └── server-status-before.txt
├── files-after/               # System state after test
│   ├── processes-after.txt
│   ├── ports-after.txt
│   └── server-status-after.txt
├── logs/                      # Server logs
│   ├── server.log
│   └── vite.log
├── iterations/                # Per-iteration analysis
│   ├── iteration-1/
│   │   ├── error-analysis.txt
│   │   └── fix-applied.txt
│   └── iteration-2/
└── summary/                   # Overall summary
    ├── all-errors-found.txt
    ├── all-fixes-applied.txt
    └── final-status.txt
```

### What to Document After Each Iteration

1. **Error Analysis** (`iterations/iteration-N/error-analysis.txt`):
   - Error message and stack trace
   - Which test failed
   - Root cause analysis
   - Port/process status
   - Server log excerpts

2. **Fix Applied** (`iterations/iteration-N/fix-applied.txt`):
   - Files changed
   - What was changed
   - Why it fixes the error

3. **Update Summary Files:**
   - Add error to `summary/all-errors-found.txt`
   - Add fix to `summary/all-fixes-applied.txt`
   - Update `summary/final-status.txt`

---

## Known Issues (Status Tracking)

This section tracks known issues that may appear. Status: ✅ **FIXED**, 🔴 **OUTSTANDING**, 🟡 **PENDING**, or 🟢 **PARTIALLY FIXED**.

### Issue 1: Port Conflicts - Multiple Servers on Different Ports

**Status:** ✅ **FIXED** (Iteration 1)  
**Priority:** CRITICAL

**Symptoms:**
- Multiple Next.js servers running on ports 3001-3008
- Server starts on wrong port when 3000 is occupied
- Error: `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`

**Root Cause:**
- Next.js auto-increments port when 3000 is in use
- Ports not cleaned up between test runs

**Fix Applied:**
- Added `_cleanup_all_test_ports()` function to clean up ports 3000-3010, 5173
- Updated `start_servers()` and `react_version` fixture to call cleanup before starting
- Added verification that ports are free before starting servers

**Files Changed:**
- `tests/utils/server_manager.py` - Added `_cleanup_all_test_ports()` function
- `tests/fixtures/version.py` - Added port cleanup before version switch

---

### Issue 2: Server Not Ready When Test Navigates

**Status:** 🔴 **OUTSTANDING** (Current issue)  
**Priority:** CRITICAL

**Symptoms:**
- Error: `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`
- Test fails immediately when trying to navigate
- Server may have just been restarted by `react_version` fixture

**Root Cause:**
- Race condition: `react_version` fixture restarts servers, but `app_page` fixture navigates before server is fully ready
- `wait_for_server()` may return True but server not actually responding yet

**Fix Attempted:**
- Added server readiness check in `app_page` fixture before navigation
- Added wait after server stop in `react_version` fixture
- Increased timeouts in `react_version` fixture (60s → 120s)
- Added verification that server is actually responding after `wait_for_server()` returns True

**Files Changed:**
- `tests/fixtures/app.py` - Added server readiness check before navigation
- `tests/fixtures/version.py` - Added wait after stop, increased timeouts, added final verification

**Status:** Still occurring - needs further investigation

---

### Issue 3: Test Timeouts During Execution

**Status:** 🟡 **PENDING** (Not yet encountered)  
**Priority:** HIGH

**Symptoms:**
- Tests timeout waiting for elements to appear
- `pytest-timeout` plugin killing tests after 300 seconds

**Root Causes:**
- Slow page load (React hydration, API calls)
- Insufficient wait times for dynamic content
- API response delays

**Files That May Need Changes:**
- `tests/pages/app_page.py` - Page object wait methods
- `tests/test_suites/test_hello_world.py` - Test timeouts
- `tests/test_suites/test_version_info.py` - Version info loading timeouts

---

### Issue 4: WebDriver Issues

**Status:** 🟢 **PARTIALLY FIXED**  
**Priority:** MEDIUM

**Symptoms:**
- `ReadTimeoutError: HTTPSConnectionPool(host='googlechromelabs.github.io', port=443): Read timed out`
- Tests fail before they can even start

**Fix Applied:**
- Driver caching implemented
- Cache detection logic added

**Status:** May need refinement if it appears again

---

### Issue 5: Framework Mode Detection

**Status:** 🟢 **PARTIALLY FIXED**  
**Priority:** MEDIUM

**Symptoms:**
- Tests expecting Vite but running in Next.js mode (or vice versa)
- Server startup failing due to mode mismatch

**Fix Applied:**
- Framework mode verification added to fixtures
- Framework mode logging added

**Status:** May need refinement if it appears again

---

## Fixes Applied (By Iteration)

### Iteration 1: Port Conflict Fix ✅ FIXED

**Error:** `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`  
**Root Cause:** Multiple Next.js servers running on ports 3001-3008. When port 3000 is occupied, Next.js auto-increments to next available port.

**Fix Applied:**
- Added `_cleanup_all_test_ports()` function to `tests/utils/server_manager.py`
  - Cleans up all test ports: 3000-3010, 5173
  - Kills processes on these ports before starting servers
- Updated `start_servers()` to call `_cleanup_all_test_ports()` before starting
- Updated `react_version` fixture to clean up all ports before version switch
- Added verification that ports are actually free before starting servers

**Files Changed:**
- `tests/utils/server_manager.py` - Added `_cleanup_all_test_ports()` function
- `tests/fixtures/version.py` - Added port cleanup before version switch

**Status:** ✅ FIXED

---

### Iteration 2: Server Not Ready When Test Navigates 🔴 OUTSTANDING

**Error:** `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`  
**Root Cause:** Race condition - `react_version` fixture restarts servers, but `app_page` fixture navigates before server is fully ready.

**Fix Attempted:**
- Added server readiness check in `app_page` fixture before navigation
- Added wait after server stop in `react_version` fixture
- Increased timeouts in `react_version` fixture (60s → 120s)
- Added verification that server is actually responding after `wait_for_server()` returns True

**Files Changed:**
- `tests/fixtures/app.py` - Added server readiness check before navigation
- `tests/fixtures/version.py` - Added wait after stop, increased timeouts, added final verification

**Status:** 🔴 OUTSTANDING - Still occurring, needs further investigation

---

## Current Status

**Last Updated:** 2025-12-20  
**Current Iteration:** 2  
**Current Issue:** Issue 2 - Server Not Ready When Test Navigates

### Progress Summary

- **Iteration 1:** ✅ FIXED - Port conflicts resolved
- **Iteration 2:** 🔴 IN PROGRESS - Server readiness race condition

### Next Steps

1. Run `./scripts/run_make_test_stop_on_error.sh`
2. Analyze the first error (check if it's still Issue 2 or a new error)
3. Devise fix based on analysis
4. Apply fix
5. Test again (run script again)
6. Repeat until script exits with code 0

---

## Success Criteria

**Final Goal:**
- Script exits with code 0
- All tests pass
- No errors in output
- Servers start and stop correctly

**How to Verify:**
```bash
./scripts/run_make_test_stop_on_error.sh
echo $?  # Should be 0
```

---

## Notes

- **Scope:** This plan addresses ONLY `make test`. Other test targets will be addressed after `make test` is working.
- **Approach:** Iterative fix loop - stop at first error, analyze, fix, repeat
- **Key Principle:** Fix ONE error at a time, stop immediately at first error
- **Script:** `./scripts/run_make_test_stop_on_error.sh` handles stop-on-first-error automatically

---

**Document Created:** 2025-12-19  
**Last Updated:** 2025-12-20  
**Status:** Active - Iterative Fix Loop in Progress
