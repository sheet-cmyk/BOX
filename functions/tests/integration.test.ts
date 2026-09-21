import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { Timestamp } from 'firebase-admin/firestore';

process.env.GCLOUD_PROJECT = 'demo-jbb';
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Integration tests require the Firestore emulator.');
let db: typeof import('../src/platform').db;
let bookings: typeof import('../src/bookings');
let payments: typeof import('../src/payments');
before(async () => { db = (await import('../src/platform')).db; bookings = await import('../src/bookings'); payments = await import('../src/payments'); });
after(async () => { await db.terminate(); });
beforeEach(async () => {
  const response = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-jbb/databases/(default)/documents`, { method: 'DELETE' });
  assert.equal(response.ok, true);
  await db.doc('gymSettings/config').set({ cancellationPolicyHours: 24 });
  await db.doc('classes/junior').set({ className: 'Junior Boxing', isActive: true });
});
async function member(uid: string, credits = 2, role = 'member') { await db.doc(`users/${uid}`).set({ fullName: uid, role, isActive: true, sessionsRemaining: credits, sessionsReserved: 0 }); }
async function session(id: string, spots = 1, offsetHours = 72) {
  const start = Date.now() + offsetHours * 3_600_000;
  await db.doc(`schedule/${id}`).set({ classId: 'junior', date: Timestamp.fromMillis(start), endAt: Timestamp.fromMillis(start + 3_600_000), startTime: '16:00', endTime: '17:00', maxSpots: spots, bookedSpots: 0, isCancelled: false });
}
test('concurrent members cannot overbook the last seat', async () => {
  await session('last');
  await Promise.all(['a', 'b', 'c'].map(u => member(u)));
  const results = await Promise.allSettled(['a', 'b', 'c'].map(u => bookings.reserveBooking(u, 'last')));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal((await db.doc('schedule/last').get()).data()!.bookedSpots, 1);
});
test('duplicate booking request is idempotent', async () => {
  await member('a'); await session('one', 3);
  await Promise.all([bookings.reserveBooking('a', 'one'), bookings.reserveBooking('a', 'one')]);
  assert.equal((await db.doc('users/a').get()).data()!.sessionsReserved, 1);
  assert.equal((await db.doc('schedule/one').get()).data()!.bookedSpots, 1);
});
test('concurrent overlapping sessions reject the second booking', async () => {
  await member('a'); await session('one', 3); await session('two', 3);
  const result = await Promise.allSettled([bookings.reserveBooking('a', 'one'), bookings.reserveBooking('a', 'two')]);
  assert.equal(result.filter(r => r.status === 'fulfilled').length, 1);
});
test('one credit cannot reserve two non-overlapping classes', async () => {
  await member('a', 1); await session('one', 3, 72); await session('two', 3, 96);
  const result = await Promise.allSettled([bookings.reserveBooking('a', 'one'), bookings.reserveBooking('a', 'two')]);
  assert.equal(result.filter(r => r.status === 'fulfilled').length, 1);
});
test('cancellation restores capacity once and permits rebooking', async () => {
  await member('a'); await session('one');
  await bookings.reserveBooking('a', 'one');
  await bookings.releaseBooking('a', 'a_one'); await bookings.releaseBooking('a', 'a_one');
  assert.equal((await db.doc('users/a').get()).data()!.sessionsReserved, 0);
  assert.equal((await db.doc('schedule/one').get()).data()!.bookedSpots, 0);
  await bookings.reserveBooking('a', 'one');
  assert.equal((await db.doc('bookings/a_one').get()).data()!.revision, 2);
});
test('late cancellation and cancelling another member are forbidden', async () => {
  await member('a'); await member('b'); await session('soon', 2, 2);
  await bookings.reserveBooking('a', 'soon');
  await assert.rejects(bookings.releaseBooking('a', 'a_soon'), /cancellation window/);
  await assert.rejects(bookings.releaseBooking('b', 'a_soon'), /another member/);
});
test('completion trigger retries deduct exactly one session', async () => {
  await member('a'); await session('one'); await bookings.reserveBooking('a', 'one');
  await db.doc('bookings/a_one').update({ status: 'completed' });
  await Promise.all([bookings.settleBooking('a_one'), bookings.settleBooking('a_one')]);
  const user = (await db.doc('users/a').get()).data()!;
  assert.equal(user.sessionsRemaining, 1); assert.equal(user.sessionsReserved, 0);
});
test('members cannot mark attendance and admins cannot mark it before class end', async () => {
  await member('a'); await member('admin', 0, 'admin'); await session('one'); await bookings.reserveBooking('a', 'one');
  await assert.rejects(bookings.completeBooking('a', 'a_one', 'completed'), /Administrator/);
  await assert.rejects(bookings.completeBooking('admin', 'a_one', 'completed'), /after the class/);
});
test('payment webhook retries grant credits once and reject mismatched amount', async () => {
  await member('a', 0);
  await db.doc('payments/order').set({ userId: 'a', membershipPlanId: 'ten', credits: 10, amount: 60000, currency: 'usd', status: 'pending', stripePaymentIntentId: null });
  await assert.rejects(payments.applySuccessfulPayment('order', { id: 'pi_test', amount: 1, currency: 'usd' }), /mismatch/);
  await Promise.all([payments.applySuccessfulPayment('order', { id: 'pi_test', amount: 60000, currency: 'usd' }), payments.applySuccessfulPayment('order', { id: 'pi_test', amount: 60000, currency: 'usd' })]);
  assert.equal((await db.doc('users/a').get()).data()!.sessionsRemaining, 10);
});
