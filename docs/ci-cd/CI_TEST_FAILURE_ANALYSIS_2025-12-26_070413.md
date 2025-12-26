# CI Test Failure Analysis - December 26, 2025 07:04:13 EST

## Executive Summary

Analysis of GitHub Actions run 20521925468 (commit `7b9c2a2` - "feat: Implement Step 3 - Vite Test Job") revealed:

- **Test Vite + React Job:** Failed - Expected React 19.0 and vulnerable=true, but got different values
- **Test Next.js Startup Job:** Failed on version 16.0.6 due to deploymentId bug (similar to 15.2.5 issue)
- **Root causes identified:** 
  1. Vite test: API version response doesn't match expected values
  2. Next.js 16.0.6: Same deploymentId bug affecting server's ability to handle HTTP requests

## Run Information

- **Run ID:** 20521925468
- **Branch:** `ci-cd/step-3-vite-test-job`
- **Commit:** `7b9c2a2` - "feat: Implement Step 3 - Vite Test Job"
- **Status:** FAILED
- **URL:** https://github.com/glblackburn/react2shell-server/actions/runs/20521925468
- **Started:** 2025-12-26T11:49:40Z
- **Completed:** 2025-12-26T11:57:09Z
- **Duration:** ~7.5 minutes

## Job Results Summary

| Job | Status | Conclusion | Notes |
|-----|--------|------------|-------|
| Lint and Validate | ✅ | Success | All validation passed |
| Validate Versions | ✅ | Success | All validation passed |
| Test Vite + React | ❌ | Failure | React version/vulnerable flag mismatch |
| Test Next.js Framework | ✅ | Success | All tests passed |
| Test Python (vite) | ✅ | Success | All tests passed |
| Test Python (nextjs) | ✅ | Success | All tests passed |
| Test Next.js Startup | ❌ | Failure | Failed on 1 version (16.0.6) |

## Issue 1: Test Vite + React Job Failure

### Root Cause
The test expects React version 19.0 and vulnerable=true from the `/api/version` endpoint, but the actual response contains different values.

### Evidence from Logs

**Error Messages:**
```
❌ Expected React 19.0, got $REACT_VERSION
❌ Expected vulnerable=true, got $VULNERABLE
##[error]Process completed with exit code 7.
```

**Test Steps:**
1. Setup project: `make setup`
2. Switch to Vite framework: `make use-vite`
3. Test with vulnerable React version (19.0): `make react-19.0`
4. Start servers: `make start`
5. Wait for servers to be ready (ports 5173 and 3000)
6. Verify version API: `curl http://localhost:3000/api/version`
7. Check React version and vulnerable flag

**Failure Point:**
- The version API response doesn't match expected values
- Exit code 7 indicates the test assertion failed

### Problem Analysis

**Current Test Implementation:**
```bash
VERSION_RESPONSE=$(curl -s http://localhost:3000/api/version)
REACT_VERSION=$(echo "$VERSION_RESPONSE" | jq -r '.react')
if [ "$REACT_VERSION" != "19.0" ]; then
  echo "❌ Expected React 19.0, got $REACT_VERSION"
  exit 1
fi
VULNERABLE=$(echo "$VERSION_RESPONSE" | jq -r '.vulnerable')
if [ "$VULNERABLE" != "true" ]; then
  echo "❌ Expected vulnerable=true, got $VULNERABLE"
  exit 1
fi
```

**Possible Issues:**
1. **React version not switching correctly:** `make react-19.0` may not be updating package.json correctly
2. **API response format:** The `/api/version` endpoint may not be returning the expected format
3. **Server not using updated version:** Server may be using cached/old version
4. **Timing issue:** Server may not have restarted with new version before API check

### What We Need to Investigate
- What does `/api/version` actually return?
- Is `make react-19.0` working correctly?
- Is the server restarting after version switch?
- Are there any errors in server startup logs?

## Issue 2: Test Next.js Startup Job Failure

### Root Cause
Next.js version 16.0.6 fails with the same `deploymentId` bug that affected version 15.2.5. The server starts and reports "Ready" but cannot handle HTTP requests due to `TypeError: Cannot read properties of undefined (reading 'deploymentId')`.

### Evidence from Logs

**Test Results:**
- ✅ 14.0.0 passed
- ✅ 14.1.0 passed
- ✅ 15.0.4 passed
- ✅ 15.1.8 passed
- ✅ 15.2.5 passed (was previously failing)
- ✅ 15.3.5 passed
- ✅ 15.4.7 passed (was previously failing)
- ✅ 15.5.6 passed
- ❌ **16.0.6 failed** - Server did not accept requests on port 3000 within 30 seconds (waited: 149s)
- ✅ 14.0.1 passed (was previously failing)
- ✅ 14.1.1 passed

**Summary:**
- ✓ Passed: 10
- ❌ Failed: 1
- Failed versions: 16.0.6

**Error Details:**
```
❌ Server did not accept requests on port 3000 for 16.0.6 within 30 seconds (waited: 149s)
```

**Server Logs Show:**
- Server started successfully: `✓ Starting...`
- Server reported ready: `✓ Ready in 446ms`
- Server compiled: `✓ Compiled in 8.6s (653 modules)`
- But HTTP requests fail with: `TypeError: Cannot read properties of undefined (reading 'deploymentId')`
- Multiple errors: `GET /api/version 500 in 63ms`

**Error Stack Trace:**
```
TypeError: Cannot read properties of undefined (reading 'deploymentId')
  at renderToHTMLImpl (/home/runner/work/react2shell-server/react2shell-server/frameworks/nextjs/node_modules/next/dist/server/render.js:227:23)
  at PagesRouteModule.render (/home/runner/work/react2shell-server/react2shell-server/frameworks/nextjs/node_modules/next/dist/server/route-modules/pages/module.js:81:45)
  ...
```

**Additional Errors:**
- `Error: Cannot find module '../../client/components/react-dev-overlay/pages/pages-dev-overlay'`
- `TypeError: __webpack_modules__[moduleId] is not a function`
- Webpack cache errors

### Problem Analysis

**What's Happening:**
1. Next.js 16.0.6 starts successfully
2. Server reports "Ready" status
3. When HTTP requests are made, Next.js tries to render pages
4. During rendering, it attempts to access `metadata.assetQueryString` but `metadata` is undefined
5. This causes the `deploymentId` error
6. All HTTP requests return 500 errors
7. Test script waits 149 seconds but server never becomes responsive

**Comparison with Previous Fix:**
- Version 15.2.5 had the same issue and was documented as a known bug
- Version 16.0.6 appears to have the same bug
- The previous fix plan noted this as a known issue for 15.2.5
- We need to handle 16.0.6 similarly

**Options:**
1. **Document as known issue** (like 15.2.5)
2. **Skip 16.0.6 in CI** (test locally only)
3. **Add retry logic** (retry 3 times before failing)
4. **Investigate if there's a workaround** for 16.0.6

### What We Know
- Server starts and reports ready
- Server cannot handle HTTP requests
- Error is the same deploymentId bug as 15.2.5
- 10 out of 11 versions pass
- Only 16.0.6 fails

### What We Don't Know
- Is this a known Next.js 16.0.6 bug?
- Is there a workaround or fix?
- Should we skip this version or document it?

## Comparison with Previous Run

**Previous Successful Run (20521706863):**
- All 11 versions passed
- Port detection working correctly
- Port cleanup working correctly

**Current Run (20521925468):**
- 10 versions passed, 1 failed (16.0.6)
- Port detection still working
- New issue: 16.0.6 deploymentId bug

**Regression:**
- This appears to be a new failure, not a regression of the previous fix
- The port detection fix is still working
- 16.0.6 is a different version that wasn't tested in the previous successful run

## Next Steps

1. **For Vite + React Test:**
   - Investigate what `/api/version` actually returns
   - Verify `make react-19.0` is working correctly
   - Check if server restart is needed after version switch
   - Add diagnostic logging to see actual API response

2. **For Next.js Startup Test:**
   - Document 16.0.6 as known issue (similar to 15.2.5)
   - Or skip 16.0.6 in CI tests
   - Or add retry logic for this version
   - Investigate if there's a Next.js 16.0.6 workaround

## Log Files

- Full run log: `/tmp/github_actions_run_20521925468_2025-12-26_114940.txt`
- Next.js job log: `/tmp/github_actions_nextjs_job_20521925468_2025-12-26_114940.txt`

## Date

December 26, 2025 07:04:13 EST
