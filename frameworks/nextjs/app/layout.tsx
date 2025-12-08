import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'React2Shell Server - Security Testing',
  description: 'Security testing environment for React and Next.js vulnerabilities',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
