# Test Execution Targets Verification Plan

**Date:** 2025-12-19  
**Purpose:** Comprehensive verification of all test execution make targets  
**Note:** This will take significant time - tests require servers, browsers, and execution time

---

## Instructions

Run all test execution make targets that were not tested in the initial verification. Save all output to a dated folder in `/tmp/` (similar to previous verification work). Do not make any changes or fixes - only save output and analyze results. Document all findings in a comprehensive report.

---

## Test Execution Targets to Verify

### Test Setup and Cleanup (2 targets)
- `test-setup` - Set up Python virtual environment and install test dependencies (now includes driver installation)
- `test-clean` - Clean test artifacts (reports, screenshots, cache)

### Driver Management (4 targets) - NEW
- `test-driver-install` - Install and cache browser drivers (avoids network downloads)
- `test-driver-status` - Check driver cache status
- `test-driver-clean` - Clean driver cache
- `test-driver-upgrade` - Upgrade drivers (clean and reinstall)

### Basic Test Execution (5 targets)
- `test` - Run all tests (starts servers if needed)
- `test-quick` - Run all tests quickly (headless, no report)
- `test-parallel` - Run tests in parallel (10 workers, faster execution)
- `test-report` - Run all tests and generate HTML report
- `test-smoke` - Run only smoke tests

### Specific Test Suites (4 targets)
- `test-hello` - Run hello world button tests
- `test-version` - Run version information tests
- `test-security` - Run security status tests
- `test-version-switch` - Run version switch tests (tests all React versions, slower)

### Scanner Tests (2 targets)
- `test-scanner` - Run scanner verification tests (requires external scanner)
- `test-scanner-script` - Run scanner verification script (standalone)

### Browser-Specific Tests (1 target)
- `test-browser` - Run tests with specific browser (use BROWSER=chrome|firefox|safari)

### Test Utilities (2 targets)
- `test-open-report` - Open test report in browser
- `test-clean` - Clean test artifacts (already tested, but verify again)

**Total: 20 test execution targets** (16 original + 4 driver management)

---

## Execution Plan

### Phase 1: Preparation

1. **Create Output Directory**
   - Create dated folder: `/tmp/test-execution-verification-YYYY-MM-DD-HHMMSS/`
   - Format: `/tmp/test-execution-verification-2025-12-19-130000/` (example)
   - Create subdirectories:
     - `output/` - All command stdout/stderr
     - `files-before/` - File system state before each target
     - `files-after/` - File system state after each target
     - `logs/` - Server logs, test logs
     - `reports/` - Test reports (HTML, JSON, etc.)
     - `artifacts/` - Screenshots, performance data, etc.
     - `summary/` - Summary files and analysis

2. **Document Initial State**
   - Check test environment status
   - Verify Python virtual environment exists
   - Check if servers are running
   - Document current framework mode
   - Document current React/Next.js version

3. **Verify Prerequisites**
   - Python virtual environment available
   - Test dependencies installed
   - Browser drivers should be installed via `test-driver-install` (avoids network downloads)
   - External scanner path (if available for scanner tests)

4. **Install Browser Drivers**
   - Run `test-driver-install` to cache drivers before tests
   - Verify drivers are cached with `test-driver-status`
   - This ensures no network downloads during test execution

### Phase 2: Driver Management (NEW)

**Sequence:**
1. `test-driver-status` - Check current driver cache status
2. `test-driver-install` - Install and cache browser drivers
3. `test-driver-status` - Verify drivers are cached
4. (Optional) `test-driver-clean` - Test clean functionality
5. (Optional) `test-driver-upgrade` - Test upgrade functionality

**What to Capture:**
- Driver cache status before/after
- Driver installation output
- Cache directory location (`~/.wdm`)
- Any errors or warnings
- Verification that drivers are cached

**Note:** `test-setup` now automatically runs `test-driver-install`, so drivers will be installed during Phase 3.

### Phase 3: Test Setup and Cleanup

**Sequence:**
1. `test-clean` - Start with clean state
2. `test-setup` - Ensure test environment is set up (includes driver installation)
3. Verify setup completed successfully
4. `test-driver-status` - Verify drivers are cached after setup

**What to Capture:**
- Virtual environment creation/verification
- Dependency installation output
- Driver installation output (from test-setup dependency)
- Any errors or warnings
- File system changes (venv/, node_modules/, ~/.wdm/, etc.)

### Phase 4: Basic Test Execution

**Prerequisites:**
- Test environment set up
- Servers may need to be running (targets will start if needed)

**Sequence:**
1. `test-smoke` - Quick smoke tests first
2. `test-quick` - Quick test run (headless)
3. `test` - Full test run
4. `test-parallel` - Parallel test execution
5. `test-report` - Generate HTML report

**What to Capture:**
- Test execution output
- Test results (pass/fail counts)
- Execution time
- Any test failures
- Generated test reports
- Screenshots (if any)
- Performance data

**Expected Duration:**
- `test-smoke`: ~1-2 minutes
- `test-quick`: ~3-5 minutes
- `test`: ~5-10 minutes
- `test-parallel`: ~3-7 minutes
- `test-report`: ~5-10 minutes

**Total Estimated Time:** ~20-35 minutes

### Phase 5: Specific Test Suites

**Prerequisites:**
- Test environment set up
- Servers running (targets will start if needed)

**Sequence:**
1. `test-hello` - Hello world button tests
2. `test-version` - Version information tests
3. `test-security` - Security status tests
4. `test-version-switch` - Version switch tests (SLOW - tests all React versions)

**What to Capture:**
- Test execution output for each suite
- Test results
- Any failures specific to each suite
- Version switching behavior (for test-version-switch)

**Expected Duration:**
- `test-hello`: ~1-2 minutes
- `test-version`: ~1-2 minutes
- `test-security`: ~2-3 minutes
- `test-version-switch`: ~5-15 minutes (switches multiple React versions)

**Total Estimated Time:** ~10-25 minutes

### Phase 6: Scanner Tests

**Prerequisites:**
- External scanner available (may not be available)
- Test environment set up
- Servers running

**Sequence:**
1. `test-scanner-script` - Standalone scanner script
2. `test-scanner` - Scanner verification tests

**What to Capture:**
- Scanner availability check
- Scanner execution output
- Results (if scanner available)
- Error messages (if scanner not available - expected)

**Expected Duration:**
- `test-scanner-script`: ~1-2 minutes (or fails quickly if scanner not available)
- `test-scanner`: ~2-5 minutes (or fails quickly if scanner not available)

**Total Estimated Time:** ~3-7 minutes (or ~1 minute if scanner not available)

### Phase 7: Browser-Specific Tests

**Prerequisites:**
- Test environment set up
- Browser drivers available
- Servers running

**Sequence:**
1. `test-browser BROWSER=chrome` - Chrome browser tests
2. `test-browser BROWSER=firefox` - Firefox browser tests (if available)
3. `test-browser BROWSER=safari` - Safari browser tests (if available on macOS)

**What to Capture:**
- Browser-specific test execution
- Browser driver initialization
- Test results per browser
- Any browser-specific issues

**Expected Duration:**
- Per browser: ~3-5 minutes
- Total: ~9-15 minutes (if all browsers available)

**Total Estimated Time:** ~9-15 minutes

### Phase 8: Test Utilities

**Prerequisites:**
- Test report generated (from test-report target)

**Sequence:**
1. `test-open-report` - Open test report in browser (may require manual interaction)

**What to Capture:**
- Report file location
- Browser opening attempt
- Any errors

**Expected Duration:** ~10-30 seconds

### Phase 9: Cleanup and Verification

**Sequence:**
1. `test-clean` - Final cleanup
2. Verify cleanup completed
3. Document final state

---

## Output Storage

### Directory Structure

All output will be saved to:
```
/tmp/test-execution-verification-YYYY-MM-DD-HHMMSS/
├── output/                    # All command stdout/stderr
│   ├── TARGET_NAME-stdout.txt
│   ├── TARGET_NAME-stderr.txt
│   ├── TARGET_NAME-combined.txt
│   ├── TARGET_NAME-exitcode.txt
│   └── TARGET_NAME-metadata.txt
├── files-before/             # File system state before each target
│   ├── TARGET_NAME-files-before.txt
│   ├── TARGET_NAME-processes-before.txt
│   └── TARGET_NAME-state-before.txt
├── files-after/              # File system state after each target
│   ├── TARGET_NAME-files-after.txt
│   ├── TARGET_NAME-processes-after.txt
│   ├── TARGET_NAME-state-after.txt
│   └── TARGET_NAME-file-diff.txt
├── logs/                      # Server logs, test logs
│   ├── TARGET_NAME-vite.log
│   ├── TARGET_NAME-server.log
│   └── TARGET_NAME-test.log
├── reports/                   # Test reports
│   ├── TARGET_NAME-test-report.html
│   ├── TARGET_NAME-screenshots/
│   ├── TARGET_NAME-performance/
│   └── TARGET_NAME-test-analysis.txt
├── artifacts/                 # Test artifacts
│   ├── TARGET_NAME-screenshots/
│   ├── TARGET_NAME-performance-data.json
│   └── TARGET_NAME-test-artifacts/
└── summary/                   # Summary files and analysis
    ├── TARGET_NAME-verification.txt
    ├── TARGET_NAME-issues.txt
    ├── all-targets-summary.txt
    └── final-report-data.txt
```

### Key Files to Capture

**Test Reports:**
- HTML test reports from `test-report` target
- JSON test results (if generated)
- Screenshots from test failures
- Performance history data

**Test Artifacts:**
- Screenshots (in `tests/reports/` or framework-specific locations)
- Performance data (in `tests/.performance_history/`)
- Test cache files
- Coverage reports (if generated)

**Logs:**
- Server logs (`.logs/vite.log`, `.logs/server.log`)
- Test execution logs
- Browser driver logs
- Pytest logs

---

## Execution Strategy

### Approach

1. **Start with Clean State**
   - Run `test-clean` first
   - Ensure no leftover test artifacts

2. **Install and Cache Drivers**
   - Run `test-driver-install` to cache drivers
   - Verify drivers are cached (no network downloads during tests)
   - This is critical to avoid timeout issues

3. **Set Up Test Environment**
   - Run `test-setup` if needed (now includes driver installation)
   - Verify virtual environment exists
   - Verify test dependencies installed
   - Verify drivers are cached

4. **Run Tests in Logical Order**
   - Quick tests first (smoke, quick)
   - Full test runs
   - Specific test suites
   - Browser-specific tests
   - Scanner tests (may fail if scanner not available)

5. **Capture Everything**
   - All stdout/stderr
   - All generated files
   - All test reports
   - All screenshots
   - All performance data

6. **Allow Servers to Start Automatically**
   - Test targets will start servers if needed
   - Capture server startup logs
   - Verify servers are running

### Success Criteria

- All test targets execute (even if some fail due to missing dependencies)
- All output captured and saved
- Test reports generated and saved
- Screenshots captured (if any)
- Performance data captured (if any)
- Complete analysis of results

### Expected Behaviors

**Expected Failures (Not Bugs):**
- `test-scanner` - May fail if external scanner not available (expected)
- `test-scanner-script` - May fail if external scanner not available (expected)
- `test-browser BROWSER=firefox` - May fail if Firefox driver not available
- `test-browser BROWSER=safari` - May fail if Safari driver not available

**Expected Success:**
- `test-driver-install` - Should succeed (downloads and caches drivers)
- `test-driver-status` - Should succeed (shows cache status)
- `test-setup` - Should succeed (includes driver installation)
- `test-clean` - Should succeed
- `test-smoke` - Should succeed
- `test-quick` - Should succeed
- `test` - Should succeed
- `test-parallel` - Should succeed
- `test-report` - Should succeed
- `test-hello` - Should succeed
- `test-version` - Should succeed
- `test-security` - Should succeed
- `test-version-switch` - Should succeed (but slow)
- `test-open-report` - Should succeed if report exists

---

## Analysis Requirements

### For Each Test Target

1. **Execution Analysis:**
   - Exit code
   - Execution time
   - Output patterns
   - Error messages (if any)

2. **Test Results Analysis:**
   - Number of tests run
   - Number of tests passed
   - Number of tests failed
   - Test execution time
   - Any test failures and reasons

3. **File Generation Analysis:**
   - Test reports generated
   - Screenshots captured
   - Performance data generated
   - Log files created
   - Any other artifacts

4. **Server Management Analysis:**
   - Did servers start automatically?
   - Server startup time
   - Server logs
   - Any server errors

5. **Browser Analysis (for browser tests):**
   - Browser driver initialization
   - Browser-specific issues
   - Screenshots per browser
   - Test results per browser

### Overall Analysis

1. **Test Suite Health:**
   - Overall pass rate
   - Common failure patterns
   - Performance trends
   - Flaky tests (if any)

2. **Framework Compatibility:**
   - Tests work in Vite mode
   - Tests work in Next.js mode
   - Framework-specific issues

3. **Version Switching Tests:**
   - All React versions tested successfully
   - Version switching works correctly
   - Tests pass for all versions

4. **Performance Analysis:**
   - Test execution times
   - Parallel execution benefits
   - Slowest tests identified
   - Performance regressions (if any)

---

## Estimated Total Time

### Conservative Estimate

- Driver management: ~2-5 minutes (first time download, cached after)
- Test setup: ~2-3 minutes (includes driver installation)
- Basic test execution: ~20-35 minutes
- Specific test suites: ~10-25 minutes
- Scanner tests: ~3-7 minutes (or ~1 minute if not available)
- Browser tests: ~9-15 minutes
- Test utilities: ~1 minute
- Cleanup: ~1 minute

**Total: ~47-90 minutes** (approximately 1-1.5 hours)

**Note:** Driver installation adds ~2-5 minutes on first run, but subsequent runs use cached drivers (no download time).

### Factors Affecting Duration

- Number of tests in suite
- Server startup time
- Browser driver initialization
- Network latency (if any)
- System performance
- Parallel execution efficiency

---

## Helper Script

Use the project's test execution helper script:
- **Location:** `scripts/run_test_target.sh`
- **Documentation:** See [scripts/README.md](../scripts/README.md)
- **Features:**
  - Captures all output (stdout/stderr separately)
  - Saves file states before/after
  - Records running processes
  - Saves metadata (exit code, duration, timestamps)
  - **Special handling:** Automatically waits for background processes when running `test-parallel`

**Usage:**
```bash
OUTPUT_DIR="/tmp/test-execution-verification-$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"/{files-before,files-after,output,reports,artifacts}

./scripts/run_test_target.sh <TARGET_NAME> "$OUTPUT_DIR"
```

### Adaptations for Test Targets

For test targets that require parameters:
- `test-browser BROWSER=chrome` - Pass as: `test-browser BROWSER=chrome`
- May need to modify helper script to handle parameters

---

## Report Structure

The final report should include:

1. **Executive Summary**
   - Total test targets tested
   - Success/failure counts
   - Overall test suite health
   - Key findings

2. **Detailed Results by Category**
   - Test setup results
   - Basic test execution results
   - Specific test suite results
   - Scanner test results
   - Browser test results
   - Test utility results

3. **Test Results Analysis**
   - Pass/fail rates
   - Test execution times
   - Common failure patterns
   - Performance analysis

4. **File Generation Analysis**
   - Test reports generated
   - Screenshots captured
   - Performance data
   - Log files

5. **Issues Found**
   - Test failures
   - Missing dependencies
   - Configuration issues
   - Performance issues

6. **Recommendations**
   - Test improvements
   - Configuration updates
   - Performance optimizations

---

## Notes

- **No Code Changes:** Only capture output and analyze
- **Allow Time:** Tests will take significant time - this is expected
- **Save Everything:** Capture all output, reports, screenshots, logs
- **Document Dependencies:** Note any missing dependencies (scanner, browsers)
- **Framework Mode:** Tests should work in both Vite and Next.js modes
- **Server Management:** Let targets start servers automatically
- **Clean State:** Start with clean test artifacts

---

## Prerequisites Check

Before starting, verify:

- [ ] Python virtual environment can be created/accessed
- [ ] Test dependencies can be installed
- [ ] Browser drivers will be installed via `test-driver-install` (avoids network downloads during tests)
- [ ] Network available for initial driver download (only needed once)
- [ ] Sufficient disk space for test artifacts and driver cache (~/.wdm)
- [ ] Time available for full test execution (~1-1.5 hours)

---

## Output Document

The final report will be saved to:
`docs/TEST_EXECUTION_VERIFICATION_REPORT.md`

The report will reference the output directory for detailed logs, reports, and artifacts.

---

**Status:** Plan documented, ready for execution  
**Estimated Duration:** ~45-85 minutes  
**Output Location:** `/tmp/test-execution-verification-YYYY-MM-DD-HHMMSS/`
