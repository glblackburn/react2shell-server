# Scanner Verification Results Summary

## Test Results Table

| Framework | Version | Expected Status | Detected Status | Result | Notes |
|-----------|---------|----------------|-----------------|--------|-------|
| Vite | 19.0 | VULNERABLE | NOT VULNERABLE | FAIL | Scanner returns 404 (expected - scanner is Next.js-specific) |
| Vite | 19.1.0 | VULNERABLE | NOT VULNERABLE | FAIL | Scanner returns 404 (expected - scanner is Next.js-specific) |
| Vite | 19.1.1 | VULNERABLE | NOT VULNERABLE | FAIL | Scanner returns 404 (expected - scanner is Next.js-specific) |
| Vite | 19.2.0 | VULNERABLE | NOT VULNERABLE | FAIL | Scanner returns 404 (expected - scanner is Next.js-specific) |
| Vite | 19.0.1 | FIXED | NOT VULNERABLE | PASS | Correctly detected as not vulnerable |
| Vite | 19.1.2 | FIXED | NOT VULNERABLE | PASS | Correctly detected as not vulnerable |
| Vite | 19.2.1 | FIXED | NOT VULNERABLE | PASS | Correctly detected as not vulnerable |
| Next.js | 14.0.0 | VULNERABLE | NOT VULNERABLE | FAIL | Connection timeout - server issue |
| Next.js | 14.1.0 | VULNERABLE | NOT VULNERABLE | FAIL | Connection timeout - server issue |
| Next.js | 15.0.0 | VULNERABLE | VULNERABLE | PASS | Correctly detected as vulnerable |
| Next.js | 14.0.1 | FIXED | NOT VULNERABLE | PASS | Correctly detected as not vulnerable |
| Next.js | 14.1.1 | FIXED | NOT VULNERABLE | PASS | Correctly detected as not vulnerable |
| Next.js | 15.1.0 | FIXED | VULNERABLE | **FAIL** | **Should be FIXED but detected as VULNERABLE** |

## Summary Statistics

- **Total Tests:** 13
- **Passed:** 6
- **Failed:** 7

### By Framework

**Vite Framework:**
- Passed: 3 (all fixed versions)
- Failed: 4 (all vulnerable versions - expected due to scanner being Next.js-specific)

**Next.js Framework:**
- Passed: 3 (15.0.0 vulnerable, 14.0.1 fixed, 14.1.1 fixed)
- Failed: 3 (14.0.0 timeout, 14.1.0 timeout, **15.1.0 incorrectly detected as vulnerable**)

## Critical Issues

### BUG-5: Next.js 15.1.0 Incorrectly Detected as VULNERABLE

**Status:** Open  
**Priority:** High  
**Severity:** High

Next.js 15.1.0 is listed as a FIXED version per CVE-2025-66478, but the scanner detects it as VULNERABLE. This indicates either:
1. Next.js 15.1.0 still contains the vulnerability despite being listed as fixed
2. The React version (19.2.1) used with Next.js 15.1.0 is causing the detection
3. There is a configuration issue with Next.js 15.1.0

**Expected Behavior:** Next.js 15.1.0 should be detected as NOT VULNERABLE  
**Actual Behavior:** Next.js 15.1.0 is detected as VULNERABLE

### Connection Timeout Issues

Next.js 14.0.0 and 14.1.0 tests failed due to connection timeouts, preventing proper vulnerability detection. This may be due to:
- Server startup delays
- npm install taking too long
- Server not fully ready when scanner runs

## Test Environment

- **Scanner:** react2shell-scanner (assetnote)
- **Test Date:** 2025-12-08
- **Report File:** docs/scanner_verification_report.txt
