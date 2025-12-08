"""
Framework detection utilities.

Detects which framework is currently active (Vite or Next.js).
"""
import os
from pathlib import Path


def get_framework_mode() -> str:
    """
    Get the current framework mode from .framework-mode file.
    
    Returns:
        'vite' or 'nextjs' (defaults to 'vite' if file doesn't exist)
    """
    project_root = Path(__file__).parent.parent.parent
    framework_file = project_root / ".framework-mode"
    
    if framework_file.exists():
        try:
            mode = framework_file.read_text().strip()
            if mode in ("vite", "nextjs"):
                return mode
        except Exception:
            pass
    
    return "vite"  # Default


def is_nextjs_mode() -> bool:
    """Check if Next.js mode is active."""
    return get_framework_mode() == "nextjs"


def is_vite_mode() -> bool:
    """Check if Vite mode is active."""
    return get_framework_mode() == "vite"
