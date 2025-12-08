.PHONY: help react-19.0 react-19.1.0 react-19.1.1 react-19.2.0 react-19.0.1 react-19.1.2 react-19.2.1 install current-version clean vulnerable

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
