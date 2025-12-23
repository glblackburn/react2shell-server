# Comparison: `make test-smoke` vs `simple-run-check.sh`

**Date:** 2025-12-22  
**Purpose:** Analyze and compare what `make test-smoke` and `simple-run-check.sh` execute, create, and test  
**Related:** See [TEST_SCRIPT_MIGRATION_PLAN.md](TEST_SCRIPT_MIGRATION_PLAN.md) for migration plan to standardize `simple-run-check.sh`

---

## Executive Summary

| Aspect | `make test-smoke` | `simple-run-check.sh` |
|--------|-------------------|----------------------|
| **Type** | Python pytest test suite | Bash script |
| **Purpose** | UI/API smoke tests for current version | Version switching verification |
| **Versions Tested** | 1 (current) | 11 (all Next.js versions) |
| **Test Scope** | UI elements, API responses, version info | Version switching + API verification |
| **Dependencies** | Python, pytest, selenium, webdriver | make, curl, jq |
| **Output** | Test report (HTML/console) | Text output with JSON responses |

---

## Detailed Comparison

### 1. What Each Command Executes

#### `make test-smoke`

**Execution Flow:**
1. Checks Python virtual environment (`check-venv`)
2. Checks if servers are running on ports 5173 and 3000
3. If servers not running:
   - Runs `make start` (starts both Vite and Next.js servers)
   - Waits 3 seconds
4. Runs pytest with smoke marker: `pytest tests/ -m smoke -v`

**What it runs:**
- Python pytest test suite
- Tests marked with `@pytest.mark.smoke`
- Uses Selenium WebDriver for browser automation
- Tests against currently running server (doesn't switch versions)

#### `simple-run-check.sh`

**Execution Flow:**
1. Stops any running servers: `make stop`
2. Extracts all Next.js versions from Makefile help output
3. For each Next.js version:
   - Switches to version: `make nextjs-{version}`
   - Starts server: `make start`
   - Tests API: `curl http://localhost:3000/api/version | jq`
   - Stops server: `make stop`

**What it runs:**
- Bash script with make commands
- Tests all 11 Next.js versions sequentially
- Uses curl for HTTP requests (no browser)
- Switches versions between tests

---

### 2. What Each Command Tests

#### `make test-smoke` Tests

**Test Files Executed:**
1. `test_version_info.py` (8 tests)
   - Version info card visibility
   - Version title display
   - Version info loads successfully
   - Contains React version
   - Contains React-DOM version
   - Contains Node.js version
   - Contains status (VULNERABLE/FIXED)
   - Loading indicator behavior
   - Retry logic

2. `test_hello_world.py` (7 tests)
   - Button visibility
   - Button text correctness
   - Button enabled state
   - Button click displays message
   - Button loading state
   - Multiple clicks
   - Message appears after click

3. `test_nextjs_version_api.py` (5 tests)
   - All Next.js versions start and respond (if in Next.js mode)
   - Version API returns correct version (parametrized for each version)
   - Version API structure validation
   - Server ready check
   - API endpoint verification

**Total Tests:** ~20 tests (varies based on framework mode)

**What it verifies:**
- ✅ UI elements are visible and functional
- ✅ Version information displays correctly
- ✅ Hello World button works
- ✅ API endpoints respond correctly
- ✅ Version API structure is valid
- ✅ Server readiness

**Limitations:**
- Tests only the **currently active** Next.js version
- Requires Next.js mode to be set (`make use-nextjs`)
- Some tests skip if not in Next.js mode
- Requires browser automation (slower)

#### `simple-run-check.sh` Tests

**What it verifies:**
- ✅ All 11 Next.js versions can be switched to
- ✅ Each version starts successfully
- ✅ Version API responds for each version
- ✅ API returns correct version number
- ✅ Servers stop cleanly between versions

**Test Coverage:**
- Tests all versions: 14.0.0, 14.1.0, 15.0.4, 15.1.8, 15.2.5, 15.3.5, 15.4.7, 15.5.6, 16.0.6, 14.0.1, 14.1.1
- Verifies version switching works end-to-end
- Checks Node.js version switching (if implemented)
- Validates npm installation completes

**Limitations:**
- Only tests API endpoint (`/api/version`)
- No UI testing (no browser)
- No validation of API response structure beyond JSON parsing
- No verification of UI elements
- No testing of button functionality

---

### 3. What Each Command Creates

#### `make test-smoke` Creates

**Files/Directories:**
- Test reports (if configured): `tests/reports/report.html`
- Screenshots (on failure): `tests/reports/screenshots/`
- Performance history (if enabled): `tests/reports/performance_history.json`
- Test artifacts: `.pytest_cache/`, `__pycache__/`

**Processes:**
- Python virtual environment (if not exists)
- Browser process (Chrome/Firefox/Safari via WebDriver)
- Server processes (if not already running)

**State Changes:**
- May start servers if not running
- Leaves servers running after tests (unless cleanup runs)
- May change framework mode (if tests require it)

#### `simple-run-check.sh` Creates

**Files/Directories:**
- Output file: `simple-run-check_YYYY-MM-DD_HHMMSS.txt` (if redirected)
- Temporary npm files during version switches
- `.nvmrc` file (if Node.js version switching is active)

**Processes:**
- Server processes (started and stopped for each version)
- npm install processes (for each version switch)

**State Changes:**
- Stops servers at start
- Switches Next.js versions (modifies `package.json`)
- Starts/stops servers for each version
- Leaves last version active after completion
- May leave servers running (depends on last test)

---

### 4. Key Differences

| Feature | `make test-smoke` | `simple-run-check.sh` |
|---------|-------------------|----------------------|
| **Test Framework** | pytest (Python) | Bash script |
| **Browser Testing** | ✅ Yes (Selenium) | ❌ No |
| **API Testing** | ✅ Yes (requests) | ✅ Yes (curl) |
| **UI Testing** | ✅ Yes | ❌ No |
| **Version Switching** | ❌ No (tests current) | ✅ Yes (all versions) |
| **Version Coverage** | 1 version | 11 versions |
| **Dependencies** | Python, pytest, selenium | make, curl, jq |
| **Speed** | Slower (browser automation) | Faster (HTTP only) |
| **Output Format** | Test report (HTML/console) | Text with JSON |
| **Error Handling** | Detailed test failures | Simple pass/fail |
| **Server Management** | Starts if needed, may leave running | Explicit start/stop per version |
| **Framework Mode** | Requires Next.js mode for some tests | Works in any mode |
| **Node.js Version** | Uses current system version | Switches via nvm (if implemented) |

---

### 5. Overlapping Functionality

**Both commands test:**
- ✅ Version API endpoint (`/api/version`)
- ✅ Server startup capability
- ✅ API response format (JSON)
- ✅ Server readiness

**Both commands use:**
- `make start` to start servers
- `make stop` to stop servers
- HTTP requests to test API

---

### 6. Unique Functionality

#### `make test-smoke` Only:
- ✅ UI element visibility testing
- ✅ Button click functionality
- ✅ Version info card display
- ✅ Loading states
- ✅ Multiple test scenarios per feature
- ✅ Detailed error reporting
- ✅ Screenshot capture on failure
- ✅ Performance tracking
- ✅ Test parametrization

#### `simple-run-check.sh` Only:
- ✅ Tests all 11 Next.js versions
- ✅ Version switching verification
- ✅ Sequential version testing
- ✅ Node.js version switching (if implemented)
- ✅ npm installation verification
- ✅ Simple pass/fail output
- ✅ No browser dependencies

---

### 7. When to Use Each

#### Use `make test-smoke` when:
- Testing UI functionality
- Verifying current version works correctly
- Need detailed test reports
- Testing user interactions (button clicks)
- Need browser-based testing
- Want performance metrics
- Testing in CI/CD with test reports

#### Use `simple-run-check.sh` when:
- Verifying all versions can switch correctly
- Quick check that version switching works
- Testing Node.js version switching
- No browser available
- Need simple pass/fail output
- Testing version compatibility
- Debugging version switching issues

---

### 8. Complementary Usage

**Recommended Workflow:**
1. Run `simple-run-check.sh` first to verify all versions can switch
2. Switch to a specific version: `make nextjs-16.0.6`
3. Run `make test-smoke` to test UI/API for that version
4. Repeat for other versions if needed

**Or:**
1. Run `make test-smoke` to verify current version works
2. Run `simple-run-check.sh` to verify all versions can switch
3. Use both for comprehensive testing

---

### 9. Test Coverage Comparison

| Test Area | `make test-smoke` | `simple-run-check.sh` |
|-----------|-------------------|----------------------|
| Version Switching | ❌ | ✅ |
| All Versions | ❌ | ✅ |
| API Endpoint | ✅ | ✅ |
| API Structure | ✅ | ⚠️ (basic) |
| UI Elements | ✅ | ❌ |
| Button Functionality | ✅ | ❌ |
| Version Info Display | ✅ | ❌ |
| Server Startup | ✅ | ✅ |
| Server Shutdown | ⚠️ (may leave running) | ✅ |
| Node.js Version | ❌ | ✅ (if implemented) |

---

### 10. Output Comparison

#### `make test-smoke` Output:
```
Running smoke tests...
============================= test session starts ==============================
tests/test_suites/test_version_info.py::TestVersionInformation::test_version_info_card_is_visible PASSED
tests/test_suites/test_version_info.py::TestVersionInformation::test_version_title_displayed PASSED
...
============================= 20 passed in 45.23s ==============================
```

#### `simple-run-check.sh` Output:
```
================================================================================
version=[nextjs-14.0.0]: switch
================================================================================
Switching to Next.js 14.0.0 (VULNERABLE - for security testing)...
✓ Switched to Next.js 14.0.0 (VULNERABLE)
================================================================================
version=[nextjs-14.0.0]: start
================================================================================
✓ Started Next.js server (PID: 91109)
================================================================================
version=[nextjs-14.0.0]: curl
================================================================================
{
  "react": "18.3.0",
  "reactDom": "18.3.0",
  "nextjs": "14.0.0",
  "node": "v24.12.0",
  "vulnerable": false,
  "status": "FIXED"
}
================================================================================
version=[nextjs-14.0.0]: stop
================================================================================
✓ Server stopped
```

---

## Recommendations

### For Comprehensive Testing:
1. **Run `simple-run-check.sh`** to verify all versions can switch
2. **Run `make test-smoke`** for each version to test UI/API
3. **Use both** in CI/CD pipeline for complete coverage

### For Quick Verification:
- Use `simple-run-check.sh` for version switching verification
- Use `make test-smoke` for UI/API testing of current version

### For CI/CD:
- `simple-run-check.sh`: Fast version switching verification
- `make test-smoke`: Comprehensive UI/API testing with reports

---

## Conclusion

**`make test-smoke`** and **`simple-run-check.sh`** serve different but complementary purposes:

- **`make test-smoke`**: Comprehensive UI/API testing for current version
- **`simple-run-check.sh`**: Version switching verification across all versions

**Both are needed** for complete test coverage:
- `simple-run-check.sh` ensures all versions can switch correctly
- `make test-smoke` ensures UI and API work correctly for each version

---

**Status:** ✅ Analysis Complete  
**Related Documentation:**
- [TEST_SCRIPT_MIGRATION_PLAN.md](TEST_SCRIPT_MIGRATION_PLAN.md) - Plan to migrate `simple-run-check.sh` to standard `make test-*` pattern

**Last Updated:** 2025-12-22
