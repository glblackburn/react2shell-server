# Outstanding Questions for Node.js Version Switching Implementation

**Date:** 2025-12-21  
**Status:** Pre-Implementation Review

---

## Summary

**Total Outstanding Questions:** 15  
**Critical (Must Resolve):** 6  
**Important (Should Resolve):** 4  
**Nice to Have:** 5

---

## Critical Questions (Must Resolve Before Implementation)

### 1. Auto-Install Behavior ✅ RESOLVED

**Question:** Should `nvm install` be called automatically if Node.js version is not installed?

**Decision:** ✅ **YES - Auto-install enabled**

**Implementation:**
- `nvm install 24.12.0 && nvm use 24.12.0` runs automatically
- nvm install is idempotent (safe to run multiple times)
- No environment variable to disable (always auto-installs)

**Rationale:**
- Seamless user experience
- nvm handles already-installed versions gracefully
- Network dependency acceptable (user can install manually if needed)

---

### 2. Version Comparison Implementation ✅ RESOLVED

**Question:** How to implement version comparison (check if current version satisfies requirement)?

**Decision:** ✅ **Use semver from `frameworks/nextjs/node_modules/semver`**

**Test Results:**
- ✅ semver found in `frameworks/nextjs/node_modules/semver/package.json`
- ✅ semver works correctly: `semver.satisfies('24.12.0', '>=20.9.0')` returns `true`
- ✅ semver works correctly: `semver.satisfies('18.20.8', '>=20.9.0')` returns `false`

**Implementation:**
```makefile
cd frameworks/nextjs && node -e "const semver=require('semver');process.exit(semver.satisfies(process.version, '>=24.12.0') ? 0 : 1)"
```

**Note:** Must change directory to `frameworks/nextjs` to access semver module

---

### 3. Shell Context and nvm Sourcing ✅ RESOLVED

**Question:** How to properly source nvm in Makefile context?

**Decision:** ✅ **Use `. "$$HOME/.nvm/nvm.sh"` in each recipe that needs nvm**

**Test Results:**
- ✅ nvm sourcing works in Makefile context
- ✅ Test command: `. "$$HOME/.nvm/nvm.sh" && nvm --version`
- ✅ Result: Successfully sourced and executed nvm commands

**Implementation:**
```makefile
. "$$HOME/.nvm/nvm.sh" && nvm install 24.12.0 && nvm use 24.12.0
```

**Note:** Must source nvm in each recipe line that uses nvm (sourcing doesn't persist across separate commands)

---

### 4. Error Handling Strategy ✅ RESOLVED

**Question:** What should happen in various error scenarios?

**Decision:** ✅ **Add nvm installation to Makefile setup targets**

**Error Handling:**
1. **nvm not found:** 
   - Show error message directing to `make setup`
   - `make setup` checks for nvm and provides installation instructions
   - Exit with error code 1

2. **nvm install fails:**
   - nvm will show its own error messages
   - Makefile will exit with error (due to `&&` chain)
   - User can manually install version if needed

3. **nvm use fails:**
   - nvm will show its own error messages
   - Makefile will exit with error
   - Usually means version wasn't installed (handled by auto-install)

4. **Version switch doesn't persist:**
   - Acceptable - version switch is for make command execution
   - User can manually run `nvm use` if they want persistence

5. **Node.js version still incorrect after switch:**
   - Version check happens before switch, so this shouldn't occur
   - If it does, nvm error messages will indicate the issue

**Implementation:** Added `make setup` target to check/install nvm

---

### 5. Version Persistence ✅ RESOLVED

**Question:** Should Node.js version switch persist after make command completes?

**Decision:** ✅ **YES - Version can persist**

**Implementation:**
- `nvm use 24.12.0` persists in the shell session
- If user wants persistence in their terminal, they can manually run `nvm use`
- For make commands, version switch is for the duration of the command execution

**Note:** Makefile runs in subshell, so `nvm use` in Makefile won't affect parent shell, but this is acceptable behavior.

---

### 6. Version Format and Parsing ✅ RESOLVED

**Question:** What format should be used for Node.js versions?

**Decision:** ✅ **Use exact version without 'v' prefix, strip 'v' from node -v output**

**Test Results:**
- `node -v` returns: `v18.20.8` (with 'v' prefix)
- nvm accepts: `24.12.0` or `v24.12.0` (both work)
- nvm list shows: `v18.20.8` (with 'v' prefix)

**Implementation:**
- Store versions in Makefile: `24.12.0` (without 'v')
- Parse `node -v` output: `node -v | sed 's/v//'` → `18.20.8`
- nvm commands: `nvm install 24.12.0` (works with or without 'v')

**Format Standard:**
- Makefile variables: `24.12.0` (no 'v' prefix)
- Version comparison: Strip 'v' from `node -v` output
- nvm commands: Use version without 'v' prefix for consistency

---

## Important Questions (Should Resolve During Implementation)

### 7. Version Range Handling

**Question:** How to handle version ranges like `^18.18.0 || ^19.8.0 || >= 20.0.0`?

**Status:** ✅ **RESOLVED** - Using Node.js 24.12.0 for all versions (satisfies all ranges)

**Note:** Since we're using a single latest LTS version (24.12.0) for all Next.js versions, range parsing is not needed. The version mapping is static and pre-defined.

---

### 8. Version Switching: Mandatory vs Optional

**Question:** Should version switching be mandatory or optional (via environment variable)?

**Options:**
1. **Mandatory:** Always switch if version mismatch detected
2. **Optional:** `SKIP_NODE_VERSION_CHECK=true` to disable
3. **Configurable:** `DISABLE_NODE_SWITCH=true` environment variable

**Considerations:**
- CI/CD may already have correct version
- Some users may prefer manual control
- Performance: skipping check saves time

**Action Needed:** Decide on default behavior and environment variable support

---

### 9. Performance and Optimization

**Question:** How to minimize performance impact?

**Gaps:**
- ❓ Should we check Node.js version on every `make nextjs-{version}` call?
- ❓ Should we cache the current Node.js version check?
- ❓ Should we skip check if already on correct version?

**Options:**
1. Check version once at start of Makefile
2. Check version only when switching Next.js versions
3. Cache version check result in file
4. Skip check if environment variable indicates correct version

**Action Needed:** Define performance requirements, implement caching strategy

---

### 10. CI/CD Integration

**Question:** How should this work in CI/CD environments?

**Gaps:**
- ❓ Should version switching be enabled in CI by default?
- ❓ How to handle CI environments where nvm may not be available?
- ❓ Should we use environment variables to skip switching?

**Action Needed:** Define CI/CD strategy, add environment variable to disable switching

---

## Nice to Have (Can Resolve Later)

### 11. Testing and Verification

**Question:** How to verify the implementation works correctly?

**Gaps:**
- ❓ What are the specific test cases to implement?
- ❓ How to test without nvm installed (mock or skip)?
- ❓ How to test version switching without actually installing Node.js versions?

**Action Needed:** Create detailed test plan with specific scenarios

---

### 12. Integration with simple-run-check.sh

**Question:** How will this work with the simple-run-check.sh script?

**Status:** Script calls `make nextjs-{version}` which will trigger version switching automatically.

**Action Needed:** Test version switching in script context, verify it works

---

### 13. Documentation and User Instructions

**Question:** What documentation is needed for users?

**Gaps:**
- ❓ Installation instructions for nvm (platform-specific?)
- ❓ How to verify nvm is working?
- ❓ Troubleshooting guide for common issues

**Action Needed:** Create user documentation, add troubleshooting section

---

### 14. Makefile Variable Scoping

**Question:** How do Makefile variables work in the context of version switching?

**Gaps:**
- ❓ Can `HAS_NVM` be set once at Makefile level, or must be checked each time?
- ❓ How to pass variables between Makefile functions?
- ❓ Does `$$HOME` work correctly in all contexts?

**Action Needed:** Test variable scoping in Makefile, verify variable usage

---

### 15. Version Mapping Implementation Details

**Question:** How to implement the version mapping function in Makefile?

**Status:** ✅ **RESOLVED** - Complete mapping created with all 11 versions using Node.js 24.12.0

**Implementation:**
```makefile
NEXTJS_14.0.0_NODE := 24.12.0
NEXTJS_14.0.1_NODE := 24.12.0
# ... (all 11 versions)
get_node_version = $(if $(NEXTJS_$(1)_NODE),$(NEXTJS_$(1)_NODE),24.12.0)
```

---

## Priority Summary

### ✅ Critical (All Resolved)
1. ✅ Auto-Install Behavior - **RESOLVED: YES, auto-install enabled**
2. ✅ Version Comparison Implementation - **RESOLVED: Use semver from frameworks/nextjs/node_modules**
3. ✅ Shell Context and nvm Sourcing - **RESOLVED: Tested and verified working**
4. ✅ Error Handling Strategy - **RESOLVED: Add nvm to make setup target**
5. ✅ Version Persistence - **RESOLVED: YES, can persist**
6. ✅ Version Format and Parsing - **RESOLVED: Strip 'v' prefix, use exact versions**

### 🟡 Important (Should Resolve)
7. Version Switching: Mandatory vs Optional
8. Performance and Optimization
9. CI/CD Integration

### 🟢 Nice to Have (Can Resolve Later)
10. Testing and Verification
11. Integration with simple-run-check.sh
12. Documentation and User Instructions
13. Makefile Variable Scoping

---

## Recommended Next Steps

1. **Research Phase:**
   - Test nvm sourcing in Makefile context
   - Check if semver is available in project
   - Test version persistence behavior

2. **Decision Phase:**
   - Make decisions on auto-install, version persistence, error handling
   - Define version comparison approach
   - Decide on mandatory vs optional switching

3. **Implementation Phase:**
   - Implement with decisions from phase 2
   - Test thoroughly
   - Document any deviations from design

---

**Document Status:** Questions Identified  
**Next Action:** Resolve critical questions before starting implementation
