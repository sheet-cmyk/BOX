import { Checkout } from '@/components/checkout';
import { Suspense } from 'react';
export const metadata={title:'Secure Checkout'};
export default function Page(){return <Suspense fallback={<div className="container page-wrap">Loading checkout…</div>}><Checkout/></Suspense>;}
