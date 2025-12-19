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
 * Check if a React version is vulnerable.
 * @param {string} version - React version string
 * @returns {boolean} True if version is vulnerable
 */
export function isVulnerableVersion(version) {
  return VULNERABLE_VERSIONS.includes(version);
}

/**
 * Get status string for a React version.
 * @param {string} version - React version string
 * @returns {string} 'VULNERABLE', 'FIXED', or 'UNKNOWN'
 */
export function getVersionStatus(version) {
  if (isVulnerableVersion(version)) {
    return 'VULNERABLE';
  } else if (FIXED_VERSIONS.includes(version)) {
    return 'FIXED';
  } else {
    return 'UNKNOWN';
  }
}
