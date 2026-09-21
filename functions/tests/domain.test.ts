import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DateTime } from 'luxon';
import { canCancel, csvCell, nextWeekOccurrence, overlaps, reservationAvailable } from '../src/domain';

test('overlapping intervals include partial overlap but allow adjacent sessions', () => {
  assert.equal(overlaps(10, 20, 15, 25), true);
  assert.equal(overlaps(10, 20, 20, 30), false);
  assert.equal(overlaps(10, 30, 15, 20), true);
});
test('cancellation permits exact 24-hour boundary and rejects past sessions', () => {
  assert.equal(canCancel(86_400_000, 0, 24), true);
  assert.equal(canCancel(86_399_999, 0, 24), false);
  assert.equal(canCancel(0, 1, 0), false);
});
test('CSV escaping prevents formula injection and preserves quotes and commas', () => {
  assert.equal(csvCell('=SUM(A1)'), '"\'=SUM(A1)"');
  assert.equal(csvCell('a,"b"'), '"a,""b"""');
  assert.equal(csvCell('  +cmd'), '"\'  +cmd"');
});
test('schedule uses gym timezone and preserves wall-clock time across DST', () => {
  const result = nextWeekOccurrence(DateTime.fromISO('2026-03-01T18:00', { zone: 'America/Los_Angeles' }), 0, '16:00', 'America/Los_Angeles');
  assert.equal(result.toISO(), '2026-03-08T16:00:00.000-07:00');
});
test('reserved session credits cannot be booked twice', () => {
  assert.equal(reservationAvailable(5, 5), 0);
  assert.equal(reservationAvailable(5, 2), 3);
});
