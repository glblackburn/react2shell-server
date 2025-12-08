# Python Selenium Tests

This directory contains Selenium-based end-to-end tests for the React2Shell Server application, written in Python using pytest.

## Framework Choice: pytest

We use **pytest** as our testing framework. See [TESTING_PLAN.md](../TESTING_PLAN.md) for framework comparison and rationale.

**Key benefits:**
- Most popular Python testing framework
- Excellent Selenium integration
- Rich plugin ecosystem
- Clean, readable syntax
- Powerful fixtures system
- Great reporting capabilities

## Setup

### Quick Setup (Recommended)

```bash
# Set up test environment (creates venv and installs dependencies)
make test-setup
```

### Manual Setup

**1. Install Python Dependencies:**
```bash
python3 -m venv venv
source venv/bin/activate  # Mac/Linux
# or venv\Scripts\activate  # Windows
pip install -r tests/requirements.txt
```

**2. Browser Drivers:**
Tests use `webdriver-manager` which automatically downloads and manages browser drivers. No manual installation needed!

**3. Start Application Servers:**
```bash
make start  # Or manually: npm run dev & npm run server
```

> **Note:** Test fixtures automatically start/stop servers if needed, but manual startup is recommended for development.

## Running Tests

### Using Makefile (Recommended)

```bash
make test          # Run all tests
make test-quick    # Quick run (headless)
make test-report   # Generate HTML report
make test-smoke    # Run smoke tests only
make test-hello    # Run hello world tests
make test-version  # Run version info tests
make test-security # Run security status tests
```

See main [README.md](../README.md#testing) for all Makefile test commands.

### Direct pytest Commands

```bash
# Run all tests
pytest tests/

# Run specific test suite
pytest tests/test_suites/test_hello_world.py

# Run specific test
pytest tests/test_suites/test_hello_world.py::TestHelloWorldButton::test_button_click_displays_message

# Common options
pytest -v                          # Verbose output
pytest -s                          # Show print statements
pytest -n 4                        # Parallel execution (4 workers)
pytest --browser=chrome            # Specific browser
pytest --headless=false            # Visible browser
pytest --html=reports/report.html --self-contained-html  # HTML report
pytest --reruns=2 --reruns-delay=1 # Retry on failure
pytest -m smoke                    # Run only smoke tests
```

## Test Structure

```
tests/
├── conftest.py              # Pytest fixtures and configuration
├── pytest.ini              # Pytest settings
├── requirements.txt        # Python dependencies
├── pages/                  # Page Object Model
│   ├── base_page.py        # Base page class
│   └── app_page.py         # Application page
├── test_suites/            # Test files
│   ├── test_hello_world.py
│   ├── test_version_info.py
│   └── test_security_status.py
└── utils/                  # Utilities
    └── server_manager.py   # Server management
```

## Test Markers

Tests are organized with markers:

- `@pytest.mark.smoke` - Critical smoke tests (timeout: 10s)
- `@pytest.mark.regression` - Regression tests
- `@pytest.mark.version_switch` - Tests that switch React versions (timeout: 120s)
- `@pytest.mark.slow` - Slow tests (timeout: 60s)
- `@pytest.mark.browser_chrome` - Chrome-specific tests
- `@pytest.mark.browser_firefox` - Firefox-specific tests

## Test Time Limits

Test time limits are automatically enforced to prevent tests from running too long. Limits are configured in `tests/performance_config.yaml`:

**Priority Order:**
1. **Individual test limit** (if configured) - Each test can have its own limit
2. **Marker-based limit** - Based on test markers (smoke: 10s, slow: 60s, version_switch: 120s)
3. **Default limit** - 7s for tests without specific markers

**Viewing Limits:**
- Individual limits are shown in the performance report (highlighted in blue/bold)
- Run `make test-performance-report` to see all limits
- Limits are calculated with 10% buffer above max observed time

**Setting Limits:**
- Edit `tests/performance_config.yaml` to manually set limits
- Or collect performance data and let the system calculate limits automatically
- See [PERFORMANCE_TRACKING.md](PERFORMANCE_TRACKING.md) for details

## Reports

### Test Execution Reports

Test reports are generated in the `reports/` directory:

- `reports/report.html` - HTML test report (pytest-generated)
- `reports/YYYY-MM-DD_HH-MM-SS/` - Timestamped reports for parallel test runs
- `reports/screenshots/` - Screenshots on test failures

### Performance Reports

Generate comprehensive performance history reports:

```bash
make test-performance-report  # Generate and open HTML performance report
```

The performance report includes:
- Recent test runs summary
- Suite performance trends with limits
- Slowest tests with individual limits
- Performance trends over time
- Baseline comparison

Reports are saved to `tests/reports/performance_history_report.html` and automatically open in your browser.

## Writing New Tests

### 1. Create Test File

Create a new test file in `tests/test_suites/`:

```python
import pytest
from pages.app_page import AppPage

class TestMyFeature:
    def test_my_feature(self, app_page):
        # Your test code here
        assert app_page.is_element_visible(...)
```

### 2. Use Page Object Model

Always use the Page Object Model for maintainability:

```python
# Good - uses page object
app_page.click_hello_button()

# Bad - direct WebDriver calls
driver.find_element(By.CLASS_NAME, "big-red-button").click()
```

### 3. Use Fixtures

Leverage pytest fixtures:

- `driver` - WebDriver instance
- `app_page` - AppPage instance (already navigated)
- `start_servers` - Server lifecycle management

## Best Practices

1. **Use Page Object Model** - Keep test logic separate from page logic
2. **Use Explicit Waits** - Never use `time.sleep()` for waiting
3. **Keep Tests Independent** - Each test should work in isolation
4. **Use Meaningful Assertions** - Clear error messages
5. **Take Screenshots on Failure** - Already configured in conftest.py
6. **Use Markers** - Organize tests with markers
7. **Clean Up** - Fixtures handle cleanup automatically

## Troubleshooting

### Tests Fail with "Server not ready"

Make sure servers are running:
```bash
make status
make start
```

### Browser Driver Issues

The tests use `webdriver-manager` which should handle drivers automatically. If you have issues:

1. Check browser is installed
2. Try updating webdriver-manager: `pip install --upgrade webdriver-manager`
3. Manually install browser drivers

### Port Already in Use

If ports 5173 or 3000 are in use:
```bash
make stop
# Or manually kill processes
lsof -ti:5173 | xargs kill
lsof -ti:3000 | xargs kill
```

### Import Errors

Make sure you're running from the project root or have the correct Python path:
```bash
# From project root
pytest tests/
```

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Selenium Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install Node dependencies
        run: npm install
      - name: Install Python dependencies
        run: pip install -r tests/requirements.txt
      - name: Start servers
        run: make start
      - name: Run tests
        run: pytest tests/ --html=reports/report.html
      - name: Upload report
        uses: actions/upload-artifact@v3
        with:
          name: test-report
          path: reports/report.html
```

## Quick Reference

- **[Quick Start Guide](QUICKSTART.md)** - Get started in 5 minutes
- **[Testing Plan](../TESTING_PLAN.md)** - Complete testing strategy
- **[Main README](../README.md#testing)** - Project overview and testing section

## Resources

- [pytest Documentation](https://docs.pytest.org/)
- [Selenium Python Documentation](https://selenium-python.readthedocs.io/)
- [Page Object Model Pattern](https://selenium-python.readthedocs.io/page-objects.html)
