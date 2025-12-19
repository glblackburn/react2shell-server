# Plan: Test Verification Script

## Problem Statement

The assistant has been incorrectly reporting that tests are passing when they are not. We need a reliable, automated way to verify the actual test status that the assistant can use to determine when work is truly complete.

## Requirements

### Primary Goal
Create a script that provides a clear, unambiguous pass/fail status for all tests in the project.

### Key Requirements

1. **Run all tests** - Execute the full test suite (`make test-parallel`)
2. **Parse test results** - Extract actual pass/fail counts from test output
3. **Return clear status** - Provide a simple exit code and summary:
   - Exit code 0 = All tests passed
   - Exit code 1 = Any tests failed
4. **Provide summary output** - Show:
   - Total tests run
   - Tests passed
   - Tests failed
   - Tests skipped/errors
   - Overall status (PASS/FAIL)
5. **Be reliable** - Must accurately detect test failures, not just parse "✓" symbols

## Implementation Plan

### Phase 1: Basic Script Structure
- Create a bash script (`scripts/verify_tests.sh` or `scripts/test_status.sh`)
- Run `make test-parallel` and capture output
- Parse pytest output for actual test results
- Extract pass/fail counts from pytest summary line

### Phase 2: Result Parsing
- Parse pytest's final summary line: `X passed, Y failed, Z skipped, N errors`
- Handle both version-switch tests and non-version-switch tests
- Check for any failure indicators in output
- Verify all version test suites passed

### Phase 3: Status Reporting
- Print clear summary:
  ```
  TEST VERIFICATION RESULTS
  ========================
  Total Tests: X
  Passed: Y
  Failed: Z
  Skipped: N
  Errors: M
  Status: PASS/FAIL
  ```
- Return appropriate exit code
- Make output easy to parse programmatically

### Phase 4: Integration
- Add Makefile target: `make verify-tests` or `make test-status`
- Ensure script can be called from any directory
- Handle edge cases (no tests run, timeout, etc.)

## Technical Considerations

### Parsing Strategy
- Look for pytest's final summary line pattern: `\d+ passed, \d+ failed`
- Check for "FAILED" in test output
- Verify "✓ All tests completed!" message
- Check version test results: "✓ All X versions passed!"

### Error Handling
- Handle test execution failures
- Handle timeout scenarios
- Handle malformed output
- Provide meaningful error messages

### Output Format
- Clear, human-readable summary
- Machine-parseable format (optional JSON output)
- Include timestamp
- Include test duration

## Success Criteria

1. Script accurately reports test status
2. Exit code correctly reflects pass/fail
3. Can be easily called by assistant: `./scripts/verify_tests.sh`
4. Output is clear and unambiguous
5. Works in both CI and local environments

## Future Enhancements (Optional)

- JSON output option for programmatic parsing
- Detailed failure reporting (which tests failed)
- Historical tracking of test results
- Integration with CI/CD systems
- Performance metrics reporting

## Files to Create

1. `scripts/verify_tests.sh` - Main verification script
2. `Makefile` - Add `verify-tests` target (optional)
3. Documentation update - Add usage instructions

## Questions to Resolve - RESOLVED

1. Should script stop on first failure or run all tests?
   - **Answer: Run the full set of tests so all issues can be addressed**

2. Should it include performance metrics?
   - **Answer: No**

3. Should it generate a report file?
   - **Answer: Generate a report markdown file each time the script runs and open the markdown file in the browser**

4. What level of detail in output?
   - **Answer: Verbose**
