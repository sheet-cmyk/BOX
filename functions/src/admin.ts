import { createHash } from 'node:crypto';
import { DateTime } from 'luxon';
import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { callable, db, emulator, enforceAppCheck, notify, now, rateLimit, zone } from './platform';
import { csvCell } from './domain';

export const getDashboardStats = callable(z.object({}), 'dashboard', async () => {
  const today = DateTime.now().setZone(zone).startOf('day');
  const month = today.startOf('month');
  const from = today.minus({ days: 29 });
  const [members, todayBookings, plans, monthPayments, recentPayments, bookings] = await Promise.all([
    db.collection('users').where('role', '==', 'member').count().get(),
    db.collection('bookings').where('date', '>=', Timestamp.fromMillis(today.toMillis())).where('date', '<', Timestamp.fromMillis(today.plus({ days: 1 }).toMillis())).get(),
    db.collection('membershipPlans').where('isActive', '==', true).count().get(),
    db.collection('payments').where('status', '==', 'completed').where('createdAt', '>=', Timestamp.fromMillis(month.toMillis())).get(),
    db.collection('payments').where('status', '==', 'completed').where('createdAt', '>=', Timestamp.fromMillis(from.toMillis())).get(),
    db.collection('bookings').where('date', '>=', Timestamp.fromMillis(from.toMillis())).where('date', '<', Timestamp.fromMillis(today.plus({ days: 1 }).toMillis())).get(),
  ]);
  const revenue: Record<string, number> = {};
  for (let i = 0; i < 30; i++) revenue[from.plus({ days: i }).toISODate()!] = 0;
  recentPayments.docs.forEach(p => { const d = DateTime.fromJSDate(p.data().createdAt.toDate()).setZone(zone).toISODate()!; revenue[d] = (revenue[d] ?? 0) + p.data().amount; });
  const popular: Record<string, number> = {};
  bookings.docs.filter(b => b.data().status !== 'cancelled').forEach(b => { const name = b.data().className; popular[name] = (popular[name] ?? 0) + 1; });
  return { totalMembers: members.data().count, bookingsToday: todayBookings.docs.filter(b => b.data().status !== 'cancelled').length, activePlans: plans.data().count, revenueThisMonth: monthPayments.docs.reduce((sum, p) => sum + p.data().amount, 0), revenue: Object.entries(revenue).map(([date, amount]) => ({ date, amount })), popularClasses: Object.entries(popular).map(([name, count]) => ({ name, count })) };
}, true);

export const exportBookingsCSV = callable(z.object({ from: z.string().datetime(), to: z.string().datetime(), collection: z.enum(['bookings', 'payments']).default('bookings') }), 'export', async input => {
  const from = new Date(input.from), to = new Date(input.to);
  if (to <= from || +to - +from > 366 * 86_400_000) throw new HttpsError('invalid-argument', 'Choose a range of up to one year.');
  const field = input.collection === 'bookings' ? 'date' : 'createdAt';
  const rows = await db.collection(input.collection).where(field, '>=', from).where(field, '<', to).orderBy(field).limit(10001).get();
  if (rows.size > 10000) throw new HttpsError('resource-exhausted', 'Narrow the export date range.');
  const columns = input.collection === 'bookings' ? ['id', 'userId', 'className', 'date', 'startTime', 'endTime', 'status'] : ['id', 'userId', 'membershipPlanId', 'amount', 'currency', 'status', 'paymentMethod', 'createdAt'];
  const csv = [columns.map(csvCell).join(','), ...rows.docs.map(row => columns.map(key => { const value = key === 'id' ? row.id : row.data()[key]; return csvCell(value instanceof Timestamp ? value.toDate().toISOString() : value); }).join(','))].join('\r\n');
  return { csv, filename: `${input.collection}-${from.toISOString().slice(0, 10)}.csv` };
}, true);

// Second-factor PIN gate for the in-app admin dashboard. Only callable by
// accounts already flagged role:'admin' (enforced by `callable(..., true)`),
// so this is defense-in-depth, not the primary access control. The PIN's
// hash lives in adminSecurity/pin, a collection no Firestore rule grants
// client access to — it is only ever read here via the Admin SDK.
export const verifyAdminPin = callable(z.object({ pin: z.string().regex(/^\d{4,8}$/) }), 'verifyAdminPin', async input => {
  const doc = await db.doc('adminSecurity/pin').get();
  const stored = doc.data()?.hash as string | undefined;
  if (!stored || createHash('sha256').update(input.pin).digest('hex') !== stored) throw new HttpsError('permission-denied', 'Incorrect PIN.');
  return { verified: true };
}, true);

export const contactGym = onCall({ enforceAppCheck, maxInstances: 5 }, async request => {
  const input = z.object({ name: z.string().min(2).max(100), email: z.email().max(254), message: z.string().min(10).max(4000), website: z.string().max(0).default('') }).safeParse(request.data);
  if (!input.success) throw new HttpsError('invalid-argument', 'Check your name, email and message.');
  const ipHash = createHash('sha256').update(request.rawRequest.ip || 'unknown').digest('hex');
  await rateLimit(ipHash, 'contact', 3);
  const admins = await db.collection('users').where('role', '==', 'admin').where('isActive', '==', true).get();
  const ref = db.collection('contactMessages').doc();
  await db.runTransaction(async tx => {
    tx.create(ref, { ...input.data, createdAt: now(), status: 'new' });
    for (const admin of admins.docs) notify(tx, `contact_${ref.id}_${admin.id}`, admin.id, `Website enquiry from ${input.data.name}`, `Reply to: ${input.data.email}\n\n${input.data.message}`, 'contact');
  });
  return { success: true };
});
