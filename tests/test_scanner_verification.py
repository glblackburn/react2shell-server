"""
Scanner verification tests.

This module tests that the react2shell-scanner correctly detects vulnerabilities
when scanning the application with different React versions.

Note: This requires the scanner to be available at:
    /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner
"""
import sys
import os
import subprocess
import time
import pytest
from pathlib import Path

# Add scanner to path
SCANNER_PATH = Path("/Users/lblackb/data/lblackb/git/third-party/react2shell-scanner")
if not SCANNER_PATH.exists():
    pytest.skip("Scanner not found at expected path", allow_module_level=True)

sys.path.insert(0, str(SCANNER_PATH))

try:
    from scanner import check_vulnerability
except ImportError:
    pytest.skip("Failed to import scanner module", allow_module_level=True)

from tests.utils.version_constants import VULNERABLE_VERSIONS, FIXED_VERSIONS, ALL_VERSIONS
from tests.utils.server_constants import FRONTEND_URL
from tests.utils.server_manager import get_current_react_version


def switch_react_version(version: str) -> bool:
    """
    Switch to a specific React version using Makefile.
    
    Args:
        version: React version to switch to (e.g., '19.0', '19.1.0')
    
    Returns:
        True if switch was successful, False otherwise
    """
    project_root = Path(__file__).parent.parent
    try:
        result = subprocess.run(
            ["make", f"react-{version}"],
            cwd=project_root,
            capture_output=True,
            text=True,
            timeout=120
        )
        if result.returncode != 0:
            print(f"Error switching to version {version}: {result.stderr}")
            return False
        return True
    except subprocess.TimeoutExpired:
        print(f"Timeout switching to version {version}")
        return False
    except Exception as e:
        print(f"Exception switching to version {version}: {e}")
        return False


def wait_for_server(url: str, timeout: int = 30) -> bool:
    """
    Wait for server to be ready.
    
    Args:
        url: Server URL to check
        timeout: Maximum time to wait in seconds
    
    Returns:
        True if server is ready, False otherwise
    """
    import requests
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, timeout=5, verify=False)
            if response.status_code in (200, 404):  # 404 is OK, means server is up
                return True
        except Exception:
            pass
        time.sleep(1)
    return False


@pytest.mark.scanner
@pytest.mark.version_switch
class TestScannerVerification:
    """Test that scanner correctly detects vulnerabilities for each React version."""
    
    @pytest.fixture(scope="class", autouse=True)
    def ensure_servers_running(self, start_servers):
        """Ensure servers are running before scanner tests."""
        # start_servers fixture handles this
        pass
    
    @pytest.mark.parametrize("version", VULNERABLE_VERSIONS)
    def test_scanner_detects_vulnerable_version(self, version):
        """
        Test that scanner detects vulnerability for vulnerable React versions.
        
        Args:
            version: Vulnerable React version to test
        """
        # Switch to the vulnerable version
        assert switch_react_version(version), f"Failed to switch to version {version}"
        
        # Wait for npm install and server restart
        time.sleep(5)
        
        # Verify version switch
        current_version = get_current_react_version()
        assert current_version == version, \
            f"Version mismatch: expected {version}, got {current_version}"
        
        # Wait for server to be ready
        assert wait_for_server(FRONTEND_URL), "Server not ready after version switch"
        
        # Run scanner check
        result = check_vulnerability(
            FRONTEND_URL,
            timeout=15,
            verify_ssl=False,
            safe_check=False  # Use RCE PoC for detection
        )
        
        # Verify scanner detected vulnerability
        assert result["vulnerable"] is True, \
            f"Scanner should detect vulnerability for version {version}. " \
            f"Status: {result.get('status_code')}, Error: {result.get('error')}"
    
    @pytest.mark.parametrize("version", FIXED_VERSIONS)
    def test_scanner_does_not_detect_fixed_version(self, version):
        """
        Test that scanner does NOT detect vulnerability for fixed React versions.
        
        Args:
            version: Fixed React version to test
        """
        # Switch to the fixed version
        assert switch_react_version(version), f"Failed to switch to version {version}"
        
        # Wait for npm install and server restart
        time.sleep(5)
        
        # Verify version switch
        current_version = get_current_react_version()
        assert current_version == version, \
            f"Version mismatch: expected {version}, got {current_version}"
        
        # Wait for server to be ready
        assert wait_for_server(FRONTEND_URL), "Server not ready after version switch"
        
        # Run scanner check
        result = check_vulnerability(
            FRONTEND_URL,
            timeout=15,
            verify_ssl=False,
            safe_check=False  # Use RCE PoC for detection
        )
        
        # Verify scanner did NOT detect vulnerability
        assert result["vulnerable"] is False, \
            f"Scanner should NOT detect vulnerability for fixed version {version}. " \
            f"Status: {result.get('status_code')}, Error: {result.get('error')}"
