'use client';
import { where } from 'firebase/firestore';
import { useRows } from '@/lib/hooks';
import { Row } from '@/lib/types';
import { money } from '@/lib/utils';
import { ActionLink, Loading, Notice, Empty, PageHeading } from './ui';
export function Store() {
  const {rows,loading,error}=useRows('products',[where('isActive','==',true)]);
  const products=rows as Row[];
  if (loading) return <Loading/>;
  if (error) return <Notice error>{error}</Notice>;
  if (!products.length) return <Empty>Products will appear here when available.</Empty>;
  const visible=[...products].sort((a,b)=>(a.sortOrder??0)-(b.sortOrder??0));
  return <div className="plan-grid">{visible.map(p=><article className="plan" key={p.id}>{p.imageUrl&&<img src={p.imageUrl} alt={p.name} style={{width:'100%',aspectRatio:'1',objectFit:'cover',borderRadius:12,marginBottom:12}}/>}<h3>{p.name}</h3><span className="price">{p.priceLabel}</span>{p.description&&<p className="rate">{p.description}</p>}<ActionLink href="/contact" secondary>Ask the gym to order</ActionLink></article>)}</div>;
}
export function StorePage() { return <div className="container page-wrap"><PageHeading eyebrow="Gym store" title="Gear up.">Merchandise and equipment available through the gym. Contact us to order.</PageHeading><Store/></div>; }
