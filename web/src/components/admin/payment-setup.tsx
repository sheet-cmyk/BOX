'use client';
import { useState } from 'react';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useDocument } from '@/lib/hooks';
import { errorMessage } from '@/lib/utils';
import { Button, Notice } from '../ui';
export function PaymentSetup() {
  const settings = useDocument('gymSettings/config'), [busy,setBusy] = useState(false), [error,setError] = useState(''), [message,setMessage] = useState('');
  return <details className="card" style={{marginBottom:24}}><summary>Card payment setup</summary><p>Use the Stripe publishable key (pk_test_ or pk_live_). The matching secret key and signed webhook must be configured securely in Firebase. Never paste a secret key here. Test a complete payment and refund before enabling live purchases.</p><form className="stack" key={settings?.stripePublishableKey || 'empty'} onSubmit={async e=>{
    e.preventDefault();const key=String(new FormData(e.currentTarget).get('key')).trim();setError('');setMessage('');
    if (key && !/^pk_(test|live)_[A-Za-z0-9]+$/.test(key)) {setError('Enter a publishable key beginning pk_test_ or pk_live_.');return;}
    setBusy(true);try {await setDoc(doc(db,'gymSettings/config'),{stripePublishableKey:key,updatedAt:serverTimestamp()},{merge:true});setMessage('Public key saved for the website and Android app. A real payment test is still required.');}catch(e){setError(errorMessage(e));}finally{setBusy(false);}
  }}><label className="field">Stripe publishable key<input name="key" autoComplete="off" defaultValue={settings?.stripePublishableKey || ''}/></label><p className="muted">Leave empty to disable card checkout. Existing payment history remains available.</p>{error&&<Notice error>{error}</Notice>}{message&&<Notice>{message}</Notice>}<Button busy={busy}>Save Public Payment Key</Button></form></details>;
}
