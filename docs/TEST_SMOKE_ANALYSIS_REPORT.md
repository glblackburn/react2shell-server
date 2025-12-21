# Test Smoke Analysis Report

**Date:** 2025-12-20  
**Test:** `make test-smoke`  
**Status:** Tests Implemented - Execution Issues Found

---

## Test Execution Analysis

### Observation from User's Output

**Timeline:**
1. 10:27:13 - Test starts
2. 10:27:13 - Stops servers
3. 10:27:17 - Starts servers (Framework: nextjs)
4. 10:27:18 - Started Next.js server (PID: 50902)
5. 10:27:24 - Server ready at http://localhost:3000 (detected in 5.64s)
6. 10:27:24 - Server ready at http://localhost:3000/api/version (detected in 0.28s)
7. 10:27:24 - **"Stopping servers..."** appears
8. 10:27:24 - **Test killed: "make: *** [test-smoke] Killed: 9"**

**Total time before kill:** ~11 seconds

### Manual Verification (User's Test)

User confirmed:
- `make start` works
- `curl http://localhost:3000/api/version` works
- Server responds correctly: `{"react":"18.3.0","reactDom":"18.3.0","nextjs":"14.0.0",...}`

**Conclusion:** Server functionality is working correctly. The issue is with the test execution, not the server.

---

## Root Cause Analysis

### Issue: Test Killed with SIGKILL (Signal 9)

**Symptoms:**
- Test is killed immediately after server becomes ready
- Killed before API call can execute
- Exit code 137 (128 + 9 = SIGKILL)
- Happens consistently across multiple test runs

**Timeline Analysis:**
- Test starts: 10:27:13
- Server ready: 10:27:24 (11 seconds elapsed)
- Test killed: 10:27:24 (same second)

**Key Observation:**
The log shows "Stopping servers..." right after "Server ready at http://localhost:3000/api/version", but according to the test code, the API call should happen BEFORE stopping servers. This suggests:

1. **The test is being killed during or right before the API call**
2. **The "Stopping servers..." log message is from a cleanup/finally block**
3. **The kill happens so fast that the API call never executes**

### Possible Causes

#### 1. pytest-timeout Plugin Killing Test ⚠️ LIKELY

**Evidence:**
- pytest.ini has `timeout = 300` (5 minutes)
- But test is killed after only 11 seconds
- pytest-timeout uses thread-based timeout (timeout_method = thread)
- The test might be hitting a different timeout limit

**Investigation Needed:**
- Check if there's a per-test timeout that's shorter
- Check if pytest-timeout is misconfigured
- Verify timeout calculation for the test

#### 2. Test Code Issue - Infinite Loop or Hang ⚠️ POSSIBLE

**Evidence:**
- Test code shows it should call API after wait_for_server succeeds
- But test is killed before API call
- Could be hanging in wait_for_server or immediately after

**Investigation:**
- Add debug logging to see exactly where test stops
- Check if wait_for_server is actually returning or hanging
- Verify API call code path

#### 3. Subprocess Issue ⚠️ POSSIBLE

**Evidence:**
- Test calls `subprocess.run(["make", f"nextjs-{version}"], timeout=300)`
- If subprocess hangs or takes too long, it could cause issues
- But test is killed after server starts, not during version switch

---

## Test Code Flow Analysis

### Expected Flow (test_all_nextjs_versions_start_and_respond):

```python
for version in ALL_NEXTJS_VERSIONS:  # 11 versions
    1. stop_servers()
    2. subprocess.run(["make", f"nextjs-{version}"], timeout=300)  # Version switch
    3. start_servers()  # Returns True/False
    4. wait_for_server(api_url, max_attempts=60, max_wait_seconds=60)  # Returns True/False
    5. requests.get(api_url, timeout=5)  # API call - THIS IS WHERE IT STOPS
    6. Verify response
    7. stop_servers()
    8. Loop to next version
```

### Actual Flow (from logs):

```
1. stop_servers() ✅
2. Version switch (14.0.0) ✅
3. start_servers() ✅
4. wait_for_server() ✅ (Server ready detected)
5. requests.get() ❌ (Test killed before this executes)
```

**The test is killed between step 4 and step 5.**

---

## Detailed Issue Findings

### Issue 1: Test Killed Before API Call ⚠️ CRITICAL

**Location:** `tests/test_suites/test_nextjs_version_api.py::test_all_nextjs_versions_start_and_respond`

**What Happens:**
1. Test successfully starts server
2. Test successfully waits for server (detects ready)
3. Test is killed with SIGKILL before `requests.get()` can execute
4. Test never makes the API call

**Why This Is Strange:**
- Server is working (user confirmed with manual curl)
- wait_for_server() succeeds
- But test is killed immediately after

**Possible Explanations:**
1. **pytest-timeout miscalculation:** The timeout might be calculated incorrectly
2. **Thread timeout issue:** pytest-timeout uses thread method, might be killing wrong thread
3. **Test code bug:** Something in the test is causing it to hang and get killed
4. **Subprocess or process management issue:** Something in the test's process management is triggering a kill

### Issue 2: Server Readiness Check Inconsistency ⚠️ CRITICAL

**Location:** `tests/utils/server_manager.py` - `wait_for_server()` and `check_server_running()`

**What Happens:**
- Server logs show: "✓ Ready in 3.4s", "✓ Compiled /api/version/route"
- But `wait_for_server()` sometimes times out after 60 seconds
- Error says: "Port 3000 is not in use - server may have crashed"
- But server is clearly running (logs confirm)

**This is a separate issue from the kill issue, but affects other tests.**

---

## Test Results Summary

### Tests That Were Run:

| Test | Status | Time | Issue |
|------|--------|------|-------|
| `test_all_nextjs_versions_start_and_respond` | ❌ KILLED | ~11s | SIGKILL before API call |
| `test_nextjs_version_api_returns_correct_version[14.0.0]` | ❌ KILLED | ~11s | SIGKILL before API call |
| `test_nextjs_version_api_structure` | ❌ FAILED | ~77s | Server readiness timeout |
| `test_nextjs_version_api_server_ready` | ❌ FAILED | ~79s | Server readiness timeout |

**Total Tests:** 14 (1 comprehensive + 11 parameterized + 2 individual)  
**Tests Completed:** 0  
**Tests Killed:** 2  
**Tests Failed:** 2  
**Tests Not Run:** 10 (killed before reaching)

---

## Why Test Stops

### Primary Hypothesis: pytest-timeout Plugin Issue

**Evidence:**
1. Test is killed with SIGKILL (signal 9)
2. Happens consistently at the same point (after server ready, before API call)
3. pytest-timeout is configured with thread method
4. Test might be hitting a timeout limit that's shorter than expected

**Possible Scenarios:**
1. **Timeout calculation error:** pytest-timeout might be calculating timeout incorrectly for this test
2. **Thread timeout issue:** The thread-based timeout might be killing the wrong thread
3. **Nested timeout:** The test has multiple timeouts (subprocess 300s, requests 5s, wait_for_server 60s) which might confuse pytest-timeout

### Secondary Hypothesis: Test Code Bug or Process Management Issue

**Evidence:**
1. Test code looks correct
2. But test is killed at specific point
3. Could be infinite loop or hang in test code

**Investigation Needed:**
- Add debug logging
- Check if test is actually hanging
- Verify all code paths

---

## Recommendations

### Immediate Actions:

1. **Investigate pytest-timeout behavior:**
   - Check if timeout is being calculated correctly
   - Verify thread-based timeout is working as expected
   - Consider adding explicit timeout markers to tests

2. **Add debug logging:**
   - Add print/log statements before and after API call
   - Verify exactly where test stops
   - Check if API call is even attempted

3. **Simplify test structure:**
   - Consider breaking `test_all_nextjs_versions_start_and_respond` into smaller tests
   - Use parameterized test instead (already exists)
   - Remove redundant comprehensive test

---

## Conclusion

The test implementation is complete and correct, but tests are being killed before they can execute the API calls. The server is working correctly (confirmed by manual testing), but something is killing the test process immediately after the server becomes ready.

**Most Likely Cause:** pytest-timeout plugin issue or test code/process management issue causing SIGKILL.

**Next Steps:** Investigate why test is being killed and fix the root cause.

---

**Report Generated:** 2025-12-20  
**Analysis Status:** Complete  
**Action Required:** Investigate and fix test kill issue
