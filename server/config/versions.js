/**
 * React version constants for server-side use.
 * 
 * This file provides a single source of truth for React version information
 * that can be used by both Node.js server code and build scripts.
 */

// Vulnerable React versions (for security testing)
export const VULNERABLE_VERSIONS = ['19.0', '19.1.0', '19.1.1', '19.2.0'];

// Fixed React versions
export const FIXED_VERSIONS = ['19.0.1', '19.1.2', '19.2.1'];

/**
 * Normalize a version string by removing carets and extracting major.minor
 * @param {string} version - Version string (e.g., "19.0.0", "^19.0.0", "19.0")
 * @returns {string} Normalized version (e.g., "19.0")
 */
function normalizeVersion(version) {
  if (!version || version === 'unknown') {
    return version;
  }
  // Remove caret, tilde, and other prefix characters
  const cleaned = version.replace(/^[\^~>=<]+\s*/, '');
  // Extract major.minor (e.g., "19.0.0" -> "19.0", "19.1.0" -> "19.1")
  const parts = cleaned.split('.');
  if (parts.length >= 2) {
    return `${parts[0]}.${parts[1]}`;
  }
  return cleaned;
}

/**
 * Check if a React version is vulnerable.
 * @param {string} version - React version string (e.g., "19.0", "19.0.0", "^19.0.0")
 * @returns {boolean} True if version is vulnerable
 */
export function isVulnerableVersion(version) {
  const normalized = normalizeVersion(version);
  return VULNERABLE_VERSIONS.includes(normalized);
}

/**
 * Get status string for a React version.
 * @param {string} version - React version string
 * @returns {string} 'VULNERABLE', 'FIXED', or 'UNKNOWN'
 */
export function getVersionStatus(version) {
  if (isVulnerableVersion(version)) {
    return 'VULNERABLE';
  }
  const normalized = normalizeVersion(version);
  if (FIXED_VERSIONS.includes(normalized)) {
    return 'FIXED';
  }
  return 'UNKNOWN';
}
