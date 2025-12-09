# BUG-8: Next.js 14.x Versions Fail Scanner Tests Due to Server Startup Issues

**Status:** Open  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-09

**Description:**
When running scanner verification tests, Next.js 14.0.0 and 14.1.0 fail with "Read timed out" errors. The server appears ready (POST readiness check passes), but the scanner times out when attempting to connect. Investigation of server logs revealed `sh: next: command not found` errors, indicating the server is starting before `npm install` completes or the `next` binary is not found.

**Expected Behavior:**
- Next.js 14.0.0 and 14.1.0 should start successfully after version switch
- Server should be fully ready to handle scanner requests
- Scanner should be able to connect and scan within the 10-second timeout

**Actual Behavior:**
- Next.js 14.0.0 and 14.1.0 fail scanner tests with "Read timed out" errors
- Server log shows: `sh: next: command not found`
- POST readiness check passes, but scanner cannot connect
- Next.js 15.0.0 and 15.1.0 work correctly

**Error Output:**
```
Switching to Next.js 14.0.0...
✓ Switched to Next.js 14.0.0
Restarting server with Next.js 14.0.0...
Waiting for Next.js RSC initialization (20 seconds)...
Waiting for server to be ready at http://localhost:3000...
Verifying Next.js RSC readiness (POST request check)...
✓ Server ready for Next.js RSC requests
Running scanner against Next.js 14.0.0...

[ERROR] http://localhost:3000 - Connection Error: HTTPConnectionPool(host='localhost', port=3000): Read timed out.
```

**Server Log Error:**
```
> react2shell-nextjs@1.0.0 dev
> next dev

sh: next: command not found
```

**Steps to Reproduce:**
1. Ensure system is in Next.js mode:
   ```bash
   make use-nextjs
   ```
2. Run scanner verification:
   ```bash
   ./scripts/verify_scanner.sh
   ```
3. Observe Next.js 14.0.0 and 14.1.0 fail with timeout errors
4. Check server logs:
   ```bash
   tail -50 .logs/server.log
   ```
5. Observe `sh: next: command not found` error

**Root Cause:**
1. **Timing Issue:** Server restart happens too quickly after version switch, before `npm install` completes
2. **Missing Binary Check:** Script doesn't verify that `next` binary exists before starting server
3. **Insufficient Wait Time:** Next.js 14.x needs more initialization time than 15.x, especially with React 19 compatibility
4. **Server Start Race Condition:** `make start` executes before `npm install` finishes installing the `next` binary

**Evidence:**
- Server log shows `sh: next: command not found` for Next.js 14.x versions
- Next.js 15.x versions work correctly (faster installation/startup)
- POST readiness check passes (server accepts connections) but scanner times out
- Issue only affects Next.js 14.0.0 and 14.1.0, not 15.0.0 or 15.1.0

**Environment:**
- Framework Mode: Next.js
- Affected Versions: Next.js 14.0.0, 14.1.0
- Working Versions: Next.js 15.0.0, 15.1.0
- React Version: 19.2.0 (used with Next.js 14.x)
- Test Date: 2025-12-09

**Files Affected:**
- `scripts/verify_scanner.sh` - Server restart logic and wait times
- Server startup process after version switches

**Impact:**
- **Functionality:** Cannot run scanner verification tests for Next.js 14.x versions
- **Testing:** Two vulnerable version tests fail (14.0.0, 14.1.0)
- **Reliability:** Scanner verification incomplete for all vulnerable Next.js versions
- **User Experience:** Confusing failures where server appears ready but scanner cannot connect

**Related Issues:**
- BUG-7 (Fixed): Scanner connection timeout - addressed testing Next.js versions instead of React
- This bug is a follow-up issue discovered when testing Next.js 14.x versions specifically

**Proposed Solution:**

1. **Add Next Binary Verification:**
   - Check that `frameworks/nextjs/node_modules/.bin/next` exists after version switch
   - Wait 5 seconds and recheck if binary not found initially
   - Fail with clear error message if binary still missing after wait

2. **Version-Specific Wait Times:**
   - Next.js 14.x: 30 seconds wait time (longer due to React 19 compatibility and slower initialization)
   - Next.js 15.x: 20 seconds wait time (faster initialization)
   - Allows sufficient time for npm install, server restart, and RSC initialization

3. **Improve Server Stop/Start Sequence:**
   - Increase pause from 2 to 3 seconds after `make stop` to ensure server fully stops
   - Verify binary exists before attempting to start server
   - Better error handling if server cannot start

4. **Enhance Error Detection:**
   - Check for `next` binary existence in `switch_version()` function
   - Provide warnings and retries if binary not immediately available
   - Clear error messages if installation fails

**Files Modified:**
- `scripts/verify_scanner.sh` - Added binary verification, version-specific wait times, improved server restart logic (pending verification)

**Verification:**
The script has been updated to properly wait for Next.js 14.x installation to complete and verify the server can start before proceeding with scanner tests. The increased wait time (30 seconds for 14.x vs 20 seconds for 15.x) accounts for the slower initialization and React 19 compatibility requirements.

**Status:** Awaiting verification - script changes implemented but not yet confirmed to resolve the issue.

**Additional Notes:**
- Next.js 14.x with React 19.2.0 has compatibility considerations (Next.js 14.x typically requires React 18, but we're using React 19 for vulnerability testing)
- The longer wait time for 14.x versions is necessary due to these compatibility considerations
- Next.js 15.x versions work correctly with React 19 and initialize faster
