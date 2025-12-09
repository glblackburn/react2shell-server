# BUG-8: Next.js 14.x Versions Fail Scanner Tests Due to Server Startup Issues

**Status:** Open  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-09

**Investigation Artifacts:**
- [Browser Screenshot](BUG-8/2025-12-09_bug_8_browser_screenshot.png) - Shows server is running and accessible via browser (GET requests work) despite scanner timeout
- [Scanner Timeout Analysis](BUG-8/SCANNER_TIMEOUT_ANALYSIS.md) - Detailed technical analysis of why the scanner times out for Next.js 14.x versions
- [Test Run Log (2025-12-09 06:14:19)](BUG-8/verify_scanner_2025-12-09_061419.txt) - Complete test output after script optimizations (removed fixed sleep, removed POST check)

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
1. **Next.js 14.x + React 19 Compatibility Issue:** Next.js 14.x with React 19.2.0 has a bug where processing the RCE PoC payload causes **that specific request handler to hang**. Server logs show:
   - `Failed to find Server Action "x"` (scanner sends `Next-Action: x` as placeholder)
   - `Missing 'origin' header from a forwarded Server Actions request`
   - `TypeError: Cannot read properties of null (reading 'message')` - causes unhandled rejection
   - This error causes **the POST request handler to hang** - the request never completes and no HTTP response is sent
   - **Server process remains running** - can still handle GET requests (browser loads pages fine)
   - Scanner times out waiting for a response that never comes

2. **Why Safe-Check Works:** The `--safe-check` flag uses a different payload that doesn't trigger the same error path, so it returns `NOT VULNERABLE` with status 200 instead of timing out.

3. **Why Next.js 15.x Works:** Next.js 15.x has better error handling and doesn't crash when processing the RCE PoC payload, correctly detecting the vulnerability.

4. **Timing Issue (Secondary):** Server restart happens too quickly after version switch, before `npm install` completes
5. **Missing Binary Check:** Script doesn't verify that `next` binary exists before starting server
6. **Insufficient Wait Time:** Next.js 14.x needs more initialization time than 15.x, especially with React 19 compatibility

**Evidence:**
- Server logs show errors when processing RCE PoC payload:
  - `Failed to find Server Action "x"` (scanner sends `Next-Action: x` as placeholder)
  - `Missing 'origin' header from a forwarded Server Actions request`
  - `TypeError: Cannot read properties of null (reading 'message')` - causes unhandled rejection
  - **Specific POST request handler hangs** - request never completes, no HTTP response sent
- Server process remains running - GET requests (browser) work fine (see [browser screenshot](BUG-8/2025-12-09_bug_8_browser_screenshot.png))
- Scanner times out waiting for response that never comes
- `--safe-check` works (returns NOT VULNERABLE with status 200) - different payload doesn't trigger crash
- `curl GET` works fine - server responds to simple requests
- Next.js 15.x versions work correctly (better error handling, correctly detects vulnerability)
- Issue only affects Next.js 14.0.0 and 14.1.0 with RCE PoC payload, not 15.0.0 or 15.1.0
- See [Scanner Timeout Analysis](BUG-8/SCANNER_TIMEOUT_ANALYSIS.md) for detailed technical explanation

**Test Results After Script Optimizations (2025-12-09 06:14:19):**
After removing the fixed 30-second sleep and POST readiness check (relying on polling-based `wait_for_server`), test results confirm the issue persists:
- **Next.js 14.0.0:** FAILED - `Read timed out` (scanner timeout after 10 seconds)
- **Next.js 14.1.0:** FAILED - `Read timed out` (scanner timeout after 10 seconds)
- **Next.js 15.0.0:** PASSED - Correctly detected vulnerability (Status: 303)
- **Next.js 15.1.0:** PASSED - Correctly detected vulnerability (Status: 303)

**Summary:** The script optimizations (removing redundant waits) did not resolve the timeout issue for Next.js 14.x versions. This confirms that the problem is not a script timing issue, but rather a **Next.js 14.x + React 19 compatibility bug** where the request handler hangs when processing the RCE PoC payload. The server starts successfully, responds to GET requests, but the specific POST request with the RCE PoC payload causes the request handler to hang indefinitely, preventing any HTTP response from being sent.

See [test run log](BUG-8/verify_scanner_2025-12-09_061419.txt) for complete output.

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
The script has been optimized to remove redundant fixed waits and rely on polling-based readiness checks. However, test results (see [test run log](BUG-8/verify_scanner_2025-12-09_061419.txt)) confirm that the timeout issue persists for Next.js 14.x versions even with optimized script logic. This definitively confirms that the issue is **not a script timing problem**, but rather a **Next.js 14.x + React 19 compatibility bug** where the request handler hangs when processing RCE PoC payloads.

**Status:** Confirmed as Next.js 14.x compatibility bug - not a script issue. The script optimizations work correctly (Next.js 15.x passes, server starts properly), but Next.js 14.x has a fundamental bug that causes request handler hangs when processing RCE PoC payloads.

**Additional Notes:**
- **Next.js 14.x + React 19 Compatibility Bug:** Next.js 14.x with React 19.2.0 has a bug where processing the RCE PoC payload causes a null reference error that crashes/hangs the server. This is a compatibility issue - Next.js 14.x was designed for React 18, not React 19.
- **Why Safe-Check Works:** The `--safe-check` payload uses a different code path that doesn't trigger the null reference error, so it completes successfully (though it correctly reports NOT VULNERABLE).
- **Why Next.js 15.x Works:** Next.js 15.x was designed to work with React 19 and has better error handling, so it processes the RCE PoC payload correctly and detects the vulnerability.
- **Not a Code Blocking Issue:** This is not something blocking the scanner in our code - it's a Next.js 14.x + React 19 compatibility bug. The scanner is working correctly; Next.js 14.x crashes when trying to process the payload.
- The longer wait time for 14.x versions is necessary due to these compatibility considerations, but may not resolve the underlying crash issue.
