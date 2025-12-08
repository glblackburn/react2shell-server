.PHONY: help react-19.0 react-19.1.0 react-19.1.1 react-19.2.0 react-19.0.1 react-19.1.2 react-19.2.1 install current-version clean vulnerable start stop status tail-vite tail-server

# Default target
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
	@echo "Note: Versions 19.0, 19.1.0, 19.1.1, and 19.2.0 contain a critical"
	@echo "      security vulnerability in React Server Components."
	@echo "      Fixed versions: 19.0.1, 19.1.2, 19.2.1"
	@echo ""

# Switch to React 19.0 (VULNERABLE)
react-19.0:
	@echo "Switching to React 19.0 (VULNERABLE - for security testing)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.0';pkg.dependencies['react-dom']='19.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.0 (VULNERABLE)"

# Convenience target for switching to vulnerable version
vulnerable: react-19.0
	@echo "⚠️  WARNING: This is a VULNERABLE version for security testing only!"

# Switch to React 19.1.0 (VULNERABLE)
react-19.1.0:
	@echo "Switching to React 19.1.0 (VULNERABLE - for security testing)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.1.0';pkg.dependencies['react-dom']='19.1.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.1.0 (VULNERABLE)"

# Switch to React 19.1.1 (VULNERABLE)
react-19.1.1:
	@echo "Switching to React 19.1.1 (VULNERABLE - for security testing)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.1.1';pkg.dependencies['react-dom']='19.1.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.1.1 (VULNERABLE)"

# Switch to React 19.2.0 (VULNERABLE)
react-19.2.0:
	@echo "Switching to React 19.2.0 (VULNERABLE - for security testing)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.2.0';pkg.dependencies['react-dom']='19.2.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.2.0 (VULNERABLE)"

# Switch to React 19.0.1 (FIXED)
react-19.0.1:
	@echo "Switching to React 19.0.1 (FIXED)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.0.1';pkg.dependencies['react-dom']='19.0.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.0.1 (FIXED)"

# Switch to React 19.1.2 (FIXED)
react-19.1.2:
	@echo "Switching to React 19.1.2 (FIXED)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.1.2';pkg.dependencies['react-dom']='19.1.2';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.1.2 (FIXED)"

# Switch to React 19.2.1 (FIXED)
react-19.2.1:
	@echo "Switching to React 19.2.1 (FIXED)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.2.1';pkg.dependencies['react-dom']='19.2.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.2.1 (FIXED)"

# Show current React version
current-version:
	@node -e "const pkg=require('./package.json');console.log('React:',pkg.dependencies.react||'not set');console.log('React-DOM:',pkg.dependencies['react-dom']||'not set');"

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

# Start both servers
start: $(PID_DIR) $(LOG_DIR)
	@echo "Starting development servers..."
	@if [ -f $(VITE_PID) ] && kill -0 `cat $(VITE_PID)` 2>/dev/null; then \
		echo "⚠️  Vite dev server is already running (PID: $$(cat $(VITE_PID)))"; \
	else \
		nohup npm run dev > $(VITE_LOG) 2>&1 & \
		echo $$! > $(VITE_PID); \
		echo "✓ Started Vite dev server (PID: $$(cat $(VITE_PID)))"; \
	fi
	@if [ -f $(SERVER_PID) ] && kill -0 `cat $(SERVER_PID)` 2>/dev/null; then \
		echo "⚠️  Express server is already running (PID: $$(cat $(SERVER_PID)))"; \
	else \
		nohup npm run server > $(SERVER_LOG) 2>&1 & \
		echo $$! > $(SERVER_PID); \
		echo "✓ Started Express server (PID: $$(cat $(SERVER_PID)))"; \
	fi
	@echo ""
	@echo "=========================================="
	@echo "🚀 Servers are starting up..."
	@echo "=========================================="
	@echo ""
	@echo "Frontend (Vite):  http://localhost:5173"
	@echo "Backend (Express): http://localhost:3000"
	@echo "API Endpoint:    http://localhost:3000/api/hello"
	@echo "Version API:     http://localhost:3000/api/version"
	@echo ""
	@echo "Log files:"
	@echo "  Frontend: $(VITE_LOG)"
	@echo "  Backend:  $(SERVER_LOG)"
	@echo ""
	@echo "Check status:  make status"
	@echo "Stop servers:  make stop"
	@echo ""
	@sleep 2
	@echo "Waiting for servers to be ready..."
	@for i in 1 2 3 4 5; do \
		if lsof -ti:5173 >/dev/null 2>&1 && lsof -ti:3000 >/dev/null 2>&1; then \
			echo "✓ Both servers are ready!"; \
			break; \
		fi; \
		sleep 1; \
	done

# Stop both servers
stop:
	@echo "Stopping servers..."
	@if [ -f $(VITE_PID) ]; then \
		PID=$$(cat $(VITE_PID) 2>/dev/null); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID 2>/dev/null && echo "✓ Stopped Vite dev server (PID: $$PID)"; \
		else \
			echo "⚠️  Vite dev server was not running"; \
		fi; \
		rm -f $(VITE_PID); \
	else \
		echo "⚠️  No Vite PID file found"; \
	fi
	@if [ -f $(SERVER_PID) ]; then \
		PID=$$(cat $(SERVER_PID) 2>/dev/null); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID 2>/dev/null && echo "✓ Stopped Express server (PID: $$PID)"; \
		else \
			echo "⚠️  Express server was not running"; \
		fi; \
		rm -f $(SERVER_PID); \
	else \
		echo "⚠️  No Express PID file found"; \
	fi
	@# Also try to kill by port in case PID file is missing
	@lsof -ti:5173 2>/dev/null | xargs kill -9 2>/dev/null && echo "✓ Killed process on port 5173" || true
	@lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null && echo "✓ Killed process on port 3000" || true
	@echo "✓ Servers stopped"

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
