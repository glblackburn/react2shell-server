/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable React Server Components
  experimental: {
    serverActions: true,
  },
};

module.exports = nextConfig;
