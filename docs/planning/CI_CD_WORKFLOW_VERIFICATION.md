# CI/CD Workflow Verification Guide

**Date:** 2025-12-23
**Purpose:** Steps to verify GitHub Actions workflows are recognized and working
**Context:** After implementing Step 1 (workflow infrastructure)

---

## Overview

After creating workflow skeleton files, you need to verify that GitHub recognizes them and they can be triggered. This guide provides step-by-step instructions for verification.

---

## Prerequisites

- Workflow files have been committed to a feature branch
- Branch has been pushed to GitHub (or ready to push)

---

## Step 1: Push the Branch

### If Using SSH (Default)

```bash
git push --set-upstream origin feature/ci-cd-implementation
```

### If SSH Authentication Fails

Switch to HTTPS:

```bash
# Check current remote URL
git remote -v

# Switch to HTTPS if needed
git remote set-url origin https://github.com/glblackburn/react2shell-server.gi

# Push branch
git push --set-upstream origin feature/ci-cd-implementation
```

---

## Step 2: Verify Workflows Are Recognized

### 2.1 Navigate to GitHub Actions

1. Go to your repository on GitHub
2. Click on the **Actions** tab
3. URL: `https://github.com/glblackburn/react2shell-server/actions`

### 2.2 Check Workflow Lis

In the left sidebar, you should see **5 workflows**:

- ✅ **CI** (new - main CI pipeline)
- ✅ **Version Validation** (new - deep version validation)
- ✅ **Performance Check** (new - performance regression detection)
- ✅ **Scanner Verification** (new - optional scanner tests)
- ✅ **Validate GitHub Setup** (existing - repository setup validation)

**Success Indicator:** All 5 workflows appear in the sidebar, even if they haven't run yet.

---

## Step 3: Test Workflow Execution

Choose one of the following methods to verify workflows can be triggered:

### Option A: Create a Pull Request (Recommended)

**Steps:**
1. Push the feature branch to GitHub
2. Create a Pull Request from `feature/ci-cd-implementation` to `main`
3. The **CI** workflow should trigger automatically on PR creation
4. Go to **Actions** tab to see the workflow running

**What to Look For:**
- CI workflow appears in the workflow runs lis
- All 5 jobs start (lint, test-vite, test-nextjs, test-python, validate-versions)
- Jobs complete quickly (they're placeholders)
- Job logs show: "Placeholder - ... implementation pending"

**Expected Result:** Workflow runs successfully, confirming GitHub recognizes the workflow files.

### Option B: Manual Workflow Trigger

**Steps:**
1. Go to **Actions** tab
2. Click on **CI** workflow (or any workflow)
3. Click **Run workflow** button (if available)
4. Select branch: `feature/ci-cd-implementation`
5. Click **Run workflow**

**What to Look For:**
- Workflow run appears in the lis
- Jobs start and complete
- Placeholder messages in logs

**Note:** Some workflows (like `scanner-verification.yml`) are `workflow_dispatch` only, so they can only be triggered manually.

### Option C: Push a Small Change

**Steps:**
1. Make a small commit (e.g., add a comment to a workflow file)
2. Push to the feature branch
3. CI workflow should trigger automatically on push

**What to Look For:**
- New workflow run appears in Actions tab
- Triggered by "push" even
- Jobs execute successfully

---

## Step 4: Verify Workflow Structure

### 4.1 Check Workflow Run Details

1. Click on a workflow run in the Actions tab
2. Verify all jobs are listed:
   - `lint` - Lint and Validate
   - `test-vite` - Test Vite Framework
   - `test-nextjs` - Test Next.js Framework
   - `test-python / vite` - Test Python (vite)
   - `test-python / nextjs` - Test Python (nextjs)
   - `validate-versions` - Validate Versions

### 4.2 Check Job Dependencies

Verify job dependencies are correct:
- `lint` runs first (no dependencies)
- Other jobs depend on `lint` (`needs: lint`)
- Jobs run in parallel after `lint` completes

### 4.3 Check Job Logs

Click on any job to see logs:
- Should show: "Placeholder - ... implementation pending"
- Job should complete successfully (exit code 0)
- Duration should be very short (< 10 seconds)

---

## Step 5: Verify Workflow Files in Repository

### 5.1 Check File Structure

Verify workflow files exist in the repository:

```
.github/
└── workflows/
    ├── ci.yml                    ✅ Main CI pipeline
    ├── version-validation.yml    ✅ Version validation
    ├── performance-check.yml      ✅ Performance check
    ├── scanner-verification.yml  ✅ Scanner verification
    └── validate-setup.yml        ✅ Setup validation (existing)
```

### 5.2 Verify File Conten

Check that workflow files are valid YAML:
- Files should be viewable on GitHub
- No syntax errors shown
- GitHub Actions recognizes them automatically

---

## Expected Results

### ✅ Success Indicators

1. **Workflows Appear in Actions Tab**
   - All 5 workflows listed in sidebar
   - Workflows are clickable and show details

2. **Workflows Can Be Triggered**
   - CI triggers on push/PR
   - Manual workflows can be triggered
   - Workflow runs appear in the lis

3. **Jobs Execute Successfully**
   - All jobs start and complete
   - Job logs show placeholder messages
   - No errors or failures

4. **Workflow Structure is Correct**
   - Job names match expected names
   - Dependencies are configured correctly
   - Matrix strategy works (for test-python)

### ⚠️ Common Issues

**Issue:** Workflows don't appear in Actions tab
- **Solution:** Verify files are in `.github/workflows/` directory
- **Solution:** Check YAML syntax is valid
- **Solution:** Ensure files are committed and pushed

**Issue:** Workflows appear but can't be triggered
- **Solution:** Check `on:` triggers are configured correctly
- **Solution:** Verify branch name matches trigger conditions
- **Solution:** For manual workflows, use `workflow_dispatch`

**Issue:** Jobs fail immediately
- **Solution:** Check YAML syntax
- **Solution:** Verify `runs-on` and `steps` are correc
- **Solution:** Check job logs for specific error messages

---

## Next Steps After Verification

Once workflows are verified to be recognized by GitHub:

1. **Proceed to Step 2:** Implement lint job
   - Replace placeholder in `ci.yml` with actual linting logic
   - Test lint job execution

2. **Continue Implementation:**
   - Step 3: Implement Vite test job
   - Step 4: Implement Next.js test job
   - Step 5: Implement Python test job
   - Step 6: Implement version validation job

3. **Configure Status Checks:**
   - After workflows are fully implemented
   - Add required status checks to branch protection
   - Ensure PRs require passing CI

---

## Verification Checklis

Use this checklist to verify everything is working:

- [ ] Branch pushed to GitHub successfully
- [ ] All 5 workflows appear in Actions tab sidebar
- [ ] Workflow files are visible in repository (`.github/workflows/`)
- [ ] CI workflow can be triggered (via PR or push)
- [ ] Manual workflows can be triggered (workflow_dispatch)
- [ ] All jobs in CI workflow appear and execute
- [ ] Job dependencies are correct (lint runs first)
- [ ] Jobs complete successfully (even with placeholders)
- [ ] Job logs show placeholder messages
- [ ] No YAML syntax errors
- [ ] Matrix strategy works (test-python shows both vite and nextjs)

---

## Related Documentation

- **Implementation Plan:** `docs/planning/CI_CD_COMPLETE_PLAN.md`
- **Step 1 Details:** See "Step 1: Create GitHub Actions Infrastructure" in plan
- **Workflow Templates:** See "Appendix: Workflow Templates" in plan

---

**Status:** ✅ Ready for verification
**Last Updated:** 2025-12-23
