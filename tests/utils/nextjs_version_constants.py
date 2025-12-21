"""
Next.js version constants for testing.

These match the versions defined in the Makefile.
"""

# Vulnerable Next.js versions (for security testing)
NEXTJS_VULNERABLE_VERSIONS = [
    "14.0.0",
    "14.1.0",
    "15.0.4",
    "15.1.8",
    "15.2.5",
    "15.3.5",
    "15.4.7",
    "15.5.6",
    "16.0.6",
]

# Fixed Next.js versions
NEXTJS_FIXED_VERSIONS = [
    "14.0.1",
    "14.1.1",
]

# All Next.js versions
ALL_NEXTJS_VERSIONS = NEXTJS_VULNERABLE_VERSIONS + NEXTJS_FIXED_VERSIONS
