# CI Fix Iteration Workflow

**Date:** December 26, 2025  
**Purpose:** Document the iterative workflow for fixing CI/CD test failures  
**Context:** Process used to fix the Next.js startup test in GitHub Actions

---

## Overview

This document describes the systematic workflow for fixing CI/CD test failures. The process follows a strict iterative loop: analyze → plan → test locally → commit → push → monitor → repeat until success.

---

## Workflow Rules

### Core Principles

1. **Always test locally before pushing to GitHub**
2. **Always produce an analysis document with a next steps plan before making changes**
3. **Commit the plan and the changes together**
4. **Push and observe GitHub Actions**
5. **Continue iterating until the test works in GitHub Actions**
6. **Require three consecutive successful runs** where the entire GitHub Actions workflow completes without any failures before considering the fix complete

### Exception to Standard Commit Rules

**For CI fix sessions only:** The standard two-step commit confirmation process is bypassed. Commits can be made directly without showing commit info first, **but only for this specific session until the CI test is fixed.**

Once the CI test passes, normal commit rules resume.

---

## Step-by-Step Workflow

### Step 1: Analyze the Problem

**Objective:** Understand the root cause of the CI failure

**Actions:**
1. Review GitHub Actions run logs
2. Identify which job failed and why
3. Check for patterns (specific versions, timing issues, etc.)
4. Compare with local test results (if available)

**Output:**
- Analysis document (e.g., `CI_TEST_FAILURE_ANALYSIS_YYYY-MM-DD.md`)
- Root cause identification
- Evidence from logs

**Tools:**
```bash
# Get latest run
gh run list --limit 1

# View run details
gh run view RUN_ID --log

# Save logs for analysis
./scripts/save_github_actions_log.sh RUN_ID
```

**Example:**
- File: `docs/ci-cd/CI_TEST_FAILURE_ANALYSIS_2025-12-26.md`
- Identified: Port conflicts causing Next.js to start on alternate ports

---

### Step 2: Create Fix Plan Document

**Objective:** Document the planned solution before making changes

**Actions:**
1. Create a fix plan document with timestamp (e.g., `NEXTJS_STARTUP_FIX_PLAN_2025-12-26_063200.md`)
   - **Naming:** `<TEST>_FIX_PLAN_YYYY-MM-DD_HHMMSS.md`
   - **Purpose:** Separate document for each attempt/iteration
   - **Timestamp:** Use current date and time to ensure uniqueness
2. Document:
   - Date created and attempt number
   - Problem statement
   - Root cause analysis
   - Proposed changes
   - Testing plan
   - Success criteria
   - Next steps
   - **GitHub Actions Run Results section** (to be filled in after Step 7)

**Output:**
- Fix plan document in `docs/ci-cd/` with unique timestamp
- Clear plan of what will be changed and why
- Placeholder for GitHub run results

**Example:**
- File: `docs/ci-cd/NEXTJS_STARTUP_FIX_PLAN_2025-12-26_063200.md`
- Plan: Expand port cleanup, add port detection, update checks to use detected port
- Attempt: 1

---

### Step 3: Implement Changes

**Objective:** Make the code changes according to the plan

**Actions:**
1. Implement the fixes documented in the plan
2. Follow code quality standards:
   - No trailing whitespace
   - Files end with newline
   - Clean up backup files
3. Update code comments/documentation as needed

**Output:**
- Modified code files
- All changes align with the fix plan

**Example:**
- Modified: `tests/test_nextjs_startup.sh`
- Changes: Added port detection, expanded port cleanup

---

### Step 4: Test Locally

**Objective:** Verify fixes work before pushing to GitHub

**Actions:**
1. Clean environment:
   ```bash
   make stop
   # Clean up ports
   for port in 3000 3001 3002 3003 3004 3005; do
     lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
   done
   ```

2. Run the test locally:
   ```bash
   make test-nextjs-startup
   ```

3. Verify all versions pass

4. Save test output:
   ```bash
   make test-nextjs-startup 2>&1 | tee /tmp/local_test_$(date +%Y%m%d_%H%M%S).txt
   ```

**Output:**
- Local test results (all versions should pass)
- Test output saved to `/tmp/` for later analysis

**Success Criteria:**
- All test versions pass locally
- No errors or warnings
- Clean output

**If local test fails:**
- Analyze the failure
- Update the fix plan
- Make additional changes
- Test again
- **Do not proceed to commit until local test passes**

---

### Step 5: Commit Plan and Changes Together

**Objective:** Commit both the plan document and code changes in a single commit

**Actions:**
1. Stage all files:
   ```bash
   git add <fix-plan-doc>
   git add <modified-files>
   ```

2. Commit with descriptive message:
   ```bash
   git commit -m "fix: <description>

   - <change 1>
   - <change 2>
   - <change 3>

   Related: docs/ci-cd/<fix-plan-doc>"
   ```

3. Save commit output:
   ```bash
   git commit -m "..." 2>&1 | tee /tmp/git_commit_$(date +%Y%m%d_%H%M%S).txt
   ```

**Output:**
- Single commit containing both plan and implementation
- Commit message references the plan document

**Example:**
```bash
git add docs/ci-cd/NEXTJS_STARTUP_FIX_PLAN_2025-12-26.md
git add tests/test_nextjs_startup.sh
git commit -m "fix: Improve Next.js startup test port handling

- Expand pre-start port cleanup to check ports 3000-3010
- Add port detection to find which port server started on
- Update checks to use detected port

Related: docs/ci-cd/NEXTJS_STARTUP_FIX_PLAN_2025-12-26.md"
```

---

### Step 6: Push to GitHub

**Objective:** Trigger GitHub Actions run

**Actions:**
1. Push the branch:
   ```bash
   git push origin <branch-name>
   ```

2. Save push output:
   ```bash
   git push origin <branch> 2>&1 | tee /tmp/git_push_$(date +%Y%m%d_%H%M%S).txt
   ```

3. Get the new run ID:
   ```bash
   sleep 5
   gh run list --limit 1 --json databaseId --jq '.[0].databaseId'
   ```

**Output:**
- Code pushed to GitHub
- New GitHub Actions run triggered
- Run ID for monitoring

---

### Step 7: Monitor GitHub Actions

**Objective:** Watch the CI run and analyze results

**Actions:**
1. Check run status:
   ```bash
   RUN_ID=<run-id>
   gh run view "$RUN_ID" --json status,conclusion
   ```

2. Monitor until completion:
   ```bash
   # Watch in real-time
   gh run watch "$RUN_ID" --log
   
   # Or check periodically
   while [ "$STATUS" != "completed" ]; do
     sleep 30
     STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
   done
   ```

3. Save logs when complete:
   ```bash
   ./scripts/save_github_actions_log.sh "$RUN_ID"
   ```

4. Analyze results:
   - Check if target job passed
   - Review logs for errors
   - Compare with local test results

5. **Update Fix Plan Document with Results:**
   - Add "GitHub Actions Run Results" section
   - Document run ID, status, conclusion
   - Record which versions passed/failed
   - Note key observations
   - Save log file locations

**Output:**
- Full GitHub Actions log saved to `/tmp/`
- Job-specific log (e.g., Next.js job log)
- Analysis of pass/fail status
- **Updated fix plan document with run results**

**Tools:**
- `scripts/save_github_actions_log.sh` - Save full run log
- `scripts/monitor_and_fix_nextjs_test.sh` - Automated monitoring script

---

### Step 8: Analyze Results and Iterate

**Objective:** Determine if fix worked or if another iteration is needed

**Decision Point:**

#### ✅ If CI Test Passes:

**IMPORTANT:** A single successful run is not sufficient. **Three consecutive successful runs** are required to ensure stability.

1. **Record the successful run:**
   - Update fix plan document with run results
   - Note this as successful run #N (where N = 1, 2, or 3)

2. **Check if this is the third consecutive success:**
   - Count consecutive successful runs
   - If this is run #1 or #2: Continue to Step 9 (Verify Stability)
   - If this is run #3: Proceed to create success report

3. **If not yet three successes:**
   - Document this successful run in fix plan
   - Make a small change (e.g., update comment, add logging) or push empty commit to trigger another run
   - Return to Step 6 (Push) to trigger next run
   - Continue until three consecutive successes

4. **If three consecutive successes achieved:**
   - Create success report:
     - Document what worked
     - Identify the exact fix that solved it
     - List all three successful run IDs
     - Save to `docs/ci-cd/<TEST>_FIX_SUCCESS_REPORT_YYYY-MM-DD.md`
   - Commit success report:
     ```bash
     git add docs/ci-cd/<success-report>
     git commit -m "docs: Add <test> fix success report"
     git push
     ```
   - **Done!** ✅

#### ❌ If CI Test Fails:

1. **Analyze the failure:**
   - Review GitHub Actions logs
   - Compare with local test results
   - Identify what's different in CI

2. **Update analysis:**
   - Add findings to analysis document
   - Update fix plan with new approach

3. **Return to Step 3** (Implement Changes)
   - Make additional fixes
   - Test locally again
   - Commit and push
   - Monitor again

4. **Repeat until success**

---

### Step 9: Verify Stability (Three Consecutive Successes)

**Objective:** Ensure the fix is stable and not flaky

**Requirement:** **Three consecutive successful GitHub Actions runs** where:
- The entire workflow completes without any failures
- The target job passes
- All other jobs in the workflow also pass

**Actions:**

1. **Track consecutive successes:**
   - Run 1: ✅ Success - Record run ID
   - Run 2: ✅ Success - Record run ID
   - Run 3: ✅ Success - Record run ID

2. **If any run fails:**
   - Reset counter to 0
   - Analyze the failure
   - Return to Step 3 (Implement Changes) if fix needs adjustment
   - Or return to Step 6 (Push) if it was a transient issue

3. **Trigger additional runs if needed:**
   ```bash
   # Option 1: Make a trivial change (update comment, add whitespace)
   # Option 2: Push empty commit
   git commit --allow-empty -m "ci: Trigger run to verify stability"
   git push
   ```

4. **Document all three successful runs:**
   - Update fix plan with all three run IDs
   - Note that three consecutive successes were achieved
   - Record any differences between the runs

**Success Criteria:**
- ✅ Run 1: Entire workflow passes (all jobs successful)
- ✅ Run 2: Entire workflow passes (all jobs successful)
- ✅ Run 3: Entire workflow passes (all jobs successful)
- ✅ All three runs completed without any failures

**Why Three Runs?**
- Catches flaky tests that pass intermittently
- Ensures stability across different CI runner conditions
- Validates that the fix is robust, not just lucky
- Industry best practice for CI/CD stability verification

---

## Complete Workflow Diagram

```
┌─────────────────┐
│  CI Test Fails  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Step 1: Analyze│
│  - Review logs  │
│  - Find root    │
│    cause        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 2: Plan    │
│ - Create plan   │
│   document      │
│ - Document      │
│   solution      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 3: Implement│
│ - Make changes  │
│ - Follow plan   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 4: Test   │
│   Locally       │
│ - Clean env     │
│ - Run test      │
│ - Verify pass   │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Pass?   │
    └────┬────┘
         │ No
         ▼
    ┌─────────┐
    │ Fix &   │
    │ Retest  │
    └────┬────┘
         │
         │ Yes
         ▼
┌─────────────────┐
│ Step 5: Commit  │
│ - Plan + Code   │
│ - Together      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 6: Push    │
│ - Trigger CI    │
│ - Get run ID    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 7: Monitor │
│ - Watch CI run  │
│ - Save logs     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Step 8: Analyze │
│ - Check results │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Pass?   │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
    │ Yes     │ No
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│ Step 9: │ │ Iterate │
│ Verify  │ │ (Step 3)│
│ Stability│ └─────────┘
└─────────┘
         │
         ▼
┌─────────────────┐
│ Count Successes │
│ Run 1: ✅       │
│ Run 2: ✅       │
│ Run 3: ✅       │
└────────┬────────┘
         │
    ┌────┴────┐
    │ 3 in a  │
    │  row?   │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
    │ Yes     │ No
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│ Success │ │ Trigger │
│ Report  │ │ Next Run│
│ Done!   │ │ (Step 6)│
└─────────┘ └─────────┘
```

---

## File Organization

### Analysis Documents
- Location: `docs/ci-cd/`
- Naming: `CI_TEST_FAILURE_ANALYSIS_YYYY-MM-DD.md`
- Purpose: Document the problem and root cause

### Fix Plan Documents
- Location: `docs/ci-cd/`
- Naming: `<TEST>_FIX_PLAN_YYYY-MM-DD_HHMMSS.md` (with timestamp for each attempt)
- Purpose: Document planned solution before implementation
- **Important:** Each iteration gets a separate document with unique timestamp
- **Contains:** Plan + GitHub Actions run results (updated after monitoring)

### Success Reports
- Location: `docs/ci-cd/`
- Naming: `<TEST>_FIX_SUCCESS_REPORT_YYYY-MM-DD.md`
- Purpose: Document what worked and why

### Log Files
- Location: `/tmp/`
- Naming: `<type>_YYYYMMDD_HHMMSS.txt`
- Types:
  - `local_test_*.txt` - Local test outputs
  - `git_commit_*.txt` - Commit outputs
  - `git_push_*.txt` - Push outputs
  - `gh_run_*.txt` - GitHub Actions run info
  - `github_actions_run_*.txt` - Full GitHub Actions logs
  - `github_actions_nextjs_job_*.txt` - Job-specific logs

---

## Tools and Scripts

### Monitoring Scripts

1. **`scripts/save_github_actions_log.sh`**
   - Saves full GitHub Actions run log
   - Extracts job-specific logs
   - Usage: `./scripts/save_github_actions_log.sh RUN_ID`

2. **`scripts/monitor_and_fix_nextjs_test.sh`**
   - Automated monitoring loop
   - Checks run status periodically
   - Analyzes results when complete
   - Usage: `./scripts/monitor_and_fix_nextjs_test.sh RUN_ID`

3. **`scripts/save_command_output.sh`**
   - Saves any command output to timestamped file
   - Usage: `./scripts/save_command_output.sh <name> <command>`

### GitHub CLI Commands

```bash
# List recent runs
gh run list --limit 5

# View specific run
gh run view RUN_ID

# Watch run in real-time
gh run watch RUN_ID --log

# Get run status
gh run view RUN_ID --json status,conclusion
```

---

## Example: Next.js Startup Test Fix

### Iteration 1: Initial Fix

1. **Analyze:** Port conflicts causing failures
2. **Plan:** `NEXTJS_STARTUP_FIX_PLAN_2025-12-26.md`
3. **Implement:** Expanded port cleanup, added port detection
4. **Test Locally:** ✅ All 11 versions passed
5. **Commit:** Plan + code changes together
6. **Push:** Triggered run 20521706863
7. **Monitor:** Watched until completion
8. **Result:** ✅ **SUCCESS** - All 11 versions passed in CI
9. **Verify Stability:** 
   - Run 1: ✅ 20521706863 - Success
   - Run 2: [Would need to trigger additional runs]
   - Run 3: [Would need to trigger additional runs]

**Note:** This example shows the first successful run. In practice, two more successful runs would be needed to complete the fix.

---

## Best Practices

### 1. Always Test Locally First

**Why:** Local testing catches most issues before wasting CI resources.

**Rule:** Never push changes that fail locally.

### 2. Document Before Implementing

**Why:** Planning prevents wasted effort and helps track what was tried.

**Rule:** Always create a fix plan document before making changes.

### 3. Commit Plan and Code Together

**Why:** Keeps context together - plan explains why changes were made.

**Rule:** Single commit contains both plan document and implementation.

### 4. Save All Outputs

**Why:** Enables later analysis and comparison between iterations.

**Rule:** Save all command outputs to `/tmp/` with timestamps.

### 5. Monitor Actively

**Why:** Quick feedback enables faster iteration.

**Rule:** Watch CI runs actively, don't just push and forget.

### 6. Iterate Until Success

**Why:** CI tests must pass for code to be merged.

**Rule:** Continue the loop until the target test passes in CI.

### 7. Require Three Consecutive Successes

**Why:** Single success may be flaky. Three consecutive successes prove stability.

**Rule:** The fix is not complete until three consecutive GitHub Actions runs pass entirely (all jobs successful).

---

## Common Pitfalls

### ❌ Pushing Without Local Testing

**Problem:** Wastes CI resources, delays feedback  
**Solution:** Always test locally first

### ❌ Making Changes Without a Plan

**Problem:** Unclear what was tried, why it failed  
**Solution:** Always document the plan first

### ❌ Committing Plan and Code Separately

**Problem:** Loses context, harder to understand later  
**Solution:** Commit together in single commit

### ❌ Not Monitoring CI Runs

**Problem:** Don't know if fix worked  
**Solution:** Actively monitor until completion

### ❌ Stopping After First Failure

**Problem:** CI test still broken  
**Solution:** Iterate until it passes

### ❌ Considering Fix Complete After One Success

**Problem:** Flaky tests may pass once but fail later  
**Solution:** Require three consecutive successful runs before declaring success

---

## Related Documentation

- [CI Test Failure Analysis 2025-12-26](CI_TEST_FAILURE_ANALYSIS_2025-12-26.md) - Example analysis
- [Next.js Startup Fix Plan 2025-12-26](NEXTJS_STARTUP_FIX_PLAN_2025-12-26.md) - Example fix plan
- [Next.js Startup Fix Success Report](NEXTJS_STARTUP_FIX_SUCCESS_REPORT.md) - Example success report
- [How to Monitor GitHub Actions Runs](CI_TEST_FAILURE_ANALYSIS_2025-12-26.md#how-to-monitor-github-actions-runs) - Monitoring guide

---

## Date

December 26, 2025
