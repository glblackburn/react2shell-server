# Implementation Plan: Version Centralization, Makefile Refactoring, and CI/CD

**Date:** 2025-12-22  
**Status:** Planning  
**Priority:** High

---

## Executive Summary

This plan addresses three high-priority improvements:
1. **Centralize Version Constants** - Single source of truth for all version definitions
2. **Improve Makefile Maintainability** - Refactor complex Makefile into manageable components
3. **Add CI/CD with GitHub Actions** - Automated testing pipeline

**Estimated Total Time:** 12-16 hours  
**Phases:** 3 phases, can be executed incrementally

---

## Table of Contents

1. [Phase 1: Centralize Version Constants](#phase-1-centralize-version-constants)
2. [Phase 2: Improve Makefile Maintainability](#phase-2-improve-makefile-maintainability)
3. [Phase 3: Add CI/CD with GitHub Actions](#phase-3-add-cicd-with-github-actions)
4. [Dependencies and Prerequisites](#dependencies-and-prerequisites)
5. [Testing Strategy](#testing-strategy)
6. [Rollback Plan](#rollback-plan)

---

## Phase 1: Centralize Version Constants

### Overview

Create a single source of truth for version constants that all components (Makefile, server, tests, scripts) can consume.

**Current State:**
- Versions defined in 6+ locations:
  - `Makefile` (shell variables)
  - `server/config/versions.js` (JavaScript - React only)
  - `tests/utils/version_constants.py` (Python - React only)
  - `tests/utils/nextjs_version_constants.py` (Python - Next.js only)
  - `scripts/verify_scanner.sh` (bash arrays)
  - `scripts/scanner_verification_report.sh` (bash arrays)

**Target State:**
- Single JSON/YAML config file as source of truth
- All components read from this file
- Easy to add new versions

### Step 1.1: Create Centralized Version Configuration File

**File:** `config/versions.json`

```json
{
  "react": {
    "vulnerable": ["19.0", "19.1.0", "19.1.1", "19.2.0"],
    "fixed": ["19.0.1", "19.1.2", "19.2.1"],
    "default": "19.0"
  },
  "nextjs": {
    "vulnerable": ["14.0.0", "14.1.0", "15.0.4", "15.1.8", "15.2.5", "15.3.5", "15.4.7", "15.5.6", "16.0.6"],
    "fixed": ["14.0.1", "14.1.1"],
    "default": "15.0.4"
  },
  "node": {
    "default": "24.12.0",
    "nextjs": {
      "14.0.0": "24.12.0",
      "14.0.1": "24.12.0",
      "14.1.0": "24.12.0",
      "14.1.1": "24.12.0",
      "15.0.4": "24.12.0",
      "15.1.8": "24.12.0",
      "15.2.5": "24.12.0",
      "15.3.5": "24.12.0",
      "15.4.7": "24.12.0",
      "15.5.6": "24.12.0",
      "16.0.6": "24.12.0"
    }
  },
  "reactVersionsForNextjs": {
    "14.x": "18.3.0",
    "14.0.0": "18.3.0",
    "14.1.0": "18.2.0",
    "14.0.1": "18.2.0",
    "14.1.1": "18.2.0",
    "15.x": "19.2.0",
    "16.x": "19.2.0"
  }
}
```

**Tasks:**
1. Create `config/` directory if it doesn't exist
2. Create `config/versions.json` with above structure
3. Add validation script to verify JSON structure
4. Document schema in `config/README.md`

**Time Estimate:** 1 hour

### Step 1.2: Create Version Reader Utilities

Create utilities for each language to read from the centralized config.

#### 1.2.1: JavaScript/Node.js Reader

**File:** `server/config/version_reader.js`

```javascript
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const VERSIONS_CONFIG_PATH = join(__dirname, '..', '..', 'config', 'versions.json');

let versionsConfig = null;

function loadVersionsConfig() {
  if (!versionsConfig) {
    versionsConfig = JSON.parse(readFileSync(VERSIONS_CONFIG_PATH, 'utf-8'));
  }
  return versionsConfig;
}

export function getReactVersions() {
  const config = loadVersionsConfig();
  return {
    vulnerable: config.react.vulnerable,
    fixed: config.react.fixed,
    all: [...config.react.vulnerable, ...config.react.fixed],
    default: config.react.default
  };
}

export function getNextjsVersions() {
  const config = loadVersionsConfig();
  return {
    vulnerable: config.nextjs.vulnerable,
    fixed: config.nextjs.fixed,
    all: [...config.nextjs.vulnerable, ...config.nextjs.fixed],
    default: config.nextjs.default
  };
}

export function getNodeVersionForNextjs(nextjsVersion) {
  const config = loadVersionsConfig();
  return config.node.nextjs[nextjsVersion] || config.node.default;
}

export function getReactVersionForNextjs(nextjsVersion) {
  const config = loadVersionsConfig();
  // Extract major version (e.g., "14" from "14.0.0")
  const majorVersion = nextjsVersion.split('.')[0];
  const versionKey = `${majorVersion}.x`;
  
  // Check for exact match first
  if (config.reactVersionsForNextjs[nextjsVersion]) {
    return config.reactVersionsForNextjs[nextjsVersion];
  }
  
  // Fall back to major version
  return config.reactVersionsForNextjs[versionKey] || config.reactVersionsForNextjs['15.x'];
}

export function isVulnerableVersion(version, type = 'react') {
  const config = loadVersionsConfig();
  if (type === 'react') {
    return config.react.vulnerable.includes(version);
  } else if (type === 'nextjs') {
    return config.nextjs.vulnerable.includes(version);
  }
  return false;
}

export function getVersionStatus(version, type = 'react') {
  const config = loadVersionsConfig();
  if (isVulnerableVersion(version, type)) {
    return 'VULNERABLE';
  } else if (type === 'react' && config.react.fixed.includes(version)) {
    return 'FIXED';
  } else if (type === 'nextjs' && config.nextjs.fixed.includes(version)) {
    return 'FIXED';
  }
  return 'UNKNOWN';
}
```

**Tasks:**
1. Create `server/config/version_reader.js`
2. Update `server/config/versions.js` to use version_reader.js
3. Update `server/server.js` to use new version reader
4. Test server endpoints

**Time Estimate:** 1.5 hours

#### 1.2.2: Python Reader

**File:** `tests/utils/version_reader.py`

```python
"""Version reader utility for Python tests.

Reads version constants from centralized config/versions.json file.
"""
import json
import os
from pathlib import Path
from typing import Dict, List, Optional

# Path to versions.json (relative to project root)
PROJECT_ROOT = Path(__file__).parent.parent.parent
VERSIONS_CONFIG_PATH = PROJECT_ROOT / "config" / "versions.json"

_versions_config: Optional[Dict] = None


def _load_versions_config() -> Dict:
    """Load versions configuration from JSON file."""
    global _versions_config
    if _versions_config is None:
        if not VERSIONS_CONFIG_PATH.exists():
            raise FileNotFoundError(
                f"Versions config not found at {VERSIONS_CONFIG_PATH}"
            )
        with open(VERSIONS_CONFIG_PATH, 'r') as f:
            _versions_config = json.load(f)
    return _versions_config


def get_react_versions() -> Dict[str, List[str]]:
    """Get React version lists.
    
    Returns:
        Dictionary with keys: 'vulnerable', 'fixed', 'all', 'default'
    """
    config = _load_versions_config()
    react = config['react']
    return {
        'vulnerable': react['vulnerable'],
        'fixed': react['fixed'],
        'all': react['vulnerable'] + react['fixed'],
        'default': react['default']
    }


def get_nextjs_versions() -> Dict[str, List[str]]:
    """Get Next.js version lists.
    
    Returns:
        Dictionary with keys: 'vulnerable', 'fixed', 'all', 'default'
    """
    config = _load_versions_config()
    nextjs = config['nextjs']
    return {
        'vulnerable': nextjs['vulnerable'],
        'fixed': nextjs['fixed'],
        'all': nextjs['vulnerable'] + nextjs['fixed'],
        'default': nextjs['default']
    }


def is_vulnerable_version(version: str, version_type: str = 'react') -> bool:
    """Check if a version is vulnerable.
    
    Args:
        version: Version string (e.g., '19.0', '15.0.4')
        version_type: 'react' or 'nextjs'
    
    Returns:
        True if version is vulnerable, False otherwise
    """
    config = _load_versions_config()
    if version_type == 'react':
        return version in config['react']['vulnerable']
    elif version_type == 'nextjs':
        return version in config['nextjs']['vulnerable']
    return False


def get_version_status(version: str, version_type: str = 'react') -> str:
    """Get status string for a version.
    
    Args:
        version: Version string
        version_type: 'react' or 'nextjs'
    
    Returns:
        'VULNERABLE', 'FIXED', or 'UNKNOWN'
    """
    config = _load_versions_config()
    if is_vulnerable_version(version, version_type):
        return 'VULNERABLE'
    
    if version_type == 'react' and version in config['react']['fixed']:
        return 'FIXED'
    elif version_type == 'nextjs' and version in config['nextjs']['fixed']:
        return 'FIXED'
    
    return 'UNKNOWN'
```

**Tasks:**
1. Create `tests/utils/version_reader.py`
2. Update `tests/utils/version_constants.py` to use version_reader.py (backward compatibility)
3. Update `tests/utils/nextjs_version_constants.py` to use version_reader.py
4. Update all test files that import version constants
5. Run tests to verify

**Time Estimate:** 2 hours

#### 1.2.3: Bash/Makefile Reader

**File:** `scripts/read_versions.sh`

```bash
#!/usr/bin/env bash
# Version reader utility for bash scripts and Makefile
# Reads version constants from centralized config/versions.json file

set -euET -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_CONFIG="${PROJECT_ROOT}/config/versions.json"

if [ ! -f "$VERSIONS_CONFIG" ]; then
    echo "Error: Versions config not found at $VERSIONS_CONFIG" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to read versions config" >&2
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 1
fi

# Function to get React versions
get_react_versions() {
    local type=$1  # 'vulnerable', 'fixed', 'all', or 'default'
    case "$type" in
        vulnerable)
            jq -r '.react.vulnerable[]' "$VERSIONS_CONFIG"
            ;;
        fixed)
            jq -r '.react.fixed[]' "$VERSIONS_CONFIG"
            ;;
        all)
            jq -r '.react.vulnerable[], .react.fixed[]' "$VERSIONS_CONFIG"
            ;;
        default)
            jq -r '.react.default' "$VERSIONS_CONFIG"
            ;;
        *)
            echo "Error: Invalid type '$type'. Use: vulnerable, fixed, all, default" >&2
            exit 1
            ;;
    esac
}

# Function to get Next.js versions
get_nextjs_versions() {
    local type=$1  # 'vulnerable', 'fixed', 'all', or 'default'
    case "$type" in
        vulnerable)
            jq -r '.nextjs.vulnerable[]' "$VERSIONS_CONFIG"
            ;;
        fixed)
            jq -r '.nextjs.fixed[]' "$VERSIONS_CONFIG"
            ;;
        all)
            jq -r '.nextjs.vulnerable[], .nextjs.fixed[]' "$VERSIONS_CONFIG"
            ;;
        default)
            jq -r '.nextjs.default' "$VERSIONS_CONFIG"
            ;;
        *)
            echo "Error: Invalid type '$type'. Use: vulnerable, fixed, all, default" >&2
            exit 1
            ;;
    esac
}

# Function to get Node.js version for Next.js version
get_node_version_for_nextjs() {
    local nextjs_version=$1
    jq -r --arg v "$nextjs_version" '.node.nextjs[$v] // .node.default' "$VERSIONS_CONFIG"
}

# Function to get React version for Next.js version
get_react_version_for_nextjs() {
    local nextjs_version=$1
    # Try exact match first
    local react_version=$(jq -r --arg v "$nextjs_version" '.reactVersionsForNextjs[$v] // empty' "$VERSIONS_CONFIG")
    
    if [ -n "$react_version" ]; then
        echo "$react_version"
        return
    fi
    
    # Extract major version (e.g., "14" from "14.0.0")
    local major_version=$(echo "$nextjs_version" | cut -d. -f1)
    local version_key="${major_version}.x"
    
    # Try major version key
    react_version=$(jq -r --arg k "$version_key" '.reactVersionsForNextjs[$k] // empty' "$VERSIONS_CONFIG")
    
    if [ -n "$react_version" ]; then
        echo "$react_version"
        return
    fi
    
    # Default fallback
    jq -r '.reactVersionsForNextjs["15.x"]' "$VERSIONS_CONFIG"
}

# Export functions if sourced, or run as script
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Sourced - export functions
    export -f get_react_versions
    export -f get_nextjs_versions
    export -f get_node_version_for_nextjs
    export -f get_react_version_for_nextjs
else
    # Run as script - execute command
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <command> [args...]"
        echo "Commands:"
        echo "  get_react_versions <type>          - Get React versions (vulnerable|fixed|all|default)"
        echo "  get_nextjs_versions <type>         - Get Next.js versions (vulnerable|fixed|all|default)"
        echo "  get_node_version_for_nextjs <v>   - Get Node.js version for Next.js version"
        echo "  get_react_version_for_nextjs <v>  - Get React version for Next.js version"
        exit 1
    fi
    
    command=$1
    shift
    "$command" "$@"
fi
```

**Tasks:**
1. Create `scripts/read_versions.sh`
2. Make executable: `chmod +x scripts/read_versions.sh`
3. Test script with various commands
4. Update Makefile to source this script

**Time Estimate:** 1.5 hours

### Step 1.3: Update All Components to Use Centralized Config

#### 1.3.1: Update Makefile

**Changes:**
- Source `scripts/read_versions.sh` at the top
- Replace hardcoded version lists with function calls
- Update version switching functions to use centralized config

**Example Makefile changes:**

```makefile
# At top of Makefile, after initial comments
-include scripts/read_versions.sh

# Replace this:
# VULNERABLE_VERSIONS := 19.0 19.1.0 19.1.1 19.2.0
# With:
VULNERABLE_VERSIONS := $(shell ./scripts/read_versions.sh get_react_versions vulnerable | tr '\n' ' ')

# Similar for other version lists
FIXED_VERSIONS := $(shell ./scripts/read_versions.sh get_react_versions fixed | tr '\n' ' ')
NEXTJS_VULNERABLE_VERSIONS := $(shell ./scripts/read_versions.sh get_nextjs_versions vulnerable | tr '\n' ' ')
NEXTJS_FIXED_VERSIONS := $(shell ./scripts/read_versions.sh get_nextjs_versions fixed | tr '\n' ' ')
```

**Tasks:**
1. Update Makefile version variable definitions
2. Update version switching functions to use centralized config
3. Test all Makefile targets that use versions
4. Verify version switching still works

**Time Estimate:** 2 hours

#### 1.3.2: Update Scripts

**Files to update:**
- `scripts/verify_scanner.sh`
- `scripts/scanner_verification_report.sh`

**Changes:**
- Source `scripts/read_versions.sh`
- Replace hardcoded arrays with function calls

**Example:**

```bash
# At top of script, after set -euET
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/read_versions.sh"

# Replace:
# NEXTJS_VULNERABLE_VERSIONS=("14.0.0" "14.1.0" ...)
# With:
NEXTJS_VULNERABLE_VERSIONS=($(get_nextjs_versions vulnerable))
NEXTJS_FIXED_VERSIONS=($(get_nextjs_versions fixed))
```

**Tasks:**
1. Update `scripts/verify_scanner.sh`
2. Update `scripts/scanner_verification_report.sh`
3. Test both scripts
4. Verify scanner verification still works

**Time Estimate:** 1 hour

#### 1.3.3: Update Server Code

**Files to update:**
- `server/config/versions.js` - Update to use version_reader.js
- `server/server.js` - Verify it uses updated versions.js

**Tasks:**
1. Refactor `server/config/versions.js` to use version_reader.js
2. Test `/api/version` endpoint
3. Verify version status detection works

**Time Estimate:** 0.5 hours

#### 1.3.4: Update Test Code

**Files to update:**
- `tests/utils/version_constants.py` - Add backward compatibility wrapper
- `tests/utils/nextjs_version_constants.py` - Update to use version_reader.py
- All test files that import version constants

**Tasks:**
1. Update version_constants.py to use version_reader.py (with backward compatibility)
2. Update nextjs_version_constants.py to use version_reader.py
3. Run all tests to verify nothing broke
4. Update any test files that directly reference version lists

**Time Estimate:** 1.5 hours

### Step 1.4: Add Validation and Documentation

**File:** `config/README.md`

Document the version configuration structure, how to add new versions, and validation rules.

**File:** `scripts/validate_versions.sh`

Create validation script to check:
- JSON syntax is valid
- Required fields exist
- Version lists are not empty
- No duplicate versions

**Tasks:**
1. Create `config/README.md`
2. Create `scripts/validate_versions.sh`
3. Add validation to Makefile (run before version operations)
4. Document in main README

**Time Estimate:** 1 hour

### Phase 1 Summary

**Total Time Estimate:** 11.5 hours  
**Files Created:**
- `config/versions.json`
- `server/config/version_reader.js`
- `tests/utils/version_reader.py`
- `scripts/read_versions.sh`
- `scripts/validate_versions.sh`
- `config/README.md`

**Files Modified:**
- `Makefile`
- `server/config/versions.js`
- `server/server.js`
- `tests/utils/version_constants.py`
- `tests/utils/nextjs_version_constants.py`
- `scripts/verify_scanner.sh`
- `scripts/scanner_verification_report.sh`
- `README.md`

---

## Phase 2: Improve Makefile Maintainability

### Overview

Refactor the 1,324-line Makefile into smaller, more maintainable components.

**Current State:**
- Single 1,324-line Makefile
- Complex shell scripting embedded in Makefile
- Difficult to navigate and maintain

**Target State:**
- Main Makefile with includes
- Complex logic moved to shell scripts
- Clear separation of concerns
- Easier to test and maintain

### Step 2.1: Analyze Makefile Structure

**Tasks:**
1. Identify logical sections:
   - Version configuration
   - Version switching functions
   - Server management
   - Testing targets
   - Setup/installation
   - Help/documentation

2. Map dependencies between sections

3. Identify functions that can be extracted to scripts

**Time Estimate:** 1 hour

### Step 2.2: Create Makefile Include Structure

**New Structure:**
```
Makefile                    # Main Makefile (includes others)
Makefile.includes/
  versions.mk              # Version configuration and targets
  server.mk                # Server management targets
  testing.mk               # Testing targets
  setup.mk                 # Setup and installation targets
  help.mk                  # Help and documentation
```

**Main Makefile (simplified):**

```makefile
# ============================================================================
# React2Shell Server - Main Makefile
# ============================================================================

# Include version configuration (must be first)
-include Makefile.includes/versions.mk

# Include other sections
-include Makefile.includes/setup.mk
-include Makefile.includes/server.mk
-include Makefile.includes/testing.mk
-include Makefile.includes/help.mk

# Default target
.DEFAULT_GOAL := help

# Common variables
PID_DIR := .pids
LOG_DIR := .logs
VENV := venv
TEST_DIR := tests

# Create directories
$(PID_DIR):
	@mkdir -p $(PID_DIR)

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)
```

**Tasks:**
1. Create `Makefile.includes/` directory
2. Split Makefile into logical includes
3. Update main Makefile to include sections
4. Test that all targets still work

**Time Estimate:** 3 hours

### Step 2.3: Extract Complex Functions to Scripts

**Functions to extract:**

1. **Version Switching Logic**
   - **File:** `scripts/switch_version.sh`
   - Extract `switch_react_version` and `switch_nextjs_version` functions
   - Makefile calls script instead of inline shell

2. **Node.js Version Management**
   - **File:** `scripts/ensure_node_version.sh`
   - Extract `ensure_node_version` function
   - Cleaner error handling

3. **Server Lifecycle Management**
   - **File:** `scripts/server_manager.sh`
   - Extract start/stop/status logic
   - Framework-aware server management

4. **Test Execution**
   - **File:** `scripts/run_tests.sh`
   - Extract test execution logic
   - Better test organization

**Example: `scripts/switch_version.sh`**

```bash
#!/usr/bin/env bash
# Version switching script
# Extracted from Makefile for better maintainability

set -euET -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "${SCRIPT_DIR}/read_versions.sh"

switch_react_version() {
    local version=$1
    local framework_mode=$(cat "${PROJECT_ROOT}/.framework-mode" 2>/dev/null || echo "vite")
    
    echo "Switching to React ${version}..."
    
    if [ "$framework_mode" = "nextjs" ]; then
        cd "${PROJECT_ROOT}/frameworks/nextjs" && \
        node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='${version}';pkg.dependencies['react-dom']='${version}';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && \
        npm install --legacy-peer-deps
    else
        cd "${PROJECT_ROOT}/frameworks/vite-react" && \
        node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='${version}';pkg.dependencies['react-dom']='${version}';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && \
        npm install
    fi
    
    echo "✓ Switched to React ${version}"
}

switch_nextjs_version() {
    local version=$1
    # Complex logic moved here from Makefile
    # ... (implementation)
}

# Main execution
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Sourced - export functions
    export -f switch_react_version
    export -f switch_nextjs_version
else
    # Run as script
    command=$1
    shift
    "$command" "$@"
fi
```

**Tasks:**
1. Create `scripts/switch_version.sh`
2. Create `scripts/ensure_node_version.sh`
3. Create `scripts/server_manager.sh`
4. Create `scripts/run_tests.sh`
5. Update Makefile to call scripts instead of inline functions
6. Test all functionality

**Time Estimate:** 4 hours

### Step 2.4: Simplify Makefile Targets

**Goal:** Make targets simpler by delegating to scripts.

**Before:**
```makefile
react-19.0:
	@echo "Switching to React 19.0..."
	@cd frameworks/vite-react && node -e "..." && npm install
	@echo "✓ Switched"
```

**After:**
```makefile
react-19.0:
	@./scripts/switch_version.sh switch_react_version 19.0
```

**Tasks:**
1. Simplify version switching targets
2. Simplify server management targets
3. Simplify test targets
4. Verify all targets work

**Time Estimate:** 2 hours

### Step 2.5: Add Makefile Documentation

**File:** `Makefile.includes/README.md`

Document:
- Purpose of each include file
- How to add new targets
- Makefile conventions
- Testing Makefile changes

**Tasks:**
1. Create documentation for Makefile structure
2. Add comments to Makefile includes
3. Document conventions

**Time Estimate:** 1 hour

### Phase 2 Summary

**Total Time Estimate:** 11 hours  
**Files Created:**
- `Makefile.includes/versions.mk`
- `Makefile.includes/setup.mk`
- `Makefile.includes/server.mk`
- `Makefile.includes/testing.mk`
- `Makefile.includes/help.mk`
- `scripts/switch_version.sh`
- `scripts/ensure_node_version.sh`
- `scripts/server_manager.sh`
- `scripts/run_tests.sh`
- `Makefile.includes/README.md`

**Files Modified:**
- `Makefile` (significantly simplified)

---

## Phase 3: Add CI/CD with GitHub Actions

### Overview

Create comprehensive GitHub Actions workflows for automated testing, version validation, and deployment checks.

**Workflows to Create:**
1. **CI Workflow** - Run tests on PRs and pushes
2. **Version Validation Workflow** - Validate version switching
3. **Scanner Verification Workflow** - Test scanner integration (optional, can be manual)
4. **Release Workflow** - Tag-based releases (future)

### Step 3.1: Set Up GitHub Actions Infrastructure

**Directory Structure:**
```
.github/
  workflows/
    ci.yml                    # Main CI workflow
    version-validation.yml     # Version switching validation
    scanner-verification.yml    # Scanner tests (optional)
    release.yml                # Release workflow (future)
```

**Tasks:**
1. Create `.github/workflows/` directory
2. Set up basic workflow structure
3. Document workflow purposes

**Time Estimate:** 0.5 hours

### Step 3.2: Create Main CI Workflow

**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  NODE_VERSION: '24.12.0'
  PYTHON_VERSION: '3.11'

jobs:
  # Job 1: Lint and validate
  lint:
    name: Lint and Validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate versions.json
        run: |
          if ! command -v jq >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y jq
          fi
          ./scripts/validate_versions.sh
      
      - name: Check Makefile syntax
        run: |
          if ! command -v make >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y make
          fi
          make help > /dev/null

  # Job 2: Test Vite + React framework
  test-vite:
    name: Test Vite + React
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install nvm
        run: |
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install ${{ env.NODE_VERSION }}
          nvm use ${{ env.NODE_VERSION }}
      
      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Setup project
        run: make setup
      
      - name: Switch to Vite framework
        run: make use-vite
      
      - name: Test with vulnerable version
        run: |
          make react-19.0
          make start
          sleep 10
          make test-smoke
          make stop
      
      - name: Test with fixed version
        run: |
          make react-19.2.1
          make start
          sleep 10
          make test-smoke
          make stop

  # Job 3: Test Next.js framework
  test-nextjs:
    name: Test Next.js
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install nvm
        run: |
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install ${{ env.NODE_VERSION }}
          nvm use ${{ env.NODE_VERSION }}
      
      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Setup project
        run: make setup
      
      - name: Switch to Next.js framework
        run: make use-nextjs
      
      - name: Test Next.js startup (all versions)
        run: make test-nextjs-startup
        timeout-minutes: 15
      
      - name: Test with vulnerable version
        run: |
          make nextjs-15.0.4
          make start
          sleep 15
          make test-smoke
          make stop
      
      - name: Test with fixed version
        run: |
          make nextjs-14.0.1
          make start
          sleep 15
          make test-smoke
          make stop

  # Job 4: Python tests
  test-python:
    name: Python Tests
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        framework: [vite, nextjs]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install nvm
        run: |
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install ${{ env.NODE_VERSION }}
          nvm use ${{ env.NODE_VERSION }}
      
      - name: Install system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq make
      
      - name: Setup project
        run: make setup
      
      - name: Switch framework
        run: make use-${{ matrix.framework }}
      
      - name: Set up test environment
        run: make test-setup
      
      - name: Start servers
        run: |
          make start
          sleep 10
      
      - name: Run tests
        run: make test-quick
      
      - name: Stop servers
        if: always()
        run: make stop
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-reports-${{ matrix.framework }}
          path: tests/reports/
          if-no-files-found: ignore

  # Job 5: Version switching validation
  validate-versions:
    name: Validate Version Switching
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        framework: [vite, nextjs]
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install nvm
        run: |
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install ${{ env.NODE_VERSION }}
          nvm use ${{ env.NODE_VERSION }}
      
      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Setup project
        run: make setup
      
      - name: Switch framework
        run: make use-${{ matrix.framework }}
      
      - name: Validate version switching
        run: |
          if [ "${{ matrix.framework }}" = "vite" ]; then
            # Test React version switching
            make react-19.0
            make current-version
            make react-19.2.1
            make current-version
          else
            # Test Next.js version switching
            make nextjs-15.0.4
            make current-version
            make nextjs-14.0.1
            make current-version
          fi
```

**Tasks:**
1. Create `.github/workflows/ci.yml`
2. Test workflow locally with act (optional) or push to test branch
3. Iterate based on failures
4. Add workflow status badges to README

**Time Estimate:** 3 hours

### Step 3.3: Create Version Validation Workflow

**File:** `.github/workflows/version-validation.yml`

```yaml
name: Version Validation

on:
  push:
    branches: [ main ]
    paths:
      - 'config/versions.json'
      - 'Makefile'
      - 'scripts/**'
  workflow_dispatch:  # Allow manual trigger

jobs:
  validate-all-versions:
    name: Validate All Versions
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '24.12.0'
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq make
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install 24.12.0
          nvm use 24.12.0
      
      - name: Setup project
        run: make setup
      
      - name: Validate versions.json
        run: ./scripts/validate_versions.sh
      
      - name: Test Vite version switching
        run: |
          make use-vite
          for version in $(./scripts/read_versions.sh get_react_versions all); do
            echo "Testing React $version..."
            make react-$version
            make current-version
          done
      
      - name: Test Next.js version switching
        run: |
          make use-nextjs
          for version in $(./scripts/read_versions.sh get_nextjs_versions all); do
            echo "Testing Next.js $version..."
            make nextjs-$version || echo "⚠️  Version $version switch failed (may be expected)"
            make current-version
          done
        continue-on-error: true  # Some versions may have known issues
```

**Tasks:**
1. Create `.github/workflows/version-validation.yml`
2. Test workflow
3. Document when it runs

**Time Estimate:** 1.5 hours

### Step 3.4: Create Scanner Verification Workflow (Optional)

**File:** `.github/workflows/scanner-verification.yml`

```yaml
name: Scanner Verification

on:
  workflow_dispatch:  # Manual trigger only (requires external scanner)
    inputs:
      scanner_path:
        description: 'Path to scanner (default: /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner)'
        required: false
        default: '/Users/lblackb/data/lblackb/git/third-party/react2shell-scanner'

jobs:
  verify-scanner:
    name: Verify Scanner
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'  # Only run on manual trigger
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '24.12.0'
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq make
          curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          nvm install 24.12.0
          nvm use 24.12.0
      
      - name: Setup project
        run: make setup
      
      - name: Run scanner verification
        run: |
          make use-nextjs
          SCANNER_PATH="${{ github.event.inputs.scanner_path }}" ./scripts/verify_scanner.sh
        env:
          SCANNER_PATH: ${{ github.event.inputs.scanner_path }}
```

**Note:** This workflow is optional and may not work in CI if scanner is not available. Can be used for local/manual verification.

**Tasks:**
1. Create `.github/workflows/scanner-verification.yml`
2. Document as optional/manual workflow
3. Test if scanner is available in CI environment

**Time Estimate:** 1 hour

### Step 3.5: Add Workflow Documentation

**File:** `.github/workflows/README.md`

Document:
- Purpose of each workflow
- When workflows run
- How to trigger manually
- Troubleshooting common issues

**Tasks:**
1. Create workflow documentation
2. Add to main README
3. Document CI/CD setup

**Time Estimate:** 0.5 hours

### Step 3.6: Add CI Status Badges

Update `README.md` to include GitHub Actions status badges.

**Example:**
```markdown
## CI Status

![CI](https://github.com/username/react2shell-server/workflows/CI/badge.svg)
![Version Validation](https://github.com/username/react2shell-server/workflows/Version%20Validation/badge.svg)
```

**Tasks:**
1. Add badges to README
2. Test badge URLs

**Time Estimate:** 0.5 hours

### Phase 3 Summary

**Total Time Estimate:** 7 hours  
**Files Created:**
- `.github/workflows/ci.yml`
- `.github/workflows/version-validation.yml`
- `.github/workflows/scanner-verification.yml` (optional)
- `.github/workflows/README.md`

**Files Modified:**
- `README.md` (add CI badges)

---

## Dependencies and Prerequisites

### Phase Dependencies

- **Phase 1** must be completed before Phase 2 (Makefile refactoring uses centralized versions)
- **Phase 2** can be done in parallel with Phase 3, but Phase 1 should be complete
- **Phase 3** depends on Phase 1 (CI workflows use centralized versions)

### Prerequisites

1. **Tools Required:**
   - `jq` (for JSON parsing) - already in project setup
   - `make` - standard on macOS/Linux
   - `node` and `npm` - for version switching
   - `python3` - for tests
   - `git` - for version control

2. **GitHub Access:**
   - Repository must be on GitHub
   - GitHub Actions enabled (default for public repos)
   - Appropriate permissions for workflow execution

3. **Testing Environment:**
   - Ability to test Makefile changes locally
   - Ability to test GitHub Actions workflows (can use `act` tool locally or test branch)

---

## Testing Strategy

### Phase 1 Testing

1. **Version Config Validation:**
   - Run `scripts/validate_versions.sh`
   - Verify JSON syntax
   - Check all required fields

2. **Version Reader Testing:**
   - Test JavaScript reader: `node -e "import('./server/config/version_reader.js')"`
   - Test Python reader: `python3 -c "from tests.utils.version_reader import get_react_versions; print(get_react_versions())"`
   - Test Bash reader: `./scripts/read_versions.sh get_react_versions all`

3. **Integration Testing:**
   - Test version switching with centralized config
   - Test server `/api/version` endpoint
   - Run all tests to verify nothing broke

### Phase 2 Testing

1. **Makefile Testing:**
   - Run `make help` to verify all targets exist
   - Test each major target category:
     - Version switching: `make react-19.0`, `make nextjs-15.0.4`
     - Server management: `make start`, `make stop`, `make status`
     - Testing: `make test-setup`, `make test-smoke`
     - Setup: `make setup`

2. **Script Testing:**
   - Test each extracted script individually
   - Verify scripts work when called from Makefile
   - Test error handling

3. **Regression Testing:**
   - Run full test suite
   - Verify all functionality still works
   - Check that no features were lost

### Phase 3 Testing

1. **Workflow Testing:**
   - Test workflows on a feature branch first
   - Verify each job completes successfully
   - Check artifact uploads
   - Test manual triggers

2. **CI Integration Testing:**
   - Create test PR to trigger CI
   - Verify all jobs run
   - Check status badges update
   - Test failure scenarios

3. **Version Validation:**
   - Test version validation workflow
   - Verify it catches invalid versions
   - Test with valid version updates

---

## Rollback Plan

### Phase 1 Rollback

If centralized version config causes issues:

1. **Immediate:** Revert to hardcoded versions in each component
2. **Files to restore from git:**
   - `Makefile`
   - `server/config/versions.js`
   - `tests/utils/version_constants.py`
   - `tests/utils/nextjs_version_constants.py`
   - `scripts/verify_scanner.sh`
   - `scripts/scanner_verification_report.sh`

3. **Keep:** Centralized config file can remain for future use

### Phase 2 Rollback

If Makefile refactoring breaks functionality:

1. **Immediate:** Revert to original Makefile
2. **Keep scripts:** Extracted scripts can remain for future use
3. **Gradual migration:** Can migrate one section at a time

### Phase 3 Rollback

If CI workflows cause issues:

1. **Disable workflows:** Rename `.github/workflows/*.yml` to `.yml.disabled`
2. **Fix issues:** Debug and fix in feature branch
3. **Re-enable:** Once fixed, restore workflow files

---

## Implementation Timeline

### Recommended Approach: Incremental

**Week 1: Phase 1**
- Days 1-2: Create centralized config and readers
- Days 3-4: Update all components
- Day 5: Testing and validation

**Week 2: Phase 2**
- Days 1-2: Analyze and plan Makefile refactoring
- Days 3-4: Extract functions to scripts
- Day 5: Update Makefile and test

**Week 3: Phase 3**
- Days 1-2: Create CI workflows
- Days 3-4: Test and iterate
- Day 5: Documentation and badges

**Total:** 3 weeks for complete implementation

### Alternative: Parallel Work

- **Phase 1** and **Phase 3** can be done in parallel (CI can use hardcoded versions initially)
- **Phase 2** should wait for Phase 1 completion

---

## Success Criteria

### Phase 1 Success

- ✅ All version constants read from single `config/versions.json`
- ✅ No hardcoded version lists in code
- ✅ All tests pass
- ✅ Version switching works for all versions
- ✅ Adding new version requires only updating JSON file

### Phase 2 Success

- ✅ Makefile reduced to <500 lines
- ✅ Complex logic in separate scripts
- ✅ All Makefile targets still work
- ✅ Easier to add new targets
- ✅ Better error messages

### Phase 3 Success

- ✅ CI runs on all PRs and pushes
- ✅ Tests run automatically
- ✅ Version validation catches errors
- ✅ Status badges in README
- ✅ Workflows complete successfully

---

## Next Steps

1. **Review this plan** with team/stakeholders
2. **Prioritize phases** based on needs
3. **Create GitHub issues** for tracking
4. **Start with Phase 1** (foundation for others)
5. **Test incrementally** after each phase

---

**End of Implementation Plan**
