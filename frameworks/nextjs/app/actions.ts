'use server';

// Server Action for scanner vulnerability testing
// The scanner sends POST requests with Next-Action header to test for RSC vulnerabilities
export async function testAction() {
  // This server action allows the scanner to test for CVE-2025-66478
  // In vulnerable versions, the scanner's payload will be executed
  return { result: 'ok' };
}
