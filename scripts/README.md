# Scripts Directory

This directory contains utility scripts for test execution, verification, and automation.

## Available Scripts

### Test Execution Utilities

#### `run_test_target.sh`

**Purpose:** Helper script for running make targets and capturing comprehensive output for verification and analysis.

**Usage:**
```bash
./scripts/run_test_target.sh <TARGET_NAME> <OUTPUT_DIR>
```

**Features:**
- Captures stdout and stderr separately
- Records file state before and after execution
- Tracks running processes (node, python, vite, next)
- Saves metadata (exit code, duration, timestamps)
- Copies test reports and screenshots
- **Special handling for `test-parallel`:** Automatically waits for background processes (pytest, run_version_tests_parallel.py) to complete

**Example:**
```bash
OUTPUT_DIR="/tmp/test-verification-$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"/{files-before,files-after,output,reports,artifacts}

./scripts/run_test_target.sh test-parallel "$OUTPUT_DIR"
```

**Output Structure:**
```
OUTPUT_DIR/
├── files-before/
│   ├── <TARGET>-files-before.txt
│   └── <TARGET>-processes-before.txt
├── files-after/
│   ├── <TARGET>-files-after.txt
│   └── <TARGET>-processes-after.txt
├── output/
│   ├── <TARGET>-stdout.txt
│   ├── <TARGET>-stderr.txt
│   ├── <TARGET>-combined.txt
│   └── <TARGET>-metadata.txt
├── reports/
│   └── [HTML reports from tests]
└── artifacts/
    └── [Screenshots and other artifacts]
```

**Background Process Tracking:**
For `test-parallel` target, the script automatically:
- Waits for pytest processes to complete
- Waits for `run_version_tests_parallel.py` to complete
- Reports progress every 30 seconds
- Maximum wait time: 1 hour

**Use Cases:**
- Test execution verification
- Comprehensive test analysis
- Debugging test failures
- Performance analysis
- CI/CD integration

---

### Test Execution Utilities (Advanced)

#### `run_make_test_stop_on_error.sh`

**Purpose:** Run tests with stop-on-first-error behavior for iterative debugging and fix loops.

**Usage:**
```bash
./scripts/run_make_test_stop_on_error.sh [OUTPUT_DIR]
```

**Features:**
- Runs pytest with `-x` flag to stop immediately at first failure
- Captures comprehensive state before and after execution
- Framework-aware (handles both Vite and Next.js modes)
- Automatically starts servers if needed
- Creates timestamped output directory structure
- Captures processes, ports, logs, and test reports
- Exits with code 0 if all tests pass, code 1 if any failure

**Output Structure:**
```
OUTPUT_DIR/
├── output/
│   ├── make-test-live.txt      # Live test output
│   ├── make-test-exitcode.txt  # Exit code
│   ├── make-test-duration.txt  # Execution duration
│   └── test-metadata.txt       # Environment metadata
├── files-before/               # State before execution
├── files-after/                # State after execution
├── logs/                       # Server logs
├── reports/                    # Test reports
└── artifacts/                  # Test artifacts
```

**Use Cases:**
- Iterative test fixing (fix one error at a time)
- Debugging test failures
- Comprehensive test execution analysis
- Following the test fix loop process

**See Also:**
- [Test Fix Plan](../docs/testing/TEST_FIX_PLAN.md) - Detailed iterative fix loop process
- [Test Execution Verification Plan](../docs/testing/TEST_EXECUTION_VERIFICATION_PLAN.md)

---

### Test Verification Scripts

#### `verify_tests.sh`

**Purpose:** Run test suite and verify results, saving output to timestamped log file.

**Usage:**
```bash
./scripts/verify_tests.sh
```

**Features:**
- Runs `make test` with timing
- Saves output to `/tmp/verify_tests_<timestamp>.txt`
- Parses test results for failures
- Checks for pytest failure patterns
- Returns exit code based on test results

**Output:**
- Log file location displayed
- Test summary with pass/fail status
- Exit code: 0 if all tests passed, 1 if failures found

---

### Scanner Verification Scripts

#### `verify_scanner.sh`

**Purpose:** Comprehensive verification of security scanner against multiple Next.js versions.

**Usage:**
```bash
./scripts/verify_scanner.sh [OPTIONS]
```

**Options:**
- `-h` - Display help message
- `-s` - Use safe side-channel detection instead of RCE PoC
- `-a` - Test all versions (default: only vulnerable versions)
- `-q` - Quiet mode (minimal output)
- `-v` - Verbose output

**Features:**
- Tests vulnerable Next.js versions (should detect vulnerability)
- Tests fixed Next.js versions (should NOT detect vulnerability)
- Automatically switches Next.js versions
- Restarts server after version switches
- Validates scanner detection accuracy
- Comprehensive test summary

**Requirements:**
- Project must be in Next.js mode (`make use-nextjs`)
- Scanner must be available at configured path
- Server must be running or will be started automatically

**Example:**
```bash
# Test only vulnerable versions
./scripts/verify_scanner.sh

# Test all versions with safe check
./scripts/verify_scanner.sh -s -a
```

**See Also:**
- [Scanner Verification Usage Guide](../docs/scanner/verify-scanner-usage.md)
- [Scanner Integration Documentation](../docs/scanner/scanner-integration.md)

---

#### `scanner_verification_report.sh`

**Purpose:** Generate comprehensive HTML report from scanner verification results.

**Usage:**
```bash
./scripts/scanner_verification_report.sh
```

**Features:**
- Aggregates scanner verification results
- Generates HTML report
- Opens report in browser automatically

---

### GitHub Token Utilities

#### `test_token_scopes.sh`

**Purpose:** Utility script to test GitHub token scopes and permissions.

**Usage:**
```bash
./scripts/test_token_scopes.sh
```

**Features:**
- Tests if GITHUB_TOKEN is set (checks environment variable or ~/.secure/github-set-token.sh)
- Validates token is valid by calling GitHub API
- Displays token scopes from GitHub API response headers
- Checks for 'repo' scope (required for branch protection API access)
- Provides clear error messages if token is invalid or missing

**Requirements:**
- GITHUB_TOKEN environment variable set, OR
- Token available in ~/.secure/github-set-token.sh

**Example Output:**
```
Testing token scopes...

✅ Token is valid

Token scopes: repo

✅ 'repo' scope is present - should work for branch protection
```

**Use Cases:**
- Debugging GitHub API authentication issues
- Verifying token has correct permissions
- Troubleshooting branch protection validation failures

**See Also:**
- [GitHub Permissions Guide](../docs/scripts/GITHUB_PERMISSIONS_REQUIRED.md)
- [Branch Protection Validation Script](#validate_branch_protection_enforcementsh)

---

### Branch Protection Validation Scripts

#### `validate_branch_protection_enforcement.sh`

**Purpose:** Comprehensive validation that GitHub branch protection is configured and enforced to prevent bypassing CI/CD automation.

**Usage:**
```bash
# Basic validation (configuration check only)
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY_OWNER="your-org"
export GITHUB_REPOSITORY_NAME="react2shell-server"
./scripts/validate_branch_protection_enforcement.sh

# Full validation with enforcement testing
./scripts/validate_branch_protection_enforcement.sh --test-enforcement
```

**Options:**
- `--test-enforcement` - Test actual enforcement by creating test branch/PR
- `--branch BRANCH` - Branch to check (default: main)
- `-h, --help` - Show help message

**Features:**
- Validates branch protection configuration exists
- Checks required pull request reviews are enabled
- Verifies required status checks include CI/CD jobs
- Validates administrators cannot bypass (CRITICAL)
- Checks force pushes and deletions are disabled
- Optionally tests enforcement by creating test branch/PR
- Detects security vulnerabilities in configuration
- Clear pass/fail output with detailed error messages

**What It Validates:**
1. ✅ Branch protection exists and is configured
2. ✅ Required pull request reviews enabled
3. ✅ Required status checks configured (with expected CI/CD checks)
4. ✅ Administrators included (CRITICAL - prevents bypass)
5. ✅ Force pushes disabled
6. ✅ Branch deletion disabled
7. ✅ Optional: Tests enforcement by creating test branch/PR

**Integration:**
- Can be run manually for validation
- Can be added to CI/CD workflow for ongoing validation
- Can be scheduled to run weekly
- Use `--test-enforcement` for comprehensive testing

**Example Output:**
```
========================================
Branch Protection Enforcement Validation
========================================

[1/6] Checking if branch protection is configured...
✓ Branch protection is configured

[2/6] Validating required pull request reviews...
✓ Required PR reviews enabled

[3/6] Validating required status checks...
✓ Required status checks configured

[4/6] Validating administrator enforcement...
✓ Administrators are included in protection

[5/6] Validating force push and deletion restrictions...
✓ Force pushes are disabled
✓ Branch deletion is disabled

✅ PASS: Branch protection is properly configured and enforced
```

**See Also:**
- [Complete CI/CD Implementation Plan](../docs/planning/CI_CD_COMPLETE_PLAN.md)
- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)

---

## Script Development Guidelines

### Best Practices

1. **Error Handling:**
   - Use `set -euET -o pipefail` for strict error handling
   - Check prerequisites before execution
   - Provide clear error messages

2. **Logging:**
   - Save output to timestamped log files in `/tmp/`
   - Use consistent naming: `<script_name>_<timestamp>_<random>.txt`
   - Display log file location to user

3. **Portability:**
   - Detect project root automatically
   - Handle both direct execution and Makefile execution
   - Use relative paths where possible

4. **Documentation:**
   - Include usage information in script comments
   - Document all options and features
   - Provide examples in comments

### Script Template

```bash
#!/usr/bin/env bash
set -euET -o pipefail

script_name=$(basename $0)
script_dir=$(dirname $0)

# Generate timestamp and log file
ts=$(date +%Y-%m-%d_%H%M%S)
temp_file=$(mktemp "/tmp/${script_name%.*}_${ts}_XXXXXX") || exit 1
random_part=$(basename "${temp_file}" | sed "s/${script_name%.*}_${ts}_//")
log_file="/tmp/${script_name%.*}_${ts}_${random_part}.txt"
rm -f "${temp_file}"
touch "${log_file}" || exit 1

# Get project root
if [ -f "Makefile" ] && [ -f "package.json" ]; then
    PROJECT_ROOT="$(pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
fi

# Main script logic here
main() {
    # Your script logic
}

# Execute and log
main 2>&1 | tee "${log_file}"
exit_code=${PIPESTATUS[0]}
exit ${exit_code}
```

---

## Integration with Test Execution

These scripts are designed to work with the test execution framework:

- **`run_test_target.sh`** - Used by test verification plans to capture comprehensive test execution data
- **`verify_tests.sh`** - Quick verification of test suite
- **`verify_scanner.sh`** - Scanner-specific verification (separate from main test suite)

See also:
- [Test Execution Verification Plan](../docs/testing/TEST_EXECUTION_VERIFICATION_PLAN.md)
- [Test Execution Recommendations](../docs/testing/TEST_EXECUTION_RECOMMENDATIONS.md)
- [Test README](../tests/README.md)

---

## Maintenance

When adding new scripts:
1. Add entry to this README
2. Update main [README.md](../README.md) if script is user-facing
3. Follow script template and best practices
4. Test script in both direct execution and Makefile contexts
5. Document all options and usage patterns
