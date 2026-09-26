import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { z, ZodType } from 'zod';

if (!getApps().length) initializeApp();
export const db = getFirestore();
export const auth = getAuth();
export const emulator = process.env.FUNCTIONS_EMULATOR === 'true' || Boolean(process.env.FIRESTORE_EMULATOR_HOST);
// Temporarily off pre-launch: reCAPTCHA Enterprise App Check scoring has been
// throttling real sign-ins (403, ~24h lockout) for this low-traffic new site.
// Flip back to `!emulator` once App Check is verified reliable for real users.
export const enforceAppCheck = false;
export const id = z.string().min(1).max(128).regex(/^[a-zA-Z0-9_-]+$/);
export const zone = process.env.GYM_TIMEZONE || 'America/Los_Angeles';
export const now = () => Timestamp.now();
export function requireAuth(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
  return request.auth.uid;
}
export function requireRegistered(request: CallableRequest): string {
  const uid = requireAuth(request);
  if (request.auth!.token.firebase?.sign_in_provider === 'anonymous') throw new HttpsError('unauthenticated', 'Sign in with Google, email or phone to continue.');
  return uid;
}
export async function requireMember(uid: string, admin = false) {
  const snapshot = await db.doc(`users/${uid}`).get();
  const user = snapshot.data();
  if (!user?.isActive) throw new HttpsError('permission-denied', 'Account is not active.');
  if (admin && user.role !== 'admin') throw new HttpsError('permission-denied', 'Administrator access required.');
  return user;
}
export async function rateLimit(uid: string, operation: string, max = 30): Promise<void> {
  const minute = Math.floor(Date.now() / 60_000);
  const ref = db.doc(`rateLimits/${uid}_${operation}_${minute}`);
  await db.runTransaction(async tx => {
    const s = await tx.get(ref);
    const count = s.data()?.count ?? 0;
    if (count >= max) throw new HttpsError('resource-exhausted', 'Please wait a minute and retry.');
    tx.set(ref, { count: count + 1, expiresAt: Timestamp.fromMillis((minute + 2) * 60_000) });
  });
}
export function callable<T>(schema: ZodType<T>, operation: string, handler: (data: T, uid: string) => Promise<unknown>, admin = false) {
  return onCall({ enforceAppCheck, region: 'us-central1', timeoutSeconds: 120, memory: '256MiB', maxInstances: 20 }, async request => {
    const uid = requireRegistered(request);
    const parsed = schema.safeParse(request.data);
    if (!parsed.success) throw new HttpsError('invalid-argument', 'Invalid input.', parsed.error.flatten());
    await requireMember(uid, admin);
    await rateLimit(uid, operation);
    return handler(parsed.data, uid);
  });
}
export function audit(tx: Transaction, actor: string, action: string, target: string, detail: Record<string, unknown> = {}) {
  tx.create(db.collection('auditLogs').doc(), { actor, action, target, detail, createdAt: now() });
}
export function notify(tx: Transaction, eventId: string, userId: string, title: string, body: string, type: string, data: Record<string, string> = {}) {
  const record = { userId, title, body, type, data, isRead: false, createdAt: now() };
  tx.set(db.doc(`notifications/${eventId}`), record);
  tx.set(db.doc(`notificationOutbox/${eventId}`), { ...record, status: 'pending', attempts: 0, nextAttemptAt: now(), pushDone: false, emailDone: false });
}
