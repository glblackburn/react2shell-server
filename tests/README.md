# Python Selenium Tests

This directory contains Selenium-based end-to-end tests for the React2Shell Server application, written in Python using pytest.

## Framework Choice: pytest

We use **pytest** as our testing framework because:
- Most popular Python testing framework
- Excellent Selenium integration
- Rich plugin ecosystem
- Clean, readable syntax
- Powerful fixtures system
- Great reporting capabilities

## Setup

### 1. Install Python Dependencies

```bash
# Create virtual environment (recommended)
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows

# Install test dependencies
pip install -r tests/requirements.txt
```

### 2. Install Browser Drivers

The tests use `webdriver-manager` which automatically downloads and manages browser drivers. No manual installation needed!

However, if you prefer manual installation:
- **Chrome**: Install ChromeDriver from https://chromedriver.chromium.org/
- **Firefox**: Install GeckoDriver from https://github.com/mozilla/geckodriver/releases
- **Safari**: Built-in on macOS (enable in Safari > Develop menu)

### 3. Start the Application Servers

Before running tests, start the application:

```bash
# From project root
make start
```

Or manually:
```bash
npm run dev      # Terminal 1 - Frontend (port 5173)
npm run server   # Terminal 2 - Backend (port 3000)
```

The test fixtures will automatically start/stop servers if needed, but it's recommended to start them manually for development.

## Running Tests

### Run All Tests

```bash
# From project root
pytest tests/

# Or from tests directory
cd tests
pytest
```

### Run Specific Test Suites

```bash
# Hello World button tests
pytest tests/test_suites/test_hello_world.py

# Version information tests
pytest tests/test_suites/test_version_info.py

# Security status tests
pytest tests/test_suites/test_security_status.py
```

### Run Specific Tests

```bash
# Run a specific test
pytest tests/test_suites/test_hello_world.py::TestHelloWorldButton::test_button_click_displays_message
```

### Run with Options

```bash
# Verbose output
pytest -v

# Show print statements
pytest -s

# Run in parallel (4 workers)
pytest -n 4

# Run with specific browser
pytest --browser=chrome
pytest --browser=firefox
pytest --browser=safari

# Run in headed mode (see browser)
pytest --headless=false

# Run with HTML report
pytest --html=reports/report.html --self-contained-html

# Run with retries on failure
pytest --reruns=2 --reruns-delay=1

# Run only smoke tests
pytest -m smoke

# Run only regression tests
pytest -m regression
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

- `@pytest.mark.smoke` - Critical smoke tests
- `@pytest.mark.regression` - Regression tests
- `@pytest.mark.version_switch` - Tests that switch React versions
- `@pytest.mark.browser_chrome` - Chrome-specific tests
- `@pytest.mark.browser_firefox` - Firefox-specific tests

## Reports

Test reports are generated in the `reports/` directory:

- `reports/report.html` - HTML test report
- `reports/screenshots/` - Screenshots on test failures

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

## Resources

- [pytest Documentation](https://docs.pytest.org/)
- [Selenium Python Documentation](https://selenium-python.readthedocs.io/)
- [Page Object Model Pattern](https://selenium-python.readthedocs.io/page-objects.html)
