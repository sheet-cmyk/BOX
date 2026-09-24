import type { MetadataRoute } from 'next';
export default function robots():MetadataRoute.Robots{return {rules:{userAgent:'*',allow:'/',disallow:['/admin','/dashboard','/book','/membership','/payments','/checkout','/settings','/notifications']},sitemap:`${process.env.NEXT_PUBLIC_SITE_URL||'http://localhost:3000'}/sitemap.xml`};}
