# Quick Start Guide - Python Selenium Tests

## Framework: pytest (Recommended)

**Why pytest?**
- Most popular Python testing framework
- Excellent Selenium integration
- Rich plugin ecosystem
- Clean, readable syntax
- Powerful fixtures system

## Quick Setup (5 minutes)

### 1. Install Python Dependencies

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate  # Mac/Linux
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r tests/requirements.txt
```

### 2. Start the Application

```bash
# From project root
make start
```

### 3. Run Your First Test

```bash
# Run all tests
pytest tests/

# Run a specific test
pytest tests/test_suites/test_hello_world.py::TestHelloWorldButton::test_button_click_displays_message

# Run with browser visible (not headless)
pytest --headless=false tests/

# Run with HTML report
pytest --html=reports/report.html --self-contained-html tests/
```

## What Was Created

### Test Infrastructure
- ✅ `conftest.py` - Pytest fixtures and configuration
- ✅ `pytest.ini` - Pytest settings
- ✅ `requirements.txt` - Python dependencies

### Page Object Model
- ✅ `pages/base_page.py` - Base page class with common methods
- ✅ `pages/app_page.py` - Application page with all locators and methods

### Test Suites
- ✅ `test_hello_world.py` - Hello World button tests
- ✅ `test_version_info.py` - Version information tests
- ✅ `test_security_status.py` - Security status tests

### Utilities
- ✅ `utils/server_manager.py` - Server management functions

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

## Common Commands

```bash
# Run all tests
pytest tests/

# Run with specific browser
pytest --browser=chrome tests/
pytest --browser=firefox tests/

# Run in parallel (faster)
pytest -n 4 tests/

# Run only smoke tests
pytest -m smoke tests/

# Run with verbose output
pytest -v tests/

# Run with HTML report
pytest --html=reports/report.html --self-contained-html tests/
```

## Next Steps

1. **Read the full README**: `tests/README.md`
2. **Review test examples**: Check `tests/test_suites/` for examples
3. **Write your own tests**: Follow the Page Object Model pattern
4. **Customize**: Modify `pytest.ini` and `conftest.py` as needed

## Need Help?

- Check `tests/README.md` for detailed documentation
- Review `TESTING_PLAN.md` for the complete testing strategy
- Look at existing tests in `tests/test_suites/` for examples
