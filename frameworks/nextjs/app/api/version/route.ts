import { NextResponse } from 'next/server';
import { readFileSync } from 'fs';
import { join } from 'path';

// Import version constants from shared config
// Note: In Next.js, we need to use dynamic import or copy the logic
function isVulnerableVersion(version: string): boolean {
  const vulnerableVersions = ['19.0', '19.1.0', '19.1.1', '19.2.0'];
  return vulnerableVersions.includes(version);
}

function getVersionStatus(version: string): string {
  return isVulnerableVersion(version) ? 'VULNERABLE' : 'FIXED';
}

export async function GET() {
  try {
    // Read package.json from Next.js framework directory
    const packageJsonPath = join(process.cwd(), 'package.json');
    const packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf-8'));
    
    const reactVersion = packageJson.dependencies?.react || 'unknown';
    const reactDomVersion = packageJson.dependencies?.['react-dom'] || 'unknown';
    const nextjsVersion = packageJson.dependencies?.next || 'unknown';
    const nodeVersion = process.version;

    const isVulnerable = isVulnerableVersion(reactVersion);
    const status = getVersionStatus(reactVersion);

    return NextResponse.json({
      react: reactVersion,
      reactDom: reactDomVersion,
      nextjs: nextjsVersion,
      node: nodeVersion,
      vulnerable: isVulnerable,
      status: status,
    });
  } catch (error) {
    console.error('Error in /api/version:', error);
    return NextResponse.json(
      { error: 'Failed to get version information' },
      { status: 500 }
    );
  }
}
