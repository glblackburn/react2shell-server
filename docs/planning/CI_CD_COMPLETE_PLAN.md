# Complete CI/CD Implementation Plan: GitHub Actions for React2Shell Server

**Date:** 2025-12-23  
**Status:** Planning  
**Priority:** High  
**Estimated Time:** 8-10 hours (basic), 12-15 hours (complete)

---

## Executive Summary

This comprehensive plan details the implementation of a CI/CD pipeline using GitHub Actions for the React2Shell Server project. The plan includes workflow implementation, branch protection configuration, automation options, testing strategies, and troubleshooting guides.

**Key Objectives:**
- Automated testing on every push and pull request
- Framework-aware testing (Vite + React and Next.js)
- Version switching validation
- Performance regression detection
- Comprehensive test coverage reporting
- Branch protection to enforce CI/CD process

**This document consolidates:**
- CI/CD implementation plan
- Automation options and validation scripts
- Branch protection policy
- Testing strategies
- Troubleshooting guides
- Recommendations from project review

---

## Table of Contents

1. [Overview and Goals](#overview-and-goals)
2. [Architecture Design](#architecture-design)
3. [GitHub Repository Branch Protection](#github-repository-branch-protection)
4. [Branch Protection Automation](#branch-protection-automation)
5. [CI/CD Pipeline Creation Options](#cicd-pipeline-creation-options)
6. [Workflow Implementation](#workflow-implementation)
7. [Testing Strategy](#testing-strategy)
8. [Implementation Steps](#implementation-steps)
9. [Validation and Testing](#validation-and-testing)
10. [Troubleshooting Guide](#troubleshooting-guide)
11. [Success Criteria](#success-criteria)
12. [Recommendations from Project Review](#recommendations-from-project-review)
13. [Appendix: Scripts and Templates](#appendix-scripts-and-templates)

---

## Overview and Goals

### Current State

- Manual testing required for each change
- No automated validation of version switching
- No continuous integration
- Tests must be run locally
- No visibility into test status for PRs
- No branch protection (direct commits to main allowed)

### Target State

- Automated testing on every push/PR
- Framework-aware CI (tests both Vite and Next.js)
- Version switching validation
- Test results visible in PRs
- Automated performance regression detection
- Status badges in README
- Branch protection enforcing PRs and CI checks

### Success Metrics

- ✅ All tests pass in CI
- ✅ CI completes in < 15 minutes
- ✅ Zero false positives
- ✅ Clear failure messages
- ✅ Test reports available as artifacts
- ✅ Branch protection prevents direct commits
- ✅ PRs require passing CI to merge

### Project Review Recommendations

From the project review, key recommendations for CI/CD:

1. **High Priority: Add CI/CD Pipeline**
   - Add GitHub Actions workflow for automated testing
   - Continuous validation of version switching and scanner verification
   - Benefit: Early bug detection and consistent quality

2. **CI/CD Integration:**
   - Automated testing on every change
   - Framework-aware testing (Vite + Next.js)
   - Version validation
   - Performance regression detection

---

## Architecture Design

### Workflow Structure

```
.github/workflows/
├── ci.yml                    # Main CI workflow (runs on push/PR)
├── version-validation.yml     # Version switching validation
├── performance-check.yml      # Performance regression detection
├── validate-setup.yml         # Repository setup validation (optional)
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

---

## Branch Protection Automation

### Overview

While branch protection can be configured manually via GitHub UI, automation options are available for validation and configuration. This section covers automation approaches.

### Option 1: GitHub API Script (Recommended for Validation)

**Use Case:** Validate branch protection is configured correctly

**Tools:**
- GitHub REST API
- `curl` or `jq` for API calls
- Shell script or Python script

**Pros:**
- Simple to implement
- Good for validation/verification
- No additional dependencies
- Can be run in CI/CD

**Cons:**
- Manual configuration still required
- Not ideal for initial setup

**Example Script:** See [Appendix: Branch Protection Validation Script](#appendix-branch-protection-validation-script)

**Usage:**
```bash
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY_OWNER="your-org"
export GITHUB_REPOSITORY_NAME="react2shell-server"
./scripts/validate_branch_protection.sh
```

### Option 2: Terraform (Recommended for Configuration)

**Use Case:** Configure branch protection as Infrastructure as Code

**Tools:**
- Terraform
- `terraform-provider-github`

**Pros:**
- Infrastructure as Code
- Version controlled
- Reproducible
- Can manage multiple repositories
- Can be applied via CI/CD

**Cons:**
- Requires Terraform setup
- Additional learning curve
- Need to manage Terraform state

**Example:** See [Appendix: Terraform Branch Protection](#appendix-terraform-branch-protection)

**Usage:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Option 3: GitHub CLI (gh)

**Use Case:** Quick configuration and validation via command line

**Tools:**
- GitHub CLI (`gh`)

**Pros:**
- Simple command-line interface
- Good for quick setup
- Can be scripted

**Cons:**
- Not version controlled (unless scripted)
- Manual process
- Less suitable for automation

**Example Commands:**

```bash
# Check branch protection
gh api repos/:owner/:repo/branches/main/protection

# Configure via API (complex, better to use UI or Terraform)
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews[required_approving_review_count]=1 \
  --field enforce_admins=true
```

### Option 4: Python Script (GitHub API)

**Use Case:** More complex validation or configuration logic

**Example:** See [Appendix: Python Validation Script](#appendix-python-validation-script)

### Recommended Approach

**For this project:**
1. **Initial Setup:** Manual configuration via GitHub UI (fastest)
2. **Validation:** Automated script (`scripts/validate_branch_protection.sh`)
3. **Future:** Consider Terraform if managing multiple repositories

---

## CI/CD Pipeline Creation Options

### Option 1: Manual YAML Files (Recommended)

**Use Case:** Standard approach, full control

**How it works:**
- Create `.github/workflows/*.yml` files manually
- Commit to repository
- GitHub automatically recognizes and runs workflows

**Pros:**
- Simple and straightforward
- Full control over workflow content
- Easy to understand and modify
- No additional tools required
- Version controlled in repository

**Cons:**
- Manual creation
- No validation before commit
- Can't easily manage multiple repositories

**Implementation:**
```bash
# Create workflow files
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
EOF

git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
```

### Option 2: Terraform GitHub Provider

**Use Case:** Manage workflows as Infrastructure as Code

**Tools:**
- Terraform
- `terraform-provider-github`

**Pros:**
- Infrastructure as Code
- Version controlled
- Can manage multiple repositories
- Can be applied via CI/CD
- Reproducible

**Cons:**
- Requires Terraform setup
- YAML content in HCL (can be verbose)
- Need to manage Terraform state
- Less intuitive than YAML

**Example:** `terraform/workflows.tf`

```hcl
resource "github_repository_file" "ci_workflow" {
  repository          = var.repository_name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/workflows/ci.yml")
  commit_message      = "Add CI workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}
```

**Workflow file:** `terraform/workflows/ci.yml` (standard YAML)

### Option 3: GitHub Actions Templates / Generators

**Use Case:** Generate workflows from templates

**Tools:**
- GitHub Actions templates
- Custom generators
- Workflow generators (e.g., `action-docs`)

**Pros:**
- Consistent workflow structure
- Can generate from templates
- Less manual work

**Cons:**
- Still need to customize
- Limited flexibility
- Additional tooling

### Option 4: GitHub API / CLI Scripts

**Use Case:** Programmatic workflow creation

**Tools:**
- GitHub API
- GitHub CLI (`gh`)
- Custom scripts

**Pros:**
- Can be automated
- Can manage multiple repos
- Scriptable

**Cons:**
- Complex API calls
- Need to handle YAML encoding
- Less intuitive

### Recommended Approach

**For this project:**
- **Initial Setup:** Manual YAML files (current plan - simplest)
- **Validation:** Check workflow files exist and are valid
- **Future:** Consider Terraform if managing multiple repositories

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

### Workflow 4: Repository Setup Validation (Optional)

**File:** `.github/workflows/validate-setup.yml`

**Trigger:**
- Manual trigger (`workflow_dispatch`)
- Weekly schedule (optional)

**Purpose:** Validate branch protection and workflow configuration

**Steps:**
1. Checkout code
2. Install dependencies (jq, curl)
3. Validate branch protection via API
4. Validate workflows exist
5. Validate required status checks
6. Generate validation report

**Time Estimate:** 2-3 minutes  
**Frequency:** Weekly or on demand

### Workflow 5: Scanner Verification (Optional)

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

6. **Branch Protection:**
   - ✅ Direct push to main fails
   - ✅ PR with failing CI cannot be merged
   - ✅ PR with passing CI can be merged

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
3. Require CI status checks to pass (configure after workflows exist)
4. Include administrators in protection
5. Test configuration

**See [GitHub Repository Branch Protection](#github-repository-branch-protection) section for detailed instructions.**

**Why First:** This ensures that once workflows are created, all future changes will automatically go through CI.

**Optional - Create Validation Script:**
- Create `scripts/validate_branch_protection_enforcement.sh` (see Appendix - recommended)
- Test script locally
- Add to CI/CD for ongoing validation
- Use `--test-enforcement` flag to test actual enforcement

**Checklist:**
- [ ] Navigate to Repository Settings → Branches
- [ ] Create/edit branch protection rule for `main`
- [ ] Enable "Protect matching branches"
- [ ] Enable "Require pull request reviews before merging"
- [ ] Enable "Require status checks to pass before merging"
- [ ] Enable "Require branches to be up to date before merging"
- [ ] Enable "Include administrators" (CRITICAL)
- [ ] Enable "Do not allow bypassing the above settings"
- [ ] Test: Try direct push to main (should fail)
- [ ] Test: Create PR (should work)
- [ ] Document branch protection policy (optional)

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
    ├── validate-setup.yml (optional)
    └── scanner-verification.yml (optional)
```

**Validation:**
- Push to test branch
- Check GitHub Actions tab shows workflows
- Verify workflows are recognized (even if they fail)

**Checklist:**
- [ ] Create `.github/workflows/` directory
- [ ] Create workflow skeleton files
- [ ] Verify GitHub recognizes workflows

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

**Checklist:**
- [ ] Create lint job in `ci.yml`
- [ ] Add JSON validation
- [ ] Add Makefile syntax check
- [ ] Test locally with `act`
- [ ] Test on feature branch

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

**Checklist:**
- [ ] Create test-vite job
- [ ] Setup Node.js environment
- [ ] Install dependencies
- [ ] Test version switching
- [ ] Test server startup
- [ ] Run smoke tests
- [ ] Handle cleanup
- [ ] Test job individually

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

**Checklist:**
- [ ] Create test-nextjs job
- [ ] Setup Node.js environment
- [ ] Install dependencies
- [ ] Test Next.js version switching
- [ ] Test server startup
- [ ] Run smoke tests
- [ ] Handle cleanup
- [ ] Test job individually

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

**Checklist:**
- [ ] Create test-python job (matrix)
- [ ] Setup Python environment
- [ ] Setup Node.js environment
- [ ] Install dependencies
- [ ] Setup test environment
- [ ] Run tests for each framework
- [ ] Upload test reports
- [ ] Handle cleanup
- [ ] Test each job individually
- [ ] Test all jobs together

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

**Checklist:**
- [ ] Create validate-versions job
- [ ] Test version switching for both frameworks
- [ ] Verify version detection
- [ ] Report results
- [ ] Test job individually

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

**Checklist:**
- [ ] Create version-validation workflow
- [ ] Configure triggers
- [ ] Test version switching
- [ ] Test workflow triggers

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

**Checklist:**
- [ ] Add CI badge to README
- [ ] Add version validation badge
- [ ] Test badge URLs

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

**Checklist:**
- [ ] Go to Settings → Branches → Edit main branch rule
- [ ] Under "Require status checks", select all CI jobs:
  - [ ] `lint`
  - [ ] `test-vite`
  - [ ] `test-nextjs`
  - [ ] `test-python / vite`
  - [ ] `test-python / nextjs`
  - [ ] `validate-versions`
- [ ] Save changes
- [ ] Test: Create PR and verify merge blocked until CI passes

### Step 10: Create Validation Scripts (Optional but Recommended)

**Time:** 1 hour

**Tasks:**
1. Create `scripts/validate_branch_protection_enforcement.sh` (comprehensive)
2. Create `scripts/validate_branch_protection.sh` (basic, optional)
3. Create `scripts/validate_github_setup.sh` (comprehensive)
4. Test scripts locally
5. Add validation workflow (optional)

**See [Appendix: Validation Scripts](#appendix-validation-scripts) for complete script examples.**

**Files:**
- `scripts/validate_branch_protection_enforcement.sh` (recommended - comprehensive)
- `scripts/validate_branch_protection.sh` (basic version, optional)
- `scripts/validate_github_setup.sh` (comprehensive)
- `.github/workflows/validate-setup.yml` (optional)

**Checklist:**
- [ ] Create `scripts/validate_branch_protection.sh`
- [ ] Create `scripts/validate_github_setup.sh`
- [ ] Test scripts locally
- [ ] Add validation workflow (optional)

### Step 11: Documentation

**Time:** 1 hour

**Tasks:**
1. Create `.github/workflows/README.md`
2. Document each workflow
3. Document troubleshooting
4. Create `.github/BRANCH_PROTECTION.md` (optional)
5. Update main README with CI info

**Files:**
- `.github/workflows/README.md`
- `.github/BRANCH_PROTECTION.md` (optional)
- Update `README.md`

**Checklist:**
- [ ] Create `.github/workflows/README.md`
- [ ] Document workflows
- [ ] Create `.github/BRANCH_PROTECTION.md` (optional)
- [ ] Update main README

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
- [ ] Branch protection enforced

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

**Expected:** All jobs pass, PR shows green checkmark, merge succeeds

#### Scenario 2: Failing Test
**Steps:**
1. Create feature branch
2. Introduce test failure
3. Push to branch
4. Create PR
5. Verify CI runs
6. Verify test job fails
7. Check error message
8. Try to merge PR

**Expected:** Test job fails with clear error, PR shows red X, merge blocked

#### Scenario 3: Version Config Change
**Steps:**
1. Modify version config (if exists) or Makefile versions
2. Push to main (should fail - branch protected)
3. Create PR instead
4. Verify version-validation workflow triggers
5. Verify validation passes
6. Merge PR

**Expected:** Direct push fails, PR triggers validation, validation passes

#### Scenario 4: Performance Regression
**Steps:**
1. Make change that slows tests
2. Push to feature branch
3. Create PR
4. Verify performance-check workflow runs (if enabled)
5. Verify regression detected

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

#### Issue 8: Branch Protection Not Working

**Symptoms:**
- Can still push directly to main
- PRs can be merged without CI passing

**Solutions:**
1. Verify branch protection is enabled
2. Check "Include administrators" is enabled
3. Verify required status checks are configured
4. Check status check names match job names

**Debug:**
```bash
# Validate branch protection
./scripts/validate_branch_protection.sh
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
- [ ] Validation scripts created (optional)
- [ ] Zero false positives

### Final Success Metrics

- ✅ **Reliability:** 95%+ success rate
- ✅ **Speed:** Total workflow < 15 minutes
- ✅ **Coverage:** All frameworks tested
- ✅ **Visibility:** Clear status in PRs
- ✅ **Maintainability:** Easy to update workflows
- ✅ **Enforcement:** Branch protection working correctly

---

## Recommendations from Project Review

### High Priority Recommendations

1. **Add CI/CD Pipeline**
   - **Current:** Manual testing required
   - **Recommendation:** Add GitHub Actions workflow for automated testing
   - **Benefit:** Continuous validation of version switching and scanner verification
   - **Implementation:** This document provides complete implementation guide

2. **CI/CD Integration**
   - **Recommendation:** Add automated testing on every change
   - **Benefit:** Early bug detection and consistent quality
   - **Implementation:** See [Workflow Implementation](#workflow-implementation) section

### Medium Priority Recommendations

1. **Performance Monitoring**
   - **Recommendation:** Add performance monitoring for version switching operations
   - **Benefit:** Identify slow version switches and optimize
   - **Implementation:** See [Workflow 3: Performance Check](#workflow-3-performance-check)

2. **Dependency Updates**
   - **Recommendation:** Regular dependency updates (with testing)
   - **Tool:** Consider Renovate or Dependabot
   - **Benefit:** Stay current with security patches

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
2. **Create GitHub issues** for tracking
3. **Start with Step 0:** Configure branch protection (CRITICAL - do this first)
4. **Optional:** Create validation scripts for branch protection
5. **Set up test branch** for implementation
6. **Start with Step 1:** Create infrastructure
7. **Test incrementally** after each step
8. **Configure required status checks** after workflows are working
9. **Add validation scripts** to CI/CD (optional)
10. **Iterate based on results**

**Important:** Configure branch protection **before** creating workflows to ensure all future changes go through CI from the start.

**Automation:** Consider creating validation scripts early to verify branch protection is configured correctly. See [Appendix: Validation Scripts](#appendix-validation-scripts) for examples.

---

## Appendix: Scripts and Templates

### Appendix: Branch Protection Validation Scripts

#### Comprehensive Enforcement Validation Script (Recommended)

**File:** `scripts/validate_branch_protection_enforcement.sh`

**Purpose:** Comprehensive validation that branch protection is configured AND enforced to prevent bypassing CI/CD.

**Features:**
- Validates all required branch protection settings
- Checks that administrators are included (no bypass)
- Verifies required status checks are configured
- Optionally tests enforcement by creating test branch/PR
- Detects security vulnerabilities in configuration

**Usage:**
```bash
# Basic validation (configuration check)
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY_OWNER="your-org"
export GITHUB_REPOSITORY_NAME="react2shell-server"
./scripts/validate_branch_protection_enforcement.sh

# Full validation with enforcement testing
./scripts/validate_branch_protection_enforcement.sh --test-enforcement
```

**What It Validates:**
1. ✅ Branch protection exists
2. ✅ Required pull request reviews enabled
3. ✅ Required status checks configured (with expected CI/CD checks)
4. ✅ Administrators included (CRITICAL - prevents bypass)
5. ✅ Force pushes disabled
6. ✅ Branch deletion disabled
7. ✅ Optional: Tests enforcement by creating test branch/PR

**Output:**
- Clear pass/fail status
- Detailed error messages for failures
- Warnings for suboptimal configurations
- Summary of all checks

**Integration:**
- Can be run manually for validation
- Can be added to CI/CD workflow for ongoing validation
- Can be scheduled to run weekly

#### Basic Validation Script

**File:** `scripts/validate_branch_protection.sh`

Simple script to check branch protection configuration (basic version).

```bash
#!/usr/bin/env bash
# Validate branch protection configuration via GitHub API

set -euET -o pipefail

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
BRANCH="main"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable required" >&2
    exit 1
fi

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Error: Repository owner and name required" >&2
    echo "Set GITHUB_REPOSITORY_OWNER and GITHUB_REPOSITORY_NAME" >&2
    exit 1
fi

API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection"

echo "Checking branch protection for ${REPO_OWNER}/${REPO_NAME}:${BRANCH}..."

# Check if branch protection exists
response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "$API_URL")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "404" ]; then
    echo "❌ FAIL: Branch protection not configured for ${BRANCH}"
    exit 1
fi

if [ "$http_code" != "200" ]; then
    echo "❌ FAIL: API request failed (HTTP ${http_code})"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    exit 1
fi

# Validate required settings
echo "Validating branch protection settings..."

# Check required pull request reviews
required_pr=$(echo "$body" | jq -r '.required_pull_request_reviews // empty')
if [ -z "$required_pr" ] || [ "$required_pr" = "null" ]; then
    echo "❌ FAIL: Required pull request reviews not enabled"
    exit 1
fi

# Check required status checks
required_status_checks=$(echo "$body" | jq -r '.required_status_checks // empty')
if [ -z "$required_status_checks" ] || [ "$required_status_checks" = "null" ]; then
    echo "❌ FAIL: Required status checks not configured"
    exit 1
fi

# Check if administrators are included
enforce_admins=$(echo "$body" | jq -r '.enforce_admins.enabled // false')
if [ "$enforce_admins" != "true" ]; then
    echo "⚠️  WARNING: Administrators not included in protection (not enforced)"
fi

# Check if allow force pushes is disabled
allow_force_pushes=$(echo "$body" | jq -r '.allow_force_pushes // false')
if [ "$allow_force_pushes" = "true" ]; then
    echo "⚠️  WARNING: Force pushes are allowed (not recommended)"
fi

# Check if allow deletions is disabled
allow_deletions=$(echo "$body" | jq -r '.allow_deletions // false')
if [ "$allow_deletions" = "true" ]; then
    echo "⚠️  WARNING: Branch deletion is allowed (not recommended)"
fi

echo "✅ PASS: Branch protection is configured correctly"
echo ""
echo "Summary:"
echo "  - Required PR reviews: ✅"
echo "  - Required status checks: ✅"
echo "  - Enforce admins: $([ "$enforce_admins" = "true" ] && echo "✅" || echo "⚠️")"
echo "  - Force pushes: $([ "$allow_force_pushes" = "true" ] && echo "⚠️" || echo "✅")"
echo "  - Deletions: $([ "$allow_deletions" = "true" ] && echo "⚠️" || echo "✅")"

exit 0
```

### Appendix: Python Validation Script

**File:** `scripts/validate_branch_protection.py`

```python
#!/usr/bin/env python3
"""Validate branch protection configuration."""

import os
import sys
import requests
import json

GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
REPO_OWNER = os.environ.get('GITHUB_REPOSITORY_OWNER')
REPO_NAME = os.environ.get('GITHUB_REPOSITORY_NAME')
BRANCH = 'main'

if not all([GITHUB_TOKEN, REPO_OWNER, REPO_NAME]):
    print("Error: GITHUB_TOKEN, GITHUB_REPOSITORY_OWNER, and GITHUB_REPOSITORY_NAME required")
    sys.exit(1)

headers = {
    'Authorization': f'token {GITHUB_TOKEN}',
    'Accept': 'application/vnd.github.v3+json'
}

url = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/branches/{BRANCH}/protection'

response = requests.get(url, headers=headers)

if response.status_code == 404:
    print(f"❌ FAIL: Branch protection not configured for {BRANCH}")
    sys.exit(1)

if response.status_code != 200:
    print(f"❌ FAIL: API request failed (HTTP {response.status_code})")
    print(response.text)
    sys.exit(1)

data = response.json()

# Validate settings
errors = []
warnings = []

if not data.get('required_pull_request_reviews'):
    errors.append("Required pull request reviews not enabled")

if not data.get('required_status_checks'):
    errors.append("Required status checks not configured")

if not data.get('enforce_admins', {}).get('enabled'):
    warnings.append("Administrators not included in protection")

if data.get('allow_force_pushes'):
    warnings.append("Force pushes are allowed")

if data.get('allow_deletions'):
    warnings.append("Branch deletion is allowed")

if errors:
    print("❌ FAIL: Branch protection validation failed")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

if warnings:
    print("⚠️  WARNINGS:")
    for warning in warnings:
        print(f"  - {warning}")

print("✅ PASS: Branch protection is configured correctly")
sys.exit(0)
```

### Appendix: Comprehensive Validation Script

**File:** `scripts/validate_github_setup.sh`

```bash
#!/usr/bin/env bash
# Comprehensive validation of GitHub repository setup
# Validates branch protection, workflows, and required status checks

set -euET -o pipefail

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN required" >&2
    exit 1
fi

API_BASE="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"

echo "Validating GitHub repository setup..."
echo "Repository: ${REPO_OWNER}/${REPO_NAME}"
echo ""

# Check branch protection
echo "1. Checking branch protection..."
./scripts/validate_branch_protection.sh
BRANCH_PROTECTION_STATUS=$?

# Check workflows exist
echo ""
echo "2. Checking GitHub Actions workflows..."
WORKFLOWS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_BASE}/actions/workflows" | jq -r '.workflows[].name')

if [ -z "$WORKFLOWS" ]; then
    echo "❌ FAIL: No workflows found"
    WORKFLOW_STATUS=1
else
    echo "✅ Found workflows:"
    echo "$WORKFLOWS" | while read -r workflow; do
        echo "  - $workflow"
    done
    WORKFLOW_STATUS=0
fi

# Check required status checks
echo ""
echo "3. Checking required status checks..."
STATUS_CHECKS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "${API_BASE}/branches/main/protection/required_status_checks" | \
    jq -r '.contexts[]?')

if [ -z "$STATUS_CHECKS" ]; then
    echo "⚠️  WARNING: No required status checks configured"
    STATUS_CHECK_STATUS=1
else
    echo "✅ Required status checks:"
    echo "$STATUS_CHECKS" | while read -r check; do
        echo "  - $check"
    done
    STATUS_CHECK_STATUS=0
fi

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "Branch Protection: $([ $BRANCH_PROTECTION_STATUS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Workflows: $([ $WORKFLOW_STATUS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Status Checks: $([ $STATUS_CHECK_STATUS -eq 0 ] && echo "✅ PASS" || echo "⚠️  WARN")"
echo ""

if [ $BRANCH_PROTECTION_STATUS -ne 0 ] || [ $WORKFLOW_STATUS -ne 0 ]; then
    echo "❌ Validation failed"
    exit 1
fi

echo "✅ All validations passed"
exit 0
```

### Appendix: Terraform Branch Protection

**File:** `terraform/branch-protection.tf`

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or username"
  type        = string
}

variable "repository_name" {
  description = "Repository name"
  type        = string
  default     = "react2shell-server"
}

# Branch protection for main branch
resource "github_branch_protection" "main" {
  repository_id = var.repository_name
  pattern       = "main"

  # Require pull request reviews
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  # Require status checks
  required_status_checks {
    strict   = true  # Require branches to be up to date
    contexts = [
      "lint",
      "test-vite",
      "test-nextjs",
      "test-python / vite",
      "test-python / nextjs",
      "validate-versions"
    ]
  }

  # Enforce for administrators
  enforce_admins = true

  # Prevent force pushes
  allows_force_pushes = false

  # Prevent deletions
  allows_deletions = false

  # Require conversation resolution
  require_conversation_resolution = true
}

# Output for validation
output "branch_protection_id" {
  value       = github_branch_protection.main.id
  description = "Branch protection rule ID"
}
```

### Appendix: Workflow Templates

#### Basic Workflow Template

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

#### Matrix Job Template

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

### Appendix: Validation Workflow

**File:** `.github/workflows/validate-setup.yml`

```yaml
name: Validate GitHub Setup

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  validate:
    name: Validate Repository Setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq curl
      
      - name: Validate branch protection
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
          GITHUB_REPOSITORY_NAME: ${{ github.event.repository.name }}
        run: |
          chmod +x scripts/validate_branch_protection.sh
          ./scripts/validate_branch_protection.sh
      
      - name: Validate workflows exist
        run: |
          if [ ! -f .github/workflows/ci.yml ]; then
            echo "❌ CI workflow not found"
            exit 1
          fi
          echo "✅ Workflows found"
```

---

### Appendix: Comprehensive Branch Protection Enforcement Validation

**File:** `scripts/validate_branch_protection_enforcement.sh`

Complete script for validating branch protection enforcement. See script file for full implementation.

**Key Validation Points:**
1. Branch protection exists and is configured
2. Required PR reviews are enabled
3. Required status checks include CI/CD jobs
4. Administrators cannot bypass (CRITICAL)
5. Force pushes are disabled
6. Branch deletion is disabled
7. Optional enforcement testing

**Usage in CI/CD:**
```yaml
- name: Validate branch protection
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
    GITHUB_REPOSITORY_NAME: ${{ github.event.repository.name }}
  run: |
    chmod +x scripts/validate_branch_protection_enforcement.sh
    ./scripts/validate_branch_protection_enforcement.sh
```

---

**End of Complete CI/CD Implementation Plan**
