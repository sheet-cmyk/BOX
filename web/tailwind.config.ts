import type { Config } from 'tailwindcss';
export default { content: ['./src/**/*.{ts,tsx}'], theme: { extend: { colors: { crimson: '#E50914', ink: '#0D0D0D', card: '#181818', line: '#2A2A2A' }, fontFamily: { display: ['Oswald','sans-serif'], sans: ['Roboto','sans-serif'] } } }, plugins: [] } satisfies Config;
