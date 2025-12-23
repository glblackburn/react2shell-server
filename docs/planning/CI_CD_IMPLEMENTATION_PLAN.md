# Phase 1: CI/CD Implementation Plan with GitHub Actions

**Date:** 2025-12-23  
**Status:** Planning  
**Priority:** High  
**Estimated Time:** 8-10 hours

---

## Executive Summary

This plan details the implementation of a comprehensive CI/CD pipeline using GitHub Actions for the React2Shell Server project. The pipeline will automate testing, version validation, and quality checks across both Vite+React and Next.js frameworks.

**Key Objectives:**
- Automated testing on every push and pull request
- Framework-aware testing (Vite + React and Next.js)
- Version switching validation
- Performance regression detection
- Comprehensive test coverage reporting

---

## Table of Contents

1. [Overview and Goals](#overview-and-goals)
2. [Architecture Design](#architecture-design)
3. [GitHub Repository Branch Protection](#github-repository-branch-protection)
4. [Automation Options](#automation-options)
5. [Workflow Implementation](#workflow-implementation)
6. [Testing Strategy](#testing-strategy)
7. [Implementation Steps](#implementation-steps)
8. [Validation and Testing](#validation-and-testing)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Success Criteria](#success-criteria)

---

## Overview and Goals

### Current State

- Manual testing required for each change
- No automated validation of version switching
- No continuous integration
- Tests must be run locally
- No visibility into test status for PRs

### Target State

- Automated testing on every push/PR
- Framework-aware CI (tests both Vite and Next.js)
- Version switching validation
- Test results visible in PRs
- Automated performance regression detection
- Status badges in README

### Success Metrics

- ✅ All tests pass in CI
- ✅ CI completes in < 15 minutes
- ✅ Zero false positives
- ✅ Clear failure messages
- ✅ Test reports available as artifacts

---

## Architecture Design

### Workflow Structure

```
.github/workflows/
├── ci.yml                    # Main CI workflow (runs on push/PR)
├── version-validation.yml     # Version switching validation
├── performance-check.yml      # Performance regression detection
└── scanner-verification.yml   # Optional: Scanner integration tests
```

### Job Dependencies

```
┌─────────────┐
│   Lint      │
└──────┬──────┘
       │
       ├───> Test Vite ──────┐
       ├───> Test Next.js ──┤
       ├───> Test Python ───┤───> All Jobs Complete
       └───> Validate Versions
```

### Matrix Strategy

**Python Tests:**
- Framework: `[vite, nextjs]`
- Browser: `[chrome]` (headless)

**Version Validation:**
- Framework: `[vite, nextjs]`
- Test subset of versions (not all to save time)

---

## GitHub Repository Branch Protection

### Overview

To ensure all changes go through the CI/CD process, we must configure GitHub branch protection rules for the `main` branch. This prevents direct commits to `main` and requires all changes to go through pull requests with passing CI checks.

### Branch Protection Policy

**Critical Requirements:**
1. **Prevent direct pushes to main** - All changes must go through PRs
2. **Require CI/CD to pass** - PRs cannot be merged if CI fails
3. **Require PR reviews** (optional but recommended)
4. **Require up-to-date branches** - PRs must be rebased/merged with latest main

### Implementation Steps

#### Step 1: Access Repository Settings

1. Navigate to GitHub repository
2. Go to **Settings** → **Branches**
3. Under **Branch protection rules**, click **Add rule** or edit existing rule for `main`

#### Step 2: Configure Branch Protection Rule

**Rule Name:** `main` (or pattern: `main`)

**Required Settings:**

1. **Protect matching branches**
   - ✅ Enable this rule

2. **Require a pull request before merging**
   - ✅ Require pull request reviews before merging
     - Required number of approving reviews: `1` (or `0` if solo project)
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from Code Owners (if CODEOWNERS file exists)
   - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date before merging
     - **Status checks that are required:**
       - `lint` (from ci.yml)
       - `test-vite` (from ci.yml)
       - `test-nextjs` (from ci.yml)
       - `test-python / vite` (from ci.yml)
       - `test-python / nextjs` (from ci.yml)
       - `validate-versions` (from ci.yml)
   - ✅ Require conversation resolution before merging (optional but recommended)
   - ✅ Require signed commits (optional, for security)

3. **Restrict who can push to matching branches**
   - ✅ Do not allow bypassing the above settings
   - ✅ Restrict pushes that create files larger than 100 MB (optional)

4. **Rules applied to everyone including administrators**
   - ✅ ✅ **CRITICAL:** Include administrators
   - This ensures even repo admins must use PRs

5. **Allow force pushes** (if needed for emergency fixes)
   - ❌ Do not allow force pushes (recommended)
   - Or: ✅ Allow force pushes (only if absolutely necessary, with restrictions)

6. **Allow deletions**
   - ❌ Do not allow deleting this branch (recommended)

**Optional Settings:**

- **Require linear history** - Enforces rebase-only merges (optional)
- **Require deployments to succeed before merging** - If using deployment workflows (optional)
- **Lock branch** - Prevents all changes (use for releases, optional)

#### Step 3: Verify Configuration

**Test the Protection Rule:**

1. **Test Direct Push Prevention:**
   ```bash
   # Try to push directly to main (should fail)
   git checkout main
   git commit --allow-empty -m "Test direct push"
   git push origin main
   # Expected: Error - "remote: error: GH006: Protected branch update failed"
   ```

2. **Test PR Requirement:**
   - Create a feature branch
   - Make a change
   - Try to push directly to main (should fail)
   - Create PR instead (should work)

3. **Test CI Requirement:**
   - Create PR with failing CI
   - Try to merge PR
   - Expected: Merge button disabled with message "Required status checks must pass"

4. **Test CI Pass Requirement:**
   - Create PR with passing CI
   - Verify merge button is enabled
   - Merge PR (should succeed)

### Configuration Screenshot Reference

**GitHub UI Path:**
```
Repository → Settings → Branches → Branch protection rules → Add rule
```

**Key Settings to Enable:**
- ✅ Protect matching branches
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Include administrators
- ✅ Do not allow bypassing the above settings

### Status Checks Configuration

**After workflows are created, configure required status checks:**

1. Go to **Settings** → **Branches** → Edit `main` branch rule
2. Under **Require status checks to pass before merging**
3. Check the following status checks (these appear after first workflow run):
   - `lint` - Lint and validation job
   - `test-vite` - Vite framework tests
   - `test-nextjs` - Next.js framework tests
   - `test-python / vite` - Python tests for Vite
   - `test-python / nextjs` - Python tests for Next.js
   - `validate-versions` - Version validation

**Note:** Status check names match the job `name:` in workflow files. Ensure job names are descriptive and consistent.

### Emergency Bypass (If Needed)

**If emergency fix is needed and CI is broken:**

1. **Option 1: Temporarily disable protection** (not recommended)
   - Go to branch protection settings
   - Temporarily disable rule
   - Make emergency fix
   - Re-enable protection
   - Fix CI issues

2. **Option 2: Use admin override** (if not restricted)
   - If "Include administrators" is disabled, admins can bypass
   - Use sparingly and document reason

3. **Option 3: Fix CI first** (recommended)
   - Create PR to fix CI
   - Merge with admin override if needed
   - Then proceed with actual fix

### Documentation

**Add to Repository:**

1. **Create `.github/BRANCH_PROTECTION.md`** (optional):
   ```markdown
   # Branch Protection Policy

   The `main` branch is protected. All changes must go through pull requests.

   ## Requirements

   - All changes must be made via pull requests
   - CI/CD checks must pass before merging
   - At least one approval required (if reviews enabled)
   - Branch must be up to date with main

   ## Emergency Procedures

   See repository settings for emergency bypass procedures.
   ```

2. **Update `CONTRIBUTING.md`** (if exists):
   - Document branch protection policy
   - Explain PR process
   - Link to CI/CD documentation

### Verification Checklist

- [ ] Branch protection rule created for `main`
- [ ] Direct pushes to main are blocked
- [ ] PRs are required for all changes
- [ ] CI status checks are required
- [ ] Administrators are included in protection
- [ ] Test direct push fails
- [ ] Test PR with failing CI cannot be merged
- [ ] Test PR with passing CI can be merged
- [ ] Documentation updated

### Time Estimate

**Setup Time:** 15-30 minutes

**Steps:**
1. Configure branch protection: 10 minutes
2. Test configuration: 10 minutes
3. Document policy: 5 minutes

### Automation Options

**For automated validation and configuration, see [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md).**

**Quick Summary:**
- **Validation:** Use GitHub API scripts to validate branch protection
- **Configuration:** Use Terraform for Infrastructure as Code (optional)
- **Verification:** Add validation scripts to CI/CD pipeline

**Recommended for this project:**
1. **Initial setup:** Manual configuration (fastest)
2. **Validation:** Automated script (`scripts/validate_branch_protection.sh`)
3. **Future:** Consider Terraform if managing multiple repositories

See [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md) for:
- Branch protection automation scripts
- Terraform configuration examples
- Validation and verification approaches
- CI/CD pipeline creation options

---

## Automation Options

### Overview

This section covers automation options for branch protection validation and CI/CD pipeline creation. For detailed information, see [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md).

### Branch Protection Automation

**Options:**
1. **GitHub API Script** (Recommended for validation)
   - Simple bash/Python scripts
   - Validate branch protection via API
   - Can be run in CI/CD

2. **Terraform** (Recommended for configuration)
   - Infrastructure as Code
   - Version controlled
   - Reproducible across repositories

3. **GitHub CLI** (`gh`)
   - Quick command-line interface
   - Good for manual operations

**See [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md) for complete examples.**

### CI/CD Pipeline Creation

**Options:**
1. **Manual YAML Files** (Current plan - Recommended)
   - Create `.github/workflows/*.yml` files
   - Simple and straightforward
   - Full control

2. **Terraform GitHub Provider**
   - Manage workflows as Infrastructure as Code
   - Good for multiple repositories

3. **GitHub API / CLI Scripts**
   - Programmatic creation
   - Can be automated

**See [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md) for complete details.**

### Recommended Approach

**For this project:**
- **Branch Protection:** Manual setup + validation script
- **CI/CD Pipelines:** Manual YAML files (current plan)
- **Validation:** Automated scripts in CI/CD

**Future enhancements:**
- Consider Terraform if managing multiple repositories
- Add weekly validation workflow
- Automate validation in CI/CD

---

## Workflow Implementation

### Workflow 1: Main CI Pipeline

**File:** `.github/workflows/ci.yml`

#### Job 1: Lint and Validate

**Purpose:** Quick validation before running expensive tests

**Steps:**
1. Checkout code
2. Validate `config/versions.json` (if exists) or Makefile version definitions
3. Check Makefile syntax
4. Validate JSON/YAML files
5. Check for common issues (trailing whitespace, etc.)

**Time Estimate:** 1-2 minutes  
**Failure Action:** Block other jobs

#### Job 2: Test Vite + React Framework

**Purpose:** Test Vite framework with React versions

**Steps:**
1. Setup Node.js (24.12.0)
2. Install nvm and Node.js
3. Install system dependencies (jq, make)
4. Run `make setup`
5. Switch to Vite: `make use-vite`
6. Test vulnerable version:
   - Switch to React 19.0
   - Start server: `make start`
   - Wait for readiness
   - Run smoke tests: `make test-smoke`
   - Stop server: `make stop`
7. Test fixed version:
   - Switch to React 19.2.1
   - Start server: `make start`
   - Wait for readiness
   - Run smoke tests: `make test-smoke`
   - Stop server: `make stop`

**Time Estimate:** 5-8 minutes  
**Failure Action:** Report failure, continue other jobs

#### Job 3: Test Next.js Framework

**Purpose:** Test Next.js framework with Next.js versions

**Steps:**
1. Setup Node.js (24.12.0)
2. Install nvm and Node.js
3. Install system dependencies (jq, make)
4. Run `make setup`
5. Switch to Next.js: `make use-nextjs`
6. Test vulnerable version:
   - Switch to Next.js 15.0.4
   - Start server: `make start`
   - Wait for readiness (longer for Next.js)
   - Run smoke tests: `make test-smoke`
   - Stop server: `make stop`
7. Test fixed version:
   - Switch to Next.js 14.0.1
   - Start server: `make start`
   - Wait for readiness
   - Run smoke tests: `make test-smoke`
   - Stop server: `make stop`

**Time Estimate:** 8-12 minutes  
**Failure Action:** Report failure, continue other jobs

#### Job 4: Python Tests (Matrix)

**Purpose:** Run comprehensive Python test suite

**Matrix:**
- Framework: `[vite, nextjs]`

**Steps:**
1. Setup Python (3.11)
2. Setup Node.js (24.12.0)
3. Install nvm and Node.js
4. Install system dependencies
5. Run `make setup`
6. Switch framework: `make use-${{ matrix.framework }}`
7. Setup test environment: `make test-setup`
8. Start servers: `make start`
9. Wait for readiness
10. Run tests: `make test-quick` (headless, fast)
11. Stop servers: `make stop` (always, even on failure)
12. Upload test reports as artifacts

**Time Estimate:** 6-10 minutes per framework  
**Failure Action:** Report failure, upload artifacts

#### Job 5: Version Validation

**Purpose:** Validate version switching works

**Steps:**
1. Setup Node.js
2. Install dependencies
3. Run `make setup`
4. Test Vite version switching:
   - Switch to React 19.0
   - Verify: `make current-version`
   - Switch to React 19.2.1
   - Verify: `make current-version`
5. Test Next.js version switching:
   - Switch to Next.js 15.0.4
   - Verify: `make current-version`
   - Switch to Next.js 14.0.1
   - Verify: `make current-version`

**Time Estimate:** 3-5 minutes  
**Failure Action:** Report failure

### Workflow 2: Version Validation (Deep)

**File:** `.github/workflows/version-validation.yml`

**Trigger:** 
- Push to `main` when `config/versions.json` or `Makefile` changes
- Manual trigger via `workflow_dispatch`

**Purpose:** Comprehensive validation of all version switches

**Steps:**
1. Setup environment
2. Validate versions.json structure
3. Test all React versions (Vite mode)
4. Test all Next.js versions (Next.js mode)
5. Generate validation report

**Time Estimate:** 10-15 minutes  
**Frequency:** On version config changes or manual trigger

### Workflow 3: Performance Check

**File:** `.github/workflows/performance-check.yml`

**Trigger:**
- Push to `main`
- Manual trigger

**Purpose:** Detect performance regressions

**Steps:**
1. Setup environment
2. Run performance tests: `make test-performance`
3. Compare against baseline
4. Generate performance report
5. Fail if regressions detected

**Time Estimate:** 8-12 minutes  
**Frequency:** Daily or on main branch pushes

### Workflow 4: Scanner Verification (Optional)

**File:** `.github/workflows/scanner-verification.yml`

**Trigger:** Manual only (`workflow_dispatch`)

**Purpose:** Test scanner integration (requires external scanner)

**Note:** May not work in CI if scanner not available. Documented for completeness.

---

## Testing Strategy

### Unit Testing the Workflows

**Tool:** `act` (GitHub Actions local runner)

**Steps:**
1. Install `act`: `brew install act` (macOS) or download from GitHub
2. Test workflow locally:
   ```bash
   act push  # Simulate push event
   act pull_request  # Simulate PR event
   ```
3. Debug workflow issues locally
4. Iterate until workflows pass

### Integration Testing

**Approach:** Test workflows on feature branch

**Steps:**
1. Create feature branch: `git checkout -b feature/ci-cd-setup`
2. Push workflows to branch
3. Create test PR
4. Verify workflows trigger
5. Check job execution
6. Fix issues and iterate
7. Merge when all tests pass

### Validation Testing

**Test Cases:**

1. **Workflow Triggers:**
   - ✅ Push to main triggers CI
   - ✅ Push to feature branch triggers CI
   - ✅ PR triggers CI
   - ✅ Manual trigger works

2. **Job Execution:**
   - ✅ All jobs start
   - ✅ Jobs complete successfully
   - ✅ Job dependencies work
   - ✅ Matrix strategy works

3. **Test Execution:**
   - ✅ Vite tests pass
   - ✅ Next.js tests pass
   - ✅ Python tests pass
   - ✅ Version validation passes

4. **Artifacts:**
   - ✅ Test reports uploaded
   - ✅ Artifacts downloadable
   - ✅ Artifacts contain expected files

5. **Failure Handling:**
   - ✅ Failed jobs report correctly
   - ✅ Other jobs continue (where appropriate)
   - ✅ Clear error messages

### Performance Testing

**Metrics to Track:**
- Total workflow duration
- Individual job durations
- Test execution times
- Setup time

**Targets:**
- Total workflow: < 15 minutes
- Individual jobs: < 12 minutes
- Setup time: < 2 minutes per job

---

## Implementation Steps

### Step 0: Configure Branch Protection (CRITICAL - Do First)

**Time:** 15-30 minutes

**Tasks:**
1. Configure branch protection for `main` branch
2. Require PRs for all changes
3. Require CI status checks to pass
4. Include administrators in protection
5. Test configuration

**See [GitHub Repository Branch Protection](#github-repository-branch-protection) section for detailed instructions.**

**Why First:** This ensures that once workflows are created, all future changes will automatically go through CI.

**Optional - Create Validation Script:**
- Create `scripts/validate_branch_protection.sh` (see [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md))
- Test script locally
- Add to CI/CD for ongoing validation

### Step 1: Create GitHub Actions Infrastructure

**Time:** 30 minutes

**Tasks:**
1. Create `.github/workflows/` directory
2. Create initial workflow files (empty/skeleton)
3. Verify directory structure
4. Test that GitHub recognizes workflows

**Note:** After creating workflows, return to branch protection settings to add required status checks.

**Files to Create:**
```
.github/
└── workflows/
    ├── ci.yml
    ├── version-validation.yml
    ├── performance-check.yml
    └── scanner-verification.yml
```

**Validation:**
- Push to test branch
- Check GitHub Actions tab shows workflows
- Verify workflows are recognized (even if they fail)

### Step 2: Implement Lint Job

**Time:** 1 hour

**Tasks:**
1. Create lint job in `ci.yml`
2. Add JSON validation (if versions.json exists)
3. Add Makefile syntax check
4. Add basic file validation
5. Test locally with `act`

**Test:**
```bash
# Test locally
act push -j lint

# Or test on branch
git push origin feature/ci-cd-setup
# Check GitHub Actions
```

**Success Criteria:**
- Lint job completes in < 2 minutes
- Catches invalid JSON
- Catches Makefile syntax errors

### Step 3: Implement Vite Test Job

**Time:** 1.5 hours

**Tasks:**
1. Create test-vite job
2. Setup Node.js environment
3. Install dependencies
4. Test version switching
5. Test server startup
6. Run smoke tests
7. Handle cleanup

**Test:**
```bash
# Test locally
act push -j test-vite

# Or test on branch
git push origin feature/ci-cd-setup
```

**Success Criteria:**
- Job completes successfully
- Tests pass
- Server starts and stops correctly
- No resource leaks

### Step 4: Implement Next.js Test Job

**Time:** 1.5 hours

**Tasks:**
1. Create test-nextjs job
2. Setup Node.js environment
3. Install dependencies
4. Test Next.js version switching
5. Test server startup (longer wait time)
6. Run smoke tests
7. Handle cleanup

**Test:**
```bash
# Test locally
act push -j test-nextjs

# Or test on branch
```

**Success Criteria:**
- Job completes successfully
- Next.js server starts correctly
- Tests pass
- Proper cleanup

### Step 5: Implement Python Test Job (Matrix)

**Time:** 2 hours

**Tasks:**
1. Create test-python job with matrix
2. Setup Python environment
3. Setup Node.js environment
4. Install dependencies
5. Setup test environment
6. Run tests for each framework
7. Upload test reports
8. Handle cleanup

**Test:**
```bash
# Test locally (may need adjustments for act)
act push -j test-python

# Or test on branch
```

**Success Criteria:**
- Both matrix jobs complete
- Tests pass for both frameworks
- Reports uploaded as artifacts
- Proper cleanup

### Step 6: Implement Version Validation Job

**Time:** 1 hour

**Tasks:**
1. Create validate-versions job
2. Test version switching for both frameworks
3. Verify version detection
4. Report results

**Test:**
```bash
# Test locally
act push -j validate-versions
```

**Success Criteria:**
- Version switching works
- Version detection accurate
- Job completes quickly

### Step 7: Implement Version Validation Workflow

**Time:** 1 hour

**Tasks:**
1. Create `version-validation.yml`
2. Configure triggers
3. Implement comprehensive version testing
4. Generate validation report

**Test:**
```bash
# Test manual trigger
act workflow_dispatch -W .github/workflows/version-validation.yml
```

**Success Criteria:**
- Workflow triggers correctly
- All versions validated
- Report generated

### Step 8: Add Status Badges

**Time:** 30 minutes

**Tasks:**
1. Add CI badge to README
2. Add version validation badge
3. Test badge URLs
4. Verify badges show correct status

**Test:**
- View README on GitHub
- Verify badges display
- Verify badges show correct status

### Step 9: Configure Required Status Checks

**Time:** 15 minutes

**Tasks:**
1. Go to repository Settings → Branches
2. Edit `main` branch protection rule
3. Under "Require status checks to pass before merging"
4. Select all CI job status checks:
   - `lint`
   - `test-vite`
   - `test-nextjs`
   - `test-python / vite`
   - `test-python / nextjs`
   - `validate-versions`
5. Save changes
6. Test: Create PR and verify merge is blocked until CI passes

**Note:** Status checks only appear after workflows have run at least once. You may need to run workflows first, then return to configure required checks.

### Step 10: Create Validation Scripts (Optional but Recommended)

**Time:** 1 hour

**Tasks:**
1. Create `scripts/validate_branch_protection.sh`
2. Create `scripts/validate_github_setup.sh` (comprehensive)
3. Test scripts locally
4. Add validation workflow (optional)

**See [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md) for complete script examples.**

**Files:**
- `scripts/validate_branch_protection.sh`
- `scripts/validate_github_setup.sh`
- `.github/workflows/validate-setup.yml` (optional)

### Step 11: Documentation

**Time:** 1 hour

**Tasks:**
1. Create `.github/workflows/README.md`
2. Document each workflow
3. Document troubleshooting
4. Create `.github/BRANCH_PROTECTION.md` (optional)
5. Update main README with CI info
6. Reference automation options document

**Files:**
- `.github/workflows/README.md`
- `.github/BRANCH_PROTECTION.md` (optional)
- Update `README.md`

---

## Validation and Testing

### Pre-Implementation Testing

**Before creating workflows:**

1. **Test Local Environment:**
   ```bash
   # Verify all commands work locally
   make setup
   make use-vite
   make react-19.0
   make start
   make test-smoke
   make stop
   ```

2. **Test on Clean System:**
   - Use GitHub Codespaces or fresh VM
   - Verify setup works from scratch
   - Document any missing dependencies

### Workflow Testing Checklist

#### Phase 1: Basic Structure
- [ ] Workflows recognized by GitHub
- [ ] Workflows appear in Actions tab
- [ ] Can trigger workflows manually

#### Phase 2: Lint Job
- [ ] Lint job runs
- [ ] Catches invalid JSON
- [ ] Catches Makefile errors
- [ ] Completes in < 2 minutes

#### Phase 3: Vite Tests
- [ ] Job runs successfully
- [ ] Server starts
- [ ] Tests pass
- [ ] Server stops
- [ ] Completes in < 8 minutes

#### Phase 4: Next.js Tests
- [ ] Job runs successfully
- [ ] Next.js server starts
- [ ] Tests pass
- [ ] Server stops
- [ ] Completes in < 12 minutes

#### Phase 5: Python Tests
- [ ] Matrix jobs run
- [ ] Both frameworks tested
- [ ] Tests pass
- [ ] Reports uploaded
- [ ] Completes in < 10 minutes per job

#### Phase 6: Version Validation
- [ ] Job runs successfully
- [ ] Version switching works
- [ ] Version detection accurate
- [ ] Completes in < 5 minutes

#### Phase 7: Full Integration
- [ ] All jobs run on PR
- [ ] All jobs pass
- [ ] Total time < 15 minutes
- [ ] Artifacts available
- [ ] Status badges work

### Testing Scenarios

#### Scenario 1: Successful PR
**Steps:**
1. Create feature branch
2. Make small change
3. Push to branch
4. Create PR
5. Verify CI runs
6. Verify all jobs pass
7. Merge PR

**Expected:** All jobs pass, PR shows green checkmark

#### Scenario 2: Failing Test
**Steps:**
1. Create feature branch
2. Introduce test failure
3. Push to branch
4. Create PR
5. Verify CI runs
6. Verify test job fails
7. Check error message

**Expected:** Test job fails with clear error, PR shows red X

#### Scenario 3: Version Config Change
**Steps:**
1. Modify version config (if exists) or Makefile versions
2. Push to main
3. Verify version-validation workflow triggers
4. Verify validation passes

**Expected:** Version validation runs and passes

#### Scenario 4: Performance Regression
**Steps:**
1. Make change that slows tests
2. Push to main
3. Verify performance-check workflow runs
4. Verify regression detected

**Expected:** Performance check fails with regression report

### Local Testing with `act`

**Installation:**
```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Or download from: https://github.com/nektos/act/releases
```

**Basic Usage:**
```bash
# List workflows
act -l

# Run specific workflow
act push

# Run specific job
act push -j lint

# Run with secrets (if needed)
act push --secret-file .secrets

# Dry run (see what would run)
act push --dryrun
```

**Limitations:**
- May not perfectly match GitHub Actions
- Some actions may not work
- Use for basic validation, test on GitHub for final validation

---

## Troubleshooting Guide

### Common Issues

#### Issue 1: Workflow Not Triggering

**Symptoms:**
- Workflow doesn't appear in Actions tab
- Workflow doesn't run on push/PR

**Solutions:**
1. Check workflow file syntax (YAML)
2. Verify workflow is in `.github/workflows/`
3. Check file extension is `.yml` or `.yaml`
4. Verify `on:` triggers are correct
5. Check branch names match

**Debug:**
```bash
# Validate YAML syntax
yamllint .github/workflows/ci.yml

# Check GitHub Actions tab for errors
```

#### Issue 2: Job Fails Immediately

**Symptoms:**
- Job starts then fails quickly
- Exit code 1

**Solutions:**
1. Check job logs for error message
2. Verify all required tools are installed
3. Check file paths are correct
4. Verify permissions

**Debug:**
- Check job logs in GitHub Actions
- Look for error messages
- Test commands locally

#### Issue 3: Tests Timeout

**Symptoms:**
- Tests start but never complete
- Job times out

**Solutions:**
1. Increase timeout for job
2. Check server startup time
3. Verify servers are stopping
4. Check for hanging processes

**Debug:**
```yaml
# Add timeout to job
jobs:
  test-vite:
    timeout-minutes: 15
```

#### Issue 4: Server Won't Start

**Symptoms:**
- `make start` fails
- Port already in use
- Server doesn't respond

**Solutions:**
1. Add port cleanup before start
2. Increase wait time for server
3. Check for port conflicts
4. Verify Node.js version

**Debug:**
```bash
# In workflow, add debugging
- name: Check ports
  run: |
    lsof -i :3000 || echo "Port 3000 free"
    lsof -i :5173 || echo "Port 5173 free"
```

#### Issue 5: Version Switching Fails

**Symptoms:**
- `make react-19.0` fails
- Version not detected correctly

**Solutions:**
1. Verify Makefile targets exist
2. Check version format matches
3. Verify npm install completes
4. Check for npm errors

**Debug:**
```bash
# Add verbose output
- name: Switch version
  run: make react-19.0 VERBOSE=1
```

#### Issue 6: Python Tests Fail

**Symptoms:**
- pytest fails
- Import errors
- Browser driver issues

**Solutions:**
1. Verify virtual environment setup
2. Check Python version
3. Verify dependencies installed
4. Check browser driver setup

**Debug:**
```bash
# In workflow, add debugging
- name: Debug Python
  run: |
    python3 --version
    which python3
    ls -la venv/bin/
```

#### Issue 7: Matrix Job Issues

**Symptoms:**
- Only one matrix job runs
- Matrix jobs fail inconsistently

**Solutions:**
1. Verify matrix syntax
2. Check job dependencies
3. Verify framework switching works
4. Check for race conditions

**Debug:**
```yaml
# Add matrix debugging
strategy:
  matrix:
    framework: [vite, nextjs]
  fail-fast: false  # Don't stop on first failure
```

### Debugging Strategies

1. **Add Debugging Steps:**
   ```yaml
   - name: Debug environment
     run: |
       echo "Node version: $(node -v)"
       echo "Python version: $(python3 --version)"
       echo "Framework: $(cat .framework-mode)"
   ```

2. **Use `tmate` for Interactive Debugging:**
   ```yaml
   - name: Setup tmate
     uses: mxschmitt/action-tmate@v3
     if: failure()
   ```

3. **Check Artifacts:**
   - Download test reports
   - Check log files
   - Review screenshots (if any)

4. **Test Locally First:**
   - Run commands locally
   - Use `act` for basic validation
   - Test on feature branch before main

---

## Success Criteria

### Phase 1: Basic CI (Week 1)

- [ ] Branch protection configured for main
- [ ] Direct pushes to main blocked
- [ ] PRs required for all changes
- [ ] Workflows created and recognized
- [ ] Lint job works
- [ ] At least one test job works (Vite or Next.js)
- [ ] Workflows run on push/PR

### Phase 2: Complete CI (Week 2)

- [ ] All test jobs work (Vite, Next.js, Python)
- [ ] Version validation works
- [ ] Matrix strategy works
- [ ] Artifacts upload correctly
- [ ] Required status checks configured
- [ ] PRs cannot be merged without passing CI
- [ ] Total workflow time < 15 minutes

### Phase 3: Polish (Week 3)

- [ ] Status badges work
- [ ] Documentation complete
- [ ] Troubleshooting guide complete
- [ ] Performance checks implemented
- [ ] Zero false positives

### Final Success Metrics

- ✅ **Reliability:** 95%+ success rate
- ✅ **Speed:** Total workflow < 15 minutes
- ✅ **Coverage:** All frameworks tested
- ✅ **Visibility:** Clear status in PRs
- ✅ **Maintainability:** Easy to update workflows

---

## Implementation Timeline

### Week 1: Foundation
- **Day 1:** Configure branch protection, setup infrastructure, create workflow files
- **Day 2:** Implement lint job, test locally
- **Day 3:** Implement Vite test job, test on branch
- **Day 4:** Implement Next.js test job, test on branch
- **Day 5:** Testing and debugging, configure required status checks

### Week 2: Completion
- **Day 1:** Implement Python test job (matrix)
- **Day 2:** Implement version validation
- **Day 3:** Full integration testing
- **Day 4:** Add status badges, documentation
- **Day 5:** Final testing and polish

### Week 3: Advanced (Optional)
- **Day 1:** Performance check workflow
- **Day 2:** Scanner verification workflow (if applicable)
- **Day 3:** Optimization and tuning
- **Day 4:** Documentation updates
- **Day 5:** Final validation

**Total Estimated Time:** 8-10 hours for basic CI, 12-15 hours for complete implementation

---

## Next Steps

1. **Review this plan** with team
2. **Review [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md)** for automation approaches
3. **Create GitHub issues** for tracking
4. **Start with Step 0:** Configure branch protection (CRITICAL - do this first)
5. **Optional:** Create validation scripts for branch protection
6. **Set up test branch** for implementation
7. **Start with Step 1:** Create infrastructure
8. **Test incrementally** after each step
9. **Configure required status checks** after workflows are working
10. **Add validation scripts** to CI/CD (optional)
11. **Iterate based on results**

**Important:** Configure branch protection **before** creating workflows to ensure all future changes go through CI from the start.

**Automation:** Consider creating validation scripts early to verify branch protection is configured correctly. See [CI/CD Automation Options](CI_CD_AUTOMATION_OPTIONS.md) for examples.

---

## Appendix: Workflow Templates

### Basic Workflow Template

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  NODE_VERSION: '24.12.0'
  PYTHON_VERSION: '3.11'

jobs:
  job-name:
    name: Job Description
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Step description
        run: |
          echo "Command here"
```

### Matrix Job Template

```yaml
jobs:
  test-matrix:
    name: Test Matrix
    runs-on: ubuntu-latest
    strategy:
      matrix:
        framework: [vite, nextjs]
        include:
          - framework: vite
            port: 5173
          - framework: nextjs
            port: 3000
    steps:
      - uses: actions/checkout@v4
      - name: Test ${{ matrix.framework }}
        run: |
          echo "Testing ${{ matrix.framework }} on port ${{ matrix.port }}"
```

---

**End of CI/CD Implementation Plan**
