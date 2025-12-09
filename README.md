# React Hello World Server

**Purpose: Security Testing Project**

This project provides a React application with easily switchable React versions, including **vulnerable versions** for security scanner testing. The primary purpose is to enable security scanners and testing tools to detect and validate detection of the React Server Components security vulnerability (CVE).

A React application with a backend server that displays a big red button. When clicked, the button sends a request to the server, which responds with "Hello World!". This simple application serves as a testbed for security scanners to identify vulnerable React versions.

## Table of Contents

- [Purpose](#purpose)
- [Security Vulnerability](#security-vulnerability)
  - [React Server Components Vulnerability](#react-server-components-vulnerability)
  - [Next.js RSC Vulnerability](#nextjs-rsc-vulnerability)
- [Features](#features)
- [React Version Switching](#react-version-switching)
- [Security Scanner Testing](#security-scanner-testing)
- [Setup](#setup)
- [Development](#development)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Development Tools](#development-tools)
- [Switching React Versions](#switching-react-versions)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Defect Tracking](#defect-tracking)
- [License](#license)

## Purpose

This project is designed to provide **scannable vulnerable React versions** for security testing purposes. It allows security scanners and testing tools to:

- Detect vulnerable React versions in a controlled environment
- Validate that security scanners correctly identify the React Server Components vulnerability
- Test scanner accuracy by switching between vulnerable and fixed versions
- Provide a reproducible test environment for security research

**⚠️ WARNING: This project intentionally includes vulnerable React versions. Do NOT use in production environments.**

## Security Vulnerability

### React Server Components Vulnerability

**CVE Reference:** [React Security Advisory - Critical Security Vulnerability in React Server Components](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components)

The vulnerability affects React Server Components in the following versions:
- React 19.0
- React 19.1.0
- React 19.1.1
- React 19.2.0

Fixed versions:
- React 19.0.1
- React 19.1.2
- React 19.2.1

### Next.js RSC Vulnerability

**CVE Reference:** [Next.js Security Advisory - CVE-2025-66478](https://nextjs.org/blog/CVE-2025-66478)

This project also supports Next.js framework mode for testing Next.js-specific vulnerabilities. The vulnerability affects Next.js applications using React Server Components.

**Vulnerable Next.js versions:**
- Next.js 14.0.0
- Next.js 14.1.0
- Next.js 15.0.0
- Next.js 15.1.0

**Fixed Next.js versions:**
- Next.js 14.0.1
- Next.js 14.1.1

> **Note:** Next.js version switching is only available when in Next.js mode (`make use-nextjs`). See [Framework Switching](#framework-switching) section for details.

## Features

- Big red button UI with smooth animations
- Express.js backend server
- React frontend with version switching capability
- Easy switching between React versions (including vulnerable versions for security testing)
- Support for testing React Server Components security vulnerability (CVE)

## React Version Switching

This project supports easy switching between different React versions using a Makefile.

### Available React Versions

**Vulnerable Versions (for security testing):**
- React 19.0 ⚠️ VULNERABLE
- React 19.1.0 ⚠️ VULNERABLE
- React 19.1.1 ⚠️ VULNERABLE
- React 19.2.0 ⚠️ VULNERABLE

**Fixed Versions:**
- React 19.0.1 ✅ FIXED
- React 19.1.2 ✅ FIXED
- React 19.2.1 ✅ FIXED

> **Security Note:** Versions 19.0, 19.1.0, 19.1.1, and 19.2.0 contain a critical security vulnerability in React Server Components. This project supports these versions for security scanner testing purposes.
>
> **CVE Documentation:** 
> - [React Security Advisory](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components)
> - [Next.js Security Advisory - CVE-2025-66478](https://nextjs.org/blog/CVE-2025-66478)

### Makefile Commands

```bash
# Switch to vulnerable versions (for security testing)
make vulnerable      # Switch to React 19.0 (VULNERABLE) - quick option
make react-19.0      # Switch to React 19.0 (VULNERABLE)
make react-19.1.0    # Switch to React 19.1.0 (VULNERABLE)
make react-19.1.1    # Switch to React 19.1.1 (VULNERABLE)
make react-19.2.0    # Switch to React 19.2.0 (VULNERABLE)

# Switch to fixed versions
make react-19.0.1    # Switch to React 19.0.1 (FIXED)
make react-19.1.2    # Switch to React 19.1.2 (FIXED)
make react-19.2.1    # Switch to React 19.2.1 (FIXED)

# Framework Switching
make use-vite        # Switch to Vite + React mode (default)
make use-nextjs      # Switch to Next.js mode
make current-framework # Show current framework mode

# Next.js Version Switching (only available in Next.js mode)
make use-nextjs      # First, switch to Next.js mode
make nextjs-14.0.0   # Switch to Next.js 14.0.0 (VULNERABLE)
make nextjs-14.1.0   # Switch to Next.js 14.1.0 (VULNERABLE)
make nextjs-15.0.0   # Switch to Next.js 15.0.0 (VULNERABLE)
make nextjs-14.0.1   # Switch to Next.js 14.0.1 (FIXED)
make nextjs-14.1.1   # Switch to Next.js 14.1.1 (FIXED)
make nextjs-15.1.0   # Switch to Next.js 15.1.0 (FIXED)

# Check current React version
make current-version

# Install dependencies for current version
make install

# Clean node_modules and package-lock.json
make clean

# Server Management
make start           # Start both frontend and backend servers
make stop            # Stop both servers
make status          # Check status of servers
make tail-vite       # Tail frontend server log (Ctrl+C to exit)
make tail-server     # Tail backend server log (Ctrl+C to exit)

# Show help
make help
```

## Security Scanner Testing

To test your security scanner against vulnerable React versions:

1. **Switch to a vulnerable version:**
   ```bash
   make react-19.2.0  # or any other vulnerable version
   ```

2. **Start the application:**
   ```bash
   make start       # Starts both servers automatically
   ```
   Or manually:
   ```bash
   npm run dev      # Terminal 1
   npm run server   # Terminal 2
   ```

3. **Run your security scanner** against the application

4. **Switch to a fixed version** to verify scanner detects the difference:
   ```bash
   make react-19.2.1  # FIXED version
   ```

### Scanner Verification

This project includes automated scanner verification to ensure that security scanners correctly detect vulnerabilities when scanning different React versions.

**Available Methods:**

1. **Python Test Suite** (pytest-based):
   ```bash
   make test-scanner
   ```
   Runs pytest tests that switch between versions and verify scanner detection.

2. **Standalone Script**:
   ```bash
   make test-scanner-script
   ```
   Runs a shell script that tests all vulnerable and fixed versions.

**Requirements:**
- Scanner must be available at: `/Users/lblackb/data/lblackb/git/third-party/react2shell-scanner`
- Scanner dependencies must be installed (see scanner's `requirements.txt`)

**What It Tests:**
- ✅ Vulnerable versions (19.0, 19.1.0, 19.1.1, 19.2.0) are correctly detected as vulnerable
- ✅ Fixed versions (19.0.1, 19.1.2, 19.2.1) are correctly identified as not vulnerable

**Note:** Scanner verification is kept separate from the main test suite to avoid slowing down regular test execution. See `docs/SCANNER_INTEGRATION.md` for detailed analysis of pros/cons.

## Setup

1. **Clone the repository** (if applicable) or navigate to the project directory

2. **Switch to your desired React version** (for security testing, use a vulnerable version):
   ```bash
   make react-19.0
   ```
   Or choose any other version:
   ```bash
   make react-19.1.0
   make react-19.1.1
   make react-19.2.0
   ```

3. **Verify the React version**:
   ```bash
   make current-version
   ```

## Development

### Quick Start (Recommended)

**Start both servers with one command:**
```bash
make start
```

This will:
- Start both the Vite dev server (port 5173) and Express server (port 3000) in the background
- Capture output to log files (`.logs/vite.log` and `.logs/server.log`)
- Display the URLs to access the application
- Wait for servers to be ready

**Check server status:**
```bash
make status
```

**View server logs (live):**
```bash
make tail-vite      # View frontend server log
make tail-server    # View backend server log
```

**Stop both servers:**
```bash
make stop
```

### Manual Start (Alternative)

If you prefer to start servers manually:

1. **Start the Vite dev server** (runs on port 5173):
   ```bash
   npm run dev
   ```

2. **In a separate terminal, start the Express server** (runs on port 3000):
   ```bash
   npm run server
   ```

3. **Open your browser** to `http://localhost:5173`

The Vite dev server is configured to proxy API requests to the Express server.

### Production Mode

1. **Build the React app**:
   ```bash
   npm run build
   ```

2. **Start the server**:
   ```bash
   npm run server
   ```

   Or use the combined command:
   ```bash
   npm start
   ```

3. **Open your browser** to `http://localhost:3000`

## Testing

This project includes Python Selenium end-to-end tests using **pytest** framework.

### Quick Start

```bash
# Set up test environment (first time only)
make test-setup

# Run all tests (automatically starts servers if needed)
make test

# Run tests in parallel (faster - 4 workers)
make test-parallel

# Run tests with HTML report
make test-report
make test-open-report
```

### Test Commands

**Makefile shortcuts:**
- `make test-setup` - Set up Python virtual environment
- `make test` - Run all tests
- `make test-quick` - Quick test run (headless)
- `make test-parallel` - Run tests in parallel (10 workers, faster execution)
- `make test-report` - Generate HTML report
- `make test-smoke` - Run smoke tests only
- `make test-hello` - Run hello world tests
- `make test-version` - Run version info tests
- `make test-security` - Run security status tests
- `make test-version-switch` - Run version switch tests (tests all React versions, slower)
- `make test-browser BROWSER=chrome` - Run with specific browser
- `make test-clean` - Clean test artifacts

**Performance Tracking:**
- `make test-performance-report` - Generate and open comprehensive HTML performance report
- `make test-performance-compare` - Compare latest run against baseline
- `make test-performance-trends` - View performance trends
- `make test-performance-slowest` - List slowest tests
- `make test-update-baseline` - Update performance baseline

**For detailed documentation:**
- **[Quick Start Guide](tests/QUICKSTART.md)** - Get started in 5 minutes
- **[Complete Testing Guide](tests/README.md)** - Comprehensive documentation
- **[Performance Tracking Guide](tests/PERFORMANCE_TRACKING.md)** - Performance metrics and limits
- **[Testing Plan](TESTING_PLAN.md)** - Testing strategy and implementation plan

## Project Structure

```
react2shell-server/
├── Makefile                  # React version switching and server management
├── package.json              # Dependencies (React version updated by Makefile)
├── vite.config.js            # Vite build configuration
├── server.js                 # Express server
├── index.html                # HTML entry point
├── start-cursor-agent.sh     # Cursor IDE agent startup script
├── src/
│   ├── App.jsx               # Main React component
│   ├── index.jsx             # React entry point
│   └── App.css               # Styles
├── tests/                    # Python Selenium tests
│   ├── conftest.py           # Pytest fixtures and configuration
│   ├── pytest.ini            # Pytest settings
│   ├── requirements.txt     # Python test dependencies
│   ├── pages/                # Page Object Model
│   │   ├── base_page.py      # Base page class
│   │   └── app_page.py       # Application page
│   ├── test_suites/          # Test files
│   │   ├── test_hello_world.py
│   │   ├── test_version_info.py
│   │   └── test_security_status.py
│   ├── utils/                # Test utilities
│   │   └── server_manager.py # Server management
│   └── reports/              # Test reports (generated)
├── dist/                     # Build output (generated)
├── .pids/                    # Server PID files (generated by make start)
└── .logs/                    # Server log files (generated by make start)
```

## API Endpoints

- **GET /api/hello**
  - Returns: `{ "message": "Hello World!" }`

- **GET /api/version**
  - Returns: `{ "react": "version", "reactDom": "version", "node": "version", "vulnerable": boolean, "status": "VULNERABLE" | "FIXED" }`

## Development Tools

### Cursor Agent Script

The `start-cursor-agent.sh` script provides a convenient way to start a Cursor IDE agent session for AI-assisted development.

**Usage:**
```bash
./start-cursor-agent.sh
```

**Requirements:**
- Cursor IDE installed
- `cursor-agent` command available in PATH

**What it does:**
- Starts a Cursor agent session with a specific resume ID
- Allows resuming previous agent sessions for continuity
- Enables AI-assisted development workflows within Cursor IDE

**Note:** This script is optional and only needed if you're using Cursor IDE's agent features for development assistance.

## Switching React Versions

To switch React versions during development:

1. **Stop any running servers**

2. **Switch to the desired version**:
   ```bash
   make react-19.2.0
   ```

3. **Verify the switch**:
   ```bash
   make current-version
   ```

4. **Restart your development servers**

## Requirements

### Application Requirements
- Node.js (v18 or higher recommended)
- npm
- make (usually pre-installed on macOS/Linux)

### Testing Requirements
- Python 3.8 or higher
- pip (Python package manager)
- pytest and Selenium (installed via `tests/requirements.txt`)
- Browser (Chrome, Firefox, or Safari) for Selenium tests

## Troubleshooting

### If `make` command is not found

On Windows, you may need to use WSL or install make. Alternatively, you can manually update `package.json` and run `npm install`.

### If dependencies fail to install

Try cleaning and reinstalling:
```bash
make clean
make install
```

### Port already in use

If port 3000 or 5173 is already in use, you can:
- Change the port in `server.js` (PORT environment variable)
- Change the port in `vite.config.js` (server.port)

### Test-related Issues

See [tests/README.md](tests/README.md#troubleshooting) for detailed troubleshooting guide.

Common issues:
- **Tests fail with "Server not ready"**: Run `make start` to ensure servers are running
- **Browser driver issues**: Tests auto-manage drivers via `webdriver-manager`
- **Import errors**: Ensure virtual environment is activated and dependencies installed
- **Port conflicts**: Use `make stop` to free ports

## Defect Tracking

This section tracks known bugs and issues in the project. For detailed defect reports, see the [Defect Tracking Documentation](docs/defect-tracking/README.md).

| ID | Status | Priority | Severity | Title |
|----|--------|----------|----------|-------|
| [BUG-1](docs/defect-tracking/BUG-1.md) | Fixed | High | High | Version API Endpoint Not Accessible in Dev Mode |
| [BUG-2](docs/defect-tracking/BUG-2.md) | Fixed | High | High | Missing pytest Option Registration After Refactoring |
| [BUG-3](docs/defect-tracking/BUG-3.md) | Fixed | Medium | Medium | Next.js Version Not Displayed in UI |
| [BUG-4](docs/defect-tracking/BUG-4.md) | Fixed | Medium | Medium | Next.js Frontend Layout Mismatch |
| [BUG-5](docs/defect-tracking/BUG-5.md) | Open | High | High | Next.js 15.1.0 Incorrectly Detected as VULNERABLE |
| [BUG-6](docs/defect-tracking/BUG-6.md) | Open | High | High | verify_scanner.sh Fails Due to Port Mismatch |

For complete defect details, see the [Defect Tracking Documentation](docs/defect-tracking/README.md).


## License

ISC
