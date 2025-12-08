# ============================================================================
# React Version Configuration
# ============================================================================

# Vulnerable React versions (for security testing)
VULNERABLE_VERSIONS := 19.0 19.1.0 19.1.1 19.2.0

# Fixed React versions
FIXED_VERSIONS := 19.0.1 19.1.2 19.2.1

# All React versions
ALL_VERSIONS := $(VULNERABLE_VERSIONS) $(FIXED_VERSIONS)

# Version status mapping (for display messages)
VERSION_19.0_STATUS := VULNERABLE
VERSION_19.1.0_STATUS := VULNERABLE
VERSION_19.1.1_STATUS := VULNERABLE
VERSION_19.2.0_STATUS := VULNERABLE
VERSION_19.0.1_STATUS := FIXED
VERSION_19.1.2_STATUS := FIXED
VERSION_19.2.1_STATUS := FIXED

# ============================================================================
# Next.js Version Configuration
# ============================================================================

# Vulnerable Next.js versions (for security testing)
# Note: These versions verified against scanner results
NEXTJS_VULNERABLE_VERSIONS := 14.0.0 14.1.0 15.0.0 15.1.0

# Fixed Next.js versions
# Note: These versions verified against scanner results
NEXTJS_FIXED_VERSIONS := 14.0.1 14.1.1

# All Next.js versions
ALL_NEXTJS_VERSIONS := $(NEXTJS_VULNERABLE_VERSIONS) $(NEXTJS_FIXED_VERSIONS)

# Next.js version status mapping (for display messages)
NEXTJS_VERSION_14.0.0_STATUS := VULNERABLE
NEXTJS_VERSION_14.1.0_STATUS := VULNERABLE
NEXTJS_VERSION_15.0.0_STATUS := VULNERABLE
NEXTJS_VERSION_15.1.0_STATUS := VULNERABLE
NEXTJS_VERSION_14.0.1_STATUS := FIXED
NEXTJS_VERSION_14.1.1_STATUS := FIXED

# Framework mode detection
FRAMEWORK_MODE := $(shell cat .framework-mode 2>/dev/null || echo "vite")

# Generic function to switch React version (works for both frameworks)
# Usage: $(call switch_react_version,version)
define switch_react_version
	@echo "Switching to React $(1) ($(VERSION_$(1)_STATUS) - for security testing)..."
	@if [ -f .framework-mode ] && grep -q "^nextjs" .framework-mode 2>/dev/null; then \
		echo "Switching in Next.js framework..."; \
		cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='$(1)';pkg.dependencies['react-dom']='$(1)';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install --legacy-peer-deps; \
	else \
		echo "Switching in Vite framework..."; \
		cd frameworks/vite-react && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='$(1)';pkg.dependencies['react-dom']='$(1)';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install; \
	fi
	@echo "✓ Switched to React $(1) ($(VERSION_$(1)_STATUS))"
endef

# Generic function to switch Next.js version
# Usage: $(call switch_nextjs_version,version)
# Note: Next.js 14.x requires React 18, Next.js 15.x requires React 19
define switch_nextjs_version
	@if ! grep -q '^nextjs' .framework-mode 2>/dev/null; then \
		echo "⚠️  Error: Next.js version switching only available in Next.js mode"; \
		echo "   Run 'make use-nextjs' first to switch to Next.js mode"; \
		exit 1; \
	fi
	@case "$(1)" in \
		14.0.0|14.1.0) \
			echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
			echo "Note: Next.js 14.x requires React 18, using React 19.2.0 (vulnerable) for testing..."; \
			cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';pkg.dependencies.react='19.2.0';pkg.dependencies['react-dom']='19.2.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install --legacy-peer-deps && \
			echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;; \
		15.0.0|15.1.0) \
			echo "Switching to Next.js $(1) (VULNERABLE - for security testing)..."; \
			cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';pkg.dependencies.react='19.2.0';pkg.dependencies['react-dom']='19.2.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install --legacy-peer-deps && \
			echo "✓ Switched to Next.js $(1) (VULNERABLE)" ;; \
		14.0.1|14.1.1) \
			echo "Switching to Next.js $(1) (FIXED - for security testing)..."; \
			echo "Note: Next.js 14.x requires React 18, using React 19.2.1 (fixed) for testing..."; \
			cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';pkg.dependencies.react='19.2.1';pkg.dependencies['react-dom']='19.2.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install --legacy-peer-deps && \
			echo "✓ Switched to Next.js $(1) (FIXED)" ;; \
		*) \
			echo "Switching to Next.js $(1) (FIXED - for security testing)..."; \
			cd frameworks/nextjs && node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';pkg.dependencies.react='19.2.1';pkg.dependencies['react-dom']='19.2.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));" && npm install --legacy-peer-deps && \
			echo "✓ Switched to Next.js $(1) (FIXED)" ;; \
	esac
endef

# Generate version switching targets dynamically
$(foreach version,$(VULNERABLE_VERSIONS),$(eval react-$(version):;$(call switch_react_version,$(version))))
$(foreach version,$(FIXED_VERSIONS),$(eval react-$(version):;$(call switch_react_version,$(version))))
$(foreach version,$(NEXTJS_VULNERABLE_VERSIONS),$(eval nextjs-$(version):;$(call switch_nextjs_version,$(version))))
$(foreach version,$(NEXTJS_FIXED_VERSIONS),$(eval nextjs-$(version):;$(call switch_nextjs_version,$(version))))

.PHONY: help react-19.0 react-19.1.0 react-19.1.1 react-19.2.0 react-19.0.1 react-19.1.2 react-19.2.1 nextjs-14.0.0 nextjs-14.1.0 nextjs-15.0.0 nextjs-15.1.0 nextjs-14.0.1 nextjs-14.1.1 install current-version clean vulnerable start stop status tail-vite tail-server test-setup test test-quick test-parallel test-report test-smoke test-hello test-version test-security test-version-switch test-browser test-clean test-open-report test-update-baseline test-performance-check test-performance-trends test-performance-compare test-performance-slowest test-performance-history test-performance-summary test-performance-report test-makefile

# Set help as the default target when make is run without arguments
.DEFAULT_GOAL := help

# Default target - shows all available targets with descriptions
help:
	@echo "React Version Switcher"
	@echo "======================"
	@echo ""
	@echo "VULNERABLE VERSIONS (for security testing):"
	@echo "  make react-19.0      - Switch to React 19.0 (VULNERABLE)"
	@echo "  make react-19.1.0    - Switch to React 19.1.0 (VULNERABLE)"
	@echo "  make react-19.1.1    - Switch to React 19.1.1 (VULNERABLE)"
	@echo "  make react-19.2.0    - Switch to React 19.2.0 (VULNERABLE)"
	@echo "  make vulnerable      - Switch to React 19.0 (VULNERABLE) - default for testing"
	@echo ""
	@echo "FIXED VERSIONS:"
	@echo "  make react-19.0.1    - Switch to React 19.0.1 (FIXED)"
	@echo "  make react-19.1.2    - Switch to React 19.1.2 (FIXED)"
	@echo "  make react-19.2.1    - Switch to React 19.2.1 (FIXED)"
	@echo ""
	@echo "NEXT.JS VULNERABLE VERSIONS (for security testing):"
	@echo "  make nextjs-14.0.0   - Switch to Next.js 14.0.0 (VULNERABLE)"
	@echo "  make nextjs-14.1.0   - Switch to Next.js 14.1.0 (VULNERABLE)"
	@echo "  make nextjs-15.0.0   - Switch to Next.js 15.0.0 (VULNERABLE)"
	@echo "  make nextjs-15.1.0   - Switch to Next.js 15.1.0 (VULNERABLE)"
	@echo ""
	@echo "NEXT.JS FIXED VERSIONS:"
	@echo "  make nextjs-14.0.1   - Switch to Next.js 14.0.1 (FIXED)"
	@echo "  make nextjs-14.1.1   - Switch to Next.js 14.1.1 (FIXED)"
	@echo ""
	@echo "Server Management:"
	@echo "  make start           - Start both frontend and backend servers"
	@echo "  make stop            - Stop both servers"
	@echo "  make status          - Check status of servers"
	@echo "  make tail-vite       - Tail frontend server log (Ctrl+C to exit)"
	@echo "  make tail-server     - Tail backend server log (Ctrl+C to exit)"
	@echo ""
	@echo "Other commands:"
	@echo "  make current-version - Show currently installed React version"
	@echo "  make install         - Install dependencies for current version"
	@echo "  make clean           - Remove node_modules and package-lock.json"
	@echo ""
	@echo "Framework Switching:"
	@echo "  make use-vite        - Switch to Vite + React mode (default)"
	@echo "  make use-nextjs     - Switch to Next.js mode"
	@echo "  make current-framework - Show current framework mode"
	@echo ""
	@echo "Testing (Python Selenium):"
	@echo "  make test-setup      - Set up Python virtual environment and install test dependencies"
	@echo "  make test            - Run all tests (starts servers if needed)"
	@echo "  make test-quick      - Run all tests quickly (headless, no report)"
	@echo "  make test-parallel   - Run tests in parallel (10 workers, faster execution)"
	@echo "  make test-report     - Run all tests and generate HTML report"
	@echo "  make test-smoke      - Run only smoke tests"
	@echo "  make test-hello      - Run hello world button tests"
	@echo "  make test-version    - Run version information tests"
	@echo "  make test-security   - Run security status tests"
	@echo "  make test-version-switch - Run version switch tests (tests all React versions, slower)"
	@echo "  make test-scanner   - Run scanner verification tests (requires external scanner)"
	@echo "  make test-scanner-script - Run scanner verification script (standalone)"
	@echo "  make test-browser    - Run tests with specific browser (use BROWSER=chrome|firefox|safari)"
	@echo "  make test-clean      - Clean test artifacts (reports, screenshots, cache)"
	@echo "  make test-open-report - Open test report in browser"
	@echo "  make test-update-baseline - Update performance baseline with current test times"
	@echo "  make test-performance-check - Check for performance regressions"
	@echo "  make test-performance-trends [TEST_ID=test_id] [LIMIT=N] - Show performance trends"
	@echo "  make test-performance-compare - Compare latest run against baseline"
	@echo "  make test-performance-slowest [LIMIT=N] - List slowest tests"
	@echo "  make test-performance-history [LIMIT=N] - List recent performance history"
	@echo "  make test-performance-summary [LIMIT=N] - Show summary of recent runs"
	@echo "  make test-performance-report - Generate and open comprehensive HTML performance report"
	@echo ""
	@echo "Note: Versions 19.0, 19.1.0, 19.1.1, and 19.2.0 contain a critical"
	@echo "      security vulnerability in React Server Components."
	@echo "      Fixed versions: 19.0.1, 19.1.2, 19.2.1"
	@echo ""
	@echo "Makefile Testing:"
	@echo "  make test-makefile - Run BATS tests to verify Makefile help output"
	@echo ""
	@echo ""

# Convenience target for switching to vulnerable React version
vulnerable: react-19.0
	@echo "⚠️  WARNING: This is a VULNERABLE React version for security testing only!"

# Convenience target for switching to vulnerable Next.js version (only in Next.js mode)
vulnerable-nextjs: use-nextjs nextjs-15.0.0
	@echo "⚠️  WARNING: This is a VULNERABLE Next.js version for security testing only!"

# Framework switching
use-vite:
	@echo "vite" > .framework-mode
	@echo "✓ Switched to Vite + React mode"

use-nextjs:
	@echo "nextjs" > .framework-mode
	@echo "✓ Switched to Next.js mode"

current-framework:
	@FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	echo "Current framework: $$FRAMEWORK"

# Show current React version
current-version:
	@FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	if [ "$$FRAMEWORK" = "nextjs" ]; then \
		cd frameworks/nextjs && node -e "const pkg=require('./package.json');console.log('Framework: Next.js');console.log('React:',pkg.dependencies.react||'not set');console.log('React-DOM:',pkg.dependencies['react-dom']||'not set');console.log('Next.js:',pkg.dependencies.next||'not set');"; \
	else \
		cd frameworks/vite-react && node -e "const pkg=require('./package.json');console.log('Framework: Vite + React');console.log('React:',pkg.dependencies.react||'not set');console.log('React-DOM:',pkg.dependencies['react-dom']||'not set');"; \
	fi

# Install dependencies
install:
	@npm install

# Clean node_modules
clean:
	@echo "Cleaning node_modules and package-lock.json..."
	@rm -rf node_modules package-lock.json
	@echo "✓ Cleaned"

# PID and log file locations
PID_DIR := .pids
LOG_DIR := .logs
VITE_PID := $(PID_DIR)/vite.pid
SERVER_PID := $(PID_DIR)/server.pid
VITE_LOG := $(LOG_DIR)/vite.log
SERVER_LOG := $(LOG_DIR)/server.log

# Create directories if they don't exist
$(PID_DIR):
	@mkdir -p $(PID_DIR)

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)

# Start servers (framework-aware)
start: $(PID_DIR) $(LOG_DIR)
	@FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	echo "Starting servers (Framework: $$FRAMEWORK)..."; \
	if [ "$$FRAMEWORK" = "nextjs" ]; then \
		if [ -f $(SERVER_PID) ] && kill -0 `cat $(SERVER_PID)` 2>/dev/null; then \
			echo "⚠️  Next.js server is already running (PID: $$(cat $(SERVER_PID)))"; \
		else \
			cd frameworks/nextjs && nohup npm run dev > ../../$(SERVER_LOG) 2>&1 & \
			PID=$$!; \
			echo $$PID > ../../$(SERVER_PID); \
			echo "✓ Started Next.js server (PID: $$PID)"; \
		fi; \
		echo ""; \
		echo "=========================================="; \
		echo "🚀 Next.js server is starting up..."; \
		echo "=========================================="; \
		echo ""; \
		echo "Application: http://localhost:3000"; \
		echo "API Endpoint: http://localhost:3000/api/hello"; \
		echo "Version API:  http://localhost:3000/api/version"; \
		echo ""; \
		echo "Log file: $(SERVER_LOG)"; \
		echo ""; \
		echo "Check status:  make status"; \
		echo "Stop server:   make stop"; \
		echo ""; \
		sleep 2; \
		echo "Waiting for server to be ready..."; \
		for i in 1 2 3 4 5; do \
			if lsof -ti:3000 >/dev/null 2>&1; then \
				echo "✓ Next.js server is ready!"; \
				break; \
			fi; \
			sleep 1; \
		done; \
	else \
		if [ -f $(VITE_PID) ] && kill -0 `cat $(VITE_PID)` 2>/dev/null; then \
			echo "⚠️  Vite dev server is already running (PID: $$(cat $(VITE_PID)))"; \
		else \
			cd frameworks/vite-react && nohup npm run dev > ../../$(VITE_LOG) 2>&1 & \
			PID=$$!; \
			echo $$PID > ../../$(VITE_PID); \
			echo "✓ Started Vite dev server (PID: $$PID)"; \
		fi; \
		if [ -f $(SERVER_PID) ] && kill -0 `cat $(SERVER_PID)` 2>/dev/null; then \
			echo "⚠️  Express server is already running (PID: $$(cat $(SERVER_PID)))"; \
		else \
			nohup node server.js > $(SERVER_LOG) 2>&1 & \
			echo $$! > $(SERVER_PID); \
			echo "✓ Started Express server (PID: $$(cat $(SERVER_PID)))"; \
		fi; \
		echo ""; \
		echo "=========================================="; \
		echo "🚀 Servers are starting up..."; \
		echo "=========================================="; \
		echo ""; \
		echo "Frontend (Vite):  http://localhost:5173"; \
		echo "Backend (Express): http://localhost:3000"; \
		echo "API Endpoint:    http://localhost:3000/api/hello"; \
		echo "Version API:     http://localhost:3000/api/version"; \
		echo ""; \
		echo "Log files:"; \
		echo "  Frontend: $(VITE_LOG)"; \
		echo "  Backend:  $(SERVER_LOG)"; \
		echo ""; \
		echo "Check status:  make status"; \
		echo "Stop servers:  make stop"; \
		echo ""; \
		sleep 2; \
		echo "Waiting for servers to be ready..."; \
		for i in 1 2 3 4 5; do \
			if lsof -ti:5173 >/dev/null 2>&1 && lsof -ti:3000 >/dev/null 2>&1; then \
				echo "✓ Both servers are ready!"; \
				break; \
			fi; \
			sleep 1; \
		done; \
	fi

# Stop servers (framework-aware)
stop:
	@FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	echo "Stopping servers (Framework: $$FRAMEWORK)..."; \
	if [ "$$FRAMEWORK" = "nextjs" ]; then \
		if [ -f $(SERVER_PID) ]; then \
			PID=$$(cat $(SERVER_PID) 2>/dev/null); \
			if kill -0 $$PID 2>/dev/null; then \
				kill $$PID 2>/dev/null && echo "✓ Stopped Next.js server (PID: $$PID)"; \
			else \
				echo "⚠️  Next.js server was not running"; \
			fi; \
			rm -f $(SERVER_PID); \
		else \
			echo "⚠️  No Next.js PID file found"; \
		fi; \
		lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null && echo "✓ Killed process on port 3000" || true; \
		echo "✓ Server stopped"; \
	else \
		if [ -f $(VITE_PID) ]; then \
			PID=$$(cat $(VITE_PID) 2>/dev/null); \
			if kill -0 $$PID 2>/dev/null; then \
				kill $$PID 2>/dev/null && echo "✓ Stopped Vite dev server (PID: $$PID)"; \
			else \
				echo "⚠️  Vite dev server was not running"; \
			fi; \
			rm -f $(VITE_PID); \
		else \
			echo "⚠️  No Vite PID file found"; \
		fi; \
		if [ -f $(SERVER_PID) ]; then \
			PID=$$(cat $(SERVER_PID) 2>/dev/null); \
			if kill -0 $$PID 2>/dev/null; then \
				kill $$PID 2>/dev/null && echo "✓ Stopped Express server (PID: $$PID)"; \
			else \
				echo "⚠️  Express server was not running"; \
			fi; \
			rm -f $(SERVER_PID); \
		else \
			echo "⚠️  No Express PID file found"; \
		fi; \
		lsof -ti:5173 2>/dev/null | xargs kill -9 2>/dev/null && echo "✓ Killed process on port 5173" || true; \
		lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null && echo "✓ Killed process on port 3000" || true; \
		echo "✓ Servers stopped"; \
	fi

# Check server status
status:
	@echo "Server Status"
	@echo "============="
	@echo ""
	@# Check Vite dev server
	@if [ -f $(VITE_PID) ] && kill -0 `cat $(VITE_PID)` 2>/dev/null; then \
		echo "Frontend (Vite):  ✓ Running (PID: $$(cat $(VITE_PID)))"; \
	elif lsof -ti:5173 >/dev/null 2>&1; then \
		echo "Frontend (Vite):  ✓ Running on port 5173 (PID file missing)"; \
	else \
		echo "Frontend (Vite):  ✗ Not running"; \
	fi
	@# Check Express server
	@if [ -f $(SERVER_PID) ] && kill -0 `cat $(SERVER_PID)` 2>/dev/null; then \
		echo "Backend (Express): ✓ Running (PID: $$(cat $(SERVER_PID)))"; \
	elif lsof -ti:3000 >/dev/null 2>&1; then \
		echo "Backend (Express): ✓ Running on port 3000 (PID file missing)"; \
	else \
		echo "Backend (Express): ✗ Not running"; \
	fi
	@echo ""
	@# Show URLs if servers are running
	@if lsof -ti:5173 >/dev/null 2>&1 || lsof -ti:3000 >/dev/null 2>&1; then \
		echo "Access URLs:"; \
		[ -n "$$(lsof -ti:5173 2>/dev/null)" ] && echo "  Frontend: http://localhost:5173" || true; \
		[ -n "$$(lsof -ti:3000 2>/dev/null)" ] && echo "  Backend:  http://localhost:3000" || true; \
		echo ""; \
	fi
	@# Show log file locations
	@if [ -f $(VITE_LOG) ] || [ -f $(SERVER_LOG) ]; then \
		echo "Log files:"; \
		[ -f $(VITE_LOG) ] && echo "  Frontend: $(VITE_LOG)" || true; \
		[ -f $(SERVER_LOG) ] && echo "  Backend:  $(SERVER_LOG)" || true; \
		echo ""; \
	fi

# Tail frontend server log
tail-vite:
	@if [ ! -f $(VITE_LOG) ]; then \
		echo "⚠️  Log file not found: $(VITE_LOG)"; \
		echo "   Start the server first with: make start"; \
		exit 1; \
	fi
	@echo "Tailing Vite dev server log: $(VITE_LOG)"
	@echo "Press Ctrl+C to exit"
	@echo ""
	@tail -f $(VITE_LOG)

# Tail backend server log
tail-server:
	@if [ ! -f $(SERVER_LOG) ]; then \
		echo "⚠️  Log file not found: $(SERVER_LOG)"; \
		echo "   Start the server first with: make start"; \
		exit 1; \
	fi
	@echo "Tailing Express server log: $(SERVER_LOG)"
	@echo "Press Ctrl+C to exit"
	@echo ""
	@tail -f $(SERVER_LOG)

# ============================================================================
# Testing Targets
# ============================================================================

# Python and virtual environment detection
PYTHON := $(shell which python3 || which python)
VENV := venv
VENV_BIN := $(VENV)/bin
VENV_ACTIVATE := $(VENV_BIN)/activate
PYTEST := $(VENV_BIN)/pytest
PIP := $(VENV_BIN)/pip
TEST_DIR := tests
REPORT_DIR := $(TEST_DIR)/reports
REPORT_HTML := $(REPORT_DIR)/report.html

# Check if virtual environment exists
check-venv:
	@if [ ! -d "$(VENV)" ]; then \
		echo "⚠️  Virtual environment not found. Run 'make test-setup' first."; \
		exit 1; \
	fi

# Set up Python test environment
test-setup:
	@echo "Setting up Python test environment..."
	@if [ -z "$(PYTHON)" ]; then \
		echo "❌ Python not found. Please install Python 3.8 or higher."; \
		exit 1; \
	fi
	@echo "Using Python: $(PYTHON)"
	@$(PYTHON) --version
	@if [ ! -d "$(VENV)" ]; then \
		echo "Creating virtual environment..."; \
		$(PYTHON) -m venv $(VENV); \
	fi
	@echo "Installing test dependencies..."
	@$(PIP) install --upgrade pip > /dev/null 2>&1
	@$(PIP) install -q -r $(TEST_DIR)/requirements.txt
	@echo "✓ Test environment ready!"
	@echo ""
	@echo "To activate the virtual environment manually:"
	@echo "  source $(VENV_ACTIVATE)  # Mac/Linux"
	@echo "  $(VENV_BIN)\\activate     # Windows"

# Run all tests (with server management)
test: check-venv
	@echo "Running all Selenium tests..."
	@echo ""
	@# Ensure servers are running (framework-aware)
	@FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	if [ "$$FRAMEWORK" = "nextjs" ]; then \
		if ! lsof -ti:3000 >/dev/null 2>&1; then \
			echo "⚠️  Server not running. Starting Next.js server..."; \
			$(MAKE) start > /dev/null 2>&1; \
			sleep 5; \
		fi; \
	else \
		if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
			echo "⚠️  Servers not running. Starting servers..."; \
			$(MAKE) start > /dev/null 2>&1; \
			sleep 3; \
		fi; \
	fi
	@$(PYTEST) $(TEST_DIR)/ -v
	@echo ""
	@echo "✓ Tests completed!"

# Run tests quickly (headless, no report)
test-quick: check-venv
	@echo "Running tests quickly (headless mode)..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ --headless=true -v --tb=short

# Run tests in parallel (faster execution)
# Version switch tests run in parallel within each version (versions switched sequentially)
test-parallel: check-venv
	@TIMESTAMP=$$(date +%Y-%m-%d_%H-%M-%S); \
	REPORT_DIR_TIMESTAMPED="$(REPORT_DIR)/$$TIMESTAMP"; \
	mkdir -p "$$REPORT_DIR_TIMESTAMPED/screenshots"; \
	echo "📊 Reports will be saved to: $$REPORT_DIR_TIMESTAMPED"; \
	echo ""; \
	echo "Running tests in parallel (10 workers)..."; \
	echo "⚠️  Note: Version switch tests run in parallel within each version"; \
	FRAMEWORK=$$(cat .framework-mode 2>/dev/null || echo "vite"); \
	if [ "$$FRAMEWORK" = "nextjs" ]; then \
		if ! lsof -ti:3000 >/dev/null 2>&1; then \
			echo "⚠️  Server not running. Starting Next.js server..."; \
			$(MAKE) start > /dev/null 2>&1; \
			sleep 5; \
		fi; \
	else \
		if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
			echo "⚠️  Servers not running. Starting servers..."; \
			$(MAKE) start > /dev/null 2>&1; \
			sleep 3; \
		fi; \
	fi; \
	echo "Running non-version-switch tests in parallel..."; \
	PYTEST_REPORT_DIR="$$REPORT_DIR_TIMESTAMPED" PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -n 10 -v -m "not version_switch" \
		--html="$$REPORT_DIR_TIMESTAMPED/non-version-switch-report.html" \
		--self-contained-html || true; \
	echo ""; \
	echo "Running version switch tests (parallel within each version)..."; \
	cd $(TEST_DIR) && PYTEST_REPORT_DIR="$$REPORT_DIR_TIMESTAMPED" ../$(VENV_BIN)/python3 run_version_tests_parallel.py \
		--workers 6 --project-root .. --python ../$(VENV_BIN)/python3 \
		--report-dir "$$REPORT_DIR_TIMESTAMPED"; \
	echo ""; \
	echo "✓ All tests completed!"; \
	echo "📊 Reports saved to: $$REPORT_DIR_TIMESTAMPED"

# Run tests and generate HTML report
test-report: check-venv
	@echo "Running tests with HTML report..."
	@mkdir -p $(REPORT_DIR)
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ --html=$(REPORT_HTML) --self-contained-html -v
	@echo ""
	@echo "✓ Test report generated: $(REPORT_HTML)"
	@echo "  Open with: make test-open-report"

# Run only smoke tests
test-smoke: check-venv
	@echo "Running smoke tests..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ -m smoke -v

# Run hello world button tests
test-hello: check-venv
	@echo "Running hello world button tests..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/test_suites/test_hello_world.py -v

# Run version information tests
test-version: check-venv
	@echo "Running version information tests..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/test_suites/test_version_info.py -v

# Run security status tests
test-security: check-venv
	@echo "Running security status tests..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/test_suites/test_security_status.py -v

# Run version switch tests (tests all React versions by switching to each)
test-version-switch: check-venv
	@echo "Running version switch tests (will test all React versions)..."
	@echo "⚠️  Note: These tests are slower as they switch React versions (~2-5 minutes)"
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/test_suites/test_security_status.py -m version_switch -v
	@echo ""
	@echo "✓ Version switch tests completed!"
	@echo "  Note: React version is now set to the last tested version"

# Run scanner verification tests (requires external scanner)
test-scanner: check-venv
	@echo "Running scanner verification tests..."
	@echo "⚠️  Note: This requires the scanner at:"
	@echo "    /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner"
	@echo ""
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ -m scanner -v

# Run scanner verification script (standalone)
test-scanner-script:
	@echo "Running scanner verification script..."
	@echo "⚠️  Note: This requires the scanner at:"
	@echo "    /Users/lblackb/data/lblackb/git/third-party/react2shell-scanner"
	@echo ""
	@if [ ! -f scripts/verify_scanner.sh ]; then \
		echo "Error: scripts/verify_scanner.sh not found"; \
		exit 1; \
	fi
	@bash scripts/verify_scanner.sh

# Update performance baseline
test-update-baseline: check-venv
	@echo "Updating performance baseline..."
	@PYTEST_UPDATE_BASELINE=true PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -v || true
	@echo ""
	@echo "✓ Performance baseline updated!"

# Check for performance regressions
test-performance-check: check-venv
	@echo "Checking for performance regressions..."
	@PYTEST_SAVE_HISTORY=true $(PYTEST) $(TEST_DIR)/ -v || true
	@echo ""
	@echo "✓ Performance check completed!"

# Performance analysis commands
test-performance-trends: check-venv
	@echo "Performance Trends:"
	@cd $(TEST_DIR) && $(VENV_BIN)/python3 performance_report.py trends $(TEST_ID) --limit $(or $(LIMIT),10)

test-performance-compare: check-venv
	@echo "Comparing latest run against baseline..."
	@cd $(TEST_DIR) && $(VENV_BIN)/python3 performance_report.py compare

test-performance-slowest: check-venv
	@echo "Slowest tests:"
	@cd $(TEST_DIR) && $(VENV_BIN)/python3 performance_report.py slowest --limit $(or $(LIMIT),10)

test-performance-history: check-venv
	@echo "Recent performance history:"
	@cd $(TEST_DIR) && $(VENV_BIN)/python3 performance_report.py history --limit $(or $(LIMIT),10)

test-performance-summary: check-venv
	@echo "Performance summary:"
	@cd $(TEST_DIR) && $(VENV_BIN)/python3 performance_report.py summary --limit $(or $(LIMIT),5)

test-performance-report: check-venv
	@echo "Generating comprehensive performance history report..."
	@cd $(TEST_DIR) && ./generate_performance_report.sh

# Run BATS tests for Makefile
test-makefile:
	@echo "Running BATS tests for Makefile help output..."
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "⚠️  BATS not installed. Install with: brew install bats-core (macOS) or apt-get install bats (Linux)"; \
		exit 1; \
	fi
	@bats tests/makefile.bats

# Run tests with specific browser
test-browser: check-venv
	@if [ -z "$(BROWSER)" ]; then \
		echo "❌ Please specify BROWSER (chrome, firefox, or safari)"; \
		echo "   Example: make test-browser BROWSER=chrome"; \
		exit 1; \
	fi
	@echo "Running tests with $(BROWSER) browser..."
	@# Ensure servers are running
	@if ! lsof -ti:5173 >/dev/null 2>&1 || ! lsof -ti:3000 >/dev/null 2>&1; then \
		echo "⚠️  Servers not running. Starting servers..."; \
		$(MAKE) start > /dev/null 2>&1; \
		sleep 3; \
	fi
	@$(PYTEST) $(TEST_DIR)/ --browser=$(BROWSER) -v

# Clean test artifacts
test-clean:
	@echo "Cleaning test artifacts..."
	@rm -rf $(REPORT_DIR)
	@rm -rf $(TEST_DIR)/.pytest_cache
	@rm -rf $(TEST_DIR)/__pycache__
	@rm -rf $(TEST_DIR)/**/__pycache__
	@find $(TEST_DIR) -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find $(TEST_DIR) -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Test artifacts cleaned"

# Open test report in browser
test-open-report:
	@if [ ! -f "$(REPORT_HTML)" ]; then \
		echo "❌ Test report not found: $(REPORT_HTML)"; \
		echo "   Run 'make test-report' first to generate the report."; \
		exit 1; \
	fi
	@echo "Opening test report in browser..."
	@if command -v open > /dev/null; then \
		open $(REPORT_HTML); \
	elif command -v xdg-open > /dev/null; then \
		xdg-open $(REPORT_HTML); \
	elif command -v start > /dev/null; then \
		start $(REPORT_HTML); \
	else \
		echo "Please open $(REPORT_HTML) manually in your browser."; \
	fi
