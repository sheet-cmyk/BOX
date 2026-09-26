import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { z } from 'zod';
import { audit, callable, db, emulator, enforceAppCheck, id, notify, now, rateLimit, requireAuth, requireRegistered, requireMember } from './platform';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');
const stripe = () => new Stripe(STRIPE_SECRET_KEY.value());
const purchaseSchema = z.object({ planId: id, requestId: z.string().uuid() });

export const createPaymentIntent = onCall({ secrets: [STRIPE_SECRET_KEY], enforceAppCheck, maxInstances: 20 }, async request => {
  const uid = requireRegistered(request);
  const user = await requireMember(uid);
  if (!user.phone?.trim() || !user.childName?.trim() || !Number.isInteger(user.childAge) || user.childAge < 1) throw new HttpsError('failed-precondition', 'Complete your phone number and participant details in Profile Settings before purchasing.');
  await rateLimit(uid, 'payment', 8);
  const input = purchaseSchema.safeParse(request.data);
  if (!input.success) throw new HttpsError('invalid-argument', 'A plan and unique request ID are required.');
  const { planId, requestId } = input.data;
  const ref = db.doc(`payments/${uid}_${requestId}`);
  const order = await db.runTransaction(async tx => {
    const [old, planSnap] = await Promise.all([tx.get(ref), tx.get(db.doc(`membershipPlans/${planId}`))]);
    if (old.exists) {
      if (old.data()!.membershipPlanId !== planId) throw new HttpsError('already-exists', 'Use a new checkout request when changing plans.');
      if (!old.data()!.stripePaymentIntentId && Date.now() - old.data()!.createdAt.toMillis() > 23 * 3_600_000) throw new HttpsError('failed-precondition', 'Checkout expired. Start a new checkout.', { reason: 'checkout-expired' });
      return old.data()!;
    }
    const plan = planSnap.data();
    if (!plan?.isActive || !Number.isInteger(plan.price) || plan.price <= 0) throw new HttpsError('failed-precondition', 'Plan is not available.');
    const credits = plan.sessionCount ?? plan.creditsPerPurchase;
    if (!Number.isInteger(credits) || credits <= 0) throw new HttpsError('failed-precondition', 'This plan requires a credit configuration.');
    const data = { userId: uid, membershipPlanId: planId, amount: plan.price, credits, currency: 'usd', status: 'pending', paymentMethod: 'stripe', stripePaymentIntentId: null, receiptUrl: null, createdAt: now(), updatedAt: now() };
    tx.create(ref, data);
    return data;
  });
  if (['completed', 'refunded', 'refund_pending'].includes(order.status)) return { paymentId: ref.id, status: order.status };
  const api = stripe();
  const intent = order.stripePaymentIntentId ? await api.paymentIntents.retrieve(order.stripePaymentIntentId) : await api.paymentIntents.create({ amount: order.amount, currency: 'usd', automatic_payment_methods: { enabled: true }, receipt_email: user.email || undefined, metadata: { paymentId: ref.id, userId: uid, planId } }, { idempotencyKey: ref.id });
  await ref.update({ stripePaymentIntentId: intent.id, updatedAt: now() });
  return { paymentId: ref.id, clientSecret: intent.client_secret, status: intent.status };
});
export const purchaseMembership = createPaymentIntent;

export async function applySuccessfulPayment(paymentId: string, intent: { id: string; amount: number; currency: string }, receiptUrl: string | null = null) {
  await db.runTransaction(async tx => {
    const ref = db.doc(`payments/${paymentId}`);
    const p = await tx.get(ref), payment = p.data();
    if (!payment) throw new Error('Unknown payment order');
    if (['completed', 'refunded', 'refund_pending'].includes(payment.status)) return;
    if (payment.amount !== intent.amount || payment.currency !== intent.currency || (payment.stripePaymentIntentId && payment.stripePaymentIntentId !== intent.id)) throw new Error('Payment verification mismatch');
    const user = await tx.get(db.doc(`users/${payment.userId}`));
    tx.update(ref, { status: 'completed', stripePaymentIntentId: intent.id, receiptUrl, updatedAt: now(), paidAt: now(), fulfillmentStatus: user.exists ? 'fulfilled' : 'account_deleted' });
    if (!user.exists) return;
    tx.update(user.ref, { membershipPlanId: payment.membershipPlanId, sessionsRemaining: user.data()!.sessionsRemaining + payment.credits, updatedAt: now() });
    notify(tx, `payment_${paymentId}`, payment.userId, 'Membership purchased', `${payment.credits} session credits have been added to your account.`, 'membership_purchased', { paymentId });
  });
}

export const handleStripeWebhook = onRequest({ secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET], timeoutSeconds: 60 }, async (request, response) => {
  if (request.method !== 'POST') { response.status(405).send('Method not allowed'); return; }
  let event: Stripe.Event;
  try { event = stripe().webhooks.constructEvent(request.rawBody, request.headers['stripe-signature'] as string, STRIPE_WEBHOOK_SECRET.value()); }
  catch { response.status(400).send('Invalid signature'); return; }
  try {
    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object;
      if (intent.metadata.paymentId) {
        const charge = intent.latest_charge ? await stripe().charges.retrieve(typeof intent.latest_charge === 'string' ? intent.latest_charge : intent.latest_charge.id) : null;
        await applySuccessfulPayment(intent.metadata.paymentId, intent, charge?.receipt_url ?? null);
      }
    } else if (event.type === 'payment_intent.payment_failed' || event.type === 'payment_intent.canceled') {
      const intent = event.data.object;
      if (intent.metadata.paymentId) await db.runTransaction(async tx => {
        const ref = db.doc(`payments/${intent.metadata.paymentId}`), old = await tx.get(ref);
        if (old.exists && ['pending', 'failed'].includes(old.data()!.status)) tx.update(ref, { status: 'failed', updatedAt: now() });
      });
    } else if (event.type === 'refund.updated' || event.type === 'refund.created' || event.type === 'refund.failed') {
      await settleRefund(event.data.object);
    }
    response.status(200).json({ received: true });
  } catch (error) {
    logger.error('Stripe event failed', { eventId: event.id, error: String(error) });
    response.status(500).send('Retry required');
  }
});

async function settleRefund(refund: Stripe.Refund) {
  const paymentId = refund.metadata?.paymentId;
  if (!paymentId) return;
  await db.runTransaction(async tx => {
    const ref = db.doc(`payments/${paymentId}`), snap = await tx.get(ref), p = snap.data();
    if (!p || p.status !== 'refund_pending') return;
    const user = await tx.get(db.doc(`users/${p.userId}`));
    if (refund.status === 'succeeded') tx.update(ref, { status: 'refunded', stripeRefundId: refund.id, updatedAt: now() });
    else if (refund.status === 'failed' || refund.status === 'canceled') {
      tx.update(ref, { status: 'completed', refundError: refund.failure_reason ?? refund.status, updatedAt: now() });
      if (user.exists) tx.update(user.ref, { sessionsRemaining: user.data()!.sessionsRemaining + p.credits, updatedAt: now() });
    }
  });
}
export const createRefund = onCall({ secrets: [STRIPE_SECRET_KEY], enforceAppCheck }, async request => {
  const uid = requireAuth(request); await requireMember(uid, true); await rateLimit(uid, 'refund', 10);
  const input = z.object({ paymentId: id }).safeParse(request.data);
  if (!input.success) throw new HttpsError('invalid-argument', 'Payment ID is required.');
  const ref = db.doc(`payments/${input.data.paymentId}`);
  const p = await db.runTransaction(async tx => {
    const snap = await tx.get(ref), payment = snap.data();
    if (!payment) throw new HttpsError('not-found', 'Payment not found.');
    if (['refunded', 'refund_pending'].includes(payment.status)) return payment;
    if (payment.status !== 'completed' || payment.refundError) throw new HttpsError('failed-precondition', 'Payment is not eligible for an automatic refund.');
    const user = await tx.get(db.doc(`users/${payment.userId}`));
    if (user.exists && user.data()!.sessionsRemaining - (user.data()!.sessionsReserved ?? 0) < payment.credits) throw new HttpsError('failed-precondition', 'Cancel reservations or resolve used credits before refunding.');
    if (user.exists) tx.update(user.ref, { sessionsRemaining: user.data()!.sessionsRemaining - payment.credits, updatedAt: now() });
    tx.update(ref, { status: 'refund_pending', updatedAt: now() });
    audit(tx, uid, 'refund', ref.id);
    return payment;
  });
  if (p.status === 'refunded') return { status: 'refunded' };
  if (p.paymentMethod !== 'stripe') { await ref.update({ status: 'refunded', updatedAt: now() }); return { status: 'refunded' }; }
  const refund = await stripe().refunds.create({ payment_intent: p.stripePaymentIntentId, metadata: { paymentId: ref.id } }, { idempotencyKey: `refund_${ref.id}` });
  await settleRefund(refund);
  return { status: refund.status };
});

export const recordManualPayment = callable(z.object({ userId: id, planId: id, requestId: z.string().uuid(), method: z.enum(['cash', 'manual']), note: z.string().max(500).default('') }), 'manualPayment', async (input, uid) => {
  const ref = db.doc(`payments/manual_${input.requestId}`);
  await db.runTransaction(async tx => {
    const [old, plan, user] = await Promise.all([tx.get(ref), tx.get(db.doc(`membershipPlans/${input.planId}`)), tx.get(db.doc(`users/${input.userId}`))]);
    if (old.exists) {
      if (old.data()!.userId !== input.userId || old.data()!.membershipPlanId !== input.planId || old.data()!.paymentMethod !== input.method) throw new HttpsError('already-exists', 'This request was already used for a different payment.');
      return;
    }
    const p = plan.data(), u = user.data(), credits = p?.sessionCount ?? p?.creditsPerPurchase;
    if (!p?.isActive || !u?.isActive || !Number.isInteger(credits) || credits <= 0 || !Number.isInteger(p.price) || p.price <= 0) throw new HttpsError('failed-precondition', 'Select an active member and plan with a valid price.');
    tx.create(ref, { userId: input.userId, membershipPlanId: input.planId, amount: p.price, currency: 'usd', credits, status: 'completed', paymentMethod: input.method, stripePaymentIntentId: null, receiptUrl: null, note: input.note, createdAt: now(), updatedAt: now(), paidAt: now() });
    tx.update(user.ref, { sessionsRemaining: u.sessionsRemaining + credits, membershipPlanId: input.planId, updatedAt: now() });
    notify(tx, `payment_${ref.id}`, input.userId, 'Payment recorded', `${credits} session credits were added to your account.`, 'membership_purchased');
    audit(tx, uid, 'manualPayment', ref.id);
  });
  return { paymentId: ref.id };
}, true);
export const getPaymentHistory = callable(z.object({ before: z.string().datetime().optional() }), 'paymentHistory', async ({ before }, uid) => {
  let q = db.collection('payments').where('userId', '==', uid).orderBy('createdAt', 'desc').limit(50);
  if (before) q = q.startAfter(new Date(before));
  const page = await q.get();
  return { payments: page.docs.map(d => ({ ...d.data(), id: d.id, createdAt: d.data().createdAt.toDate().toISOString(), updatedAt: d.data().updatedAt.toDate().toISOString() })) };
});
