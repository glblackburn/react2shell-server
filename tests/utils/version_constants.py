"""
React version constants and utilities.

This module provides a single source of truth for React version information,
including which versions are vulnerable and which are fixed.
"""
from typing import List


# Vulnerable React versions (for security testing)
VULNERABLE_VERSIONS: List[str] = ['19.0', '19.1.0', '19.1.1', '19.2.0']

# Fixed React versions
FIXED_VERSIONS: List[str] = ['19.0.1', '19.1.2', '19.2.1']

# All React versions
ALL_VERSIONS: List[str] = VULNERABLE_VERSIONS + FIXED_VERSIONS


def is_vulnerable_version(version: str) -> bool:
    """Check if React version is vulnerable.
    
    Args:
        version: React version string (e.g., '19.0', '19.1.0')
    
    Returns:
        True if version is in the vulnerable versions list, False otherwise
    """
    return version in VULNERABLE_VERSIONS


def is_fixed_version(version: str) -> bool:
    """Check if React version is fixed.
    
    Args:
        version: React version string (e.g., '19.0.1', '19.1.2')
    
    Returns:
        True if version is in the fixed versions list, False otherwise
    """
    return version in FIXED_VERSIONS


def get_version_status(version: str) -> str:
    """Get status string for a React version.
    
    Args:
        version: React version string
    
    Returns:
        'VULNERABLE' if version is vulnerable, 'FIXED' otherwise
    """
    return 'VULNERABLE' if is_vulnerable_version(version) else 'FIXED'
