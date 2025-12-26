# [Test Name] Fix Plan

**Date Created:** YYYY-MM-DD HH:MM:SS [TIMEZONE]  
**Attempt:** [N]  
**Status:** [Pending/In Progress/Success/Failed]

## Problem Statement

[Describe the problem being fixed]

## Root Cause Analysis

[Analyze why the problem occurs]

## Changes Implemented

### 1. [Change Name] ✅
**Location:** `path/to/file` lines X-Y

**Changes:**
- [What was changed]

**Rationale:** [Why this change was made]

### 2. [Change Name] ✅
[Repeat for each change]

## Testing Plan

### Local Testing Steps

1. **Clean environment test:**
   ```bash
   # Commands to clean environment
   ```

2. **Run test:**
   ```bash
   # Commands to run test
   ```

3. **Verify results:**
   - [What to check]

### Expected Results

**Success Criteria:**
- [Criteria 1]
- [Criteria 2]

**Failure Indicators:**
- [Indicator 1]
- [Indicator 2]

## Local Test Results

**Date Tested:** YYYY-MM-DD HH:MM:SS  
**Result:** [Pass/Fail]

**Output:**
- [Summary of local test results]
- [Any issues found]

**Log File:** `/tmp/local_test_YYYYMMDD_HHMMSS.txt`

## Next Steps

### Immediate Actions

1. **Test locally:**
   - [Steps]

2. **Commit and push:**
   - [Steps]

3. **Monitor GitHub Actions:**
   - [Steps]

4. **Iterate if needed:**
   - [Steps]

### Success Criteria

- ✅ [Criterion 1]
- ✅ [Criterion 2]

## GitHub Actions Run Results

### Stability Verification Status

**Requirement:** Three consecutive successful runs where the entire workflow completes without any failures.

**Consecutive Successes:**
- Run 1: [✅ Success / ❌ Failed / ⏳ Pending] - Run ID: [RUN_ID]
- Run 2: [✅ Success / ❌ Failed / ⏳ Pending] - Run ID: [RUN_ID]
- Run 3: [✅ Success / ❌ Failed / ⏳ Pending] - Run ID: [RUN_ID]

**Status:** [0/3, 1/3, 2/3, or 3/3 consecutive successes achieved]

---

### Run 1 Results

**Run Information:**
- **Run ID:** [RUN_ID]
- **Branch:** [branch-name]
- **Commit:** [commit-hash] - "[commit message]"
- **Status:** [queued/in_progress/completed]
- **Conclusion:** [success/failure/cancelled/N/A]
- **URL:** https://github.com/[owner]/[repo]/actions/runs/[RUN_ID]
- **Started:** [ISO timestamp]
- **Completed:** [ISO timestamp]
- **Duration:** [duration]

**Workflow Status:**
- **Overall Conclusion:** [success/failure]
- **All Jobs Passed:** [Yes/No]
- **Failed Jobs:** [List any failed jobs]

**Target Job: [Job Name]**
- **Status:** [status]
- **Conclusion:** [conclusion]
- **Versions Tested:**
  - ✅ [Version] passed
  - ❌ [Version] failed - [reason]
  - [etc.]

**Summary:**
```
[Summary output from test]
```

**Key Observations:**
1. **[Observation 1]**
   - [Details]

2. **[Observation 2]**
   - [Details]

**Log Files Saved:**
- Full run log: `/tmp/github_actions_run_[RUN_ID]_[timestamp].txt`
- Job-specific log: `/tmp/github_actions_[job]_[RUN_ID]_[timestamp].txt`

---

### Run 2 Results

[Repeat structure from Run 1 if available]

---

### Run 3 Results

[Repeat structure from Run 1 if available]

---

### Analysis

[Analysis of what worked, what didn't, and why]

**Conclusion:** 
- [If 3/3 successes]: ✅ **FIX COMPLETE** - Three consecutive successful runs achieved
- [If < 3 successes]: ⏳ **IN PROGRESS** - Need [N] more consecutive successful runs
- [If any failure]: ❌ **NEEDS ITERATION** - Fix requires adjustment

---

## Known Issues

[Any known issues or limitations]

## Related Documentation

- [Related analysis document](RELATED_DOC.md)
- [Related files](path/to/file)

## Date

YYYY-MM-DD
