# Node.js Version Switching Design Document

**Date:** 2025-12-21  
**Purpose:** Design capability to automatically switch Node.js versions to meet Next.js requirements  
**Status:** Design Complete - nvm and Pre-defined Version Mapping Selected for Implementation

---

## Problem Statement

Next.js 16.0.6 requires Node.js >= 20.9.0, but the current system is running Node.js v18.20.8. This causes Next.js 16.0.6 to fail silently (server starts but exits immediately).

**Current State:**
- System Node.js: v18.20.8
- Next.js 16.0.6 requirement: >= 20.9.0
- Makefile now detects and errors, but doesn't fix the issue

**Goal:**
Automatically switch to the correct Node.js version when switching Next.js versions, ensuring compatibility.

---

## Requirements

### Functional Requirements

1. **Automatic Version Detection:**
   - Detect required Node.js version for each Next.js version
   - Check current Node.js version
   - Switch if current version doesn't meet requirements

2. **Version Switching:**
   - Support switching Node.js versions on-demand
   - Work with existing Node.js version managers (nvm, n, fnm, etc.)
   - Fallback gracefully if no version manager is available

3. **Integration with Existing Workflow:**
   - Integrate with `make nextjs-{version}` targets
   - Work with `simple-run-check.sh` script
   - Maintain compatibility with existing test infrastructure

4. **Version Mapping:**
   - Map Next.js versions to required Node.js versions
   - Handle version ranges (e.g., >= 20.9.0)
   - Support multiple Next.js versions with same Node.js requirement

### Non-Functional Requirements

1. **Performance:**
   - Version switching should be fast (< 5 seconds)
   - Should not significantly slow down `make nextjs-{version}`

2. **Reliability:**
   - Should not break existing functionality
   - Should handle missing version managers gracefully
   - Should provide clear error messages

3. **Maintainability:**
   - Easy to update version mappings
   - Clear documentation
   - Minimal code changes to existing Makefile

---

## Design Options

### Option 1: Node Version Manager (nvm) - ✅ SELECTED

**Status:** This option has been selected for implementation.

**Pros:**
- Most popular Node.js version manager
- Well-documented and widely used
- Supports automatic version switching via `.nvmrc` files
- Works on macOS, Linux, Windows (via nvm-windows)
- Large community and extensive resources
- Reliable and well-tested

**Cons:**
- Requires nvm to be installed
- Shell initialization can be tricky
- May need to source nvm in Makefile context

**Implementation:**
- Check if nvm is available
- Use `nvm install` and `nvm use` commands
- Create `.nvmrc` files for different Next.js versions (optional)
- Source nvm in Makefile if needed
- Show clear error with installation instructions if nvm not found

### Option 2: n (Node Version Manager)

**Pros:**
- Simpler than nvm
- Works well on macOS/Linux
- Easy to install and use

**Cons:**
- Less popular than nvm
- Requires sudo on some systems
- No automatic switching via config files

**Implementation:**
- Check if n is available
- Use `n {version}` to install and switch
- May need sudo permissions

### Option 3: fnm (Fast Node Manager)

**Pros:**
- Fast performance
- Cross-platform (macOS, Linux, Windows)
- Written in Rust
- Supports `.node-version` files

**Cons:**
- Less popular than nvm
- Requires installation
- May not be available on all systems

**Implementation:**
- Check if fnm is available
- Use `fnm install` and `fnm use`
- Create `.node-version` files

### Option 4: asdf (Version Manager)

**Pros:**
- Supports multiple languages (Node.js, Python, Ruby, etc.)
- Plugin-based architecture
- Good for multi-language projects

**Cons:**
- More complex setup
- Less popular for Node.js specifically
- Requires plugin installation

### Option 5: Direct Node.js Installation Detection

**Pros:**
- No external dependencies
- Works if multiple Node.js versions are installed via different methods

**Cons:**
- Requires manual Node.js version installation
- Complex PATH management
- Platform-specific implementation

---

## Selected Version Manager: nvm (Node Version Manager)

**Decision:** nvm has been selected as the version manager for Node.js version switching.

**Rationale:**
- Most widely used and supported
- Good documentation and community support
- Automatic switching via `.nvmrc` files
- Well-tested and reliable
- Large community and extensive resources

**Fallback Strategy:**
1. **Primary:** Use nvm for all Node.js version switching
2. **If nvm not available:** Show clear error message with nvm installation instructions
3. **No fallback to other managers:** Keep implementation simple and focused on nvm

**Note:** This decision simplifies implementation by focusing on a single, well-supported tool rather than supporting multiple version managers.

---

## Node.js Version Determination Strategy

This section describes different approaches for determining which Node.js version is required for each Next.js version.

### Option A: Pre-defined Version Mapping (Static) - ✅ SELECTED

**Status:** This option has been selected for implementation.

**Description:** Hard-code Node.js version requirements in the Makefile for each Next.js version.

**Implementation:**
```makefile
# Node.js version requirements for Next.js versions
# Using latest Node.js LTS (24.12.0) that satisfies all Next.js engine requirements
# Next.js 14.x requires: >=18.17.0
# Next.js 15.x requires: ^18.18.0 || ^19.8.0 || >= 20.0.0
# Next.js 16.0.6 requires: >=20.9.0
# All versions support Node.js 24.12.0 (current LTS)
NEXTJS_14.0.0_NODE := 24.12.0
NEXTJS_14.0.1_NODE := 24.12.0
NEXTJS_14.1.0_NODE := 24.12.0
NEXTJS_14.1.1_NODE := 24.12.0
NEXTJS_15.0.4_NODE := 24.12.0
NEXTJS_15.1.8_NODE := 24.12.0
NEXTJS_15.2.5_NODE := 24.12.0
NEXTJS_15.3.5_NODE := 24.12.0
NEXTJS_15.4.7_NODE := 24.12.0
NEXTJS_15.5.6_NODE := 24.12.0
NEXTJS_16.0.6_NODE := 24.12.0

# Function to get required Node.js version
get_node_version = $(NEXTJS_$(1)_NODE)
```

**Pros:**
- ✅ Fast (no network calls)
- ✅ Works offline
- ✅ Predictable and reliable
- ✅ Easy to understand and debug
- ✅ No npm dependency for version lookup
- ✅ Simple implementation

**Cons:**
- ❌ Requires manual updates when Next.js versions change
- ❌ May become outdated if Next.js updates requirements
- ❌ Doesn't handle version ranges (e.g., `^18.18.0 || >= 20.0.0`)
- ❌ Need to maintain mapping for each new Next.js version

---

### Option B: Runtime npm Registry Query (Dynamic)

**Description:** Query npm registry at runtime to get Node.js engine requirements from package metadata.

**Implementation:**
```makefile
# Query npm registry for Node.js version requirement
get_node_version = $(shell npm view next@$(1) engines.node 2>/dev/null | sed 's/[{}"]//g' | cut -d: -f2 | xargs)
```

**Pros:**
- ✅ Always up-to-date (queries live npm registry)
- ✅ No manual maintenance needed
- ✅ Automatically handles new Next.js versions
- ✅ Gets actual version ranges from package.json

**Cons:**
- ❌ Requires network connection
- ❌ Slower (network latency on each query)
- ❌ May fail if npm registry is down
- ❌ More complex parsing of version ranges
- ❌ Requires npm to be available
- ❌ May have rate limiting issues with frequent queries

---

### Option C: Hybrid Approach (Cached Query)

**Description:** Query npm registry once, cache results, fallback to pre-defined mapping if query fails.

**Implementation:**
```makefile
# Try to get from cache or query npm, fallback to default
get_node_version = $(shell \
	if [ -f .node-versions-cache ] && grep -q "^$(1):" .node-versions-cache; then \
		grep "^$(1):" .node-versions-cache | cut -d: -f2; \
	elif REQUIRED=$$(npm view next@$(1) engines.node 2>/dev/null); then \
		echo "$$REQUIRED" | sed 's/[{}"]//g' | cut -d: -f2 | xargs; \
		echo "$(1):$$REQUIRED" >> .node-versions-cache; \
	else \
		echo "$(NODE_VERSION_DEFAULT)"; \
	fi \
)
```

**Pros:**
- ✅ Best of both worlds (fast after first query, always current)
- ✅ Works offline after initial cache
- ✅ Automatic updates when cache is refreshed
- ✅ Fallback to defaults if query fails

**Cons:**
- ❌ More complex implementation
- ❌ Requires cache management
- ❌ Still needs network for first run or cache refresh
- ❌ Cache may become stale

---

### Option D: Minimum Version Simplification

**Description:** Use minimum required Node.js version for each Next.js major version, ignoring ranges.

**Implementation:**
```makefile
# Simplified: Use minimum Node.js version per Next.js major version
# Next.js 14.x and 15.x: Node.js 18.18.0 (minimum that works)
# Next.js 16.x: Node.js 20.9.0 (minimum required)
NODE_VERSION_14 := 18.18.0
NODE_VERSION_15 := 18.18.0
NODE_VERSION_16 := 20.9.0

get_node_version = $(shell \
	MAJOR=$$(echo $(1) | cut -d. -f1); \
	case "$$MAJOR" in \
		14) echo "$(NODE_VERSION_14)" ;; \
		15) echo "$(NODE_VERSION_15)" ;; \
		16) echo "$(NODE_VERSION_16)" ;; \
		*) echo "$(NODE_VERSION_DEFAULT)" ;; \
	esac \
)
```

**Pros:**
- ✅ Very simple implementation
- ✅ Easy to maintain (one value per major version)
- ✅ Fast (no network, simple logic)
- ✅ Works for all versions in a major release

**Cons:**
- ❌ May use newer Node.js than strictly necessary
- ❌ Doesn't account for version-specific requirements
- ❌ May miss edge cases where specific patch versions need different Node.js

---

## Selected Approach: Pre-defined Version Mapping (Option A) - ✅ SELECTED

**Status:** This option has been selected for implementation.

**Rationale:** 
- Fastest and most reliable
- Works offline
- Simple to implement and maintain
- Only 11 Next.js versions to maintain
- No network dependency
- Predictable behavior

**Version Mapping:** See `docs/NODE_VERSION_MAPPING.md` for complete version mapping details.
- All Next.js versions use **Node.js 24.12.0** (current LTS)
- This version satisfies all Next.js engine requirements
- Strategy: Use latest Node.js LTS that is supported by React and Next.js frameworks

**Implementation:**
```makefile
# Get required Node.js version for Next.js version
# All versions use Node.js 24.12.0 (current LTS) which satisfies all Next.js engine requirements
NODE_VERSION_DEFAULT := 24.12.0

# Individual version mappings (all use latest LTS)
NEXTJS_14.0.0_NODE := 24.12.0
NEXTJS_14.0.1_NODE := 24.12.0
NEXTJS_14.1.0_NODE := 24.12.0
NEXTJS_14.1.1_NODE := 24.12.0
NEXTJS_15.0.4_NODE := 24.12.0
NEXTJS_15.1.8_NODE := 24.12.0
NEXTJS_15.2.5_NODE := 24.12.0
NEXTJS_15.3.5_NODE := 24.12.0
NEXTJS_15.4.7_NODE := 24.12.0
NEXTJS_15.5.6_NODE := 24.12.0
NEXTJS_16.0.6_NODE := 24.12.0

# Function to get required Node.js version
get_node_version = $(if $(NEXTJS_$(1)_NODE),$(NEXTJS_$(1)_NODE),$(NODE_VERSION_DEFAULT))
```

**Usage in switch function:**
```makefile
16.0.6) \
	echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
	REQUIRED_NODE=$(call get_node_version,$(1)); \
	$(call ensure_node_version,$$REQUIRED_NODE); \
	# ... rest of switch logic ...
```

**Maintenance:**
- When adding new Next.js versions, add corresponding `NODE_VERSION_<version>` variable
- Update version mapping if Next.js requirements change
- Simple to verify and test

---

## Version Manager Detection Strategy

This section describes how to detect if nvm (Node Version Manager) is available on the system.

**Implementation:**
```makefile
# Check if nvm is available
# nvm is a shell function, not a binary, so check for the nvm.sh script
HAS_NVM := $(shell [ -s "$$HOME/.nvm/nvm.sh" ] && echo "yes" || command -v nvm 2>/dev/null && echo "yes" || echo "no")
```

**Detection Logic:**
1. Check for `~/.nvm/nvm.sh` file (standard nvm installation location)
2. Fallback: Check if `nvm` command is available in PATH
3. Set `HAS_NVM` variable to "yes" or "no"

**Why nvm only:**
- Simplifies implementation (no need to support multiple managers)
- nvm is the most popular and widely used
- Reduces complexity and maintenance burden
- Clear error messages guide users to install nvm if needed

**Detection Logic:**
- Check if command is in PATH
- For nvm, also check for `~/.nvm/nvm.sh` file (nvm is a shell function, not a binary)
- Set flag variables that can be used in version switching function

---

## Node.js Version Switching Function

This section describes the function that checks current Node.js version and switches using nvm if needed.

**Implementation:**
```makefile
# Function to check and switch Node.js version using nvm
# Usage: $(call ensure_node_version,required_version)
# Decision: Auto-install enabled, version persistence enabled, use semver from nextjs/node_modules
define ensure_node_version
	@CURRENT_NODE=$$(node -v | sed 's/v//'); \
	REQUIRED="$(1)"; \
	@if ! cd frameworks/nextjs && node -e "const semver=require('semver');process.exit(semver.satisfies(process.version, '>=$$REQUIRED') ? 0 : 1)" 2>/dev/null; then \
		echo "⚠️  Node.js version mismatch detected"; \
		echo "   Current: $$CURRENT_NODE"; \
		echo "   Required: >= $(1)"; \
		if [ -s "$$HOME/.nvm/nvm.sh" ]; then \
			echo "   Switching to Node.js $(1) using nvm..."; \
			. "$$HOME/.nvm/nvm.sh" && nvm install $(1) && nvm use $(1); \
			echo "✓ Switched to Node.js $(1)"; \
		else \
			echo "❌ Error: nvm (Node Version Manager) not found"; \
			echo "   Please run 'make setup' to install nvm"; \
			echo "   Or install manually: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"; \
			exit 1; \
		fi; \
	fi
endef
```

**Key Decisions:**
- ✅ **Auto-install:** Enabled - `nvm install` runs automatically if version not installed
- ✅ **Version persistence:** Enabled - version switch persists in shell (via nvm use)
- ✅ **Version comparison:** Uses semver from `frameworks/nextjs/node_modules/semver`
- ✅ **nvm sourcing:** Tested and works in Makefile context using `. "$$HOME/.nvm/nvm.sh"`
```

**Function Flow:**
1. Get current Node.js version (strip 'v' prefix)
2. Compare with required version using semver from `frameworks/nextjs/node_modules`
3. If mismatch and nvm is available, auto-install and switch using nvm
4. If nvm not available, show error directing user to run `make setup`

**Key Implementation Details:**
- ✅ **nvm sourcing:** `. "$$HOME/.nvm/nvm.sh"` - tested and verified working in Makefile
- ✅ **Auto-install:** `nvm install $(1)` runs automatically (idempotent)
- ✅ **Version persistence:** `nvm use $(1)` persists in shell session
- ✅ **Version comparison:** Uses semver from `frameworks/nextjs/node_modules/semver`
- ✅ **Error handling:** Directs to `make setup` if nvm not found

**Version Comparison:**
- ✅ Uses semver library from `frameworks/nextjs/node_modules/semver` (verified available)
- Supports ranges like `>=24.12.0`, `^18.18.0`, etc.
- Version format: `node -v` returns `v18.20.8`, strip 'v' prefix with `sed 's/v//'`
- Comparison: `semver.satisfies(process.version, '>=24.12.0')` returns true/false

**nvm Commands:**
- `nvm install <version>` - Install Node.js version (if not already installed)
- `nvm use <version>` - Switch to Node.js version
- Both commands are idempotent (safe to run multiple times)

---

## Integration with Next.js Version Switching

This section describes how to integrate Node.js version checking into the existing `switch_nextjs_version` function.

**Implementation:**
```makefile
define switch_nextjs_version
	@if ! grep -q '^nextjs' .framework-mode 2>/dev/null; then \
		echo "⚠️  Error: Next.js version switching only available in Next.js mode"; \
		echo "   Run 'make use-nextjs' first to switch to Next.js mode"; \
		exit 1; \
	fi
	@# Get required Node.js version for this Next.js version
	@REQUIRED_NODE=$(call get_node_version,$(1)); \
	@# Ensure correct Node.js version
	@$(call ensure_node_version,$$REQUIRED_NODE)
	@case "$(1)" in \
		# ... existing case statements ...
	esac
endef
```

**Integration Points:**
- Before package.json modification
- Before npm install
- After framework mode check

**Flow:**
1. Check framework mode (existing)
2. **NEW:** Get required Node.js version
3. **NEW:** Ensure correct Node.js version (switch if needed)
4. Continue with existing Next.js version switch logic

---

## File Structure

```
.
├── Makefile                    # Modified to include Node.js version switching
├── .nvmrc                      # Optional: Default Node.js version for project
├── frameworks/
│   └── nextjs/
│       └── .nvmrc              # Optional: Node.js version for Next.js framework
└── docs/
    └── NODE_VERSION_SWITCHING_DESIGN.md  # This document
```

---

## Implementation Steps

### Phase 1: Version Manager Detection
1. Add functions to detect nvm, fnm, n
2. Test detection on different systems
3. Document installation requirements

### Phase 2: Version Mapping
1. Create mapping of Next.js versions to Node.js requirements
2. Support both pre-defined mapping and runtime query
3. Handle version range parsing (>=, ^, etc.)

### Phase 3: Version Switching Logic
1. Implement `ensure_node_version` function
2. Add version comparison logic
3. Implement switching for each version manager

### Phase 4: Integration
1. Integrate with `switch_nextjs_version` function
2. Update `nextjs-16.0.6` case to use new logic
3. Test with all Next.js versions

### Phase 5: Testing & Documentation
1. Test on clean system (no version manager)
2. Test with nvm installed
3. Test with fnm installed
4. Test version switching for each Next.js version
5. Update documentation

---

## Edge Cases & Considerations

### 1. No Version Manager Installed
- **Solution:** Show clear error with installation instructions
- **Fallback:** Allow manual Node.js version switching

### 2. Version Manager Not in PATH
- **Solution:** Try common installation locations (e.g., `~/.nvm/nvm.sh`)
- **Fallback:** Provide instructions to source version manager

### 3. Required Node.js Version Not Installed
- **Solution:** Automatically install using version manager
- **Consideration:** May take time on first run

### 4. Version Range Parsing
- **Challenge:** npm engines field uses ranges (>=, ^, ||)
- **Solution:** Use semver library or simple version comparison
- **Alternative:** Pre-define minimum versions for each Next.js version

### 5. Shell Context
- **Challenge:** Makefile runs in different shell context than interactive shell
- **Solution:** Source version manager in Makefile (e.g., `. ~/.nvm/nvm.sh`)

### 6. Performance
- **Consideration:** Version switching adds overhead
- **Solution:** Cache version checks, only switch when needed

### 7. CI/CD Environments
- **Consideration:** CI may have different setup
- **Solution:** Make version switching optional/configurable
- **Alternative:** Use environment variables to skip switching

### 8. Multiple Node.js Installations
- **Challenge:** System may have multiple Node.js installations
- **Solution:** Version manager handles this, but need to ensure it's used

---

## Testing Strategy

### Unit Tests
1. Test version manager detection
2. Test version comparison logic
3. Test version mapping lookup

### Integration Tests
1. Test `make nextjs-16.0.6` with Node.js 18 (should switch to 20.9.0)
2. Test `make nextjs-15.5.6` with Node.js 18 (should work, no switch needed)
3. Test `make nextjs-14.0.0` with Node.js 18 (should work, no switch needed)

### System Tests
1. Test on system with nvm installed
2. Test on system with fnm installed
3. Test on system with no version manager
4. Test `simple-run-check.sh` with all versions

### Edge Case Tests
1. Test when required Node.js version not installed (should auto-install)
2. Test when version manager not in PATH
3. Test version switching performance

---

## Configuration Options

### Environment Variables

```makefile
# Allow disabling automatic Node.js version switching
DISABLE_NODE_SWITCH ?= false

# Specify Node.js version manager to use (nvm, fnm, n, auto)
NODE_VERSION_MANAGER ?= auto

# Allow skipping version check (for CI/CD)
SKIP_NODE_VERSION_CHECK ?= false
```

### Makefile Targets

```makefile
# Check Node.js version for a specific Next.js version
check-node-version:
	@REQUIRED=$$(npm view next@$(VERSION) engines.node); \
	echo "Next.js $(VERSION) requires: $$REQUIRED"; \
	echo "Current Node.js: $$(node -v)"

# Install required Node.js version for Next.js 16.0.6
install-node-20:
	@if command -v nvm >/dev/null 2>&1; then \
		. ~/.nvm/nvm.sh && nvm install 20.9.0 && nvm use 20.9.0; \
	elif command -v fnm >/dev/null 2>&1; then \
		fnm install 20.9.0 && fnm use 20.9.0; \
	else \
		echo "Please install nvm or fnm to switch Node.js versions"; \
	fi
```

---

## Alternative: Simplified Approach

If full version manager integration is too complex, consider a simpler approach:

### Option A: Documentation Only
- Document Node.js version requirements
- Provide manual instructions for switching
- Keep current error message

### Option B: Pre-flight Check with Instructions
- Check Node.js version
- If incompatible, show error with specific installation command
- Example: "Run: nvm install 20.9.0 && nvm use 20.9.0"

### Option C: .nvmrc File Generation
- Generate `.nvmrc` file with required Node.js version
- User runs `nvm use` manually
- Makefile checks if correct version is active

---

## Recommended Implementation

**Selected Approach:**
- **Version Manager:** nvm only ✅ (SELECTED)
- **Version Determination:** Pre-defined version mapping (Option A) ✅ (SELECTED)
- **Scope:** Start with Next.js 16.0.6, expand to all versions

**Phase 1 (Initial Implementation):**
1. Add nvm detection function
2. Add `ensure_node_version` function (nvm only)
3. Integrate with `nextjs-16.0.6` case only
4. Use pre-defined version mapping (20.9.0 for 16.0.6)
5. Test with nvm installed and not installed

**Phase 2 (Expand to All Versions):**
1. Add version mapping for all Next.js versions
2. Integrate `ensure_node_version` into all `nextjs-{version}` cases
3. Test with all Next.js versions
4. Update documentation

**Phase 3 (Enhancements - Optional):**
1. Auto-install Node.js versions if not already installed
2. Performance optimizations (cache checks)
3. CI/CD integration considerations
4. Comprehensive testing across different systems

---

## Dependencies

### Required
- **nvm (Node Version Manager)** - Required for automatic Node.js version switching
  - Installation: `make setup` (checks and provides installation instructions)
  - Manual: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash`
  - Or: `brew install nvm` (macOS)
- **semver library** - Available in `frameworks/nextjs/node_modules/semver` (used for version comparison)

### Optional
- npm (for querying package engines - not needed with pre-defined mapping)
- jq (for JSON parsing if querying npm registry - not needed with pre-defined mapping)

---

## Documentation Updates Needed

1. **README.md:**
   - Add Node.js version manager installation instructions
   - Document Node.js version requirements per Next.js version
   - Add troubleshooting section

2. **Makefile Help:**
   - Add `make check-node-version` target
   - Add `make install-node-20` target
   - Document environment variables

3. **Setup Guide:**
   - Installation steps for nvm/fnm
   - How to verify Node.js version switching works
   - Common issues and solutions

---

## Success Criteria

1. ✅ `make nextjs-16.0.6` automatically switches to Node.js 20.9.0+ if available
2. ✅ `simple-run-check.sh` completes successfully for all versions including 16.0.6
3. ✅ Clear error messages when version manager not available
4. ✅ No breaking changes to existing functionality
5. ✅ Works with at least one version manager (nvm recommended)
6. ✅ Documentation is clear and complete

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Version manager not installed | High | Clear error messages, installation instructions |
| Version switching fails | Medium | Fallback to error message, don't break existing flow |
| Performance degradation | Low | Cache checks, only switch when needed |
| Shell context issues | Medium | Proper sourcing of version manager scripts |
| CI/CD incompatibility | Low | Make switching optional via environment variable |

---

## Timeline Estimate

- **Design:** ✅ Complete (this document)
- **Phase 1 Implementation:** 2-4 hours
- **Phase 2 Implementation:** 4-6 hours
- **Testing:** 2-3 hours
- **Documentation:** 1-2 hours

**Total:** ~10-15 hours

---

## Decisions Made

1. ✅ **Version Manager:** nvm only (SELECTED)
2. ✅ **Version Determination:** Pre-defined version mapping - Option A (SELECTED)
3. ⏳ **Version Switching:** To be determined (mandatory vs optional)
4. ⏳ **Version Range Handling:** To be determined (use minimum version vs full range parsing)
5. ⏳ **Auto-install:** To be determined (auto-install Node.js versions or require manual installation)

**Selected Configuration:**
- **Version Manager:** nvm (Node Version Manager)
- **Version Determination:** Pre-defined static mapping in Makefile
- **Implementation Scope:** Start with Next.js 16.0.6, expand to all versions

## Remaining Open Questions ✅ RESOLVED

1. ✅ **Version switching:** Mandatory (no environment variable to disable)
2. ✅ **Version range handling:** Using single latest LTS (24.12.0) for all versions - no range parsing needed
3. ✅ **Auto-install:** YES - `nvm install` runs automatically if version not installed
4. ✅ **Version persistence:** YES - version switch persists in shell (via `nvm use`)

**Additional Resolutions:**
- ✅ **nvm sourcing:** Tested and verified - works in Makefile using `. "$$HOME/.nvm/nvm.sh"`
- ✅ **Version comparison:** Uses semver from `frameworks/nextjs/node_modules/semver`
- ✅ **Version format:** Strip 'v' prefix from `node -v` output using `sed 's/v//'`
- ✅ **nvm installation:** Added to Makefile setup targets (see Setup section)

---

**Document Status:** Design Complete  
**Next Steps:** Review design, make implementation decision, proceed with Phase 1
