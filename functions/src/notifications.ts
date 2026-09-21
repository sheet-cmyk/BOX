import { getMessaging } from 'firebase-admin/messaging';
import { Timestamp } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { z } from 'zod';
import { callable, db, emulator, id, notify, now } from './platform';

const SENDGRID_API_KEY = defineSecret('SENDGRID_API_KEY');
const emailEnabled = process.env.EMAIL_DELIVERY_ENABLED === 'true';
const deliveryOptions = { secrets: emailEnabled ? [SENDGRID_API_KEY] : [], retry: true };

export async function deliverNotification(notificationId: string) {
  const ref = db.doc(`notificationOutbox/${notificationId}`);
  const claimed = await db.runTransaction(async tx => {
    const snap = await tx.get(ref), data = snap.data();
    if (!data || data.status === 'sent' || data.status === 'failed' || (data.leaseUntil?.toMillis() ?? 0) > Date.now()) return null;
    tx.update(ref, { leaseUntil: Timestamp.fromMillis(Date.now() + 120_000), attempts: data.attempts + 1 });
    return data;
  });
  if (!claimed) return;
  try {
    const user = (await db.doc(`users/${claimed.userId}`).get()).data();
    if (!user?.isActive) { await ref.update({ status: 'sent', skipped: 'inactive-or-deleted', leaseUntil: null }); return; }
    if (!claimed.pushDone && user.notificationPreferences?.push !== false && !emulator) {
      const devices = await db.collection(`users/${claimed.userId}/devices`).limit(100).get();
      if (!devices.empty) {
        const result = await getMessaging().sendEachForMulticast({ tokens: devices.docs.map(d => d.data().token), notification: { title: claimed.title, body: claimed.body }, data: { ...claimed.data, type: claimed.type, notificationId }, android: { collapseKey: notificationId, notification: { tag: notificationId, channelId: 'jbb_training' } } });
        let transient = false;
        for (let i = 0; i < result.responses.length; i++) {
          const response = result.responses[i];
          if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(response.error?.code || '')) await devices.docs[i].ref.delete();
          else if (!response.success) transient = true;
        }
        if (transient) throw new Error('Some push notifications require retry.');
      }
    }
    await ref.update({ pushDone: true });
    if (!claimed.emailDone && emailEnabled && user.email && user.notificationPreferences?.email !== false && !emulator) {
      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST', headers: { Authorization: `Bearer ${SENDGRID_API_KEY.value()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ personalizations: [{ to: [{ email: user.email }] }], from: { email: process.env.EMAIL_FROM }, subject: claimed.title, content: [{ type: 'text/plain', value: claimed.body }] }),
        signal: AbortSignal.timeout(20_000),
      });
      if (!response.ok) throw new Error(`Email provider returned ${response.status}`);
    }
    await ref.update({ status: 'sent', emailDone: true, emailDelivery: emailEnabled && !emulator ? 'enabled' : 'disabled', deliveredAt: now(), leaseUntil: null });
  } catch (error) {
    logger.error('Notification delivery failed', { notificationId, error: String(error) });
    const attempts = claimed.attempts + 1;
    await ref.update({ status: attempts >= 8 ? 'failed' : 'pending', leaseUntil: null, nextAttemptAt: Timestamp.fromMillis(Date.now() + Math.min(3600, 2 ** attempts * 30) * 1000) });
    throw error;
  }
}
export const deliverNotificationOnCreate = onDocumentCreated({ document: 'notificationOutbox/{notificationId}', ...deliveryOptions }, async e => deliverNotification(e.params.notificationId));
export const retryNotifications = onSchedule({ schedule: 'every 5 minutes', secrets: deliveryOptions.secrets }, async () => {
  const pending = await db.collection('notificationOutbox').where('status', '==', 'pending').where('nextAttemptAt', '<=', now()).limit(100).get();
  for (const item of pending.docs) { try { await deliverNotification(item.id); } catch { /* Persisted retry state is consumed on the next scheduled run. */ } }
});
export const sendNotification = callable(z.object({ userId: id, title: z.string().min(1).max(100), body: z.string().min(1).max(2000) }), 'sendNotification', async (input, uid) => {
  const eventId = db.collection('notifications').doc().id;
  await db.runTransaction(async tx => { notify(tx, eventId, input.userId, input.title, input.body, 'announcement', { sentBy: uid }); });
  return { notificationId: eventId };
}, true);
export const sendAnnouncement = callable(z.object({ title: z.string().min(1).max(100), body: z.string().min(1).max(2000), userIds: z.array(id).max(200).optional() }), 'announce', async (input, uid) => {
  const ref = await db.collection('announcements').add({ ...input, userIds: input.userIds ?? [], sentBy: uid, createdAt: now(), status: 'pending', cursor: '', deliveredCount: 0 });
  return { announcementId: ref.id };
}, true);
export async function processAnnouncement(announcementId: string) {
  const ref = db.doc(`announcements/${announcementId}`);
  const job = (await ref.get()).data();
  if (!job || job.status === 'sent') return;
  let users;
  if (job.userIds.length) users = await db.getAll(...job.userIds.map((uid: string) => db.doc(`users/${uid}`)));
  else {
    let q = db.collection('users').orderBy('__name__').limit(200);
    if (job.cursor) q = q.startAfter(job.cursor);
    users = (await q.get()).docs;
  }
  for (const user of users) {
    if (!user.data()?.isActive) continue;
    const key = `announce_${announcementId}_${user.id}`;
    await db.runTransaction(async tx => {
      if ((await tx.get(db.doc(`notifications/${key}`))).exists) return;
      notify(tx, key, user.id, job.title, job.body, 'announcement');
    });
  }
  await ref.update({ status: job.userIds.length || users.length < 200 ? 'sent' : 'pending', cursor: users.at(-1)?.id ?? job.cursor, deliveredCount: job.deliveredCount + users.length });
}
export const processAnnouncementOnCreate = onDocumentCreated({ document: 'announcements/{announcementId}', retry: true }, async e => processAnnouncement(e.params.announcementId));
export const continueAnnouncements = onSchedule('every 1 minutes', async () => {
  const jobs = await db.collection('announcements').where('status', '==', 'pending').limit(10).get();
  for (const job of jobs.docs) await processAnnouncement(job.id);
});
