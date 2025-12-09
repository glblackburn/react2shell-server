# BUG-2: Missing pytest Option Registration After Refactoring

**Status:** Fixed  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-08  
**Fixed:** 2025-12-08

**Description:**
After the DRY refactoring (Phase 3), all test execution fails with `ValueError: no option named '--update-baseline'`. The error occurs in `tests/conftest.py` line 65 when `pytest_configure` tries to access the `--update-baseline` option that was moved to `plugins/performance.py` during refactoring.

**Error Message:**
```
ValueError: no option named '--update-baseline'
```

**Stack Trace:**
```
File "/Users/lblackb/data/lblackb/git/react2shell-server/tests/conftest.py", line 65, in pytest_configure
    if config.getoption("--update-baseline"):
File "/Users/lblackb/data/lblackb/git/react2shell-server/venv/lib/python3.13/site-packages/_pytest/config/__init__.py", line 1897, in getoption
    raise ValueError(f"no option named {name!r}") from e
```

**Steps to Reproduce:**
1. Run any test command:
   ```bash
   make test-parallel
   # or
   make test
   # or
   pytest tests/
   ```
2. Error occurs immediately during pytest configuration phase
3. All tests fail to run

**Expected Behavior:**
- Tests should run successfully
- `--update-baseline` option should be available when accessed in `pytest_configure`
- Performance tracking should work correctly

**Actual Behavior:**
- All test execution fails with `ValueError`
- No tests can run
- Both non-version-switch tests and version-switch tests fail
- Error occurs in both parallel and sequential test execution

**Root Cause:**
During Phase 3 refactoring, the `pytest_addoption` function that registers `--update-baseline` was moved from `conftest.py` to `plugins/performance.py`. However, `pytest_configure` in `conftest.py` still tries to access this option. The issue is that:

1. `pytest_configure` in `conftest.py` runs and tries to access `--update-baseline` option
2. The `pytest_addoption` in `plugins/performance.py` may not have been called yet, or the plugin registration order causes the option to not be available
3. Pytest raises `ValueError` because the option doesn't exist in the namespace

**Environment:**
- Python Version: 3.13.7
- pytest Version: Latest (from requirements.txt)
- OS: macOS (darwin 24.6.0)
- Test Command: `make test-parallel`, `make test`, or direct pytest invocation

**Files Affected:**
- `tests/conftest.py` - Line 65: `if config.getoption("--update-baseline"):`
- `tests/plugins/performance.py` - Contains `pytest_addoption` for `--update-baseline` (if present)

**Impact:**
- **Critical:** All test execution is blocked
- Cannot run any tests until this is fixed
- Affects all test targets: `test`, `test-parallel`, `test-smoke`, etc.
- Blocks CI/CD pipelines

**Solution Implemented:**
1. ✅ Added `pytest_addoption` function to `plugins/performance.py` to register `--update-baseline` option
2. ✅ The option is now properly registered when the performance plugin is imported
3. ✅ `pytest_configure` in `conftest.py` can now safely access the option

**Files Modified:**
- `tests/plugins/performance.py` - Added `pytest_addoption` function to register `--update-baseline` option

**Verification:**
✅ Fix verified - The `--update-baseline` option is now properly registered and accessible in `pytest_configure`

**Additional Notes:**
- This was a regression introduced during the refactoring (Phase 3: File Reorganization)
- The refactoring moved performance tracking code to `plugins/performance.py` but the `pytest_addoption` function was not included
- The fix ensures the option is registered before `pytest_configure` tries to access it
