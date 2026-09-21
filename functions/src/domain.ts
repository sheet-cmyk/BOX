import { DateTime } from 'luxon';

export function overlaps(aStart: number, aEnd: number, bStart: number, bEnd: number): boolean {
  return aStart < bEnd && bStart < aEnd;
}
export function canCancel(start: number, now: number, policyHours: number): boolean {
  return start > now && start - now >= policyHours * 3_600_000;
}
export function csvCell(value: unknown): string {
  let text = String(value ?? '');
  if (/^[\s]*[=+@-]/.test(text)) text = "'" + text;
  return '"' + text.replace(/"/g, '""') + '"';
}
export function nextWeekOccurrence(now: DateTime, weekday: number, time: string, zone: string): DateTime {
  const [hour, minute] = time.split(':').map(Number);
  const start = now.setZone(zone).startOf('week').plus({ weeks: 1 });
  const result = start.plus({ days: (weekday + 6) % 7 }).set({ hour, minute });
  if (!result.isValid) throw new Error('Invalid schedule date');
  return result;
}
export function reservationAvailable(remaining: number, reserved: number): number {
  return Math.max(0, remaining - reserved);
}
