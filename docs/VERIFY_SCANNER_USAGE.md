# Scanner Verification Script Usage

## Overview

The `scripts/verify_scanner.sh` script automates verification of the `react2shell-scanner` against multiple Next.js versions. It tests that the scanner correctly detects vulnerabilities in vulnerable Next.js versions and correctly identifies fixed versions as not vulnerable.

## Scanner Project

The scanner used by this script is the **react2shell-scanner** from Assetnote:

- **GitHub Repository:** [assetnote/react2shell-scanner](https://github.com/assetnote/react2shell-scanner)
- **Purpose:** Detects CVE-2025-55182 and CVE-2025-66478 in Next.js applications using React Server Components
- **Documentation:** See the [scanner README](https://github.com/assetnote/react2shell-scanner) for detailed information about the scanner itself

## Prerequisites

1. **Next.js Mode:** The script requires the project to be in Next.js mode:
   ```bash
   make use-nextjs
   ```

2. **Scanner Installation:** The scanner must be available at:
   ```
   /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner
   ```
   Note: Update `SCANNER_PATH` in the script if your scanner is located elsewhere.

3. **Python 3:** Required to run the scanner script.

4. **Server Running:** The script will attempt to start the server if it's not running, but ensure you have the necessary dependencies installed.

## Usage

### Basic Usage

Run the script to test all vulnerable Next.js versions:

```bash
./scripts/verify_scanner.sh
```

### Options

```bash
./scripts/verify_scanner.sh [OPTIONS]
```

**Available Options:**

- `-h` - Display help message
- `-s` - Use safe side-channel detection instead of RCE PoC (see scanner documentation)
- `-a` - Test all versions (both vulnerable and fixed)
- `-q` - Quiet mode (minimal output)
- `-v` - Verbose mode (detailed configuration output)

### Examples

**Test vulnerable versions only (default):**
```bash
./scripts/verify_scanner.sh
```

**Test all versions (vulnerable and fixed):**
```bash
./scripts/verify_scanner.sh -a
```

**Use safe-check mode:**
```bash
./scripts/verify_scanner.sh -s
```

**Quiet mode:**
```bash
./scripts/verify_scanner.sh -q
```

**Verbose output:**
```bash
./scripts/verify_scanner.sh -v
```

## What It Tests

The script tests the following Next.js versions:

**Vulnerable Versions (should be detected as vulnerable):**
- Next.js 14.0.0
- Next.js 14.1.0
- Next.js 15.0.4
- Next.js 15.1.8
- Next.js 15.2.5
- Next.js 15.3.5
- Next.js 15.4.7
- Next.js 15.5.6
- Next.js 16.0.6

**Fixed Versions (tested with `-a` flag, should be detected as not vulnerable):**
- Next.js 14.0.1
- Next.js 14.1.1

## Output

The script provides:

1. **Version Information:** Before each scanner test, displays current Next.js and React versions from the UI
2. **Scanner Output:** Full scanner output for each test (unless in quiet mode)
3. **Test Results:** Pass/fail status for each version
4. **Summary:** Final summary with counts and detailed list of passed/failed versions

### Example Output

See [Example Run Output](verify_scanner_example_output.txt) for a complete example of script execution.

**Key Features of Output:**

- **Version Display:** Shows Next.js and React versions from UI before each test
- **Color Coding:** 
  - Green (✓) for passed tests
  - Red (✗) for failed tests
  - Cyan for informational messages
- **Detailed Summary:** Lists each version with pass/fail status and reason
- **Log File:** All output is saved to `/tmp/verify_scanner_YYYY-MM-DD_HHMMSS_XXXXXX.txt`

### Sample Output Snippet

```
========================================
Scanner Verification Test
========================================
Log file: /tmp/verify_scanner_2025-12-09_065838_L5hh4c.txt

Detected framework: nextjs (checking port 3000)
Waiting for server to be ready at http://localhost:3000...
Testing VULNERABLE Next.js versions...
Switching to Next.js 15.0.4...
✓ Switched to Next.js 15.0.4
Restarting server with Next.js 15.0.4...
Waiting for server to be ready at http://localhost:3000...
Current versions from UI:
  Next.js: 15.0.4
  React: 19.2.0
  Status: VULNERABLE
Running scanner against Next.js 15.0.4...

brought to you by assetnote
[*] Loaded 1 host(s) to scan
[*] Using 10 thread(s)
[*] Timeout: 10s
[*] Using RCE PoC check
[!] SSL verification disabled
[VULNERABLE] http://localhost:3000 - Status: 303
============================================================
SCAN SUMMARY
============================================================
  Total hosts scanned: 1
  Vulnerable: 1
  Not vulnerable: 0
  Errors: 0
============================================================

✓ Correctly detected vulnerability for Next.js 15.0.4
```

## How It Works

1. **Framework Detection:** Automatically detects if the project is in Next.js mode
2. **Server Management:** Starts the server if not running, waits for readiness
3. **Version Switching:** For each version:
   - Switches to the Next.js version using `make nextjs-<version>`
   - Verifies the `next` binary exists
   - Restarts the server
   - Waits for server readiness (polling-based, no fixed delays)
4. **Version Display:** Fetches and displays current versions from `/api/version` endpoint
5. **Scanner Execution:** Runs the scanner against the server
6. **Result Verification:** Checks if scanner results match expected vulnerability status

## Known Issues

### Next.js 14.x Timeout Issue

Next.js 14.0.0 and 14.1.0 may fail with "Read timed out" errors. This is a **known Next.js 14.x internal bug** (see [BUG-8](defect-tracking/BUG-8.md)) and is not a script issue. The bug causes the request handler to hang when processing RCE PoC payloads, regardless of React version.

**Status:** Not Fixable - This is a Next.js 14.x internal bug that cannot be resolved in our codebase.

### Next.js 16.0.6 Server Startup

Next.js 16.0.6 may fail to start or may require additional time. This is expected for newer versions and may require investigation.

## Troubleshooting

**Error: Scanner not found**
- Verify the scanner path in the script matches your installation
- Update `SCANNER_PATH` variable if needed

**Error: Server not ready**
- Check that the server is running: `make status`
- Verify framework mode: `make current-framework` (should show "nextjs")
- Check server logs: `make tail-server`

**Error: Framework mode mismatch**
- Ensure you're in Next.js mode: `make use-nextjs`
- The script only works with Next.js framework

**Scanner timeouts**
- For Next.js 14.x: This is expected due to Next.js 14.x bug (see BUG-8)
- For other versions: Check server logs for errors
- Verify server is responding: `curl http://localhost:3000`

## Log Files

All script output is automatically saved to log files in `/tmp/`:

- Format: `verify_scanner_YYYY-MM-DD_HHMMSS_XXXXXX.txt`
- Contains: Complete script output including all scanner results
- Example: `/tmp/verify_scanner_2025-12-09_065838_L5hh4c.txt`

## Integration with Makefile

The script can also be run via Makefile:

```bash
make test-scanner-script
```

This is equivalent to running `./scripts/verify_scanner.sh` directly.

## Related Documentation

- [Scanner Timeout Analysis](defect-tracking/BUG-8/SCANNER_TIMEOUT_ANALYSIS.md) - Detailed analysis of Next.js 14.x timeout issues
- [BUG-8](defect-tracking/BUG-8.md) - Next.js 14.x timeout issue (Not Fixable)
- [BUG-7](defect-tracking/BUG-7.md) - Scanner connection timeout (Fixed)
- [Example Run Output](verify_scanner_example_output.txt) - Complete example output

## Scanner Project Links

- **GitHub:** [assetnote/react2shell-scanner](https://github.com/assetnote/react2shell-scanner)
- **Research Blog:** [High-Fidelity Detection Mechanism for RSC Next.js RCE](https://slcyber.io/research-center/high-fidelity-detection-mechanism-for-rsc-next-js-rce-cve-2025-55182-cve-2025-66478)
- **CVEs Detected:** CVE-2025-55182, CVE-2025-66478
