import * as v1 from 'firebase-functions/v1';
import { z } from 'zod';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getStorage } from 'firebase-admin/storage';
import { UserRecord } from 'firebase-admin/auth';
import { audit, auth, callable, db, emulator, enforceAppCheck, id, notify, now, rateLimit, requireAuth } from './platform';
import { releaseBooking } from './bookings';
import type { TrainingType } from './domain';

export async function ensureUser(user: UserRecord) {
  await db.runTransaction(async tx => {
    const ref = db.doc(`users/${user.uid}`);
    const old = await tx.get(ref);
    if (old.exists) return;
    tx.create(ref, {
      fullName: user.displayName || 'Member', lastName: '', age: 0, address: '', zipCode: '', email: user.email || '', phone: user.phoneNumber || '', role: 'member',
      childName: '', childAge: 0, avatarUrl: user.photoURL || '', membershipPlanId: null, sessionsRemaining: 0, sessionsReserved: 0,
      privateSessionsRemaining: 0, privateSessionsReserved: 0, groupSessionsRemaining: 0, groupSessionsReserved: 0, duoSessionsRemaining: 0, duoSessionsReserved: 0,
      memberSince: now(), isActive: true, fcmToken: '', createdAt: now(), updatedAt: now(), notificationPreferences: { push: true, email: true },
    });
    notify(tx, `welcome_${user.uid}`, user.uid, 'Welcome to Junior Boy Boxing', 'Train. Learn. Grow. Your account is ready. Choose a plan to book your first session.', 'welcome');
  });
}
export const onUserCreated = v1.region('us-central1').runWith({ failurePolicy: true }).auth.user().onCreate(ensureUser);
export const initializeProfile = onCall({ enforceAppCheck }, async request => {
  const uid = requireAuth(request);
  await rateLimit(uid, 'initializeProfile', 10);
  const user = await auth.getUser(uid);
  await ensureUser(user);
  const ref = db.doc(`users/${uid}`);
  const updates: Record<string, unknown> = { email: user.email || '', updatedAt: now() };
  if (user.photoURL && !(await ref.get()).data()?.avatarUrl) updates.avatarUrl = user.photoURL;
  await ref.update(updates);
  return { success: true };
});

export const onUserDeleted = v1.region('us-central1').runWith({ failurePolicy: true, timeoutSeconds: 540 }).auth.user().onDelete(async user => {
  const active = await db.collection('bookings').where('userId', '==', user.uid).where('status', '==', 'confirmed').get();
  for (const b of active.docs) await releaseBooking(user.uid, b.id, 'Account deleted', true);
  for (const name of ['bookings', 'notifications', 'notificationOutbox']) {
    let page;
    do {
      page = await db.collection(name).where('userId', '==', user.uid).limit(400).get();
      const batch = db.batch();
      page.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
    } while (page.size === 400);
  }
  const payments = await db.collection('payments').where('userId', '==', user.uid).get();
  for (const p of payments.docs) await p.ref.update({ userId: 'deleted', deletedAccount: true, updatedAt: now() });
  await db.recursiveDelete(db.doc(`users/${user.uid}`));
  if (process.env.STORAGE_BUCKET || process.env.GCLOUD_PROJECT) await getStorage().bucket(process.env.STORAGE_BUCKET).deleteFiles({ prefix: `avatars/${user.uid}/` });
});

export const updateMember = callable(z.object({ userId: id, fullName: z.string().min(1).max(100), isActive: z.boolean(), role: z.enum(['member', 'coach', 'admin']), creditAdjustment: z.number().int().min(-1000).max(1000).default(0), trainingType: z.enum(['private', 'group', 'duo']).default('private'), reason: z.string().min(3).max(500) }), 'updateMember', async (input, uid) => {
  await db.runTransaction(async tx => {
    const ref = db.doc(`users/${input.userId}`);
    const s = await tx.get(ref);
    if (!s.exists) throw new HttpsError('not-found', 'Member not found.');
    if (uid === input.userId && (!input.isActive || input.role !== 'admin')) throw new HttpsError('failed-precondition', 'You cannot remove your own admin access.');
    const d = s.data()!;
    const type: TrainingType = input.trainingType;
    const remainingField = `${type}SessionsRemaining`, reservedField = `${type}SessionsReserved`;
    const typedBalance = (d[remainingField] ?? 0) + input.creditAdjustment;
    const pooledBalance = d.sessionsRemaining + input.creditAdjustment;
    if (typedBalance < (d[reservedField] ?? 0)) throw new HttpsError('failed-precondition', 'Credits are reserved for existing bookings.');
    tx.update(ref, {
      fullName: input.fullName, isActive: input.isActive, role: input.role,
      [remainingField]: typedBalance, sessionsRemaining: pooledBalance,
      updatedAt: now(),
    });
    audit(tx, uid, 'updateMember', input.userId, input);
  });
  return { success: true };
}, true);

export const addMember = callable(z.object({ email: z.email(), fullName: z.string().min(1).max(100), phone: z.string().max(32).default(''), password: z.string().min(6).max(100).optional() }), 'addMember', async input => {
  const user = await auth.createUser({ email: input.email, displayName: input.fullName, ...(input.password ? { password: input.password } : {}) });
  await ensureUser(user);
  await db.doc(`users/${user.uid}`).update({ phone: input.phone });
  if (!input.password) {
    await db.runTransaction(async tx => {
      notify(tx, `invite_${user.uid}`, user.uid, 'Set up your account', 'Your gym account has been created. Use Forgot password on the sign-in page to securely set your password.', 'welcome');
    });
  }
  return { userId: user.uid };
}, true);
