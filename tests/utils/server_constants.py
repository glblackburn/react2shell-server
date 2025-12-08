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

_urls = _get_urls()

# Server ports
FRONTEND_PORT: int = _urls["FRONTEND_PORT"]
BACKEND_PORT: int = _urls["BACKEND_PORT"]

# Server URLs
FRONTEND_URL: str = _urls["FRONTEND_URL"]
BACKEND_URL: str = _urls["BACKEND_URL"]
API_ENDPOINT: str = _urls["API_ENDPOINT"]
VERSION_ENDPOINT: str = _urls["VERSION_ENDPOINT"]
