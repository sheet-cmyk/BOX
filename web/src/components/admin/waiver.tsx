'use client';
import { useState } from 'react';
import { call } from '@/lib/firebase';
import { useDocument } from '@/lib/hooks';
import { waiverDraft } from '@/lib/waiver';
import { errorMessage } from '@/lib/utils';
import { Button, Notice, PageHeading, ActionLink } from '../ui';
export function AdminWaiver() {
  const current = useDocument('legalDocuments/waiver'), [busy,setBusy] = useState(false), [error,setError] = useState(''), [message,setMessage] = useState('');
  return <><PageHeading title="Waiver and Disclaimer."/><Notice>Publish only the final wording approved by the gym. Publishing a changed version requires members to sign again before booking when the requirement below is enabled. Previous signed versions are retained.</Notice><form className="card stack" key={current?.version || 'draft'} onSubmit={async e => {
    e.preventDefault(); const f = new FormData(e.currentTarget); setBusy(true);setError('');setMessage('');
    try { await call('publishWaiver',{title:f.get('title'),body:f.get('body'),approved:f.get('approved')==='on',requiredOnBooking:f.get('requiredOnBooking')==='on'});setMessage('Approved version published.'); } catch(e) { setError(errorMessage(e)); } finally { setBusy(false); }
  }}><label className="field">Title<input name="title" defaultValue={current?.title || 'Waiver and Disclaimer'} minLength={5} maxLength={120} required/></label><label className="field">Approved text<textarea name="body" defaultValue={current?.body || waiverDraft} minLength={200} maxLength={30000} rows={24} required/></label><label className="check-field"><input type="checkbox" name="requiredOnBooking" defaultChecked={current?.requiredOnBooking ?? true}/>Require agreement before new bookings</label><label className="check-field"><input type="checkbox" name="approved" required/>I confirm the gym has approved this final text and I authorize publication.</label>{error&&<Notice error>{error}</Notice>}{message&&<Notice>{message}</Notice>}<Button busy={busy}>Publish Approved Version</Button><ActionLink href="/waiver" secondary>View Member Page</ActionLink></form></>;
}
