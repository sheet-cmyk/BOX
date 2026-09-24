'use client';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { Elements, PaymentElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { doc, onSnapshot } from 'firebase/firestore';
import { useSearchParams } from 'next/navigation';
import { call, db } from '@/lib/firebase';
import { useDocument } from '@/lib/hooks';
import { errorMessage, money } from '@/lib/utils';
import { Button, Notice, Loading, PageHeading, ActionLink } from './ui';
import { MemberShell } from './member-pages';
import { useAuth } from './providers';
export function Checkout() {
  const search = useSearchParams(), planId = search.get('plan') || 'ten', {user, profile} = useAuth();
  const settings = useDocument('gymSettings/config');
  const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || settings?.stripePublishableKey || '';
  const stripePromise = useMemo(() => /^pk_(test|live)_/.test(publishableKey) ? loadStripe(publishableKey) : null, [publishableKey]);
  const [secret,setSecret] = useState(''), [paymentId,setPaymentId] = useState(''), [status,setStatus] = useState(''), [error,setError] = useState(''), [restartable,setRestartable] = useState(false), [attempt,setAttempt] = useState(0), [amount,setAmount] = useState<number|null>(null);
  const ready = !!profile?.isActive && !!profile?.phone?.trim() && !!profile?.childName?.trim() && profile?.childAge > 0;
  const key = `checkout:${user?.uid}:${planId}`;
  useEffect(() => {
    setSecret('');setPaymentId('');setStatus('');setError('');setRestartable(false);setAmount(null);
    if (!user || user.isAnonymous || !ready || !stripePromise) return;
    let active = true;
    let requestId = localStorage.getItem(key);
    if (!requestId) { requestId = sessionStorage.getItem(key) || crypto.randomUUID();localStorage.setItem(key,requestId); }
    call<{clientSecret?:string;paymentId:string;status:string}>('createPaymentIntent',{planId,requestId}).then(r => {
      if (!active) return;setPaymentId(r.paymentId);setStatus(r.status);
      if (r.status === 'canceled') setRestartable(true);
      else if (r.clientSecret) setSecret(r.clientSecret);
    }).catch(e => { if (active) { setError(errorMessage(e));setRestartable(e?.details?.reason === 'checkout-expired'); } });
    return () => { active = false; };
  }, [user?.uid,ready,stripePromise,planId,attempt,key]);
  useEffect(() => {
    if (!paymentId) return;
    return onSnapshot(doc(db,'payments',paymentId), snap => {
      const order = snap.data(); if (!order) return;
      setAmount(order.amount);
      if (['completed','refunded','refund_pending'].includes(order.status)) {setStatus(order.status);setRestartable(order.status !== 'refund_pending');}
    }, e => setError(errorMessage(e)));
  }, [paymentId]);
  function restart() {localStorage.removeItem(key);sessionStorage.removeItem(key);setAttempt(n=>n+1);}
  const pending = ['processing','succeeded','submitted','requires_capture'].includes(status);
  return <MemberShell><PageHeading title="Payment.">One-time purchase of training credits. No automatic renewal.</PageHeading>
    {!ready ? <><Notice>Complete your phone number and participant details before purchasing.</Notice><ActionLink href="/settings">Complete Profile</ActionLink></> : !stripePromise ? <><Notice>Card payments are not configured yet. Contact the gym for a cash or manual payment.</Notice><ActionLink href="/contact">Contact the Gym</ActionLink></> : <>
    {amount !== null && <h2 style={{fontSize:28}}>Order total: {money(amount)}</h2>}
    {error && <Notice error>{error}</Notice>}
    {status === 'completed' ? <><Notice>Payment confirmed. Your session credits have been added.</Notice><ActionLink href="/membership">View Membership</ActionLink></> : pending ? <><Notice>Your payment is being confirmed. Do not pay again. This page updates when the gym receives payment confirmation.</Notice><ActionLink href="/payments">Payment History</ActionLink></> : ['refunded','refund_pending','canceled'].includes(status) ? <Notice>Order status: {status.replace('_',' ')}.</Notice> : secret ? <Elements key={secret} stripe={stripePromise} options={{clientSecret:secret,appearance:{theme:'night',variables:{colorPrimary:'#E50914',colorBackground:'#181818'}}}}><CheckoutForm planId={planId} onSubmitted={()=>setStatus('submitted')}/></Elements> : !error && <Loading/>}
    {restartable && <Button className="secondary" onClick={restart}>Start a New Purchase</Button>}
    </>}
    <p className="muted" style={{marginTop:24}}>Read the <a href="/waiver">Waiver and Disclaimer</a> and <a href="/terms">Terms</a> before training.</p>
  </MemberShell>;
}
function CheckoutForm({planId,onSubmitted}:{planId:string;onSubmitted:()=>void}) {
  const stripe = useStripe(), elements = useElements(), [busy,setBusy] = useState(false), [error,setError] = useState('');
  async function submit(e:FormEvent) {
    e.preventDefault(); if (!stripe || !elements || busy) return;setBusy(true);setError('');
    try {
      const result = await stripe.confirmPayment({elements,confirmParams:{return_url:`${window.location.origin}/checkout?plan=${encodeURIComponent(planId)}`},redirect:'if_required'});
      if (result.error) setError(result.error.message || 'Payment was not completed.'); else onSubmitted();
    } catch(e) {setError(errorMessage(e));} finally {setBusy(false);}
  }
  return <form className="card stack" style={{maxWidth:600}} onSubmit={submit}><PaymentElement/>{error&&<Notice error>{error}</Notice>}<Button busy={busy} disabled={!stripe || !elements}>Pay Securely →</Button></form>;
}
