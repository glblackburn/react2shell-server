# Vite Express Server Fix Plan - December 26, 2025 11:31:01 EST

**Date Created:** December 26, 2025 11:31:01 EST  
**Attempt:** 1  
**Status:** In Progress

## Problem Statement

The "Test Vite + React" job fails because the Express server does not start. The Makefile runs `node server.js` from the root directory, but `server.js` is located in the `server/` subdirectory, causing Node.js to fail to find the file.

## Root Cause Analysis

**Root Cause:** Makefile path issue - `node server.js` is executed from root, but file is at `server/server.js`.

**Evidence:**
- Server PID is created (4753) but server is not running
- Status check shows "Backend (Express): ✗ Not running"
- curl fails with exit code 7 (connection refused)
- Vite server starts fine (runs from correct directory: `frameworks/vite-react`)

**Current Makefile Code:**
```makefile
nohup node server.js > $(SERVER_LOG) 2>&1 & \
```

**Issue:**
- Executes from root directory
- `server.js` is at `server/server.js`
- Node.js cannot find file, process exits immediately

**File Location:**
- `server/server.js` exists
- Makefile runs from project root

## Changes Implemented

### 1. Fix Express Server Path ✅
**Location:** `Makefile` - Vite server startup section (around line 768)

**Changes:**
- Change `node server.js` to `node server/server.js`
- Or change directory to `server/` before running

**Rationale:** Server.js is in `server/` directory, so path must be correct.

**Option A (Recommended):** Use full path
```makefile
nohup node server/server.js > $(SERVER_LOG) 2>&1 & \
```

**Option B:** Change directory first
```makefile
cd server && nohup node server.js > ../$(SERVER_LOG) 2>&1 & \
```

**Decision:** Use Option A (simpler, clearer path).

## Testing Plan

### Local Testing Steps

1. **Test server startup:**
   ```bash
   # Clean environment
   make stop
   make use-vite
   
   # Start servers
   make start
   
   # Check status
   make status
   
   # Verify Express server is running
   curl http://localhost:3000/api/version
   ```

2. **Verify API works:**
   ```bash
   # Test version API
   curl http://localhost:3000/api/version | jq '.'
   
   # Should return:
   # {
   #   "react": "...",
   #   "reactDom": "...",
   #   "node": "...",
   #   "vulnerable": true/false,
   #   "status": "..."
   # }
   ```

3. **Test full workflow:**
   ```bash
   # Switch to React 19.0
   make react-19.0
   make stop
   make start
   
   # Wait for servers
   sleep 5
   
   # Test API
   curl http://localhost:3000/api/version | jq '.'
   ```

### Expected Results

**Success Criteria:**
- ✅ Express server starts successfully
- ✅ `make status` shows "Backend (Express): ✓ Running"
- ✅ API responds at http://localhost:3000/api/version
- ✅ Version API returns correct JSON
- ✅ Vite + React test passes in CI

**Failure Indicators:**
- Express server not running
- API returns connection refused
- Server process exits immediately

## Local Test Results

**Date Tested:** [To be filled after testing]  
**Result:** [Pending]

**Output:**
- [To be filled after testing]

**Log File:** `/tmp/local_test_YYYYMMDD_HHMMSS.txt`

## Next Steps

### Immediate Actions

1. **Fix Makefile:**
   - Update `node server.js` to `node server/server.js`
   - Test locally to verify fix

2. **Test locally:**
   - Run `make start` in Vite mode
   - Verify Express server starts
   - Test API endpoint
   - Verify version matching still works

3. **Commit and push:**
   - Commit fix
   - Push to trigger GitHub Actions
   - Monitor run

4. **Monitor GitHub Actions:**
   - Watch the run
   - Check if Vite + React test passes
   - Update fix plan with results

### Success Criteria

- ✅ Express server starts in CI
- ✅ Vite + React test passes
- ✅ All jobs pass
- ✅ Version API works correctly

## GitHub Actions Run Results

### Stability Verification Status

**Requirement:** Three consecutive successful runs where the entire workflow completes without any failures.

**Consecutive Successes:**
- Run 1: ⏳ Pending - Run ID: [TBD]
- Run 2: ⏳ Pending - Run ID: [TBD]
- Run 3: ⏳ Pending - Run ID: [TBD]

**Status:** 0/3 consecutive successes achieved

---

### Run 1 Results

[To be filled after monitoring GitHub Actions run]

---

## Known Issues

None at this time.

## Related Documentation

- [CI Test Failure Analysis 2025-12-26 11:30:55](CI_TEST_FAILURE_ANALYSIS_2025-12-26_113055.md) - Original analysis
- [CI Fix Plan 2025-12-26 07:04:48](CI_FIX_PLAN_2025-12-26_070448.md) - Previous fix plan (version matching)
- [CI Fix Iteration Workflow](CI_FIX_ITERATION_WORKFLOW.md) - Workflow documentation

## Date

December 26, 2025 11:31:01 EST
