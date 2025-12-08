"""
Helper functions for test assertions.

This module provides reusable assertion helpers to reduce code duplication
in test files and ensure consistent error messages.
"""


def assert_version_info_valid(version_info, required_keys=None):
    """Assert that version info is valid and contains required keys.
    
    Args:
        version_info: Dictionary containing version information
        required_keys: Optional list of keys that must be present
    
    Raises:
        AssertionError: If version_info is None, empty, or missing required keys
    """
    assert version_info is not None, "Version info should be loaded"
    
    if required_keys:
        for key in required_keys:
            assert key in version_info, f"Version info should contain {key}"
            assert version_info[key] is not None, f"{key} should not be None"
            assert version_info[key] != "", f"{key} should not be empty"


def assert_version_status_valid(version_info):
    """Assert that version status is valid (VULNERABLE or FIXED).
    
    Args:
        version_info: Dictionary containing version information
    
    Raises:
        AssertionError: If status is missing or invalid
    """
    assert_version_info_valid(version_info, required_keys=['status'])
    assert version_info['status'] in ['VULNERABLE', 'FIXED'], \
        f"Status should be VULNERABLE or FIXED, got '{version_info['status']}'"


def assert_version_contains_key(version_info, key, description=None):
    """Assert that version info contains a specific key with a valid value.
    
    Args:
        version_info: Dictionary containing version information
        key: Key to check for
        description: Optional description of the key (for error messages)
    
    Raises:
        AssertionError: If key is missing, None, or empty
    """
    assert_version_info_valid(version_info)
    key_desc = description or key
    assert key in version_info, f"Version info should contain {key_desc}"
    assert version_info[key] is not None, f"{key_desc} should not be None"
    assert version_info[key] != "", f"{key_desc} should not be empty"
