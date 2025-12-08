# Quick Start Guide - Python Selenium Tests

Get started with testing in 5 minutes using **pytest** framework.

## Quick Setup

```bash
# 1. Set up test environment (first time only)
make test-setup

# 2. Run all tests (auto-starts servers)
make test

# 3. View test report
make test-report
make test-open-report
```

## Common Commands

```bash
# Quick test run
make test-quick

# Run specific test suites
make test-hello      # Hello World button tests
make test-version    # Version information tests
make test-security  # Security status tests

# Run with specific browser
make test-browser BROWSER=chrome

# Generate performance report
make test-performance-report  # Comprehensive HTML report with metrics and limits
```

## Example Test

```python
import pytest

@pytest.mark.smoke
def test_button_click_displays_message(app_page):
    """Test that clicking button displays 'Hello World!' message."""
    app_page.click_hello_button()
    message = app_page.get_message(timeout=10)
    assert message == "Hello World!"
```

## Next Steps

- **[Complete Testing Guide](README.md)** - Detailed documentation, setup, troubleshooting
- **[Testing Plan](../TESTING_PLAN.md)** - Testing strategy and implementation plan
- **Test Examples** - See `test_suites/` directory for example tests
