# Defect Tracking

This section tracks known bugs and issues in the project.

| ID | Status | Priority | Severity | Title | Description |
|----|--------|----------|----------|-------|-------------|
| [BUG-1](BUG-1.md) | Fixed | High | High | Version API Endpoint Not Accessible in Dev Mode | `/api/version` endpoint fails in development mode due to Vite proxy configuration |
| [BUG-2](BUG-2.md) | Fixed | High | High | Missing pytest Option Registration After Refactoring | `--update-baseline` option not registered, causing `ValueError: no option named '--update-baseline'` when running tests |
| [BUG-3](BUG-3.md) | Fixed | Medium | Medium | Next.js Version Not Displayed in UI | Next.js version is returned by API but not displayed in the UI. Should match React version display format with vulnerability status indicator |
| [BUG-4](BUG-4.md) | Fixed | Medium | Medium | Next.js Frontend Layout Mismatch | Next.js UI layout does not match React frontend layout. Visual differences in spacing, alignment, or component structure |
| [BUG-5](BUG-5.md) | Open | High | High | Next.js 15.1.0 Incorrectly Detected as VULNERABLE | Next.js 15.1.0 is listed as FIXED per CVE-2025-66478 but scanner detects it as VULNERABLE. May indicate vulnerability still exists or configuration issue |
| [BUG-6](BUG-6.md) | Fixed | High | High | verify_scanner.sh Fails Due to Port Mismatch | Scanner verification script hardcodes port 5173 (Vite) but doesn't detect framework mode, causing failures when system is in Next.js mode (port 3000) |

## Legend

- **Status:** Fixed, Open, In Progress, Closed
- **Priority:** Low, Medium, High, Critical
- **Severity:** Low, Medium, High, Critical
