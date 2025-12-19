# WebDriver Timeout Issue: googlechromelabs.github.io

**Date:** 2025-12-19  
**Issue Type:** Network timeout during WebDriver driver download  
**Status:** Known issue, not related to server startup

---

## Summary

Tests may fail with a network timeout error when `webdriver-manager` tries to download Chrome drivers from `googlechromelabs.github.io`. This is **not a server startup issue** - it's a network/download issue that occurs during WebDriver initialization.

### Error Message

```
requests.exceptions.ReadTimeout: HTTPSConnectionPool(host='googlechromelabs.github.io', port=443): Read timed out.
```

---

## Why is googlechromelabs.github.io Being Accessed?

### Root Cause

The issue occurs in `tests/fixtures/webdriver.py` at line 40:

```python
service = Service(ChromeDriverManager().install())
```

### What Happens

1. **Chrome Version Detection**: `webdriver-manager` detects your installed Chrome browser version
2. **Driver Download**: It downloads the matching chromedriver from `googlechromelabs.github.io` (Google hosts ChromeDriver releases here)
3. **Caching**: The driver is cached in `~/.wdm` directory for future use
4. **Driver Path**: Returns the path to the downloaded driver

### Why the Timeout Occurs

The timeout happens during **step 2 (download)** when:

- **Network is slow or unreachable**: Connection to `googlechromelabs.github.io` is slow or fails
- **Site is temporarily down**: The GitHub Pages site hosting ChromeDriver is unavailable
- **Firewall/proxy blocking**: Network security settings block the connection
- **Download takes too long**: The download exceeds the default timeout period

---

## Impact

### When It Happens

- **Before tests run**: During WebDriver setup/initialization
- **Intermittent**: Depends on network conditions
- **Not server-related**: Your servers are working fine

### Consequences

- Tests fail with timeout error
- Tests can't start without the driver
- Slows down test execution
- Creates false negatives (tests fail due to network, not code)

---

## This is NOT a Server Issue

### Important Distinction

- ✅ **Server startup**: Working correctly (fixed in previous commit)
- ✅ **Servers are ready**: Both frontend and backend are running
- ❌ **WebDriver download**: Network timeout during driver download
- ❌ **Test execution**: Can't proceed without driver

### Evidence

- Server startup logs show servers are ready
- Tests that don't require WebDriver work fine
- Issue only occurs during WebDriver initialization
- Error happens before any test code runs

---

## Technical Details

### WebDriver Manager Behavior

The `webdriver-manager` library (version >=4.0.0) automatically:

1. Checks Chrome version installed on system
2. Downloads matching chromedriver from `googlechromelabs.github.io`
3. Caches in `~/.wdm` directory for future use
4. Returns path to driver executable

### Cache Location

- **Default cache**: `~/.wdm/` (user's home directory)
- **Cache structure**: Organized by driver type and version
- **Reuse**: Once downloaded, driver is reused from cache

### Code Location

**File**: `tests/fixtures/webdriver.py`  
**Line**: 40  
**Function**: `driver()` fixture  
**Library**: `webdriver_manager.chrome.ChromeDriverManager`

---

## Solutions

### 1. Pre-Cache the Driver (Recommended)

**Best for**: CI/CD environments, offline testing

Run once when network is good to cache the driver:

```python
# Pre-cache driver
from webdriver_manager.chrome import ChromeDriverManager
ChromeDriverManager().install()  # Downloads and caches
```

**Benefits**:
- Driver cached locally
- No network dependency during tests
- Faster test execution

### 2. Increase Timeout for WebDriver Downloads

**Best for**: Slow but stable networks

Configure `webdriver-manager` with longer timeout:

```python
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.core.utils import ChromeType

manager = ChromeDriverManager()
# Increase timeout (default is usually 10-30 seconds)
service = Service(manager.install())
```

Or configure via environment variable:
```bash
export WDM_TIMEOUT=60  # 60 seconds
```

### 3. Use Local Driver Path

**Best for**: Controlled environments, CI/CD

Skip `webdriver-manager` and use a pre-installed driver:

```python
# Option 1: Use system PATH
service = Service()  # Uses chromedriver from PATH

# Option 2: Specify explicit path
service = Service('/usr/local/bin/chromedriver')
```

**Requirements**:
- Driver must be installed manually
- Driver version must match Chrome version
- Driver must be in PATH or specify full path

### 4. Configure Retry Logic

**Best for**: Unreliable networks

Add retry logic around driver download:

```python
from webdriver_manager.chrome import ChromeDriverManager
import time

def get_chrome_driver(max_retries=3):
    for attempt in range(max_retries):
        try:
            return ChromeDriverManager().install()
        except Exception as e:
            if attempt < max_retries - 1:
                time.sleep(5)  # Wait before retry
                continue
            raise
```

### 5. Use Alternative Driver Source

**Best for**: Firewall-restricted environments

Configure `webdriver-manager` to use a mirror or alternative source:

```python
# Use environment variable to set custom URL
import os
os.environ['WDM_CHROMEDRIVER_URL'] = 'https://alternative-mirror.com/chromedriver'
```

### 6. Pre-Install Driver in CI/CD

**Best for**: Continuous Integration

Install driver as part of CI/CD setup:

```yaml
# GitHub Actions example
- name: Install ChromeDriver
  run: |
    CHROME_VERSION=$(google-chrome --version | cut -d' ' -f3 | cut -d'.' -f1)
    wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}/chromedriver_linux64.zip"
    unzip /tmp/chromedriver.zip -d /usr/local/bin/
    chmod +x /usr/local/bin/chromedriver
```

---

## Recommended Approach

### For Development

1. **Pre-cache driver once**: Run `ChromeDriverManager().install()` when network is good
2. **Use cached driver**: Subsequent runs use cached version
3. **Handle timeouts gracefully**: Add retry logic if needed

### For CI/CD

1. **Pre-install driver**: Install as part of CI setup
2. **Use local path**: Skip `webdriver-manager` download
3. **Cache between runs**: Reuse driver across test runs

### For Production Testing

1. **Increase timeout**: Allow more time for downloads
2. **Add retry logic**: Automatically retry failed downloads
3. **Monitor network**: Track timeout frequency

---

## Current Status

### In Codebase

- **Location**: `tests/fixtures/webdriver.py:40`
- **Current behavior**: Uses `ChromeDriverManager().install()` with default timeout
- **Issue**: No timeout configuration or retry logic
- **Impact**: Intermittent test failures due to network timeouts

### Related Files

- `tests/fixtures/webdriver.py` - WebDriver fixture
- `tests/requirements.txt` - Lists `webdriver-manager>=4.0.0`
- `tests/README.md` - Mentions webdriver-manager usage

---

## Future Improvements

### Short Term

1. **Add timeout configuration**: Make timeout configurable
2. **Add retry logic**: Automatically retry failed downloads
3. **Better error messages**: Distinguish network vs. other errors

### Long Term

1. **Pre-install in CI/CD**: Include driver in CI setup
2. **Use local driver**: Skip download in controlled environments
3. **Monitor and alert**: Track timeout frequency

---

## References

- **webdriver-manager**: https://github.com/SergeyPirogov/webdriver_manager
- **ChromeDriver**: https://chromedriver.chromium.org/
- **googlechromelabs.github.io**: Hosts ChromeDriver releases
- **Issue Report**: See `docs/TEST_EXECUTION_FIX_REPORT.md` for related context

---

## Conclusion

The `googlechromelabs.github.io` timeout is a **network issue**, not a server startup issue. The servers are working correctly, but tests fail because the Chrome driver can't be downloaded.

**Key Points:**
- ✅ Server startup is fixed and working
- ❌ WebDriver download can timeout due to network
- 🔧 Solutions available: caching, timeouts, local drivers
- 📊 Issue is intermittent and network-dependent

**Recommendation**: Implement driver caching or pre-installation to avoid network dependencies during test execution.

---

**Document Created**: 2025-12-19  
**Related Issues**: Server startup fix (see `docs/TEST_EXECUTION_FIX_REPORT.md`)  
**Status**: Known issue, solutions available
