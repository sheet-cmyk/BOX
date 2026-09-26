'use client';
import { FormEvent, useState } from 'react';
import { orderBy, limit } from 'firebase/firestore';
import { Star, User as UserIcon } from 'lucide-react';
import { useAuth } from './providers';
import { useRows, useDocument } from '@/lib/hooks';
import { call } from '@/lib/firebase';
import { errorMessage } from '@/lib/utils';
import { ActionLink, Button, Notice, PageHeading, Loading } from './ui';

function Stars({ value, size = 18, onChange }: { value: number; size?: number; onChange?: (star: number) => void }) {
  const interactive = !!onChange;
  return <span className="row" style={{ gap: 2 }}>{[1, 2, 3, 4, 5].map(star => <Star key={star} size={size} onClick={interactive ? () => onChange!(star) : undefined} style={{ cursor: interactive ? 'pointer' : 'default', fill: value >= star ? 'var(--red,#e50914)' : 'transparent', color: value >= star ? 'var(--red,#e50914)' : '#555' }} />)}</span>;
}

function DistributionBar({ star, count, total }: { star: number; count: number; total: number }) {
  const pct = total ? Math.round((count / total) * 100) : 0;
  return <div className="row" style={{ gap: 8, fontSize: 12 }}><span className="muted" style={{ width: 10 }}>{star}</span><Star size={11} style={{ fill: 'var(--red,#e50914)', color: 'var(--red,#e50914)' }} /><div style={{ flex: 1, height: 6, borderRadius: 4, background: '#2a2a2a', overflow: 'hidden' }}><div style={{ width: `${pct}%`, height: '100%', background: 'var(--red,#e50914)' }} /></div><span className="muted" style={{ width: 20, textAlign: 'right' }}>{count}</span></div>;
}

export function ReviewsSummary() {
  const stats = useDocument('reviewStats/summary');
  const count = stats?.count ?? 0, average = stats?.average ?? 0, distribution = stats?.distribution ?? {};
  return <div className="card" style={{ marginBottom: 24 }}>{count === 0 ? <p className="muted">No reviews yet. Be the first to share your experience!</p> : <div className="row" style={{ gap: 24, alignItems: 'center' }}><div style={{ textAlign: 'center' }}><div style={{ fontSize: 40, fontWeight: 700, lineHeight: 1 }}>{average.toFixed(1)}</div><Stars value={average} /><div className="muted" style={{ fontSize: 12, marginTop: 4 }}>{count} {count === 1 ? 'review' : 'reviews'}</div></div><div style={{ flex: 1 }} className="stack">{[5, 4, 3, 2, 1].map(star => <DistributionBar key={star} star={star} count={distribution[String(star)] ?? 0} total={count} />)}</div></div>}</div>;
}

export function ReviewForm() {
  const { user } = useAuth();
  const existing = useDocument(user ? `reviews/${user.uid}` : null);
  const [rating, setRating] = useState(0), [touched, setTouched] = useState(false);
  const [comment, setComment] = useState(''), [commentTouched, setCommentTouched] = useState(false);
  const [busy, setBusy] = useState(false), [error, setError] = useState(''), [message, setMessage] = useState('');
  if (!user) return <Notice>Sign in to write a review.</Notice>;
  const effectiveRating = touched ? rating : (existing?.rating ?? rating);
  const effectiveComment = commentTouched ? comment : (existing?.comment ?? comment);
  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!effectiveRating) { setError('Select a star rating first.'); return; }
    setBusy(true); setError(''); setMessage('');
    try { await call('submitReview', { rating: effectiveRating, comment: effectiveComment.trim() }); setMessage('Thanks for your review!'); }
    catch (e) { setError(errorMessage(e)); }
    finally { setBusy(false); }
  }
  return <form className="card stack" onSubmit={submit} style={{ marginBottom: 24 }}>
    <h3 style={{ margin: 0 }}>{existing ? 'Edit Your Review' : 'Write a Review'}</h3>
    <Stars value={effectiveRating} size={28} onChange={v => { setRating(v); setTouched(true); }} />
    <label className="field">Share your experience (optional)<textarea value={effectiveComment} onChange={e => { setComment(e.target.value); setCommentTouched(true); }} maxLength={500} rows={4} /></label>
    {error && <Notice error>{error}</Notice>}
    {message && <Notice>{message}</Notice>}
    <Button busy={busy}>{existing ? 'Update Review' : 'Submit Review'}</Button>
  </form>;
}

export function ReviewsList() {
  const { rows, loading, error } = useRows('reviews', [orderBy('createdAt', 'desc'), limit(50)]);
  if (loading) return <Loading />;
  if (error) return <Notice error>{error}</Notice>;
  if (!rows.length) return null;
  return <div className="stack">{rows.map(r => <article className="card" key={r.id}><div className="row" style={{ gap: 12, alignItems: 'flex-start' }}>{r.userAvatarUrl ? <img src={r.userAvatarUrl} alt="" style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }} /> : <div style={{ width: 40, height: 40, borderRadius: '50%', background: '#2a2a2a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><UserIcon size={18} color="#a0a0a0" /></div>}<div style={{ flex: 1 }}><div className="row spread"><strong>{r.userName}</strong><Stars value={r.rating} size={14} /></div>{r.comment && <p className="muted" style={{ margin: '6px 0 0' }}>{r.comment}</p>}</div></div></article>)}</div>;
}

export function ReviewsPage() {
  return <div className="container page-wrap">
    <PageHeading eyebrow="Client reviews" title="What families say.">Real feedback from Junior Boy Boxing members.</PageHeading>
    <ReviewsSummary />
    <ReviewForm />
    <ReviewsList />
    <p className="row" style={{ marginTop: 24 }}><ActionLink href="/signup" secondary>Join Junior Boy Boxing</ActionLink></p>
  </div>;
}
