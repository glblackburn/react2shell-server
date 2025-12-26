# CI Test Failure Analysis - December 26, 2025

## Executive Summary

Analysis of GitHub Actions run 20514739885 (commit `88c255c` - "feat: Implement Step 3 - Vite Test Job") revealed:

- **Test Vite + React Job:** Failed due to servers not becoming ready within 30 seconds (curl exit code 7)
- **Test Next.js Startup Job:** Failed on same versions as before (15.2.5, 15.4.7, 14.0.1) due to port conflicts and Next.js 15.2.5 deploymentId bug
- **Root causes identified:** Missing diagnostics, insufficient timeout, incomplete port cleanup

## Run Information

- **Run ID:** 20514739885
- **Branch:** `ci-cd/step-3-vite-test-job`
- **Commit:** `88c255c` - "feat: Implement Step 3 - Vite Test Job"
- **Status:** FAILED
- **URL:** https://github.com/glblackburn/react2shell-server/actions/runs/20514739885

## Job Results Summary

| Job | Status | Conclusion | Notes |
|-----|--------|------------|-------|
| Lint and Validate | ✅ | Success | All validation passed |
| Test Next.js Startup | ❌ | Failure | Failed on 3 versions (15.2.5, 15.4.7, 14.0.1) |
| Test Vite + React | ❌ | Failure | Servers not ready within 30 seconds |
| Test Python (vite) | ✅ | Success | Placeholder job |
| Test Next.js Framework | ✅ | Success | Placeholder job |
| Test Python (nextjs) | ✅ | Success | Placeholder job |
| Validate Versions | ✅ | Success | Placeholder job |

## Issue 1: Test Vite + React Job Failure

### Root Cause
Servers start successfully but do not become ready within the 30-second timeout period. The script exits with curl exit code 7 ("Failed to connect to host").

### Evidence from Logs

**Timeline:**
- `02:50:46` - Servers started: Vite PID 4735, Express PID 4736
- `02:50:48` - First "Waiting for servers to be ready..." message
- `02:50:54` - Second "Waiting for servers to be ready..." message (6 seconds later)
- `02:51:24` - Process completed with exit code 7 (30 seconds total wait)

**Key Observations:**
1. Servers started successfully (PIDs assigned)
2. Warning: `/bin/sh: 41: cannot create ../../.pids/vite.pid: Directory nonexistent`
3. Script waited full 30 seconds but never saw "✓ Servers are ready"
4. Exit code 7 indicates curl failed to connect

### Problem Analysis

**Current Implementation:**
```bash
for i in {1..30}; do
  if curl -s http://localhost:5173 > /dev/null && curl -s http://localhost:3000/api/version > /dev/null; then
    echo "✓ Servers are ready"
    break
  fi
  sleep 1
done
```

**Issues:**
1. **No diagnostic output:** `curl -s` suppresses all output, so we can't see which port is failing
2. **Combined check:** Using `&&` means if either port fails, we don't know which one
3. **No error reporting:** Exit code 7 doesn't tell us which curl command failed
4. **Timeout may be insufficient:** Vite dev server can take longer than 30 seconds in CI
5. **Missing directory:** `.pids` directory doesn't exist (warning but servers still start)

### What We Know
- Servers start (PIDs 4735 and 4736 assigned)
- Script waits 30 seconds
- Neither port 5173 nor 3000 responds within timeout
- No diagnostic information about which port is failing or why

### What We Don't Know
- Which port is failing (5173 or 3000)?
- Are servers actually running but not ready?
- Is it a timing issue (need longer timeout)?
- Are there errors in server logs that would explain the failure?

## Issue 2: Test Next.js Startup Job Failure

### Root Cause
Same issue as previous runs: Port conflicts (ports 3000 and 3001 in use) cause Next.js to start on alternate port (3002), but test script only checks port 3000. Additionally, Next.js 15.2.5 has a known deploymentId bug.

### Evidence from Logs

**Failed Versions:**
- 15.2.5: Server started on port 3002 (ports 3000 and 3001 were in use)
- 15.4.7: Similar port conflict
- 14.0.1: Similar port conflict

**Success Pattern:**
- 14.0.0: ✅ Passed
- 14.1.0: ✅ Passed
- 15.0.4: ✅ Passed
- 15.1.8: ✅ Passed

**Failure Pattern:**
- 15.2.5: ❌ Failed - Port conflict + deploymentId error
- 15.4.7: ❌ Failed - Port conflict
- 14.0.1: ❌ Failed - Port conflict

### Problem Analysis

**Current Cleanup (lines 112-126 in test_nextjs_startup.sh):**
- Only checks and cleans port 3000 before starting
- Does NOT check ports 3001-3010
- If orphaned processes are on 3001, Next.js will try 3001, then 3002

**What Happens:**
1. Script checks port 3000: ✅ Free
2. Script starts server
3. Next.js tries to bind to 3000: ❌ In use (race condition or orphaned process)
4. Next.js tries 3001: ❌ In use
5. Next.js starts on 3002: ✅ Success
6. Script checks port 3000: ❌ Fails (server is on 3002)

**Next.js 15.2.5 Specific Issue:**
- Server starts successfully on port 3002
- Server reports "Ready in 1259ms"
- But when handling requests, crashes with: `TypeError: Cannot read properties of undefined (reading 'deploymentId')`
- This is a known Next.js 15.2.5 bug

## Recommendations

### Priority 1: Fix Test Vite + React Job

#### 1.1 Fix .pids Directory Issue
**Problem:** `.pids` directory doesn't exist, causing warning
**Solution:** Ensure directory exists before `make start`
```bash
mkdir -p .pids .logs
```

#### 1.2 Improve Server Readiness Check
**Problem:** No diagnostic output, combined check hides which port fails
**Solution:** Check ports separately with diagnostic output
```bash
# Check ports separately with diagnostics
VITE_READY=0
EXPRESS_READY=0

for i in {1..60}; do
  # Check Vite (port 5173)
  if [ $VITE_READY -eq 0 ]; then
    if curl -s -f http://localhost:5173 > /dev/null 2>&1; then
      echo "✓ Vite dev server is ready (port 5173)"
      VITE_READY=1
    else
      VITE_EXIT=$?
      if [ $((i % 5)) -eq 0 ]; then
        echo "  [${i}s] Waiting for Vite dev server (port 5173)... (curl exit: $VITE_EXIT)"
      fi
    fi
  fi
  
  # Check Express (port 3000)
  if [ $EXPRESS_READY -eq 0 ]; then
    if curl -s -f http://localhost:3000/api/version > /dev/null 2>&1; then
      echo "✓ Express server is ready (port 3000)"
      EXPRESS_READY=1
    else
      EXPRESS_EXIT=$?
      if [ $((i % 5)) -eq 0 ]; then
        echo "  [${i}s] Waiting for Express server (port 3000)... (curl exit: $EXPRESS_EXIT)"
      fi
    fi
  fi
  
  # Both ready?
  if [ $VITE_READY -eq 1 ] && [ $EXPRESS_READY -eq 1 ]; then
    echo "✓ Both servers are ready"
    break
  fi
  
  sleep 1
done

if [ $VITE_READY -eq 0 ] || [ $EXPRESS_READY -eq 0 ]; then
  echo "❌ Servers did not become ready within 60 seconds"
  echo "  Vite (5173): $([ $VITE_READY -eq 1 ] && echo 'ready' || echo 'not ready')"
  echo "  Express (3000): $([ $EXPRESS_READY -eq 1 ] && echo 'ready' || echo 'not ready')"
  # Show server logs for debugging
  if [ -f .logs/vite.log ]; then
    echo "--- Vite log (last 20 lines) ---"
    tail -20 .logs/vite.log
  fi
  if [ -f .logs/server.log ]; then
    echo "--- Express log (last 20 lines) ---"
    tail -20 .logs/server.log
  fi
  exit 1
fi
```

**Key Improvements:**
- Separate checks for each port
- Diagnostic output showing which port is failing
- Increased timeout to 60 seconds (Vite can be slower)
- Show curl exit codes for debugging
- Display server logs on failure

#### 1.3 Add Process Verification
**Problem:** Don't know if processes are actually running
**Solution:** Verify processes are running before checking ports
```bash
# Verify processes are running
if ! ps -p $VITE_PID > /dev/null 2>&1; then
  echo "❌ Vite process (PID: $VITE_PID) is not running"
  exit 1
fi
if ! ps -p $EXPRESS_PID > /dev/null 2>&1; then
  echo "❌ Express process (PID: $EXPRESS_PID) is not running"
  exit 1
fi
```

### Priority 2: Fix Test Next.js Startup Job

#### 2.1 Expand Pre-Start Port Cleanup
**Problem:** Only cleans port 3000, but Next.js can use 3001-3010
**Solution:** Clean all ports 3000-3010 before starting (match post-failure cleanup)

**Current code (lines 112-126):**
```bash
# Verify port 3000 is available before starting
if lsof -ti:3000 >/dev/null 2>&1; then
  # ... cleanup port 3000 only
fi
```

**Recommended fix:**
```bash
# Verify ports 3000-3010 are available before starting
PORTS_IN_USE=""
for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
  if lsof -ti:$port >/dev/null 2>&1; then
    PORTS_IN_USE="$PORTS_IN_USE $port"
  fi
done

if [ -n "$PORTS_IN_USE" ]; then
  print_error "❌ Ports in use before starting ${version_clean}:$PORTS_IN_USE"
  print_error "Attempting cleanup..."
  (cd "$PROJECT_ROOT" && make stop >/dev/null 2>&1) || true
  # Kill all processes on ports 3000-3010
  for port in 3000 3001 3002 3003 3004 3005 3006 3007 3008 3009 3010; do
    lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
  done
  # Kill all Next.js/node processes
  pkill -f "next dev" 2>/dev/null || true
  pkill -f "next-server" 2>/dev/null || true
  pkill -f "node.*next" 2>/dev/null || true
  sleep 3
  # Verify cleanup
  PORTS_STILL_IN_USE=""
  for port in 3000 3001 3002 3003 3004 3005; do
    if lsof -ti:$port >/dev/null 2>&1; then
      PORTS_STILL_IN_USE="$PORTS_STILL_IN_USE $port"
    fi
  done
  if [ -n "$PORTS_STILL_IN_USE" ]; then
    print_error "❌ Ports still in use after cleanup:$PORTS_STILL_IN_USE"
    ((FAILED++))
    FAILED_VERSIONS+=("${version_clean}: port conflict - ports in use")
    return 1
  fi
  print_info "✓ Ports cleaned up, proceeding with start"
fi
```

#### 2.2 Handle Alternate Ports
**Problem:** Script only checks port 3000, but server may start on 3001-3010
**Solution:** Detect which port server actually started on and use that port

**Recommended approach:**
```bash
# After starting server, detect which port it's actually on
DETECTED_PORT=""
for port in 3000 3001 3002 3003 3004 3005; do
  if curl -s -f http://localhost:$port/api/version > /dev/null 2>&1; then
    DETECTED_PORT=$port
    print_info "✓ Server detected on port $port"
    break
  fi
done

if [ -z "$DETECTED_PORT" ]; then
  print_error "❌ Server not found on any port 3000-3005"
  # ... existing failure handling
  return 1
fi

# Use detected port for API verification
VERSION_RESPONSE=$(curl -s http://localhost:$DETECTED_PORT/api/version)
```

#### 2.3 Document Next.js 15.2.5 Known Issue
**Problem:** Next.js 15.2.5 has a deploymentId bug that causes crashes
**Solution:** Document as known issue or add special handling

**Option A: Document as Known Issue**
- Add to CI test failure analysis documentation
- Note that 15.2.5 may fail in CI due to known Next.js bug
- All versions pass locally (as documented in previous analysis)

**Option B: Add Retry Logic**
- Retry 15.2.5 test up to 3 times
- Accept if at least one retry succeeds

**Option C: Skip in CI**
- Skip 15.2.5 in CI but test locally
- Document why it's skipped

## Next Steps

### Immediate Actions

1. **Fix Test Vite + React Job:**
   - Add `.pids` directory creation
   - Improve server readiness check with separate port checks and diagnostics
   - Increase timeout to 60 seconds
   - Add process verification
   - Show server logs on failure

2. **Fix Test Next.js Startup Job:**
   - Expand pre-start port cleanup to check ports 3000-3010
   - Add alternate port detection
   - Document Next.js 15.2.5 known issue

### Testing Plan

1. **Test Vite Job Fix:**
   - Push changes and verify servers become ready
   - Verify diagnostic output shows which port is ready/failing
   - Verify timeout is sufficient

2. **Test Next.js Job Fix:**
   - Verify pre-start cleanup prevents port conflicts
   - Verify alternate port detection works
   - Verify 15.2.5 handling (document or skip)

### Success Criteria

- **Test Vite + React:** Both servers become ready and tests pass
- **Test Next.js Startup:** All 11 versions pass (or 10 if 15.2.5 is documented as known issue)

## How to Monitor GitHub Actions Runs

**Primary Method:** Use GitHub CLI (`gh`) to monitor runs and view logs.

### Prerequisites

**Install GitHub CLI (if not already installed):**
```bash
# macOS
brew install gh

# Verify installation
gh --version
```

**Authenticate with GitHub:**
```bash
gh auth login
# Follow prompts to authenticate
```

### Monitoring Workflow Runs with `gh` CLI

#### 1. List Recent Workflow Runs

**View latest runs:**
```bash
# List last 5 runs
gh run list --limit 5

# List runs for specific branch
gh run list --branch ci-cd/step-3-vite-test-job --limit 5

# List runs with more details
gh run list --limit 5 --json databaseId,status,conclusion,workflowName,headBranch,createdAt
```

**Output shows:**
- Run ID (databaseId)
- Status (queued/in_progress/completed)
- Conclusion (success/failure/cancelled)
- Workflow name
- Branch
- Timestamp

#### 2. View a Specific Run

**View run by ID:**
```bash
# View run overview
gh run view 20514739885

# View run with full details
gh run view 20514739885 --log
```

**View latest run:**
```bash
gh run view --log
```

**View latest run for specific branch:**
```bash
gh run view --branch ci-cd/step-3-vite-test-job --log
```

#### 3. Watch a Run in Real-Time

**After pushing fixes, watch the new run:**
```bash
# Watch latest run (auto-refreshes)
gh run watch

# Watch specific run
gh run watch 20514739885

# Watch with log output
gh run watch --log
```

**This will:**
- Show run status updates
- Display job progress
- Show logs as they're generated
- Exit when run completes

#### 4. View Job Logs

**View logs for a specific job:**
```bash
# View all logs for a run
gh run view 20514739885 --log

# View logs for a specific job (by name)
gh run view 20514739885 --log | grep -A 100 "Test Vite + React"

# Save logs to file for analysis
gh run view 20514739885 --log > run-20514739885.log
```

**Filter logs for specific information:**
```bash
# Find error messages
gh run view 20514739885 --log | grep -i "error\|failed\|exit code"

# Find server startup messages
gh run view 20514739885 --log | grep -i "server\|pid\|port\|ready"

# Find timing information
gh run view 20514739885 --log | grep -E "[0-9]{2}:[0-9]{2}:[0-9]{2}"
```

#### 5. Compare Runs

**Compare two runs:**
```bash
# Get run IDs
gh run list --limit 2 --json databaseId,status,conclusion

# View both runs
gh run view RUN_ID_1 --log > run1.log
gh run view RUN_ID_2 --log > run2.log

# Compare (if you have diff tools)
diff -u run1.log run2.log
```

### Key Information to Look For in Logs

When analyzing logs, search for:

1. **Exit Codes:**
   - `exit code 7` = curl connection failure
   - `exit code 1` = test failure
   - `exit code 0` = success

2. **Server Startup:**
   - Look for PID assignments: `Vite PID 4735, Express PID 4736`
   - Server ready messages: `✓ Servers are ready`
   - Port binding: `Port 3000 is in use, trying 3001 instead`

3. **Timing:**
   - Timestamps showing when servers start vs when checks fail
   - Timeout messages: `Servers did not become ready within 30 seconds`

4. **Diagnostic Output:**
   - Port readiness checks: `Waiting for Vite dev server (port 5173)...`
   - Process verification: `Vite process (PID: 4735) is not running`

### Monitoring Workflow After Implementing Fixes

**Step-by-step process:**

1. **Push your fixes:**
   ```bash
   git push origin ci-cd/step-3-vite-test-job
   ```

2. **Get the new run ID:**
   ```bash
   # Wait a few seconds for run to start, then:
   gh run list --limit 1 --json databaseId,status,workflowName
   ```

3. **Watch the run:**
   ```bash
   # Watch latest run with logs
   gh run watch --log
   
   # Or watch specific run
   gh run watch RUN_ID --log
   ```

4. **Analyze results:**
   ```bash
   # After run completes, view full logs
   gh run view RUN_ID --log > latest-run.log
   
   # Check for specific issues
   grep -i "error\|failed" latest-run.log
   grep -i "ready\|server" latest-run.log
   ```

5. **Verify fixes worked:**
   - Check if both servers become ready (look for "✓ Both servers are ready")
   - Verify diagnostic output shows which ports are ready
   - Confirm no timeout errors
   - Check that all test versions pass

### Expected Log Output After Fixes

**For Test Vite + React Job (successful):**
```
✓ Vite dev server is ready (port 5173)
✓ Express server is ready (port 3000)
✓ Both servers are ready
Version API response: {"react":"19.0","vulnerable":true}
✓ React 19.0 (VULNERABLE) verified
```

**For Test Next.js Startup Job (successful):**
```
✓ Ports cleaned up, proceeding with start
✓ Server detected on port 3000
✓ Next.js 15.2.5 startup test passed
```

### Troubleshooting `gh` CLI

**If `gh` command not found:**
```bash
# Check if installed
which gh

# Install if needed (macOS)
brew install gh

# Verify authentication
gh auth status
```

**If authentication fails:**
```bash
# Re-authenticate
gh auth login

# Check current auth status
gh auth status
```

**If run not found:**
```bash
# Make sure you're in the right repo
gh repo view

# Check if run exists
gh run list --limit 10
```

### Alternative: Web UI Monitoring

If `gh` CLI is not available, use the web UI:

1. **Navigate to:** https://github.com/glblackburn/react2shell-server/actions
2. **Click on the run** to view details
3. **Click on failed job** to see logs
4. **Expand steps** to see detailed output

**Direct link to specific run:**
- Format: `https://github.com/glblackburn/react2shell-server/actions/runs/RUN_ID`
- Example: https://github.com/glblackburn/react2shell-server/actions/runs/20514739885

### Expected Behavior After Fixes

**For Test Vite + React Job:**
- ✅ Servers start (PIDs assigned)
- ✅ Diagnostic output shows which port is ready/failing
- ✅ Both servers become ready within 60 seconds
- ✅ Tests pass with React 19.0 and 19.2.1

**For Test Next.js Startup Job:**
- ✅ Pre-start cleanup prevents port conflicts
- ✅ All 11 versions pass (or 10 if 15.2.5 is documented as known issue)
- ✅ No "port in use" errors

## Related Documentation

- [CI Test Failure Analysis 2025-12-25](CI_TEST_FAILURE_ANALYSIS_2025-12-25.md) - Previous analysis showing all versions pass locally
- [test_nextjs_startup.sh](../../tests/test_nextjs_startup.sh) - Test script with existing cleanup code
- [CI/CD Workflow Verification Guide](../planning/CI_CD_WORKFLOW_VERIFICATION.md) - How to verify workflows are recognized

## Date

December 26, 2025
