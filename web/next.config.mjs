/** @type {import('next').NextConfig} */
const config = { output: 'export', distDir: process.env.NEXT_DIST_DIR || '.next', images: { unoptimized: true }, poweredByHeader: false, reactStrictMode: true };
export default config;
