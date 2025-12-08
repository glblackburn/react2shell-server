"""
Server URL and port constants.

This module provides a single source of truth for server URLs and ports,
making it easy to change ports for testing or different environments.
"""
from .framework_detector import get_framework_mode

# Framework-aware server configuration
def _get_urls():
    """Get URLs based on active framework."""
    framework = get_framework_mode()
    
    if framework == "nextjs":
        # Next.js runs on port 3000 only
        return {
            "FRONTEND_PORT": 3000,
            "BACKEND_PORT": 3000,
            "FRONTEND_URL": "http://localhost:3000",
            "BACKEND_URL": "http://localhost:3000",
            "API_ENDPOINT": "http://localhost:3000/api/hello",
            "VERSION_ENDPOINT": "http://localhost:3000/api/version",
        }
    else:
        # Vite mode: frontend on 5173, backend on 3000
        return {
            "FRONTEND_PORT": 5173,
            "BACKEND_PORT": 3000,
            "FRONTEND_URL": "http://localhost:5173",
            "BACKEND_URL": "http://localhost:3000",
            "API_ENDPOINT": "http://localhost:3000/api/hello",
            "VERSION_ENDPOINT": "http://localhost:3000/api/version",
        }

# Create a class that provides dynamic access to URLs
class _URLConstants:
    """Dynamic URL constants that are evaluated each time they're accessed."""
    
    @property
    def FRONTEND_URL(self):
        return _get_urls()["FRONTEND_URL"]
    
    @property
    def BACKEND_URL(self):
        return _get_urls()["BACKEND_URL"]
    
    @property
    def API_ENDPOINT(self):
        return _get_urls()["API_ENDPOINT"]
    
    @property
    def VERSION_ENDPOINT(self):
        return _get_urls()["VERSION_ENDPOINT"]
    
    @property
    def FRONTEND_PORT(self):
        return _get_urls()["FRONTEND_PORT"]
    
    @property
    def BACKEND_PORT(self):
        return _get_urls()["BACKEND_PORT"]

# Create singleton instance
_urls = _URLConstants()

# Export as module-level attributes (they'll access the properties)
def __getattr__(name):
    """Dynamic attribute access for URLs."""
    if hasattr(_urls, name):
        return getattr(_urls, name)
    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")

# For direct imports, provide functions that return the current values
def get_frontend_url():
    """Get the current frontend URL."""
    return _get_urls()["FRONTEND_URL"]

def get_backend_url():
    """Get the current backend URL."""
    return _get_urls()["BACKEND_URL"]

def get_api_endpoint():
    """Get the current API endpoint."""
    return _get_urls()["API_ENDPOINT"]

def get_version_endpoint():
    """Get the current version endpoint."""
    return _get_urls()["VERSION_ENDPOINT"]

# Set initial values for backward compatibility (but they'll be stale)
# Users should use the functions or access via __getattr__
_initial_urls = _get_urls()
FRONTEND_URL = _initial_urls["FRONTEND_URL"]
BACKEND_URL = _initial_urls["BACKEND_URL"]
API_ENDPOINT = _initial_urls["API_ENDPOINT"]
VERSION_ENDPOINT = _initial_urls["VERSION_ENDPOINT"]
FRONTEND_PORT = _initial_urls["FRONTEND_PORT"]
BACKEND_PORT = _initial_urls["BACKEND_PORT"]
