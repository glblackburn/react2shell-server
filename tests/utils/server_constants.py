"""
Server URL and port constants.

This module provides a single source of truth for server URLs and ports,
making it easy to change ports for testing or different environments.
"""

# Server ports
FRONTEND_PORT: int = 5173
BACKEND_PORT: int = 3000

# Server URLs
FRONTEND_URL: str = f"http://localhost:{FRONTEND_PORT}"
BACKEND_URL: str = f"http://localhost:{BACKEND_PORT}"
API_ENDPOINT: str = f"{BACKEND_URL}/api/hello"
VERSION_ENDPOINT: str = f"{BACKEND_URL}/api/version"
