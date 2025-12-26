# Next.js Startup Test Fix Plan

**Date Created:** December 26, 2025 06:32:00 EST  
**Attempt:** 1  
**Status:** ✅ Success

## Problem Statement

The `make test-nextjs-startup` command is failing in GitHub Actions due to:
1. Port conflicts - Next.js starts on alternate ports (3001-3010) when 3000 is in use
2. Script only checks port 3000, causing failures when server starts on alternate ports
3. Incomplete port cleanup - only port 3000 is cleaned before starting, not 3000-3010

## Root Cause Analysis

From CI Test Failure Analysis (2025-12-26):
- **Test Next.js Startup Job** fails on versions 15.2.5, 15.4.7, 14.0.1
- Port conflicts cause Next.js to start on alternate ports (3002, etc.)
- Script only checks port 3000, so it fails even though server started successfully
- Next.js 15.2.5 has a known `deploymentId` bug (documented separately)

## Changes Implemented

### 1. Expanded Pre-Start Port Cleanup ✅
**Location:** `tests/test_nextjs_startup.sh` lines 117-153

**Changes:**
- Check all ports 3000-3010 before starting (was only 3000)
- Clean all ports 3000-3010 if any are in use
- Kill Next.js/node processes
- Verify cleanup before proceeding

**Rationale:** Prevents port conflicts by ensuring all potential ports are free before starting.

### 2. Added Port Detection ✅
**Location:** `tests/test_nextjs_startup.sh` lines 163-200

**Changes:**
- Detect which port server actually started on (3000-3005)
- Check ports in parallel during startup
- Store detected port in `DETECTED_PORT` variable
- Fallback to 3000 if detection fails (backward compatibility)

**Rationale:** Handles cases where Next.js starts on alternate ports instead of failing.

### 3. Updated Server Readiness Check ✅
**Location:** `tests/test_nextjs_startup.sh` lines 201-252

**Changes:**
- Use `DETECTED_PORT` instead of hardcoded 3000
- Error messages reference detected port
- Continue checking detected port if initial detection succeeded

**Rationale:** Tests the actual port the server is using, not an assumed port.

### 4. Updated API Test ✅
**Location:** `tests/test_nextjs_startup.sh` lines 325-329

**Changes:**
- Use `DETECTED_PORT` for API calls
- Test actual port server is using

**Rationale:** Ensures API test works regardless of which port server started on.

### 5. Documented Next.js 15.2.5 Known Issue ✅
**Location:** `tests/test_nextjs_startup.sh` lines 96-99

**Changes:**
- Added comment documenting the `deploymentId` bug
- References analysis document for details

**Rationale:** Documents known issue so failures are understood, not treated as bugs.

## Testing Plan

### Local Testing Steps

1. **Clean environment test:**
   ```bash
   # Stop any running servers
   make stop
   
   # Clean up any ports
   for port in 3000 3001 3002 3003 3004 3005; do
     lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
   done
   
   # Run test
   make test-nextjs-startup
   ```

2. **Port conflict simulation test:**
   ```bash
   # Start a server on port 3000
   make start
   
   # In another terminal, run test (should handle alternate port)
   make test-nextjs-startup
   ```

3. **Verify all versions pass:**
   - Check output for all 11 versions
   - Verify no port conflict errors
   - Verify all versions detected on correct ports

### Expected Results

**Success Criteria:**
- All 11 Next.js versions pass (or 10 if 15.2.5 is documented as known issue)
- No "port conflict" errors
- Script detects and uses correct port for each version
- Clean output showing "✓ Server detected on port X"

**Failure Indicators:**
- Port conflict errors
- "Server not found on any port" errors
- Versions failing due to port issues

## Next Steps

### Immediate Actions

1. **Test locally:**
   - Run `make test-nextjs-startup` locally
   - Verify all versions pass
   - Check for any issues

2. **Commit and push:**
   - Commit this plan document
   - Commit script changes
   - Push to trigger GitHub Actions

3. **Monitor GitHub Actions:**
   - Watch the run: `gh run watch --log`
   - Check "Test Next.js Startup" job
   - Verify all versions pass

4. **Iterate if needed:**
   - If failures occur, analyze logs
   - Update plan with findings
   - Make additional fixes
   - Test locally again
   - Commit and push
   - Repeat until all versions pass

### Success Criteria

- ✅ `make test-nextjs-startup` passes locally
- ✅ GitHub Actions "Test Next.js Startup" job passes
- ✅ All 11 versions (or 10 if 15.2.5 skipped) pass in CI
- ✅ No port conflict errors in CI logs

## Known Issues

### Next.js 15.2.5 deploymentId Bug

**Status:** Documented, not fixed

**Issue:** Next.js 15.2.5 has a known bug that causes crashes:
```
TypeError: Cannot read properties of undefined (reading 'deploymentId')
```

**Options:**
- **Option A:** Document as known issue (current approach)
- **Option B:** Add retry logic (retry 3 times)
- **Option C:** Skip 15.2.5 in CI (test locally only)

**Decision:** Start with Option A (document). If CI still fails, consider Option B or C.

## Related Documentation

- [CI Test Failure Analysis 2025-12-26](CI_TEST_FAILURE_ANALYSIS_2025-12-26.md) - Original analysis
- [test_nextjs_startup.sh](../../tests/test_nextjs_startup.sh) - Test script with fixes
- [Makefile](../../Makefile) - `test-nextjs-startup` target

## GitHub Actions Run Results

### Run Information
- **Run ID:** 20521706863
- **Branch:** `ci-cd/step-3-vite-test-job`
- **Commit:** `1600e9a` - "fix: Improve Next.js startup test port handling and add logging scripts"
- **Status:** ✅ **SUCCESS**
- **Conclusion:** success
- **URL:** https://github.com/glblackburn/react2shell-server/actions/runs/20521706863
- **Started:** 2025-12-26T11:32:22Z
- **Completed:** 2025-12-26T11:37:21Z
- **Duration:** ~5 minutes

### Test Results

**Job: Test Next.js Startup**
- **Status:** ✅ **SUCCESS**
- **Conclusion:** success
- **All 11 versions passed:**
  - ✅ 14.0.0 passed
  - ✅ 14.1.0 passed
  - ✅ 15.0.4 passed
  - ✅ 15.1.8 passed
  - ✅ 15.2.5 passed (previously failed)
  - ✅ 15.3.5 passed
  - ✅ 15.4.7 passed (previously failed, started on port 3004)
  - ✅ 15.5.6 passed
  - ✅ 16.0.6 passed
  - ✅ 14.0.1 passed (previously failed)
  - ✅ 14.1.1 passed

**Summary:**
```
✓ Passed: 11
✓ All versions passed!
```

### Key Observations

1. **Port Detection Working:**
   - Most versions detected on port 3000
   - Version 15.4.7 detected on port 3004 (proving port detection works)
   - All versions passed regardless of which port they started on

2. **Port Cleanup Working:**
   - One warning: "Ports in use before starting 14.1.1: 3006"
   - Cleanup handled it successfully
   - Version 14.1.1 still passed

3. **All Previously Failing Versions Now Pass:**
   - 15.2.5: ✅ Passed (was failing)
   - 15.4.7: ✅ Passed (was failing, started on port 3004)
   - 14.0.1: ✅ Passed (was failing)

### Log Files Saved

- Full run log: `/tmp/github_actions_run_20521706863_2025-12-26_113222.txt`
- Next.js job log: `/tmp/github_actions_nextjs_job_20521706863_2025-12-26_113222.txt`

### Analysis

**The fix worked perfectly!** Port detection was the critical component that made it work. When version 15.4.7 started on port 3004 (instead of 3000), the script detected it and used port 3004 for all subsequent checks, allowing the test to pass.

**Conclusion:** No further iterations needed. The fix is complete and successful.

---

## Date

December 26, 2025
