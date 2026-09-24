'use client';
import { FormEvent, useState } from 'react';
import { useDocument } from '@/lib/hooks';
import { call } from '@/lib/firebase';
import { waiverDraft } from '@/lib/waiver';
import { errorMessage } from '@/lib/utils';
import { useAuth } from './providers';
import { ActionLink, Button, Notice, PageHeading } from './ui';
export function WaiverPage() {
  const document = useDocument('legalDocuments/waiver'), {user, profile} = useAuth();
  const [busy, setBusy] = useState(false), [error, setError] = useState(''), [saved, setSaved] = useState('');
  const accepted = document?.published && profile?.waiverVersion === document.version && profile?.waiverParticipantName === profile?.childName?.trim() && profile?.waiverParticipantAge === profile?.childAge;
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); const form = new FormData(event.currentTarget); setBusy(true); setError('');
    try { await call('acceptWaiver', {version: document!.version, signerName: form.get('signerName'), capacity: form.get('capacity'), adult: form.get('adult') === 'on', agree: form.get('agree') === 'on'}); setSaved(document!.version); }
    catch (e) { setError(errorMessage(e)); } finally { setBusy(false); }
  }
  return <div className="container page-wrap"><PageHeading title="Waiver and Disclaimer."/> {!document?.published && <Notice>Draft for gym review. Signing is available only after the gym publishes an approved version.</Notice>}<article className="card" style={{whiteSpace:'pre-wrap',lineHeight:1.85,maxWidth:850}}>{document?.published ? document.body : waiverDraft}</article>{error && <Notice error>{error}</Notice>}{document?.published && (accepted || saved === document.version ? <Notice>Your agreement to this version has been recorded.</Notice> : !user ? <ActionLink href="/signin?next=/waiver">Sign in to review and sign</ActionLink> : <form className="card stack" style={{maxWidth:850,marginTop:24}} onSubmit={submit}><p>Participant: {profile?.childName || 'Complete your participant details in Settings'} · Age: {profile?.childAge || 'Not provided'}</p><ActionLink href="/settings" secondary>Participant Settings</ActionLink><label className="field">Your full legal name<input name="signerName" required minLength={2} maxLength={100}/></label><label className="field">I am signing as<select name="capacity" required><option value="">Select</option>{profile?.childAge >= 18 && <option value="participant">Adult participant</option>}<option value="guardian">Parent or legal guardian</option></select></label><label className="check-field"><input name="adult" type="checkbox" required/>I am 18 or older and have authority to sign for this participant.</label><label className="check-field"><input name="agree" type="checkbox" required/>I have read this version, understand it, and agree by submitting my name electronically.</label><Button busy={busy}>Record My Agreement</Button></form>)}</div>;
}
