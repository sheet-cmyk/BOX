import type { Metadata } from 'next';
import { Providers } from '@/components/providers';
import { SiteShell } from '@/components/site-shell';
import './globals.css';
const url=process.env.NEXT_PUBLIC_SITE_URL||'http://localhost:3000';
export const metadata: Metadata={metadataBase:new URL(url),title:{default:'Junior Boy Boxing | Tracy, CA',template:'%s | Junior Boy Boxing'},description:'Boxing classes for kids and teens in Tracy, California. Train with Coach Sharif. Build confidence, discipline and strength.',openGraph:{title:'Junior Boy Boxing',description:'Discipline builds champions. Boxing for kids and teens in Tracy, CA.',images:['/assets/images/backgrounds/bg_home_header.png'],type:'website'},robots:{index:true,follow:true}};
export default function RootLayout({children}:{children:React.ReactNode}) {return <html lang="en"><body><a href="#main" className="skip-link">Skip to content</a><Providers><SiteShell>{children}</SiteShell></Providers></body></html>;}
