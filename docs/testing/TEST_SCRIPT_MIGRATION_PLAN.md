# Migration Plan: `simple-run-check.sh` to Standard Test Pattern

**Date:** 2025-12-22  
**Purpose:** Migrate `simple-run-check.sh` into the standard `make test-*` pattern and proper location  
**Related:** See [TEST_SMOKE_VS_SIMPLE_RUN_CHECK_COMPARISON.md](TEST_SMOKE_VS_SIMPLE_RUN_CHECK_COMPARISON.md) for comparison with `make test-smoke`

---

## Current State

### Current Script
- **Location:** `/simple-run-check.sh` (project root)
- **Name:** `simple-run-check.sh`
- **Purpose:** Verify all Next.js versions can switch, start, and respond to API
- **Usage:** `./simple-run-check.sh` or `bash simple-run-check.sh`
- **Output:** Text output with JSON responses, optionally saved to timestamped file

### Current Issues
1. ❌ Not following standard `make test-*` pattern
2. ❌ Located in project root (not with other test files)
3. ❌ Name doesn't clearly indicate it's a test script
4. ❌ Not integrated into Makefile test targets
5. ❌ Not documented in test README
6. ❌ Output files (`simple-run-check_*.txt`) in project root

---

## Proposed State

### New Script
- **Location:** `tests/test_nextjs_startup.sh`
- **Name:** `test_nextjs_startup.sh`
- **Make Target:** `make test-nextjs-startup`
- **Purpose:** Verify all Next.js versions can switch, start, and respond to API (simple startup test)
- **Usage:** `make test-nextjs-startup` or `./tests/test_nextjs_startup.sh`
- **Output:** Text output with JSON responses, optionally saved to timestamped file in `tests/reports/`

### Benefits
1. ✅ Follows standard `make test-*` pattern
2. ✅ Located with other test files in `tests/` directory
3. ✅ Clear, descriptive name indicating test purpose
4. ✅ Integrated into Makefile test targets
5. ✅ Documented in test README
6. ✅ Output files in standard test reports directory

---

## Recommended Changes

### 1. Script Rename and Relocation

**Action:** Move and rename script
- **From:** `simple-run-check.sh` (root)
- **To:** `tests/test_nextjs_startup.sh`

**Rationale:**
- `test_` prefix indicates it's a test script
- `nextjs_startup` clearly indicates it's a startup test for Next.js versions
- Simple and clear name that describes the test purpose
- Location in `tests/` directory groups it with other test files
- Follows pattern of `generate_performance_report.sh` in `tests/` directory

### 2. Script Improvements

**Enhancements to make:**
1. **Better error handling:**
   - Check if `jq` is installed
   - Check if `curl` is installed
   - Verify make targets exist
   - Handle version switching failures gracefully

2. **Output management:**
   - Save output to `tests/reports/test_all_nextjs_versions_YYYY-MM-DD_HHMMSS.txt`
   - Option to suppress output (quiet mode)
   - Option to show only failures (summary mode)

3. **Exit codes:**
   - Exit 0 if all versions pass
   - Exit 1 if any version fails
   - Exit 2 if script setup fails (missing dependencies)

4. **Documentation:**
   - Add script header with description
   - Add usage information
   - Add examples

5. **Framework mode check:**
   - Ensure Next.js mode is active
   - Switch to Next.js mode if needed
   - Warn if in wrong mode

### 3. Makefile Integration

**Add new target:**
```makefile
# Test Next.js startup for all versions (simple startup verification)
test-nextjs-startup:
	@echo "Testing Next.js startup for all versions..."
	@echo "This will verify that all Next.js versions can switch, start, and respond to API"
	@echo "⚠️  Note: This test takes ~5-10 minutes as it tests all 11 versions"
	@echo ""
	@if [ ! -f tests/test_nextjs_startup.sh ]; then \
		echo "❌ Error: tests/test_nextjs_startup.sh not found"; \
		exit 1; \
	fi
	@bash tests/test_nextjs_startup.sh
```

**Add to help:**
```makefile
@echo "  make test-nextjs-startup - Test Next.js startup for all versions (simple startup verification)"
```

**Add to .PHONY:**
```makefile
.PHONY: ... test-nextjs-startup ...
```

### 4. Output File Management

**Change output location:**
- **From:** `simple-run-check_YYYY-MM-DD_HHMMSS.txt` (root)
- **To:** `tests/reports/test_nextjs_startup_YYYY-MM-DD_HHMMSS.txt`

**Rationale:**
- Keeps test output files in standard test reports directory
- Consistent with other test outputs
- Easier to find and manage
- Can be cleaned with `make test-clean`

### 5. Documentation Updates

**Update files:**
1. **`tests/README.md`:**
   - Add section for `test-nextjs-startup`
   - Document what it tests (simple startup verification)
   - Show usage examples

2. **`README.md` (main):**
   - Add to test commands list
   - Link to test documentation

3. **`Makefile` help:**
   - Add to test commands section

4. **Create/update:**
   - Link comparison document
   - Document relationship to `make test-smoke`

---

## Implementation Steps

### Phase 1: Script Migration
1. ✅ Create improved script at `tests/test_nextjs_startup.sh`
2. ✅ Add error handling and improvements
3. ✅ Update output file location
4. ✅ Test script works correctly

### Phase 2: Makefile Integration
1. ✅ Add `test-nextjs-startup` target to Makefile
2. ✅ Add to help text
3. ✅ Add to .PHONY declaration
4. ✅ Test make target works

### Phase 3: Documentation
1. ✅ Update `tests/README.md`
2. ✅ Update main `README.md`
3. ✅ Link comparison document
4. ✅ Document in Makefile help

### Phase 4: Cleanup
1. ✅ Remove old `simple-run-check.sh`
2. ✅ Move old output files to `tests/reports/` or remove
3. ✅ Update `.gitignore` if needed
4. ✅ Final verification

---

## Detailed Script Changes

### Current Script Structure
```bash
#!/usr/bin/env bash
set -euET -o pipefail

# Stop servers
make stop

# Loop through versions
make | grep nextjs- | grep Switch | awk '{print $2}' | while read version ; do
    make ${version}    # Switch
    make start        # Start
    curl ... | jq     # Test
    make stop         # Stop
done
```

### Improved Script Structure
```bash
#!/usr/bin/env bash
set -euET -o pipefail

# Script metadata
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
REPORT_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
OUTPUT_FILE="$REPORT_DIR/test_all_nextjs_versions_${TIMESTAMP}.txt"

# Functions
check_dependencies() { ... }
ensure_nextjs_mode() { ... }
test_version() { ... }
print_summary() { ... }

# Main execution
main() {
    check_dependencies
    ensure_nextjs_mode
    mkdir -p "$REPORT_DIR"
    
    # Test all versions
    # ...
    
    print_summary
}

main "$@"
```

### Key Improvements
1. **Dependency checks:** Verify `jq`, `curl`, `make` available
2. **Framework mode:** Ensure Next.js mode is active
3. **Error handling:** Track failures, continue on errors
4. **Output management:** Save to reports directory
5. **Summary:** Show pass/fail summary at end
6. **Exit codes:** Proper exit codes for CI/CD

---

## Makefile Target Details

### Full Target Implementation
```makefile
# Test Next.js startup for all versions (simple startup verification)
# This verifies that all Next.js versions can switch, start, and respond to API
test-nextjs-startup:
	@echo "Testing Next.js startup for all versions..."
	@echo "This will verify that all Next.js versions can switch, start, and respond to API"
	@echo "⚠️  Note: This test takes ~5-10 minutes as it tests all 11 versions"
	@echo ""
	@if [ ! -f tests/test_nextjs_startup.sh ]; then \
		echo "❌ Error: tests/test_nextjs_startup.sh not found"; \
		exit 1; \
	fi
	@mkdir -p tests/reports
	@bash tests/test_nextjs_startup.sh
	@echo ""
	@echo "✓ Next.js startup test completed!"
```

### Integration with Other Test Targets
- Add to test command groups in help
- Add to test execution scripts if any
- Consider adding to CI/CD pipeline

---

## File Structure Changes

### Before
```
.
├── simple-run-check.sh
├── simple-run-check_2025-12-22_081816.txt
└── tests/
    ├── README.md
    └── ...
```

### After
```
.
└── tests/
    ├── test_nextjs_startup.sh
    ├── reports/
    │   └── test_nextjs_startup_2025-12-22_081816.txt
    ├── README.md  (updated)
    └── ...
```

---

## Testing Plan

### Pre-Migration Testing
1. ✅ Test current script works
2. ✅ Verify all 11 versions tested
3. ✅ Check output format

### Post-Migration Testing
1. ✅ Test new script location
2. ✅ Test make target
3. ✅ Verify output file location
4. ✅ Test error handling
5. ✅ Verify exit codes
6. ✅ Test backward compatibility wrapper

### Integration Testing
1. ✅ Test with `make test-clean`
2. ✅ Test with other test targets
3. ✅ Verify documentation links
4. ✅ Test in CI/CD if applicable

---

## Migration Checklist

### Script Changes
- [ ] Create `tests/test_nextjs_startup.sh`
- [ ] Add dependency checks
- [ ] Add framework mode check
- [ ] Improve error handling
- [ ] Update output file location
- [ ] Add summary output
- [ ] Test script works correctly

### Makefile Changes
- [ ] Add `test-nextjs-startup` target
- [ ] Add to help text
- [ ] Add to .PHONY declaration
- [ ] Test make target works

### Documentation Changes
- [ ] Update `tests/README.md`
- [ ] Update main `README.md`
- [ ] Link comparison document
- [ ] Update Makefile help

### Cleanup
- [ ] Move old output files
- [ ] Update `.gitignore` if needed
- [ ] Remove old script
- [ ] Final verification

---

## Rollback Plan

If issues arise:
1. Can revert Makefile changes easily
2. Script changes are isolated to `tests/` directory
3. Old script can be restored from git history if needed

---

## Success Criteria

Migration is successful when:
1. ✅ `make test-nextjs-startup` works correctly
2. ✅ Script is in `tests/` directory
3. ✅ Output files in `tests/reports/`
4. ✅ Documentation updated
5. ✅ Old script removed
6. ✅ All tests pass
7. ✅ No breaking changes (users should use new make target)

---

## Related Documentation

- [TEST_SMOKE_VS_SIMPLE_RUN_CHECK_COMPARISON.md](TEST_SMOKE_VS_SIMPLE_RUN_CHECK_COMPARISON.md) - Comparison with `make test-smoke`
- [tests/README.md](../tests/README.md) - Test documentation
- [README.md](../README.md) - Main project documentation

---

**Status:** 📋 Migration Plan Complete  
**Next Steps:** Implement Phase 1 (Script Migration)  
**Last Updated:** 2025-12-22
