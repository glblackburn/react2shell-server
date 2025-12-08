# Version Testing Guide

## Overview

The security status tests now **actually switch React versions** during test execution to verify all versions are correctly tested. Previously, tests were parameterized but only ran assertions if the current version matched.

## How It Works

The `react_version` fixture in `conftest.py`:
1. Stops the running servers
2. Switches to the specified React version using `make react-{version}`
3. Restarts the servers
4. Waits for servers to be ready
5. Yields the version string to the test

Tests using this fixture will automatically switch versions before running.

## Running Version Switch Tests

**Critical:** Version switch tests **MUST NOT** run in parallel because they:
- Modify shared state (`package.json`, `node_modules`)
- Stop and restart servers
- Cause race conditions when multiple workers run simultaneously

### Run Version Switch Tests Only (Sequential)

```bash
# Run only version switch tests (sequential, no parallel)
pytest -m version_switch tests/

# Or using Makefile
make test-version-switch  # Specifically for version switch tests
make test-security        # Runs all security tests (includes version switching)
```

### Parallel Test Execution

When using `make test-parallel`:
- Non-version-switch tests run in parallel (4 workers)
- Version switch tests are **automatically excluded** and run sequentially after
- This prevents conflicts and race conditions

### Run All Tests (Version Switch Tests Will Be Slower)

```bash
# Run all tests - version switch tests will run sequentially
pytest tests/

# With parallel (version switch tests excluded from parallel execution)
pytest tests/ -n 4  # Other tests run in parallel, version switch tests run sequentially
```

## Test Coverage

The following versions are now **actually tested** by switching to them:

**Vulnerable Versions:**
- React 19.0
- React 19.1.0
- React 19.1.1
- React 19.2.0

**Fixed Versions:**
- React 19.0.1
- React 19.1.2
- React 19.2.1

## Performance Considerations

Version switch tests are slower because they:
- Stop servers (~1 second)
- Switch React version via `npm install` (~10-30 seconds per version)
- Restart servers (~2-3 seconds)
- Wait for servers to be ready (~2-5 seconds)

**Total time per version:** ~15-40 seconds

**Total time for all 7 versions:** ~2-5 minutes (just for version switching, plus test execution time)

## Markers

- `@pytest.mark.version_switch` - Tests that switch React versions
- `@pytest.mark.slow` - Slow-running tests (includes version switch tests)

## Notes

- Version switch tests do **not** restore the original React version after running
- If you need a specific version, switch manually: `make react-19.1.1`
- In CI/CD, you may want to restore the original version after tests complete
- Version switch tests are automatically excluded from parallel execution when using `pytest-xdist`
