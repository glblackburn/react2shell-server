# Node.js Version Mapping for Next.js Versions

**Date:** 2025-12-21  
**Purpose:** Complete version mapping of Next.js versions to Node.js versions  
**Strategy:** Use latest Node.js LTS version that satisfies all Next.js engine requirements

---

## Version Mapping Table

| Next.js Version | npm Engine Requirement | Selected Node.js Version | Rationale |
|----------------|------------------------|--------------------------|-----------|
| 14.0.0 | `>=18.17.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 14.0.1 | `>=18.17.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 14.1.0 | `>=18.17.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 14.1.1 | `>=18.17.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.0.4 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.1.8 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.2.5 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.3.5 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.4.7 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 15.5.6 | `^18.18.0 \|\| ^19.8.0 \|\| >= 20.0.0` | **24.12.0** | Latest LTS that satisfies requirement |
| 16.0.6 | `>=20.9.0` | **24.12.0** | Latest LTS that satisfies requirement |

---

## Research Results

### npm Registry Engine Requirements (Verified 2025-12-21)

```bash
# Query results from npm registry
Next.js 14.0.0: >=18.17.0
Next.js 14.0.1: >=18.17.0
Next.js 14.1.0: >=18.17.0
Next.js 14.1.1: >=18.17.0
Next.js 15.0.4: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 15.1.8: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 15.2.5: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 15.3.5: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 15.4.7: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 15.5.6: ^18.18.0 || ^19.8.0 || >= 20.0.0
Next.js 16.0.6: >=20.9.0
```

### Available Node.js Versions (as of 2025-12-21)

- **Node.js 18.x (Latest):** v18.20.8
- **Node.js 20.x (Latest):** v20.19.6
- **Node.js 22.x (Latest):** v22.21.1
- **Node.js 24.x (Latest LTS - Krypton):** v24.12.0
- **Node.js 25.x (Current):** v25.2.1

---

## Decision: Use Node.js 24.12.0 for All Versions

### Rationale

1. **Latest LTS:** Node.js 24.12.0 is the current Long-Term Support (LTS) version (Krypton)
2. **Universal Compatibility:** All Next.js versions in the project support Node.js 24.12.0:
   - Next.js 14.x requires `>=18.17.0` ✅ (24.12.0 satisfies)
   - Next.js 15.x requires `^18.18.0 || ^19.8.0 || >= 20.0.0` ✅ (24.12.0 satisfies)
   - Next.js 16.0.6 requires `>=20.9.0` ✅ (24.12.0 satisfies)
3. **React Compatibility:** React does not have Node.js engine requirements, so it works with any Node.js version
4. **Consistency:** Using a single Node.js version simplifies maintenance and testing
5. **Future-Proof:** Latest LTS ensures access to modern features and security updates

### Alternative Considered

- **Minimum Versions:** Use the minimum required version for each Next.js version
  - Next.js 14.x: 18.17.0
  - Next.js 15.x: 18.18.0
  - Next.js 16.0.6: 20.9.0
  - **Rejected:** User requested "latest version" that is supported

---

## Makefile Implementation

```makefile
# Node.js version requirements for Next.js versions
# Using latest Node.js LTS (24.12.0) that satisfies all Next.js engine requirements
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
get_node_version = $(if $(NEXTJS_$(1)_NODE),$(NEXTJS_$(1)_NODE),24.12.0)
```

---

## Maintenance

### When to Update

1. **New Next.js Version Added:**
   - Query npm registry: `npm view next@<version> engines.node`
   - Verify Node.js 24.12.0 (or current LTS) satisfies requirement
   - Add mapping to Makefile

2. **Node.js LTS Changes:**
   - When new Node.js LTS is released, verify compatibility with all Next.js versions
   - Update all mappings if new LTS is compatible

3. **Next.js Engine Requirements Change:**
   - If Next.js updates engine requirements, re-verify Node.js version compatibility
   - Update mapping if needed

### Verification Command

```bash
# Verify all Next.js versions support Node.js 24.12.0
for version in 14.0.0 14.0.1 14.1.0 14.1.1 15.0.4 15.1.8 15.2.5 15.3.5 15.4.7 15.5.6 16.0.6; do
  echo "Next.js $version:"
  npm view next@$version engines.node
done
```

---

## Notes

- **React Compatibility:** React does not specify Node.js engine requirements, so any Node.js version that satisfies Next.js requirements will work with React
- **Version Format:** Node.js versions in Makefile use format `24.12.0` (without 'v' prefix) for nvm compatibility
- **LTS Status:** Node.js 24.12.0 is the current LTS (Krypton) as of 2025-12-21

---

**Status:** ✅ Complete - All versions mapped to Node.js 24.12.0  
**Last Updated:** 2025-12-21
