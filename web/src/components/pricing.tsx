'use client';
import { where } from 'firebase/firestore';
import { Check, ShieldCheck } from 'lucide-react';
import { useRows } from '@/lib/hooks';
import { Plan, plans as initialPlans } from '@/lib/types';
import { ActionLink } from './ui';
export function Pricing({compact=false}:{compact?:boolean}) {
  const {rows}=useRows('membershipPlans',[where('isActive','==',true)]);
  const plans=(rows.length?rows:initialPlans) as Plan[];
  const visible=[...plans].sort((a,b)=>a.sortOrder-b.sortOrder).filter(p=>!compact||p.planType==='package');
  return <><div className="plan-grid">{visible.map(p=><article className={`plan ${p.isRecommended?'recommended':''}`} key={p.id}>{p.isRecommended&&<span className="tag">RECOMMENDED</span>}<h3>{p.name}</h3><span className="price">{p.priceLabel}</span><p className="rate">{p.perSessionLabel}</p><ul><li><Check/>{p.sessionCount?`${p.sessionCount} coached ${p.sessionCount===1?'session':'sessions'}`:'One hour of focused training'}</li><li><Check/>Boxing fundamentals & conditioning</li><li><Check/>Book sessions at your pace</li></ul><ActionLink href={`/checkout?plan=${p.id}`} secondary={!p.isRecommended}>Choose this plan</ActionLink></article>)}</div><p className="row muted" style={{fontSize:11,marginTop:20}}><ShieldCheck size={15}/>Secure payments. No automatic renewal.</p></>;
}
export function FAQ() {return <div className="faq"><h2>A few things to know.</h2>{[['Who are the classes for?','Junior Boxing is designed for kids ages 8–14. Group Training is listed for ages 14+. Contact Coach Sharif to find the right fit.'],['What should we bring?','Wear comfortable training clothes and bring water. Contact the gym before your first visit to confirm equipment requirements.'],['Can I cancel a booking?','The default cancellation window is 24 hours before class. Your account shows the current policy. Contact the gym for late changes.'],['How do session packs work?','Choose a pack, then book available classes. A credit is reserved for each booking and used when attendance or a no-show is recorded.']].map(([q,a])=><details key={q}><summary>{q}</summary><p>{a}</p></details>)}</div>;}
