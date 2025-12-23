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
   - **Each run creates a NEW top-level directory:** `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/`
     - Example: First run creates `/tmp/make-test-fix-2025-12-20-013045/`
     - Example: Second run creates `/tmp/make-test-fix-2025-12-20-013150/` (new timestamp)
   - **Determine the output directory:**
     - **Primary method:** The script prints "Output directory: /tmp/make-test-fix-..." at the start of execution
     - **From script output:** Look for the line "Output directory: /tmp/make-test-fix-YYYY-MM-DD-HHMMSS"
     - **Fallback method:** If output is not available, find the most recent directory:
       ```bash
       ls -td /tmp/make-test-fix-* | head -1
       ```
     - **Note:** Each run creates a new timestamped directory, so the most recent one is the current run
   - **Use the current run's directory** for documentation
   - **Distinguish Script Failures vs Test Failures:**
     - **Script Failure:** Error occurs BEFORE "=== Running tests ===" appears in output
       - Examples: pytest not found, script syntax error, directory creation failure
       - **Action:** Fix the infrastructure/script issue first, then re-run (this is NOT a test failure)
     - **Test Failure:** Error occurs AFTER "=== Running tests ===" appears in output
       - This is a pytest test failure - proceed with the fix loop (step 3)

2. **Stop at First Error** (Automatic)
   - **If script failure:** Script exits with code 1 before pytest runs (see step 1 for handling)
   - **If test failure:** Pytest's `-x` flag stops immediately when first test fails
   - No more tests run after first failure
   - Script exits with code 1

3. **Analyze the Error**
   - **First, verify this is a TEST failure (not a script failure):**
     - Check if `output/make-test-live.txt` contains "=== Running tests ==="
     - If NOT present: This is a script failure - fix infrastructure issue and re-run (skip to step 1)
     - If present: This is a test failure - proceed with analysis below
   - Review error message and stack trace from `output/make-test-live.txt` in the **current run's output directory**
   - Check server logs: `logs/server.log`, `logs/vite.log` in the **current run's output directory**
   - Check port status: `netstat -an | grep LISTEN | grep -E "\.300[0-9]|\.5173"`
   - Check process status: `files-after/processes-after.txt` in the **current run's output directory**
   - Identify root cause
   - **Determine if this is a NEW error:**
     - **Review the test output in order** from `output/make-test-live.txt`
     - **If this is iteration 2+:** Check if the previous failing test (from the last iteration) appears in the output and PASSED
       - **If previous test PASSED:** The current failure is a NEW error (fix worked, now encountering next failure)
       - **If previous test is still FAILING (or not in output):** This is the SAME error (fix didn't work, continue iterating)
     - **If this is iteration 1:** This is the first error (no previous test to compare)
     - **Note:** Since the script stops at the first error, if the previous test passed, you've moved on to a new error
     - **How to find previous failing test:**
       - Check the previous run's `output/make-test-live.txt` for the failing test name
       - Or check `docs/testing/TEST_FIX_PLAN.md` "Fixes Applied" section for the last iteration's failing test
       - Look for the test name in the current run's output to see if it passed
   - **Document in the current run's output directory: `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/error-analysis.txt`**
     - Note: `YYYY-MM-DD-HHMMSS` is the timestamp from the current run's directory
   - **If this is a NEW error: Update `docs/testing/TEST_FIX_PLAN.md` - Add to "Known Issues" section with status OUTSTANDING**
     - Use the format template in the "Known Issues" section
     - Add at the end of the "Known Issues" section, before "Fixes Applied (By Iteration)"
     - Number sequentially (Issue 3, Issue 4, etc.)
     - Include: Status, Priority, Symptoms, Root Cause, Files Changed (if any)

4. **Devise Fix**
   - Based on root cause analysis
   - Plan code changes needed
   - Consider edge cases
   - Document fix plan

5. **Apply Fix**
   - Make code changes
   - Ensure fix addresses root cause
   - **Document the fix plan in the current run's output directory: `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/fix-applied.txt`**
     - Files changed
     - What was changed
     - Why it fixes the error
     - Note: `YYYY-MM-DD-HHMMSS` is the timestamp from the current run's directory (where error was analyzed)
     - **Important:** This fix documentation is in the previous run's directory. The next run (step 6) will create a new directory with the test results.
   - **Do NOT commit yet** - Wait for confirmation that fix works (exit code 0)

6. **Test Fix**
   ```bash
   ./scripts/run_make_test_stop_on_error.sh
   ```
   - **This creates a NEW top-level directory** `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/` with the test results
     - Example: If previous run was `/tmp/make-test-fix-2025-12-20-013045/`, this run creates `/tmp/make-test-fix-2025-12-20-013150/`
   - **The fix documentation is in the PREVIOUS run's directory** (from step 5)
   - **Exit code 0: ✅ Success! The test that failed is now passing (fix confirmed).**
     - **Verify:** The specific test that failed in the previous run is now passing
       - Check the test output in `output/make-test-live.txt` in the new directory
       - Process the output in order - the previously failing test should appear and PASS
       - If all tests pass, the script exits with code 0
     - **Commit the confirmed fix** (only commit when the test that failed is now passing after applying the fix)
       - **Save commit message:** Save the commit message text to `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/commit-message.txt` in the current run's output directory
       - **Show what will be committed:** Display the commit message, list of files, and changes summary
       - **Commit automatically:** Commit only the files changed for this specific fix (no waiting for confirmation - exit code 0 confirms the fix)
     - **Update `docs/testing/TEST_FIX_PLAN.md`:**
       - Update issue status (OUTSTANDING → FIXED) in "Known Issues" section
       - Update "Fixes Applied" section with iteration details
       - Update "Current Status" section with progress
     - **Proceed to step 7 (Repeat or Completion)** - Continue to verify stability with 2 more runs
   - **Exit code 1: ❌ Fix didn't work or new error detected.**
     - **Do NOT commit** - Continue iterating without committing
     - **Use the NEW output directory** (from this run) for step 3 (analyze error)

7. **Repeat or Complete**
   - **If exit code was 1:** Continue loop - Go to step 1 (run test again)
   - **If exit code was 0:** 
     - **After committing the fix (from step 6):** Verify stability with additional runs
     - **Run the script 2 more times** (total 3 consecutive successful runs) with **no code changes**
     - **If all 3 runs exit with code 0:** ✅ **COMPLETE** - All tests pass consistently
     - **If any of the 2 additional runs exit with code 1:** Go to step 3 (analyze new error)
   - Each iteration fixes ONE error
   - Track all errors and fixes in summary files

### Key Principles

1. **ONE error at a time** - Fix the first error, test, then move to next
2. **Stop immediately** - Pytest `-x` flag ensures this automatically
3. **Analyze completely** - Understand root cause before fixing
4. **Test after each fix** - Verify fix works before moving on
5. **Document everything** - Save all output, analysis, fixes
6. **Commit only confirmed fixes** - Only commit when fix is confirmed (exit code 0). Do NOT commit attempts that haven't been verified to fix the issue.

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
- **Finding the output directory:**
  - **Primary:** Script prints "Output directory: /tmp/make-test-fix-..." at start
  - **Fallback:** `ls -td /tmp/make-test-fix-* | head -1` (most recent directory)
- Live output: `output/make-test-live.txt`
- Exit code: `output/make-test-exitcode.txt`
- Duration: `output/make-test-duration.txt`
- Before/after state: `files-before/`, `files-after/`
- Server logs: `logs/`

**Exit Codes:**
- `0` - All tests passed
- `1` - Error or failure detected (could be script failure or test failure - check output to distinguish)

**Distinguishing Script Failures from Test Failures:**
- **Script Failure:** 
  - Error message appears BEFORE "=== Running tests ===" in output
  - Common causes: pytest not found, script syntax error, directory creation failure
  - **Action:** Fix the infrastructure/script issue, then re-run (do NOT follow test fix loop)
- **Test Failure:**
  - "=== Running tests ===" appears in output, then pytest finds a failing test
  - **Action:** Follow the test fix loop (proceed to step 3)

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

**Each run creates a NEW top-level directory with a unique timestamp:**

```
/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/    # New directory for each run
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
├── error-analysis.txt         # Error analysis for this run
├── fix-applied.txt            # Fix plan for this run (if applicable)
└── summary/                   # Overall summary
    ├── all-errors-found.txt
    ├── all-fixes-applied.txt
    └── final-status.txt
```

**Example:**
- Run 1: `/tmp/make-test-fix-2025-12-20-013045/` (contains error analysis and fix plan)
- Run 2: `/tmp/make-test-fix-2025-12-20-013150/` (contains test results for fix from run 1)
- Run 3: `/tmp/make-test-fix-2025-12-20-013255/` (if new error, contains new error analysis)

### What to Document During Each Iteration

**Documentation Workflow:**
- **Each run creates a NEW top-level directory:** `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/`
  - Each directory has a unique timestamp, so each run gets its own folder
- **Use the CURRENT run's directory** to document the error analysis and fix plan
- **The NEXT run** (testing the fix) creates a NEW top-level directory with test results
- **The fix documentation stays in the PREVIOUS run's directory** (where the error was analyzed)

**Documentation Location:** All iteration documentation is created directly in `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/`
- **Each run creates a NEW top-level directory:** `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/` (unique timestamp per run)
- **Finding the output directory:**
  - **Primary:** Script prints "Output directory: /tmp/make-test-fix-..." at start
  - **Fallback:** `ls -td /tmp/make-test-fix-* | head -1` (most recent directory)
- Files are created directly in the output directory (not in a subdirectory)
- Note: `YYYY-MM-DD-HHMMSS` is the timestamp from the current run's directory

1. **Error Analysis** (During Step 3):
   - **Use the current run's output directory** (the one just created in step 1)
   - **Determine if this is a NEW error:**
     - **Review test output in order** from `output/make-test-live.txt`
     - **If iteration 2+:** Check if the previous failing test (from last iteration) appears and PASSED in the output
       - **Previous test PASSED:** NEW error (fix worked, now on next failure)
       - **Previous test still FAILING:** SAME error (fix didn't work, continue iterating)
     - **Find previous failing test:**
       - Check previous run's `output/make-test-live.txt` for the failing test name
       - Or check `docs/testing/TEST_FIX_PLAN.md` "Fixes Applied" section for last iteration's failing test
       - Look for that test name in current output to verify it passed
   - Create `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/error-analysis.txt` in that directory
   - Document: Error message, stack trace, which test failed, root cause analysis, port/process status, server log excerpts
   - **If NEW error:** Update `docs/testing/TEST_FIX_PLAN.md` - Add to "Known Issues" with status OUTSTANDING

2. **Fix Applied** (During Step 5):
   - **Use the SAME output directory** from step 3 (where error was analyzed)
   - Create `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/fix-applied.txt` in that directory
   - Document: Files changed, what was changed, why it fixes the error
   - **Do NOT commit yet** - Wait for test confirmation (exit code 0)
   - **Note:** This fix documentation is in the previous run's directory. The next run (step 6) will create a new directory.

3. **After Test Confirms Fix** (During Step 6, when exit code 0):
   - **The test results are in the NEW output directory** (created by step 6)
   - **The fix documentation is in the PREVIOUS output directory** (from step 5)
   - **Commit the confirmed fix**
   - **Update `docs/testing/TEST_FIX_PLAN.md`:**
     - Update issue status (OUTSTANDING → FIXED) in "Known Issues"
     - Add iteration details to "Fixes Applied" section
     - Update "Current Status" section with progress

4. **Update Summary Files** (Optional, in output directory):
   - Add error to `summary/all-errors-found.txt`
   - Add fix to `summary/all-fixes-applied.txt`
   - Update `summary/final-status.txt`

---

## Known Issues (Status Tracking)

This section tracks known issues that may appear. Status: ✅ **FIXED**, 🔴 **OUTSTANDING**, 🟡 **PENDING**, or 🟢 **PARTIALLY FIXED**.

### Format for Adding New Issues

When adding a new issue to this section, use the following format:

```markdown
### Issue N: [Brief Descriptive Title]

**Status:** 🔴 **OUTSTANDING** (Iteration N)  
**Priority:** CRITICAL | HIGH | MEDIUM | LOW

**Symptoms:**
- [Error message or observable behavior]
- [What test fails or what doesn't work]
- [Any relevant error codes or messages]

**Root Cause:**
- [Explanation of why this is happening]
- [Technical details about the underlying problem]

**Fix Applied:** (or **Fix Attempted:** if not yet confirmed)
- [Description of fix approach]
- [What was changed]

**Files Changed:**
- `path/to/file` - [What was changed in this file]

**Status:** [Additional status note if needed]
```

**Where to add:** Add new issues at the end of the "Known Issues" section, before the "Fixes Applied (By Iteration)" section. Number sequentially (Issue 3, Issue 4, etc.).

**When to update:** 
- When status changes to FIXED: Update status to ✅ **FIXED** and add iteration number
- When fix is attempted but not confirmed: Change "Fix Applied" to "Fix Attempted" and update status accordingly

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

**Status:** ✅ **FIXED** (Iteration 1)  
**Priority:** CRITICAL

**Symptoms:**
- Error: `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`
- Test fails immediately when trying to navigate
- Server may have just been restarted by `react_version` fixture

**Root Cause:**
- Race condition: `react_version` fixture restarts servers, but `app_page` fixture navigates before server is fully ready
- `app_page` fixture didn't ensure `react_version` completed before checking server readiness
- Insufficient timeout (2s) and attempts (10) in `app_page` server readiness check

**Fix Applied:**
- Made `app_page` fixture ensure `react_version` runs first when both are used (via `request.getfixturevalue()`)
- Increased server readiness check timeout from 2s to 5s (matching `react_version` final check)
- Increased max attempts from 10 to 20 with 1.0s delay (20 seconds total wait time)
- This ensures `react_version` completes server restart before `app_page` tries to navigate

**Files Changed:**
- `tests/fixtures/app.py` - Added fixture dependency check, increased timeout and attempts

**Status:** ✅ FIXED

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

### Issue 6: Test Passes When Server Startup Fails

**Status:** 🔴 **OUTSTANDING** (Iteration 1)  
**Priority:** HIGH

**Symptoms:**
- Test `test_layout_consistency_across_frameworks[vite]` passes even when `start_servers()` fails
- `start_servers()` returns `False` and logs "Servers failed to start or become ready"
- Test continues execution and attempts to navigate to URL
- Test should fail but shows "PASSED"

**Root Cause:**
- Test calls `start_servers()` but doesn't check the return value
- `start_servers()` returns `False` on failure but doesn't raise an exception
- Test continues execution even when servers didn't start successfully

**Files That Need Changes:**
- `tests/test_suites/test_ui_layout_sync.py` - Add check for `start_servers()` return value

**Status:** Test bug - test should validate server startup before proceeding

---

## Fixes Applied (By Iteration)

### Iteration 1: Port Conflict Fix ✅ FIXED (Previous Fix)

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

### Iteration 1: Server Not Ready When Test Navigates ✅ FIXED (Current Session)

**Error:** `ERR_CONNECTION_REFUSED` when navigating to `http://localhost:3000`  
**Root Cause:** Race condition - `react_version` fixture restarts servers, but `app_page` fixture navigates before server is fully ready.

**Fix Applied:**
- Made `app_page` fixture ensure `react_version` runs first when both are used
- Increased server readiness check timeout from 2s to 5s (matching `react_version` final check)
- Increased max attempts from 10 to 20 with 1.0s delay (20 seconds total wait time)

**Files Changed:**
- `tests/fixtures/app.py` - Added fixture dependency check, increased timeout and attempts

**Status:** ✅ FIXED

---

## Current Status

**Last Updated:** 2025-12-20  
**Current Iteration:** 1 (Complete - 3 consecutive successful runs)  
**Current Issue:** Issue 6 - Test Passes When Server Startup Fails

### Progress Summary

- **Iteration 1:** ✅ COMPLETE
  - ✅ FIXED - Port conflicts resolved (Issue 1)
  - ✅ FIXED - Server readiness race condition resolved (Issue 2)
  - ✅ Verified with 3 consecutive successful runs (all exit code 0)
- **New Issue Found:** Issue 6 - Test bug where test passes when servers don't start (not blocking test execution)

### Next Steps

Follow the 7-Step Iterative Fix Loop Process (see "The Iterative Fix Loop Process" section above):
1. Run `./scripts/run_make_test_stop_on_error.sh`
2. Analyze the first error (check if it's still Issue 2 or a new error)
3. Devise fix based on analysis
4. Apply fix
5. Test again (run script again)
6. If exit code 0: Commit fix and verify stability with 2 more runs
7. If exit code 1: Continue iterating without committing

---

## Success Criteria

**Final Goal:**
- Script exits with code 0
- All tests pass
- No errors in output
- Servers start and stop correctly

**Completion Criteria:**
- **3 consecutive successful runs** (exit code 0) with **no code changes** between runs
- This ensures the fix is stable and consistent, not just a one-time success

**How to Verify:**
```bash
# Run 1
./scripts/run_make_test_stop_on_error.sh
echo $?  # Should be 0

# Run 2 (no changes made)
./scripts/run_make_test_stop_on_error.sh
echo $?  # Should be 0

# Run 3 (no changes made)
./scripts/run_make_test_stop_on_error.sh
echo $?  # Should be 0

# If all 3 runs exit with code 0: ✅ COMPLETE
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

## Workflow Clarifications

**Note:** These clarifications are integrated into the 7-Step Loop above. This section provides additional context.

### Documentation Location
- All iteration documentation files (`error-analysis.txt`, `fix-applied.txt`) are created directly in `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/`
- The timestamp (`YYYY-MM-DD-HHMMSS`) is generated by the script automatically
- Files are created directly in the output directory (not in a subdirectory)

### Plan Updates
- Update `docs/testing/TEST_FIX_PLAN.md` as changes are made and tested (see steps 3, 6, and 7):
  - When a new error is found: Add to "Known Issues" with status OUTSTANDING
  - When a fix is confirmed: Update issue status (OUTSTANDING → FIXED)
  - After each iteration: Update "Fixes Applied" section
  - Continuously: Update "Current Status" section

### Commit Workflow

**During the Test Fix Loop:**
- **Only commit at checkpoints** - When exit code 0 confirms a fix is working
- **Ignore manual "commit" requests** - Do not commit when user says "commit" during the loop
- **Do NOT commit attempts** that haven't been verified to fix the issue
- If a fix doesn't work (exit code 1), continue iterating without committing until it's confirmed

**When Exit Code 0 (Fix Confirmed):**
1. **Save commit message:** Save the commit message text (just the message, no file list or diff) to `/tmp/make-test-fix-YYYY-MM-DD-HHMMSS/commit-message.txt` in the current run's output directory
2. **Show what will be committed:** Display the commit message, list of files, and changes summary
3. **Commit automatically:** Commit only the files changed for this specific fix (no waiting for confirmation - exit code 0 confirms the fix)

**If Loop is Broken/Stopped:**
- If the test fix loop is interrupted and testing is stopped, then follow the normal AI coding standards commit workflow (two-step process with confirmation)

### Completion Criteria
- **3 consecutive successful runs** (exit code 0) with **no code changes** between runs
- This ensures stability and consistency, not just a one-time success
- After the first successful run (exit code 0), run 2 more times without making any changes
