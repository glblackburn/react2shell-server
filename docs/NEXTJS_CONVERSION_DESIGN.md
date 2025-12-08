# Next.js Conversion Design Document

## Overview

This document analyzes converting the react2shell-server project to Next.js while maintaining the ability to switch both **React versions** and **Next.js versions**, enabling comprehensive vulnerability testing for both frameworks.

## Current Architecture

### Current Stack
- **Frontend**: Vite + React (client-side rendering)
- **Backend**: Express.js (REST API)
- **Version Switching**: React versions only (via Makefile)
- **Testing**: Python Selenium tests
- **Structure**: Simple SPA with API endpoints

### Current Files
```
react2shell-server/
├── src/
│   ├── App.jsx          # Main React component
│   ├── index.jsx        # React entry point
│   └── App.css          # Styles
├── server.js            # Express backend
├── vite.config.js       # Vite configuration
├── package.json         # Dependencies
└── Makefile            # Version switching logic
```

## Design Goals

1. **Dual Version Switching**: Switch both React AND Next.js versions
2. **Same Makefile Interface**: Keep existing `make react-*` targets, add `make nextjs-*` targets
3. **Same Testing Strategy**: Python Selenium tests work unchanged
4. **Same Process**: Version switching, server management, testing workflow identical
5. **Implementation Only Changes**: Framework changes, but interface stays the same

## Architecture Options

### Option A: Single Project with Dual Framework Support

**Concept**: One project that can run as either Vite+React OR Next.js

**Structure**:
```
react2shell-server/
├── frameworks/
│   ├── vite-react/          # Current Vite implementation
│   │   ├── src/
│   │   ├── vite.config.js
│   │   └── package.json
│   └── nextjs/              # Next.js implementation
│       ├── app/              # Next.js app directory
│       ├── next.config.js
│       └── package.json
├── shared/
│   ├── components/          # Shared React components
│   └── utils/              # Shared utilities
├── server.js                # Express backend (shared)
├── Makefile                # Unified version switching
└── package.json            # Root package.json
```

**Pros**:
- ✅ Single repository
- ✅ Shared code (components, utilities, backend)
- ✅ Unified Makefile targets
- ✅ Single test suite
- ✅ Easier to maintain consistency

**Cons**:
- ❌ Complex project structure
- ❌ Two different build systems
- ❌ More complex Makefile logic
- ❌ Potential dependency conflicts
- ❌ Larger repository

**Complexity**: High

---

### Option B: Separate Projects with Shared Makefile

**Concept**: Two separate projects that share Makefile logic and testing

**Structure**:
```
react2shell-server/          # Current Vite project
├── src/
├── server.js
├── Makefile
└── package.json

react2shell-nextjs/         # New Next.js project
├── app/
├── server.js (or Next.js API routes)
├── Makefile (shared logic)
└── package.json

shared/
├── Makefile.common         # Shared Makefile functions
├── tests/                  # Shared test suite
└── scripts/                # Shared scripts
```

**Pros**:
- ✅ Clear separation of concerns
- ✅ Simpler individual projects
- ✅ No dependency conflicts
- ✅ Can develop independently
- ✅ Easier to understand

**Cons**:
- ❌ Code duplication (components, backend logic)
- ❌ Two repositories to maintain
- ❌ Need to sync changes
- ❌ More complex CI/CD

**Complexity**: Medium

---

### Option C: Next.js with Vite Fallback (Recommended)

**Concept**: Convert to Next.js, but keep Vite as optional/legacy mode

**Structure**:
```
react2shell-server/
├── app/                    # Next.js app directory (primary)
│   ├── page.tsx           # Main page (RSC)
│   ├── api/               # API routes
│   └── layout.tsx
├── src/                    # Legacy Vite (optional)
│   ├── App.jsx
│   └── index.jsx
├── next.config.js          # Next.js config
├── vite.config.js          # Vite config (legacy)
├── Makefile               # Unified switching
└── package.json
```

**Pros**:
- ✅ Next.js as primary (scanner works)
- ✅ Can still test Vite version
- ✅ Single codebase
- ✅ Shared components
- ✅ Unified Makefile

**Cons**:
- ❌ Two build systems
- ❌ More complex configuration
- ❌ Need to maintain both

**Complexity**: Medium-High

---

## Recommended Approach: Option C (Next.js Primary with Vite Legacy)

### Rationale

1. **Next.js is primary goal** - Scanner needs Next.js
2. **Vite can be legacy mode** - Keep for comparison/testing
3. **Single project** - Easier maintenance
4. **Unified interface** - Same Makefile targets work for both

## Implementation Design

### 1. Project Structure

```
react2shell-server/
├── app/                          # Next.js App Router (primary)
│   ├── page.tsx                 # Main page (Server Component)
│   ├── layout.tsx               # Root layout
│   ├── api/
│   │   ├── hello/
│   │   │   └── route.ts        # /api/hello endpoint
│   │   └── version/
│   │       └── route.ts        # /api/version endpoint
│   └── components/
│       └── VersionInfo.tsx     # Version display component
├── src/                          # Legacy Vite (optional, for comparison)
│   ├── App.jsx
│   ├── index.jsx
│   └── App.css
├── components/                   # Shared React components
│   └── VersionDisplay.tsx
├── config/
│   ├── versions.js              # Version constants (shared)
│   └── nextjs-versions.js      # Next.js version constants
├── server.js                     # Express backend (if needed, or use Next.js API)
├── next.config.js               # Next.js configuration
├── vite.config.js               # Vite config (legacy mode)
├── package.json                 # Dependencies
├── Makefile                     # Unified version switching
└── tests/                       # Python Selenium tests (unchanged)
```

### 2. Version Switching Strategy

#### Makefile Targets

```makefile
# React version switching (existing)
make react-19.0
make react-19.1.0
# ... etc

# Next.js version switching (new)
make nextjs-14.0.0
make nextjs-14.1.0
make nextjs-15.0.0
# ... etc

# Combined switching
make switch-react-19.0-nextjs-14.0.0

# Framework mode switching
make use-nextjs      # Switch to Next.js mode
make use-vite        # Switch to Vite mode (legacy)
```

#### Implementation Approach

**Option 1: Package.json Manipulation (Current Method)**
- Update `package.json` dependencies
- Run `npm install`
- Restart servers

**Option 2: Multiple package.json Files**
- `package.json.nextjs-14.0.0`
- `package.json.nextjs-15.0.0`
- `package.json.vite`
- Copy appropriate one to `package.json`

**Option 3: Workspace/Monorepo**
- Use npm/yarn workspaces
- Separate packages for each version
- More complex but cleaner

**Recommended**: Option 1 (extend current method)

### 3. Package.json Structure

```json
{
  "name": "react2shell-server",
  "scripts": {
    "dev": "next dev",                    // Next.js mode
    "dev:vite": "vite",                   // Vite legacy mode
    "build": "next build",                // Next.js build
    "build:vite": "vite build",           // Vite build
    "start": "next start",                // Next.js production
    "start:vite": "vite preview"          // Vite production
  },
  "dependencies": {
    "react": "19.2.0",                    // Switched by Makefile
    "react-dom": "19.2.0",                // Switched by Makefile
    "next": "15.0.0"                      // Switched by Makefile
  }
}
```

### 4. Next.js Configuration

**next.config.js**:
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable React Server Components
  experimental: {
    serverActions: true,
  },
  // API routes configuration
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: '/api/:path*',
      },
    ];
  },
};

module.exports = nextConfig;
```

### 5. Server Components Implementation

**app/page.tsx** (Server Component):
```tsx
import { VersionInfo } from './components/VersionInfo';

export default async function HomePage() {
  // This runs on the server
  return (
    <div>
      <VersionInfo />
      <button>Hello World</button>
    </div>
  );
}
```

**app/api/hello/route.ts** (API Route):
```typescript
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ message: 'Hello World!' });
}
```

**app/api/version/route.ts** (API Route):
```typescript
import { NextResponse } from 'next/server';
import { readFileSync } from 'fs';
import { join } from 'path';
import { isVulnerableVersion, getVersionStatus } from '@/config/versions';

export async function GET() {
  const packageJson = JSON.parse(
    readFileSync(join(process.cwd(), 'package.json'), 'utf-8')
  );
  
  const reactVersion = packageJson.dependencies.react;
  const isVulnerable = isVulnerableVersion(reactVersion);
  const status = getVersionStatus(reactVersion);
  
  return NextResponse.json({
    react: reactVersion,
    reactDom: packageJson.dependencies['react-dom'],
    node: process.version,
    vulnerable: isVulnerable,
    status: status,
  });
}
```

### 6. Makefile Implementation

```makefile
# React versions (existing)
VULNERABLE_VERSIONS := 19.0 19.1.0 19.1.1 19.2.0
FIXED_VERSIONS := 19.0.1 19.1.2 19.2.1
ALL_REACT_VERSIONS := $(VULNERABLE_VERSIONS) $(FIXED_VERSIONS)

# Next.js versions (new)
NEXTJS_VULNERABLE_VERSIONS := 14.0.0 14.1.0 15.0.0  # Example - need to verify
NEXTJS_FIXED_VERSIONS := 14.0.1 14.1.1 15.0.1        # Example - need to verify
ALL_NEXTJS_VERSIONS := $(NEXTJS_VULNERABLE_VERSIONS) $(NEXTJS_FIXED_VERSIONS)

# Current framework mode
FRAMEWORK_MODE := nextjs  # or 'vite'

# Switch React version (existing, enhanced)
define switch_react_version
	@echo "Switching to React $(1)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.react='$(1)';pkg.dependencies['react-dom']='$(1)';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to React $(1)"
endef

# Switch Next.js version (new)
define switch_nextjs_version
	@echo "Switching to Next.js $(1)..."
	@node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json'));pkg.dependencies.next='$(1)';fs.writeFileSync('package.json',JSON.stringify(pkg,null,2));"
	@npm install
	@echo "✓ Switched to Next.js $(1)"
endef

# Switch framework mode
switch-framework:
	@if [ "$(FRAMEWORK_MODE)" = "nextjs" ]; then \
		echo "Switching to Vite mode..."; \
		# Update scripts, config, etc. \
	else \
		echo "Switching to Next.js mode..."; \
		# Update scripts, config, etc. \
	fi

# Generate React version targets (existing)
$(foreach version,$(ALL_REACT_VERSIONS),$(eval react-$(version):;$(call switch_react_version,$(version))))

# Generate Next.js version targets (new)
$(foreach version,$(ALL_NEXTJS_VERSIONS),$(eval nextjs-$(version):;$(call switch_nextjs_version,$(version))))

# Combined switching
switch-both: react-$(REACT_VERSION) nextjs-$(NEXTJS_VERSION)
	@echo "✓ Switched to React $(REACT_VERSION) and Next.js $(NEXTJS_VERSION)"
```

### 7. Server Management

**Current**: Two servers (Vite on 5173, Express on 3000)

**Next.js**: Single server (Next.js on 3000, includes API routes)

**Makefile Changes**:
```makefile
# Next.js mode
start-nextjs:
	@next dev

# Vite mode (legacy)
start-vite:
	@vite &
	@node server.js &

# Unified start (detects mode)
start:
	@if [ "$(FRAMEWORK_MODE)" = "nextjs" ]; then \
		make start-nextjs; \
	else \
		make start-vite; \
	fi
```

### 8. Testing Strategy (Unchanged)

**Python Selenium tests remain the same**:
- Same URLs (`http://localhost:3000` for Next.js, or `http://localhost:5173` for Vite)
- Same page structure (components render the same)
- Same API endpoints (`/api/hello`, `/api/version`)
- Same test logic

**Only difference**: Server startup command changes based on framework mode

### 9. Version Constants

**config/versions.js** (existing, enhanced):
```javascript
// React versions
export const VULNERABLE_VERSIONS = ['19.0', '19.1.0', '19.1.1', '19.2.0'];
export const FIXED_VERSIONS = ['19.0.1', '19.1.2', '19.2.1'];

// Next.js versions (new)
export const NEXTJS_VULNERABLE_VERSIONS = ['14.0.0', '14.1.0', '15.0.0'];
export const NEXTJS_FIXED_VERSIONS = ['14.0.1', '14.1.1', '15.0.1'];

// Combined version status
export function getCombinedVersionStatus(reactVersion, nextjsVersion) {
  const reactVuln = isVulnerableVersion(reactVersion);
  const nextjsVuln = isVulnerableNextjsVersion(nextjsVersion);
  return {
    react: { version: reactVersion, vulnerable: reactVuln },
    nextjs: { version: nextjsVersion, vulnerable: nextjsVuln },
    overall: reactVuln || nextjsVuln ? 'VULNERABLE' : 'FIXED'
  };
}
```

## Implementation Phases

### Phase 1: Next.js Setup (Week 1)
1. Install Next.js
2. Create `app/` directory structure
3. Convert `App.jsx` to `app/page.tsx`
4. Move API endpoints to Next.js API routes
5. Update `next.config.js`
6. Test basic Next.js functionality

### Phase 2: Version Switching (Week 1-2)
1. Add Next.js version constants
2. Extend Makefile with Next.js switching
3. Test React version switching (should still work)
4. Test Next.js version switching
5. Test combined switching

### Phase 3: Server Management (Week 2)
1. Update Makefile server targets
2. Add framework mode detection
3. Update test fixtures to handle both modes
4. Test server startup for both frameworks

### Phase 4: Testing Integration (Week 2)
1. Verify existing tests work with Next.js
2. Update test documentation
3. Add Next.js-specific test cases if needed
4. Test scanner verification

### Phase 5: Documentation (Week 2)
1. Update README with Next.js instructions
2. Document version switching for both frameworks
3. Update development narrative
4. Create migration guide

## Effort Estimate

| Phase | Effort | Complexity |
|-------|--------|------------|
| Phase 1: Next.js Setup | 2-3 days | Medium |
| Phase 2: Version Switching | 2-3 days | Medium-High |
| Phase 3: Server Management | 1-2 days | Low-Medium |
| Phase 4: Testing Integration | 1-2 days | Low |
| Phase 5: Documentation | 1 day | Low |
| **Total** | **7-11 days** | **Medium-High** |

## Risks and Challenges

### 1. Dependency Conflicts
- **Risk**: React version conflicts between Next.js requirements and selected React version
- **Mitigation**: Test all version combinations, document compatible pairs

### 2. Build System Complexity
- **Risk**: Maintaining two build systems (Next.js and Vite)
- **Mitigation**: Make Vite legacy-only, focus on Next.js

### 3. API Route Differences
- **Risk**: Next.js API routes work differently than Express
- **Mitigation**: Keep API structure similar, abstract differences

### 4. Server Component Limitations
- **Risk**: Some React features don't work in Server Components
- **Mitigation**: Use Client Components where needed (`'use client'`)

### 5. Testing Compatibility
- **Risk**: Tests may need updates for Next.js routing
- **Mitigation**: Keep URL structure identical, use Next.js rewrites if needed

## Success Criteria

1. ✅ Can switch React versions (existing functionality preserved)
2. ✅ Can switch Next.js versions (new functionality)
3. ✅ Scanner detects vulnerabilities in Next.js mode
4. ✅ All existing tests pass
5. ✅ Makefile interface remains intuitive
6. ✅ Documentation updated
7. ✅ Both frameworks can run (Next.js primary, Vite legacy)

## Decision: Same Project vs Separate Project

### Recommendation: **Same Project (Option C)**

**Rationale**:
1. **Unified Interface**: Same Makefile, same tests, same process
2. **Code Sharing**: Components, utilities, constants can be shared
3. **Easier Maintenance**: One repository, one test suite
4. **User Experience**: Users don't need to manage two projects
5. **Testing Consistency**: Same test suite validates both frameworks

**When to Consider Separate Projects**:
- If dependency conflicts become unmanageable
- If codebases diverge significantly
- If team wants to develop independently
- If deployment strategies differ substantially

## Next Steps

1. **Verify Next.js Vulnerable Versions**: Research which Next.js versions are actually vulnerable
2. **Create Proof of Concept**: Convert one page to Next.js, test version switching
3. **Validate Approach**: Ensure scanner works with POC
4. **Plan Migration**: Detailed task breakdown
5. **Get Approval**: Review design, adjust as needed
6. **Begin Implementation**: Start with Phase 1

## Questions to Resolve

1. **Which Next.js versions are vulnerable?** Need to research CVE-2025-55182/CVE-2025-66478 Next.js versions
2. **Compatibility matrix**: Which React + Next.js version combinations work?
3. **Vite retention**: Keep Vite as legacy or remove entirely?
4. **Server architecture**: Use Next.js API routes or keep Express backend?
5. **Deployment**: Same deployment strategy for both frameworks?
