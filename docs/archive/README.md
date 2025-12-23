# Documentation Archive

This directory contains historical documentation that has been implemented or superseded. These documents are preserved for historical reference and to document the evolution of the project.

> **Note:** Documents in this archive may contain outdated information. Always refer to the current project documentation for up-to-date information.

## Contents

### Node Version Switching Documentation

**Status:** ✅ **IMPLEMENTED**  
**Date:** Historical (implementation complete)

These documents document the node version switching implementation:

- **[NODE_VERSION_MAPPING.md](NODE_VERSION_MAPPING.md)** - Node version mapping documentation
- **[NODE_VERSION_SWITCHING_DESIGN.md](NODE_VERSION_SWITCHING_DESIGN.md)** - Design for version switching
- **[NODE_VERSION_SWITCHING_IMPLEMENTATION.md](NODE_VERSION_SWITCHING_IMPLEMENTATION.md)** - Implementation details
- **[NODE_VERSION_SWITCHING_IMPLEMENTATION_GAPS.md](NODE_VERSION_SWITCHING_IMPLEMENTATION_GAPS.md)** - Implementation gaps analysis
- **[NODE_VERSION_SWITCHING_TEST_RESULTS.md](NODE_VERSION_SWITCHING_TEST_RESULTS.md)** - Test results

**Note:** Version switching is fully implemented. See [Main README](../../README.md) for current usage.

### Next.js Version Issues

- **[NEXTJS_16.0.6_VERSION_ISSUE.md](NEXTJS_16.0.6_VERSION_ISSUE.md)** - Historical issue with Next.js 16.0.6

### Questions and Resolutions

- **[QUESTIONS_RESOLVED.md](QUESTIONS_RESOLVED.md)** - Historical questions and resolutions
- **[OUTSTANDING_QUESTIONS.md](OUTSTANDING_QUESTIONS.md)** - Historical outstanding questions

### `PERFORMANCE_TARGETS_CONSOLIDATION_RECOMMENDATION.md`

**Status:** ✅ **IMPLEMENTED** (2025-12-23)  
**Original Date:** 2025-12-22  
**Implementation Date:** 2025-12-23

**Summary:**
Recommendation document for consolidating 8 separate performance-related Makefile targets into a single unified `test-performance` target. The recommendation proposed reducing cognitive overhead and simplifying the user workflow by combining test execution, baseline updates, report generation, and console summaries into one command.

**Implementation Status:**
- ✅ Unified `test-performance` target implemented (Makefile lines 1179-1213)
- ✅ Automatic baseline update logic implemented
- ✅ HTML report generation integrated
- ✅ Console summary output added
- ✅ Help text updated to show new target prominently
- ✅ All old targets marked as deprecated with warnings
- ⚠️ Documentation update partial (README.md and PERFORMANCE_TRACKING.md still reference old targets)

**Key Features Implemented:**
- Single command: `make test-performance` runs tests, updates baseline (if needed), generates HTML report, and shows console summary
- Automatic baseline management: Updates baseline if missing or if `UPDATE_BASELINE=true`
- Comprehensive output: Both HTML report and console summary
- Backward compatibility: Old targets still work but show deprecation warnings

**Current Usage:**
```bash
# Run performance tests and generate comprehensive report (RECOMMENDED)
make test-performance

# Force baseline update
UPDATE_BASELINE=true make test-performance

# Quick baseline update only (convenience target)
make test-update-baseline
```

**Implementation Details:**
- **Makefile:** Lines 1179-1270
- **Commit:** 57ad947 (2025-12-23)
- **Result:** 8 targets → 1 primary target (+ 1 optional convenience target) = 75-87.5% reduction

**Related Documentation:**
- [Main README](../README.md) - Performance Tracking section
- [Performance Tracking Guide](../../tests/PERFORMANCE_TRACKING.md) - Current performance tracking documentation
- [Makefile](../../Makefile) - Current implementation

---

## Archive Policy

Documents are moved to this archive when:

1. **Recommendations have been fully implemented**
   - The recommendation has been acted upon and is now part of the codebase
   - Historical reference is valuable for understanding design decisions
   - Example: Performance targets consolidation

2. **Documents have been superseded by newer versions**
   - A newer, more comprehensive document replaces the old one
   - The old version is kept for historical context
   - Example: Consolidated CI/CD documentation

3. **Historical reference is needed but the document is no longer actively maintained**
   - The document contains valuable historical information
   - It's no longer the source of truth but provides context
   - Example: Design proposals that were implemented differently

**Important Notes:**
- ⚠️ Documents in this archive may contain outdated information
- ✅ Always refer to current project documentation for active guidance
- 📖 These documents are preserved for historical reference and design decision documentation
- 🔗 Links to archived documents may appear in the main README or other documentation

---

## Finding Current Documentation

For current, actively maintained documentation, see:

- **[Main README](../../README.md)** - Project overview and quick start
- **[Planning Documentation](../planning/README.md)** - Active planning and implementation guides
- **[Testing Documentation](../../tests/README.md)** - Current testing guides and documentation
- **[Development Narrative](../../DEVELOPMENT_NARRATIVE.md)** - Project development history
