'use client';
import { ReactNode, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Menu, X, ArrowUpRight, MapPin } from 'lucide-react';
import { useAuth } from './providers';
import { useDocument } from '@/lib/hooks';
import { gym } from '@/lib/types';
export function SiteShell({children}:{children:ReactNode}) {
  const [open,setOpen]=useState(false),path=usePathname(),{user}=useAuth(),settings=useDocument('gymSettings/config')||gym;
  if(path.startsWith('/admin')) return <>{children}</>;
  return <><header className="site-header"><Link className="wordmark" href="/" aria-label="Junior Boy Boxing home">JUNIOR BOY <em>BOXING</em></Link><nav className={open?'site-nav open':'site-nav'} aria-label="Main navigation">{[['Programs','/programs'],['Schedule','/schedule'],['Membership','/pricing'],['Store','/store'],['Contact','/contact']].map(([label,href])=><Link onClick={()=>setOpen(false)} aria-current={path===href?'page':undefined} href={href} key={href}>{label}</Link>)}<Link onClick={()=>setOpen(false)} className="nav-cta" href={user?'/dashboard':'/signin'}>{user?'My Account':'Sign In'} <ArrowUpRight size={16}/></Link></nav><button className="mobile-menu icon-button" aria-label={open?'Close menu':'Open menu'} aria-expanded={open} onClick={()=>setOpen(!open)}>{open?<X/>:<Menu/>}</button></header><main id="main">{children}</main><footer className="site-footer"><div className="footer-top"><div><Link className="wordmark" href="/">JUNIOR BOY <em>BOXING</em></Link><p>Stronger kids. Brighter futures.</p></div><p><MapPin size={18}/> {settings.address}</p><Link href="/signup" className="footer-cta">Step into your corner <ArrowUpRight/></Link></div><div className="footer-bottom"><span>© {new Date().getFullYear()} Junior Boy Boxing</span><div><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link><Link href="/waiver">Waiver & Disclaimer</Link><Link href="/contact">Contact</Link>{Object.entries(settings.socialLinks||{}).filter(([,url])=>url&&/^https:\/\//.test(String(url))).map(([name,url])=><a key={name} href={String(url)} target="_blank" rel="noreferrer">{name}</a>)}</div></div></footer></>;
}
