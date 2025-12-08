.PHONY: help react-19.0 react-19.1.0 react-19.1.1 react-19.2.0 install current-version clean

# Default target
help:
	@echo "React Version Switcher"
	@echo "======================"
	@echo ""
	@echo "Available targets:"
	@echo "  make react-19.0      - Switch to React 19.0"
	@echo "  make react-19.1.0    - Switch to React 19.1.0"
	@echo "  make react-19.1.1    - Switch to React 19.1.1"
	@echo "  make react-19.2.0    - Switch to React 19.2.0"
	@echo "  make current-version - Show currently installed React version"
	@echo "  make install         - Install dependencies for current version"
	@echo "  make clean           - Remove node_modules and package-lock.json"
	@echo ""

# Switch to React 19.0
react-19.0:
	@echo "Switching to React 19.0..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.0';pkg.dependencies['react-dom']='19.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.0"

# Switch to React 19.1.0
react-19.1.0:
	@echo "Switching to React 19.1.0..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.1.0';pkg.dependencies['react-dom']='19.1.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.1.0"

# Switch to React 19.1.1
react-19.1.1:
	@echo "Switching to React 19.1.1..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.1.1';pkg.dependencies['react-dom']='19.1.1';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.1.1"

# Switch to React 19.2.0
react-19.2.0:
	@echo "Switching to React 19.2.0..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='19.2.0';pkg.dependencies['react-dom']='19.2.0';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React 19.2.0"

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
