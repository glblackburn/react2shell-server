# Testing Plan - Python Selenium Tests

## Framework Choice

**pytest** is used as the testing framework. See [tests/README.md](tests/README.md#framework-choice-pytest) for detailed framework comparison and rationale.

**Key plugins:**
- `pytest-selenium` - Selenium integration
- `pytest-html` - HTML test reports
- `pytest-xdist` - Parallel test execution
- `pytest-timeout` - Test timeout management
- `pytest-rerunfailures` - Retry failed tests
- `webdriver-manager` - Automatic driver management

See [tests/requirements.txt](tests/requirements.txt) for complete dependency list.

## Test Structure

```
tests/
├── conftest.py              # Pytest configuration, fixtures
├── requirements.txt         # Python test dependencies
├── pytest.ini              # Pytest configuration file
├── pages/                  # Page Object Model
│   ├── __init__.py
│   ├── base_page.py        # Base page class
│   └── app_page.py         # Main application page
├── fixtures/               # Test data and fixtures
│   └── test_data.py
├── utils/                  # Utilities
│   ├── __init__.py
│   ├── server_manager.py   # Server start/stop utilities
│   └── helpers.py          # Helper functions
└── test_suites/            # Test suites
    ├── __init__.py
    ├── test_hello_world.py      # Hello World button tests
    ├── test_version_info.py     # Version information tests
    ├── test_version_switching.py # Version switching tests
    └── test_security_status.py  # Security status tests
```

## Test Implementation Plan

### Phase 1: Setup and Infrastructure (Priority: High)

#### 1.1 Project Setup
- [ ] Create Python virtual environment
- [ ] Install pytest and Selenium dependencies
- [ ] Configure pytest.ini
- [ ] Set up conftest.py with fixtures
- [ ] Create base page object class
- [ ] Set up WebDriver management (webdriver-manager)

#### 1.2 Server Management
- [ ] Create server_manager.py utility
- [ ] Implement server start/stop functions
- [ ] Add server health check functions
- [ ] Integrate with Makefile commands
- [ ] Add server status verification

### Phase 2: Page Object Model (Priority: High)

#### 2.1 Base Page Class
- [ ] Create BasePage class with common methods
- [ ] Implement wait utilities (explicit waits)
- [ ] Add element finding methods
- [ ] Add screenshot capabilities
- [ ] Add logging integration

#### 2.2 Application Page Class
- [ ] Create AppPage class extending BasePage
- [ ] Define locators for:
  - Version information card
  - Version details elements
  - Big red button
  - Message display area
  - Loading states
- [ ] Implement page methods:
  - `get_version_info()`
  - `click_hello_button()`
  - `get_message()`
  - `wait_for_version_load()`

### Phase 3: Core Test Suites (Priority: High)

#### 3.1 Hello World Button Tests
- [ ] Test button is visible and clickable
- [ ] Test button text is correct
- [ ] Test button click triggers API call
- [ ] Test loading state during API call
- [ ] Test "Hello World!" message appears
- [ ] Test button disabled during loading
- [ ] Test error handling when server down

#### 3.2 Version Information Tests
- [ ] Test version info card displays
- [ ] Test version info loads on page load
- [ ] Test React version displays correctly
- [ ] Test React-DOM version displays correctly
- [ ] Test Node.js version displays correctly
- [ ] Test vulnerability status displays
- [ ] Test vulnerable indicator (⚠️) for vulnerable versions
- [ ] Test fixed indicator (✅) for fixed versions
- [ ] Test retry logic when server starting
- [ ] Test error message when version fetch fails

#### 3.3 Security Status Tests
- [ ] Test React 19.0 shows VULNERABLE
- [ ] Test React 19.1.0 shows VULNERABLE
- [ ] Test React 19.1.1 shows VULNERABLE
- [ ] Test React 19.2.0 shows VULNERABLE
- [ ] Test React 19.0.1 shows FIXED
- [ ] Test React 19.1.2 shows FIXED
- [ ] Test React 19.2.1 shows FIXED
- [ ] Test status badge color (red for vulnerable, green for fixed)

### Phase 4: Version Switching Tests (Priority: Medium)

#### 4.1 Version Switch Integration Tests
- [ ] Test switching to React 19.0
- [ ] Test switching to React 19.1.0
- [ ] Test switching to React 19.1.1
- [ ] Test switching to React 19.2.0
- [ ] Test switching to React 19.0.1
- [ ] Test switching to React 19.1.2
- [ ] Test switching to React 19.2.1
- [ ] Test version info updates after switch
- [ ] Test application still functional after version switch

### Phase 5: Cross-Browser Tests (Priority: Medium)

#### 5.1 Browser Compatibility
- [ ] Chrome tests
- [ ] Firefox tests
- [ ] Safari tests (if on macOS)
- [ ] Edge tests
- [ ] Headless mode tests

### Phase 6: Advanced Tests (Priority: Low)

#### 6.1 Performance Tests
- [ ] Test page load time
- [ ] Test API response time
- [ ] Test version info load time

#### 6.2 Error Handling Tests
- [ ] Test behavior when backend server down
- [ ] Test behavior when frontend server down
- [ ] Test network timeout handling
- [ ] Test invalid API responses

## Test Execution

### Running Tests

**Using Makefile (Recommended):**
```bash
make test-setup    # First time setup
make test          # Run all tests
make test-report   # Generate HTML report
```

**Direct pytest commands:**
See [tests/README.md](tests/README.md#running-tests) for complete pytest command reference.

### Continuous Integration

See [tests/README.md](tests/README.md#continuous-integration) for CI/CD examples and setup.

## Test Data and Fixtures

### Test Fixtures (conftest.py)
- `driver` - WebDriver instance
- `app_page` - AppPage instance
- `server_running` - Server start/stop fixture
- `react_version` - Parameterized React version fixture

### Test Data
- React version list (vulnerable and fixed)
- Expected version strings
- Expected status values
- API endpoint URLs

## Best Practices

### 1. Page Object Model (POM)
- Separate page logic from test logic
- Reusable page methods
- Centralized locator management

### 2. Explicit Waits
- Use WebDriverWait instead of time.sleep()
- Wait for specific conditions
- Set reasonable timeouts

### 3. Test Independence
- Each test should be independent
- Use fixtures for setup/teardown
- Clean state between tests

### 4. Error Handling
- Meaningful error messages
- Screenshots on failure
- Proper exception handling

### 5. Reporting
- HTML reports for easy viewing
- Screenshots attached to reports
- Clear test names and descriptions

### 6. Maintainability
- DRY (Don't Repeat Yourself)
- Clear naming conventions
- Good documentation
- Regular refactoring

## Success Criteria

### Test Coverage Goals
- [ ] All user flows covered
- [ ] All React versions tested
- [ ] All error scenarios covered
- [ ] Cross-browser compatibility verified

### Quality Gates
- [ ] All tests pass before merge
- [ ] Tests run in < 10 minutes
- [ ] Clear, actionable test reports
- [ ] Tests are maintainable and readable

## Maintenance

### Regular Tasks
- Update Selenium WebDriver versions
- Update browser drivers
- Review and update locators
- Refactor duplicate code
- Update test data
- Review test coverage

---

**Last Updated**: 2025-01-XX  
**Status**: Ready for Implementation
