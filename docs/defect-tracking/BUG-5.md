# BUG-5: Next.js 15.1.0 Incorrectly Detected as VULNERABLE

**Status:** Open  
**Priority:** High  
**Severity:** High  
**Reported:** 2025-12-08

**Description:**
Next.js 15.1.0 is listed as a FIXED version per CVE-2025-66478 documentation, but the scanner utility (`react2shell-scanner`) detects it as VULNERABLE. This indicates either:
1. Next.js 15.1.0 still contains the vulnerability despite being listed as fixed in the CVE documentation
2. The React version (19.2.1) used with Next.js 15.1.0 is causing incorrect detection
3. There is a configuration issue with Next.js 15.1.0 that makes it appear vulnerable
4. The CVE documentation may be incorrect about Next.js 15.1.0 being fixed

**Expected Behavior:**
- Next.js 15.1.0 should be detected as NOT VULNERABLE by the scanner
- Scanner should return status indicating the application is not vulnerable

**Actual Behavior:**
- Next.js 15.1.0 is detected as VULNERABLE by the scanner
- Scanner output shows: `[VULNERABLE] http://localhost:3000 - Status: 303`

**Scanner Verification Results:**
See [Scanner Verification Table](../scanner_verification_table.md) for complete test results.

**Test Results Summary:**
| Framework | Version | Expected | Detected | Result |
|-----------|---------|----------|----------|--------|
| Next.js | 15.1.0 | FIXED | VULNERABLE | **FAIL** |

**Steps to Reproduce:**
1. Switch to Next.js framework:
   ```bash
   make use-nextjs
   ```
2. Switch to Next.js 15.1.0:
   ```bash
   make nextjs-15.1.0
   ```
3. Start the server:
   ```bash
   make stop
   make start
   ```
4. Wait for server to be ready
5. Run scanner:
   ```bash
   cd ~/data/lblackb/git/third-party/react2shell-scanner
   ./scanner.py -u "http://localhost:3000"
   ```
6. Observe scanner detects vulnerability

**Root Cause:**
Unknown. Possible causes:
- Next.js 15.1.0 may not actually be fixed despite CVE documentation
- React 19.2.1 compatibility issue with Next.js 15.1.0
- Configuration or dependency issue
- Scanner false positive

**Environment:**
- Framework: Next.js
- Next.js Version: 15.1.0
- React Version: 19.2.1
- React-DOM Version: 19.2.1
- Scanner: react2shell-scanner (assetnote)
- Test Date: 2025-12-08

**Files Affected:**
- `frameworks/nextjs/package.json` - Next.js 15.1.0 dependency
- `docs/scanner_verification_report.txt` - Full scanner test results
- `docs/scanner_verification_table.md` - Summary table of test results

**Impact:**
- **Security:** If Next.js 15.1.0 is actually vulnerable, users may be at risk
- **Documentation:** CVE documentation may be incorrect
- **Testing:** Cannot reliably test fixed Next.js versions
- **Trust:** Undermines confidence in version status labeling

**Related Issues:**
- Next.js 14.0.0 and 14.1.0 tests failed due to connection timeouts (separate issue)
- See full test results in `docs/scanner_verification_report.txt`

**Solution:**
1. Verify CVE documentation accuracy for Next.js 15.1.0
2. Check if Next.js 15.1.0 requires additional configuration or React version
3. Investigate if this is a scanner false positive
4. Update documentation if Next.js 15.1.0 is not actually fixed
5. Consider alternative fixed Next.js versions if 15.1.0 is confirmed vulnerable
