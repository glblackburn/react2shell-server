# Test Suite Revision Plan: Refactor test-smoke

**Date:** 2025-12-20  
**Status:** Planning Document  
**Purpose:** Document the revision plan for `test-smoke` target

---

## Executive Summary

This document outlines the revision plan to refactor the `test-smoke` Makefile target to implement API-based version verification (similar to `simple-run-check.sh`) instead of running UI smoke tests. All current smoke tests will be moved to the main `test` target, and new API-based tests will be created for `test-smoke`.

---

## Current State

### Current `test-smoke` Behavior

**Makefile Target:** `test-smoke` (lines 575-583)

**What it does:**
1. Checks virtual environment exists (`check-venv`)
2. Ensures servers are running (checks ports 5173 and 3000)
3. Runs pytest with smoke marker: `pytest tests/ -m smoke -v`

**Current Tests Run:**
- All tests in `TestHelloWorldButton` class (marked `@pytest.mark.smoke`)
- All tests in `TestVersionInformation` class (marked `@pytest.mark.smoke`)

### Current `simple-run-check.sh` Behavior

**What it does:**
1. Stops any running servers (`make stop`)
2. Loops through all Next.js versions from Makefile:
   - Extracts versions: `make | grep nextjs- | grep Switch | awk '{print $2}'`
   - For each version:
     - Switches to version: `make ${version}`
     - Starts servers: `make start`
     - Curls version API: `curl -s http://localhost:3000/api/version | jq`
     - Stops servers: `make stop`

**Next.js Versions Tested:**
- Vulnerable: 14.0.0, 14.1.0, 15.0.4, 15.1.8, 15.2.5, 15.3.5, 15.4.7, 15.5.6, 16.0.6
- Fixed: 14.0.1, 14.1.1
- **Total: 11 versions**

---

## Proposed Changes

### 1. Move Current Smoke Tests

**Action:** Remove `@pytest.mark.smoke` markers from existing tests and move them to run under the main `test` target.

**Tests to Move:**

#### From `tests/test_suites/test_hello_world.py`:

1. **Class-level marker removal:**
   - Remove `@pytest.mark.smoke` from `TestHelloWorldButton` class (line 9)
   - **All tests in this class will move to main test suite:**
     - `test_button_is_visible` → Keep in `test_hello_world.py` (no marker)
     - `test_button_text_is_correct` → Keep in `test_hello_world.py` (no marker)
     - `test_button_is_enabled` → Keep in `test_hello_world.py` (no marker)
     - `test_button_click_displays_message` → Keep in `test_hello_world.py` (remove individual marker at line 29)
     - `test_button_loading_state` → Keep in `test_hello_world.py` (no marker)
     - `test_button_multiple_clicks` → Keep in `test_hello_world.py` (no marker)
     - `test_message_appears_after_click` → Keep in `test_hello_world.py` (no marker)

2. **Individual test marker removal:**
   - Remove `@pytest.mark.smoke` from `test_button_click_displays_message` method (line 29)

**Destination:** All tests remain in `test_hello_world.py` but will run under `make test` instead of `make test-smoke`.

#### From `tests/test_suites/test_version_info.py`:

1. **Class-level marker removal:**
   - Remove `@pytest.mark.smoke` from `TestVersionInformation` class (line 13)
   - **All tests in this class will move to main test suite:**
     - `test_version_info_card_is_visible` → Keep in `test_version_info.py` (no marker)
     - `test_version_title_displayed` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_loads` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_contains_react_version` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_contains_react_dom_version` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_contains_node_version` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_contains_status` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_loading_indicator` → Keep in `test_version_info.py` (no marker)
     - `test_version_info_retry_logic` → Keep in `test_version_info.py` (no marker)

**Destination:** All tests remain in `test_version_info.py` but will run under `make test` instead of `make test-smoke`.

---

### 2. Create New API-Based Smoke Tests

**Action:** Create a new test file for API-based version verification tests.

**New Test File:** `tests/test_suites/test_nextjs_version_api.py`

**Purpose:** Test that all Next.js versions can start and the version API returns the correct version.

**New Tests to Create:**

#### Test Class: `TestNextJSVersionAPI`

1. **`test_all_nextjs_versions_start_and_respond`**
   - **Purpose:** Verify all Next.js versions can start and API responds
   - **Method:**
     - Loop through all Next.js versions (from Makefile or constants)
     - For each version:
       - Stop servers
       - Switch to version (`make nextjs-{version}`)
       - Start servers (`make start`)
       - Wait for server to be ready
       - Call `/api/version` endpoint
       - Verify response is valid JSON
       - Verify `nextjs` field matches expected version
       - Stop servers
   - **Expected versions to test:**
     - Vulnerable: 14.0.0, 14.1.0, 15.0.4, 15.1.8, 15.2.5, 15.3.5, 15.4.7, 15.5.6, 16.0.6
     - Fixed: 14.0.1, 14.1.1
   - **Marker:** `@pytest.mark.smoke`

2. **`test_nextjs_version_api_returns_correct_version`** (Parameterized)
   - **Purpose:** Verify version API returns correct Next.js version for each version
   - **Method:**
     - Parameterized test with all Next.js versions
     - For each version:
       - Switch to version
       - Start servers
       - Call `/api/version`
       - Assert `nextjs` field equals expected version
       - Stop servers
   - **Parameters:**
     ```python
     @pytest.mark.parametrize("nextjs_version", [
         "14.0.0", "14.1.0", "15.0.4", "15.1.8", "15.2.5",
         "15.3.5", "15.4.7", "15.5.6", "16.0.6",  # Vulnerable
         "14.0.1", "14.1.1"  # Fixed
     ])
     ```
   - **Marker:** `@pytest.mark.smoke`

3. **`test_nextjs_version_api_structure`**
   - **Purpose:** Verify version API returns expected JSON structure
   - **Method:**
     - Switch to a known Next.js version (e.g., 16.0.6)
     - Start servers
     - Call `/api/version`
     - Verify JSON structure contains required fields:
       - `nextjs` (string)
       - `react` (string)
       - `reactDom` or `react_dom` (string)
       - `node` (string)
       - `vulnerable` (boolean)
       - `status` (string: "VULNERABLE" or "FIXED")
   - **Marker:** `@pytest.mark.smoke`

4. **`test_nextjs_version_api_server_ready`**
   - **Purpose:** Verify server is ready before calling API
   - **Method:**
     - Switch to a Next.js version
     - Start servers
     - Wait for server to be ready (check port 3000)
     - Call `/api/version`
     - Verify response is successful (200 status)
   - **Marker:** `@pytest.mark.smoke`

---

### 3. Update Makefile Target

**Current `test-smoke` target (lines 575-583):**
```makefile
test-smoke: check-venv
	@echo "Running smoke tests..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ -m smoke -v
```

**New `test-smoke` target:**
```makefile
test-smoke: check-venv
	@echo "Running Next.js version API smoke tests..."
	@echo "This will test all Next.js versions can start and API returns correct version"
	@# Ensure we're in Next.js mode
	@if ! grep -q '^nextjs' .framework-mode 2>/dev/null; then \
		echo "⚠️  Switching to Next.js mode for version API tests..."; \
		$(MAKE) use-nextjs > /dev/null 2>&1; \
	fi
	@$(PYTEST) $(TEST_DIR)/test_suites/test_nextjs_version_api.py -m smoke -v
```

**Changes:**
- Remove server startup check (tests will manage servers themselves)
- Add framework mode check (ensure Next.js mode)
- Change pytest command to run only the new API test file
- Update help text

---

## Test Migration Summary

### Tests Moving FROM `test-smoke` TO `test`:

| Test File | Test Class | Test Method | Current Location | New Location | Action |
|-----------|------------|-------------|------------------|--------------|--------|
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_is_visible` | Smoke | Main | Remove class marker |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_text_is_correct` | Smoke | Main | Remove class marker |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_is_enabled` | Smoke | Main | Remove class marker |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_click_displays_message` | Smoke | Main | Remove class + method markers |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_loading_state` | Smoke | Main | Remove class marker |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_button_multiple_clicks` | Smoke | Main | Remove class marker |
| `test_hello_world.py` | `TestHelloWorldButton` | `test_message_appears_after_click` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_card_is_visible` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_title_displayed` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_loads` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_contains_react_version` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_contains_react_dom_version` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_contains_node_version` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_contains_status` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_loading_indicator` | Smoke | Main | Remove class marker |
| `test_version_info.py` | `TestVersionInformation` | `test_version_info_retry_logic` | Smoke | Main | Remove class marker |

**Total tests moving:** 16 tests (7 from hello_world, 9 from version_info)

---

### New Tests Being Created:

| Test File | Test Class | Test Method | Purpose | Marker |
|-----------|------------|-------------|---------|--------|
| `test_nextjs_version_api.py` | `TestNextJSVersionAPI` | `test_all_nextjs_versions_start_and_respond` | Verify all versions start and API responds | `@pytest.mark.smoke` |
| `test_nextjs_version_api.py` | `TestNextJSVersionAPI` | `test_nextjs_version_api_returns_correct_version` | Verify API returns correct version (parameterized) | `@pytest.mark.smoke` |
| `test_nextjs_version_api.py` | `TestNextJSVersionAPI` | `test_nextjs_version_api_structure` | Verify API JSON structure | `@pytest.mark.smoke` |
| `test_nextjs_version_api.py` | `TestNextJSVersionAPI` | `test_nextjs_version_api_server_ready` | Verify server ready before API call | `@pytest.mark.smoke` |

**Total new tests:** 4 tests (1 parameterized test will run 11 times = 14 test cases total)

---

## Implementation Details

### New Test File Structure

**File:** `tests/test_suites/test_nextjs_version_api.py`

**Dependencies:**
- `pytest` for testing framework
- `requests` for HTTP API calls (or use `subprocess` to call `curl`)
- `utils.server_manager` for server management
- `utils.framework_detector` for framework mode detection
- `subprocess` for calling Makefile targets

**Test Fixtures Needed:**
- May need custom fixtures for version switching
- Server management fixtures (may reuse existing)

**Version List Source:**
- Option 1: Hardcode list from Makefile constants
- Option 2: Parse from Makefile dynamically
- Option 3: Import from a constants file

**Recommended:** Create `tests/utils/nextjs_version_constants.py` with:
```python
NEXTJS_VULNERABLE_VERSIONS = [
    "14.0.0", "14.1.0", "15.0.4", "15.1.8", "15.2.5",
    "15.3.5", "15.4.7", "15.5.6", "16.0.6"
]

NEXTJS_FIXED_VERSIONS = [
    "14.0.1", "14.1.1"
]

ALL_NEXTJS_VERSIONS = NEXTJS_VULNERABLE_VERSIONS + NEXTJS_FIXED_VERSIONS
```

---

## Benefits of This Change

1. **Faster Execution:** API tests are much faster than Selenium UI tests
2. **Better Coverage:** Tests all 11 Next.js versions, not just current version
3. **Infrastructure Verification:** Verifies server startup and API functionality
4. **Clear Separation:** UI tests in `test`, infrastructure tests in `test-smoke`
5. **Matches Simple Script:** `test-smoke` now matches the behavior of `simple-run-check.sh`

---

## Impact Analysis

### Files to Modify:

1. **`tests/test_suites/test_hello_world.py`**
   - Remove `@pytest.mark.smoke` from class (line 9)
   - Remove `@pytest.mark.smoke` from `test_button_click_displays_message` (line 29)

2. **`tests/test_suites/test_version_info.py`**
   - Remove `@pytest.mark.smoke` from class (line 13)

3. **`Makefile`**
   - Update `test-smoke` target (lines 575-583)
   - Update help text for `test-smoke` (line 170)

### Files to Create:

1. **`tests/test_suites/test_nextjs_version_api.py`**
   - New test file with 4 test methods

2. **`tests/utils/nextjs_version_constants.py`** (optional)
   - Constants file for Next.js version lists

### Documentation to Update:

1. **`tests/README.md`**
   - Update description of `test-smoke`
   - Update test markers section

2. **`README.md`**
   - Update `test-smoke` description in main README

3. **`docs/TEST_EXECUTION_VERIFICATION_PLAN.md`**
   - Update expected behavior for `test-smoke`

---

## Testing Strategy

### After Implementation:

1. **Verify `test-smoke` runs new API tests:**
   ```bash
   make test-smoke
   ```
   - Should run only `test_nextjs_version_api.py` tests
   - Should test all 11 Next.js versions
   - Should complete in < 5 minutes

2. **Verify moved tests still run:**
   ```bash
   make test
   ```
   - Should include all 16 tests that were moved from smoke
   - Should pass all tests

3. **Compare with simple script:**
   ```bash
   ./simple-run-check.sh
   make test-smoke
   ```
   - Both should test same versions
   - Both should verify API responses

---

## Rollback Plan

If issues arise:

1. Revert Makefile changes
2. Re-add `@pytest.mark.smoke` markers to original tests
3. Remove new `test_nextjs_version_api.py` file
4. Keep `simple-run-check.sh` as alternative

---

## Notes

- This change makes `test-smoke` focus on infrastructure/API verification
- UI functionality tests remain in main test suite
- The new API tests are faster and more comprehensive for version verification
- `simple-run-check.sh` can be deprecated after this change, or kept as a quick manual check script

---

**Document Created:** 2025-12-20  
**Status:** Planning - Awaiting Implementation  
**Next Steps:** Implement changes according to this plan
