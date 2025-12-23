# Implementation Checklist: CI/CD, Version Centralization, and Makefile Refactoring

**Quick Reference Checklist** - See [Full Implementation Plan](IMPLEMENTATION_PLAN_VERSION_CENTRALIZATION_CI.md) for details

**Note:** Phase 1 is now CI/CD. See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for detailed Phase 1 guide.

---

## Phase 1: Add CI/CD with GitHub Actions ⏱️ 8-10 hours

**See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for complete checklist and detailed steps.**

### Step 0: Configure Branch Protection (CRITICAL - Do First) ⏱️ 15-30 minutes
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

### Step 1.1: Create Infrastructure
- [ ] Create `.github/workflows/` directory
- [ ] Create workflow skeleton files
- [ ] Verify GitHub recognizes workflows

### Step 1.2: Implement Lint Job
- [ ] Create lint job in `ci.yml`
- [ ] Add JSON validation
- [ ] Add Makefile syntax check
- [ ] Test locally with `act`
- [ ] Test on feature branch

### Step 1.3: Implement Test Jobs
- [ ] Create test-vite job
- [ ] Create test-nextjs job
- [ ] Create test-python job (matrix)
- [ ] Test each job individually
- [ ] Test all jobs together

### Step 1.4: Implement Version Validation
- [ ] Create validate-versions job
- [ ] Create version-validation workflow
- [ ] Test version switching
- [ ] Test workflow triggers

### Step 1.5: Add Status Badges
- [ ] Add CI badge to README
- [ ] Add version validation badge
- [ ] Test badge URLs

### Step 1.6: Configure Required Status Checks
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

### Step 1.7: Documentation
- [ ] Create `.github/workflows/README.md`
- [ ] Document workflows
- [ ] Create `.github/BRANCH_PROTECTION.md` (optional)
- [ ] Update main README

**See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for detailed testing checklist.**

---

## Phase 2: Centralize Version Constants ⏱️ 11.5 hours

### Step 1.1: Create Centralized Config
- [ ] Create `config/` directory
- [ ] Create `config/versions.json` with version definitions
- [ ] Create `config/README.md` documentation
- [ ] Create `scripts/validate_versions.sh` validation script

### Step 1.2: Create Version Readers
- [ ] Create `server/config/version_reader.js` (JavaScript)
- [ ] Create `tests/utils/version_reader.py` (Python)
- [ ] Create `scripts/read_versions.sh` (Bash)
- [ ] Make `scripts/read_versions.sh` executable

### Step 1.3: Update Components
- [ ] Update `server/config/versions.js` to use version_reader.js
- [ ] Update `server/server.js` (verify it works)
- [ ] Update `tests/utils/version_constants.py` (backward compatibility)
- [ ] Update `tests/utils/nextjs_version_constants.py`
- [ ] Update `Makefile` to use read_versions.sh
- [ ] Update `scripts/verify_scanner.sh`
- [ ] Update `scripts/scanner_verification_report.sh`

### Step 1.4: Testing
- [ ] Run `scripts/validate_versions.sh`
- [ ] Test JavaScript reader: `node -e "import('./server/config/version_reader.js')"`
- [ ] Test Python reader: `python3 -c "from tests.utils.version_reader import get_react_versions"`
- [ ] Test Bash reader: `./scripts/read_versions.sh get_react_versions all`
- [ ] Test version switching: `make react-19.0` then `make current-version`
- [ ] Test server endpoint: `curl http://localhost:3000/api/version`
- [ ] Run full test suite: `make test`
- [ ] Verify all tests pass

---

## Phase 3: Improve Makefile Maintainability ⏱️ 11 hours

### Step 2.1: Analysis
- [ ] Analyze Makefile structure
- [ ] Identify logical sections
- [ ] Map dependencies
- [ ] Identify functions to extract

### Step 2.2: Create Include Structure
- [ ] Create `Makefile.includes/` directory
- [ ] Create `Makefile.includes/versions.mk`
- [ ] Create `Makefile.includes/setup.mk`
- [ ] Create `Makefile.includes/server.mk`
- [ ] Create `Makefile.includes/testing.mk`
- [ ] Create `Makefile.includes/help.mk`
- [ ] Update main `Makefile` to include sections
- [ ] Test: `make help` should work

### Step 2.3: Extract Functions to Scripts
- [ ] Create `scripts/switch_version.sh`
- [ ] Create `scripts/ensure_node_version.sh`
- [ ] Create `scripts/server_manager.sh`
- [ ] Create `scripts/run_tests.sh`
- [ ] Make all scripts executable
- [ ] Update Makefile to call scripts
- [ ] Test each script individually

### Step 2.4: Simplify Targets
- [ ] Simplify version switching targets
- [ ] Simplify server management targets
- [ ] Simplify test targets
- [ ] Test all targets: `make help` lists all correctly
- [ ] Test version switching: `make react-19.0`
- [ ] Test server management: `make start`, `make stop`, `make status`
- [ ] Test testing targets: `make test-setup`, `make test-smoke`

### Step 2.5: Documentation
- [ ] Create `Makefile.includes/README.md`
- [ ] Add comments to Makefile includes
- [ ] Document conventions

---

## Phase 3: Add CI/CD with GitHub Actions ⏱️ 7 hours

### Step 3.1: Infrastructure
- [ ] Create `.github/workflows/` directory
- [ ] Verify GitHub Actions enabled on repository

### Step 3.2: Main CI Workflow
- [ ] Create `.github/workflows/ci.yml`
- [ ] Add lint job
- [ ] Add test-vite job
- [ ] Add test-nextjs job
- [ ] Add test-python job (matrix: vite, nextjs)
- [ ] Add validate-versions job
- [ ] Test workflow on feature branch
- [ ] Fix any workflow errors
- [ ] Verify all jobs complete successfully

### Step 3.3: Version Validation Workflow
- [ ] Create `.github/workflows/version-validation.yml`
- [ ] Configure to run on version config changes
- [ ] Test workflow manually
- [ ] Verify version switching validation works

### Step 3.4: Scanner Verification Workflow (Optional)
- [ ] Create `.github/workflows/scanner-verification.yml`
- [ ] Configure as manual trigger only
- [ ] Document as optional workflow

### Step 3.5: Documentation
- [ ] Create `.github/workflows/README.md`
- [ ] Document each workflow
- [ ] Add troubleshooting section

### Step 3.6: Status Badges
- [ ] Add CI badge to README.md
- [ ] Add Version Validation badge to README.md
- [ ] Test badge URLs work

---

## Final Verification

### All Phases Complete
- [ ] All tests pass: `make test`
- [ ] Version switching works: Test multiple versions
- [ ] Server management works: `make start`, `make stop`
- [ ] CI workflows run successfully
- [ ] Documentation updated
- [ ] No regressions introduced

### Documentation
- [ ] Update main README.md with new features
- [ ] Document centralized version config
- [ ] Document Makefile structure
- [ ] Document CI/CD setup

---

## Quick Commands Reference

### Phase 1 Testing (CI/CD)

**See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for comprehensive testing checklist.**

### Phase 2 Testing
```bash
# Validate config
./scripts/validate_versions.sh

# Test readers
node -e "import('./server/config/version_reader.js').then(m => console.log(m.getReactVersions()))"
python3 -c "from tests.utils.version_reader import get_react_versions; print(get_react_versions())"
./scripts/read_versions.sh get_react_versions all

# Test version switching
make react-19.0
make current-version
```

### Phase 2 Testing
```bash
# Test Makefile
make help
make react-19.0
make start
make status
make stop
make test-smoke
```

### Phase 3 Testing
```bash
# Test workflows locally (optional - requires act tool)
act -l
act push

# Or push to test branch and check GitHub Actions
git checkout -b test-ci
git push origin test-ci
# Check GitHub Actions tab
```

---

## Estimated Total Time: 30.5 hours

**Breakdown:**
- Phase 1 (CI/CD): 8-10 hours
- Phase 2 (Version Centralization): 11.5 hours
- Phase 3 (Makefile Refactoring): 11 hours

**Recommended Timeline:** 3 weeks (1 week per phase)

---

**See [Full Implementation Plan](IMPLEMENTATION_PLAN_VERSION_CENTRALIZATION_CI.md) for detailed instructions.**

**See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for detailed Phase 1 implementation guide.**

**See [Complete CI/CD Implementation Plan](CI_CD_COMPLETE_PLAN.md) for detailed Phase 1 implementation guide.**
