# BUG-7: Scanner Connection Timeout After Version Switch in Next.js Mode

**Status:** Open  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-09

**Description:**
After fixing BUG-6 (port mismatch), the `scripts/verify_scanner.sh` script correctly detects Next.js mode and uses port 3000. However, when running scanner verification tests after switching React versions, the scanner times out with "Read timed out" errors. The script's `wait_for_server` function reports the server is ready, but the scanner cannot connect within its 10-second timeout period.

**Expected Behavior:**
- After switching React versions, server should restart and be fully ready
- Scanner should be able to connect and scan the server successfully
- All vulnerable version tests should pass

**Actual Behavior:**
- Script correctly detects Next.js mode and uses port 3000
- `wait_for_server` reports server is ready (no timeout error from script)
- Scanner attempts to connect but times out after 10 seconds
- All 4 vulnerable version tests fail with connection timeout errors
- Scanner error: `HTTPConnectionPool(host='localhost', port=3000): Read timed out.`

**Error Output:**
```
Detected framework: nextjs (checking port 3000)
Waiting for server to be ready at http://localhost:3000...
Testing VULNERABLE versions...
Switching to React 19.0...
✓ Switched to React 19.0
Waiting for server to be ready at http://localhost:3000...
Running scanner against React 19.0...
✗ FAILED: Should detect vulnerability for React 19.0 but did not

[ERROR] http://localhost:3000 - Connection Error: HTTPConnectionPool(host='localhost', port=3000): Read timed out.
```

**Steps to Reproduce:**
1. Ensure system is in Next.js mode:
   ```bash
   make use-nextjs
   ```
2. Ensure server is running:
   ```bash
   make start
   ```
3. Run the verification script:
   ```bash
   ./scripts/verify_scanner.sh
   ```
4. Observe all vulnerable version tests fail with connection timeout errors
5. Check that script reports server is ready, but scanner times out

**Root Cause:**
Unknown. Possible causes:
1. **Server Not Restarting:** After version switch, Next.js server may not be restarting automatically
2. **Insufficient Wait Time:** 3-second sleep + 30-second wait may not be enough for Next.js server to fully initialize after version switch
3. **Server State Mismatch:** Server may respond to simple curl checks but not be fully ready for scanner's more complex requests
4. **Scanner Timeout Too Short:** Scanner's 10-second timeout may be insufficient for Next.js server responses
5. **Version Switch Process:** The `make react-${version}` command may not properly restart the Next.js server in Next.js mode

**Evidence:**
- Script's `wait_for_server` function succeeds (server responds to curl)
- Scanner immediately times out when trying to connect
- All 4 vulnerable versions fail with same timeout error
- Issue occurs consistently after each version switch
- Server appears to be running (no "Server not ready" errors from script)

**Environment:**
- Framework Mode: Next.js
- Script: `scripts/verify_scanner.sh`
- Scanner: react2shell-scanner (assetnote)
- Scanner Timeout: 10 seconds
- Script Wait Time: 3 seconds sleep + up to 30 seconds wait
- Test Date: 2025-12-09

**Files Affected:**
- `scripts/verify_scanner.sh` - Version switching and server wait logic
- `Makefile` - React version switching targets (may need server restart)
- Server restart logic after version switches

**Impact:**
- **Functionality:** Cannot run scanner verification tests in Next.js mode
- **Testing:** All vulnerable version tests fail due to timeouts
- **Reliability:** Scanner verification is unreliable in Next.js framework mode
- **User Experience:** Confusing failures where server appears ready but scanner cannot connect

**Related Issues:**
- BUG-6 (Fixed): Port mismatch issue - now correctly uses port 3000
- This bug appears after BUG-6 fix - server detection works but scanner connection fails

**Proposed Solution:**
1. **Increase Wait Time After Version Switch:**
   - Increase sleep time from 3 seconds to 10-15 seconds for Next.js mode
   - Allow more time for npm install and server restart

2. **Improve Server Readiness Check:**
   - Check server with more comprehensive health check (not just curl)
   - Verify server is actually serving content, not just responding to connection
   - Add additional wait after `wait_for_server` succeeds

3. **Restart Server After Version Switch:**
   - Explicitly stop and restart server after version switch
   - Ensure server fully restarts with new React version

4. **Increase Scanner Timeout:**
   - If scanner supports timeout configuration, increase it for Next.js mode
   - Or add delay before running scanner to ensure server is fully ready

5. **Framework-Specific Wait Times:**
   - Use longer wait times for Next.js mode (similar to scanner_verification_report.sh which uses 90 attempts for Next.js)

**Workaround:**
1. Manually restart server after each version switch:
   ```bash
   make stop
   make start
   sleep 10
   ./scripts/verify_scanner.sh
   ```
2. Or run scanner verification in Vite mode where it may work better:
   ```bash
   make use-vite
   make stop
   make start
   ./scripts/verify_scanner.sh
   ```
