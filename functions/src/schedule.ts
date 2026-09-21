import { DateTime } from 'luxon';
import { Timestamp } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { z } from 'zod';
import { callable, db, notify, now, zone } from './platform';
import { nextWeekOccurrence } from './domain';

export async function generateSchedule(reference = DateTime.now()) {
  const templates = await db.collection('recurringTemplates').where('isActive', '==', true).get();
  let count = 0;
  for (const template of templates.docs) {
    const t = template.data();
    const parsed = z.object({ classId: z.string().min(1), dayOfWeek: z.number().int().min(0).max(6), startTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/), maxSpots: z.number().int().positive() }).parse(t);
    const start = nextWeekOccurrence(reference, parsed.dayOfWeek, parsed.startTime, zone);
    const ref = db.doc(`schedule/${template.id}_${start.toFormat('yyyy-MM-dd')}`);
    await db.runTransaction(async tx => {
      const [existing, c] = await Promise.all([tx.get(ref), tx.get(db.doc(`classes/${parsed.classId}`))]);
      if (existing.exists || !c.data()?.isActive) return;
      const end = start.plus({ minutes: c.data()!.durationMinutes });
      tx.create(ref, { classId: parsed.classId, date: Timestamp.fromMillis(start.toMillis()), endAt: Timestamp.fromMillis(end.toMillis()), dayOfWeek: start.toFormat('cccc').toLowerCase(), startTime: start.toFormat('HH:mm'), endTime: end.toFormat('HH:mm'), maxSpots: parsed.maxSpots, bookedSpots: 0, isRecurring: true, recurringDayOfWeek: parsed.dayOfWeek, templateId: template.id, isCancelled: false, createdAt: now() });
    });
    count++;
  }
  return { templatesProcessed: count };
}
export const generateWeeklySchedule = onSchedule({ schedule: '0 18 * * 0', timeZone: zone, retryCount: 3 }, async () => { await generateSchedule(); });
export const generateScheduleNow = callable(z.object({}), 'generateSchedule', async () => generateSchedule(), true);

export const sendClassReminders = onSchedule({ schedule: 'every 15 minutes', timeZone: zone, retryCount: 3 }, async () => {
  const config = (await db.doc('gymSettings/config').get()).data();
  if (config?.classRemindersEnabled === false) return;
  const bookings = await db.collection('bookings').where('status', '==', 'confirmed').where('date', '>', now()).where('date', '<=', Timestamp.fromMillis(Date.now() + 3_600_000)).get();
  for (const b of bookings.docs) {
    await db.runTransaction(async tx => {
      const fresh = await tx.get(b.ref);
      const booking = fresh.data()!;
      if (booking.status !== 'confirmed' || booking.reminderSentRevision === booking.revision) return;
      notify(tx, `reminder_${b.id}_${booking.revision}`, booking.userId, 'Your class starts soon', `${booking.className} starts at ${booking.startTime}. See you at the gym.`, 'class_reminder', { bookingId: b.id });
      tx.update(b.ref, { reminderSentRevision: booking.revision });
    });
  }
});
export const checkMembershipCredits = onSchedule({ schedule: '0 10 * * *', timeZone: zone, retryCount: 3 }, async () => {
  if ((await db.doc('gymSettings/config').get()).data()?.membershipAlertsEnabled === false) return;
  const users = await db.collection('users').where('isActive', '==', true).where('sessionsRemaining', '<=', 2).get();
  const week = DateTime.now().setZone(zone).toFormat("kkkk-'W'WW");
  for (const user of users.docs) {
    if (!user.data().membershipPlanId) continue;
    await db.runTransaction(async tx => {
      const key = `credits_${user.id}_${week}`;
      const [exists, fresh] = await Promise.all([tx.get(db.doc(`notifications/${key}`)), tx.get(user.ref)]);
      const remaining = fresh.data()?.sessionsRemaining;
      if (exists.exists || remaining > 2 || !fresh.data()?.isActive) return;
      notify(tx, key, user.id, 'Keep your training going', `You have ${remaining} session credits left.`, remaining === 0 ? 'membership_expired' : 'membership_expiring');
    });
  }
});

export const getPublicSchedule = callablePublicSchedule();
function callablePublicSchedule() {
  // Public marketing receives only a sanitized projection, never member records.
  const { onCall, HttpsError } = require('firebase-functions/v2/https') as typeof import('firebase-functions/v2/https');
  const { emulator } = require('./platform') as typeof import('./platform');
  return onCall({ enforceAppCheck: !emulator, maxInstances: 10 }, async request => {
    const parsed = z.object({ from: z.string().datetime(), to: z.string().datetime() }).safeParse(request.data);
    if (!parsed.success) throw new HttpsError('invalid-argument', 'Select a date range.');
    const from = Date.parse(parsed.data.from), to = Date.parse(parsed.data.to);
    if (to <= from || to - from > 32 * 86_400_000) throw new HttpsError('invalid-argument', 'Date range must be at most 32 days.');
    const [sessions, classes] = await Promise.all([
      db.collection('schedule').where('isCancelled', '==', false).where('date', '>=', Timestamp.fromMillis(from)).where('date', '<', Timestamp.fromMillis(to)).orderBy('date').limit(300).get(),
      db.collection('classes').where('isActive', '==', true).get(),
    ]);
    const programs = new Map(classes.docs.map(c => [c.id, c.data()]));
    return { sessions: sessions.docs.filter(s => programs.has(s.data().classId)).map(s => {
      const d = s.data(), c = programs.get(d.classId)!;
      return { id: s.id, classId: d.classId, className: c.className, description: c.description, ageGroup: c.ageGroup, imageUrl: c.imageUrl, date: d.date.toDate().toISOString(), endAt: d.endAt.toDate().toISOString(), startTime: d.startTime, endTime: d.endTime, spots: d.maxSpots - d.bookedSpots, location: c.location, address: c.address };
    }) };
  });
}
