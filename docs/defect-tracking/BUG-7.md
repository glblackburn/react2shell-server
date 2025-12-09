# BUG-7: Scanner Connection Timeout After Version Switch in Next.js Mode

**Status:** Open  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-09

**Description:**
After fixing BUG-6 (port mismatch), the `scripts/verify_scanner.sh` script correctly detects Next.js mode and uses port 3000. However, when running scanner verification tests after switching React versions, the scanner times out with "Read timed out" errors. The script's `wait_for_server` function reports the server is ready, but the scanner cannot connect within its 10-second timeout period.

**Important Context:**
The `react2shell-scanner` is designed **exclusively for Next.js applications using React Server Components**, as stated in its README. This project's primary purpose is **React version switching** for testing different React versions, not Next.js vulnerability testing. The scanner verification script attempts to use a Next.js-specific tool on a project focused on React version testing, which represents a fundamental design mismatch.

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
**Fundamental scanner design limitation:** The `react2shell-scanner` is designed **exclusively for Next.js applications using React Server Components (RSC)**, as explicitly stated in its README: "A command-line tool for detecting CVE-2025-55182 and CVE-2025-66478 in **Next.js applications using React Server Components**."

**Key Points:**
1. **Scanner is Next.js-only:** The scanner is not designed to work with standalone React applications. It specifically targets Next.js applications with RSC infrastructure.

2. **Vulnerability is Next.js-specific:** CVE-2025-55182 and CVE-2025-66478 are vulnerabilities in **Next.js**, not in React itself. While React versions 19.0, 19.1.0, 19.1.1, and 19.2.0 are involved, the actual vulnerability exists in how Next.js uses these React versions with Server Components.

3. **Project purpose mismatch:** This project is designed for **React version switching** to test different React versions. The scanner verification script (`verify_scanner.sh`) attempts to use a Next.js-specific scanner on a project that focuses on React version testing, not Next.js vulnerability testing.

4. **Timeout as symptom:** The "Read timed out" errors are a symptom of the fundamental mismatch. The scanner sends POST requests with Next.js-specific headers (`Next-Action`, `X-Nextjs-*`) expecting Next.js RSC protocol responses. Even when the project is in "Next.js mode" (`frameworks/nextjs/`), the scanner may not receive the expected RSC protocol responses, or the RSC infrastructure may not be fully initialized/configured to handle scanner requests properly.

5. **Inappropriate tool usage:** Running `verify_scanner.sh` to test React version switching is using the wrong tool for the purpose. The scanner is for testing Next.js applications, not for validating React version switching in a standalone React project (even if it has a Next.js framework option).

**Secondary Issue - Readiness Check Mismatch:**
Additionally, the `verify_scanner.sh` script's `check_server` function only verifies that the server responds to simple GET requests, but the scanner sends complex POST requests with multipart/form-data payloads and Next.js-specific headers. After a React version switch, the server may respond to GET requests before it's fully ready to handle POST requests with Next.js RSC protocol, but this is secondary to the fundamental design mismatch.

**Detailed Analysis:**

1. **Server Readiness Check (Inadequate):**
   - `check_server()` function (line 157-163) only performs: `curl -s -f "${FRONTEND_URL}"`
   - This is a simple GET request that checks if the server accepts connections
   - GET requests are lightweight and return quickly even if the server is still initializing

2. **Scanner Request Type (Complex):**
   - Scanner sends POST requests with `multipart/form-data` payloads (scanner.py line 241)
   - Payloads can be large (especially with WAF bypass, up to 128KB+ of junk data)
   - Scanner includes Next.js-specific headers:
     - `Next-Action: x`
     - `X-Nextjs-Request-Id: b5dce965`
     - `X-Nextjs-Html-Request-Id: SSTMXm7OJ_g0Ncx6jpQt9`
     - `Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryx8jO2oVc6SWP3Sad`
   - Scanner has a 10-second timeout (scanner.py line 499, default)

3. **Next.js Server Initialization After Version Switch:**
   - After `make react-${version}`, the Makefile runs `npm install --legacy-peer-deps` (line 55)
   - Next.js dev server needs time to:
     - Detect package.json changes
     - Recompile the application with new React version
     - Initialize React Server Components (RSC) infrastructure
     - Be ready to process POST requests with Next.js-specific headers
   - The script only waits 3 seconds after version switch (line 325), then checks with GET request
   - GET request succeeds, but POST requests with complex payloads may still fail

4. **Timeout Mismatch:**
   - Script's `wait_for_server` uses 30 attempts × 1 second = 30 seconds max wait
   - But it only checks GET requests, which succeed before POST requests are ready
   - Scanner has 10-second timeout for the actual POST request
   - Server may not be ready for POST within 10 seconds even though GET succeeds

5. **Request Processing Difference:**
   - GET requests to `/` in Next.js are simple static file serving or basic routing
   - POST requests with `Next-Action` header require Next.js Server Actions/RSC processing
   - RSC infrastructure may need additional initialization time after version changes
   - The server accepts connections (GET works) but can't process complex POST requests yet

**Conclusion:**
The root cause is that `check_server()` validates server readiness using GET requests, but the scanner requires the server to be ready for complex POST requests with Next.js-specific headers. After version switches, Next.js needs more time to initialize RSC infrastructure than the current 3-second wait provides, and the GET-based readiness check gives a false positive that the server is ready for scanner requests.

**Additional Context from Scanner Analysis:**

1. **Scanner Timeout Behavior:**
   - Scanner uses Python `requests` library with single timeout value (default 10 seconds)
   - Timeout applies to entire request lifecycle: connection establishment + response reading
   - Error "Read timed out" (from `HTTPConnectionPool`) indicates:
     - Connection was successfully established (not a connection timeout)
     - Request was sent to server
     - Server did not send response within 10-second window
   - This is a **read timeout**, meaning server is accepting connections but not responding in time

2. **Next.js RSC Request Processing:**
   - When Next.js receives POST with `Next-Action` header, it must:
     - Parse multipart/form-data payload (can be large, especially with WAF bypass up to 128KB+)
     - Route through React Server Components (RSC) infrastructure
     - Process server actions if configured (`frameworks/nextjs/app/actions.ts`)
     - Execute RSC protocol handling
     - Return response with appropriate headers
   - This processing requires fully initialized RSC infrastructure

3. **Post-Version-Switch Initialization:**
   - After `make react-${version}`, Next.js dev server must:
     - Detect `package.json` changes (React version update)
     - Recompile application with new React version
     - Reinitialize RSC infrastructure for new React version
     - Rebuild server action handlers
     - Be ready to process RSC requests with new version
   - This initialization is more complex than simple HTTP server startup
   - GET requests to `/` may work (basic routing) while RSC infrastructure is still initializing
   - POST requests with `Next-Action` header require fully initialized RSC, which takes longer

4. **Request Processing Difference:**
   - **GET request** (`check_server`): Simple routing, static file serving, or basic API endpoint
     - Lightweight, returns quickly even during initialization
     - Doesn't require RSC infrastructure to be fully ready
   - **POST with Next-Action** (scanner): Requires RSC protocol processing
     - Must parse complex multipart payload
     - Must route through RSC infrastructure
     - Must process server actions
     - Requires fully initialized Next.js RSC system
     - Takes longer to process, especially during initialization

5. **Timeout Window:**
   - Script waits 3 seconds after version switch, then checks with GET (succeeds quickly)
   - Scanner runs immediately after GET check succeeds
   - Scanner has 10-second timeout for POST request
   - If RSC infrastructure needs 15-20 seconds to initialize, scanner times out
   - Server accepts connection (GET works) but can't process POST within 10 seconds

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

**Option 1: Remove or Deprecate Scanner Verification (Recommended)**
- **Recognize the fundamental mismatch:** The scanner is designed for Next.js applications, not for React version switching testing
- **Update documentation:** Clarify that `verify_scanner.sh` is only applicable if the project is being used as a Next.js application for vulnerability testing, not for React version switching
- **Mark as experimental/informational:** Document that scanner verification may not work as expected because the scanner is Next.js-specific
- **Alternative:** If Next.js vulnerability testing is needed, create a separate dedicated Next.js project specifically for that purpose

**Option 2: Fix Scanner Verification for Next.js Mode (If Next.js Testing is Required)**
If the project needs to support Next.js vulnerability testing:

1. **Improve Server Readiness Check:**
   - Replace GET-based `check_server()` with POST-based check that matches scanner behavior
   - Send a test POST request with Next.js headers to verify server can handle scanner requests
   - Check for Next.js-specific endpoints/headers that indicate RSC is ready

2. **Increase Wait Time After Version Switch:**
   - Increase sleep time from 3 seconds to 15-20 seconds for Next.js mode
   - Allow time for npm install, Next.js recompilation, and RSC initialization
   - Use framework-specific wait times (longer for Next.js, shorter for Vite)

3. **Add POST-Based Health Check:**
   - After `wait_for_server` succeeds, send a lightweight POST request with Next.js headers
   - Verify the server responds (even if with error) within reasonable time
   - Only proceed with scanner if POST request succeeds

4. **Ensure Full Next.js RSC Implementation:**
   - Verify that Next.js mode fully implements RSC infrastructure
   - Ensure Server Actions are properly configured and functional
   - Test that Next.js RSC protocol responses work correctly

5. **Increase Scanner Timeout (If Configurable):**
   - Scanner timeout is hardcoded to 10 seconds (scanner.py line 499)
   - If scanner supports timeout configuration via CLI, increase it for Next.js mode
   - Or add additional delay after POST-based health check before running scanner

**Option 3: Accept Limitation and Document**
- Document that scanner verification is only for Next.js applications
- Clarify that this project's primary purpose is React version switching, not Next.js vulnerability testing
- Note that scanner verification may not work as expected due to fundamental design mismatch

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
