import { DateTime } from 'luxon';
export const zone = 'America/Los_Angeles';
export function asDate(value: any): Date { return value?.toDate ? value.toDate() : new Date(value); }
export const dateLabel = (value: any) => DateTime.fromJSDate(asDate(value)).setZone(zone).toFormat('ccc, LLL d');
export const timeLabel = (value: any) => DateTime.fromJSDate(asDate(value)).setZone(zone).toFormat('h:mm a');
export const money = (amount: number) => new Intl.NumberFormat('en-US', {style:'currency',currency:'USD'}).format(amount / 100);
export function errorMessage(error: unknown): string {
  const e = error as { code?: string; message?: string };
  if (['auth/invalid-credential','auth/wrong-password','auth/user-not-found'].includes(e.code || '')) return 'Check your email and password.';
  if (e.code === 'auth/email-already-in-use') return 'This email already has an account. Please sign in.';
  if (e.code === 'functions/unavailable' || e.code === 'unavailable') return 'Connection unavailable. Please retry in a moment.';
  return e.message?.replace(/^Firebase:\s*/,'').replace(/\s*\(auth\/[^)]+\)\.?$/,'') || 'Unable to complete this action. Please retry.';
}
export function downloadCSV(csv: string, filename: string) { const url = URL.createObjectURL(new Blob(['\ufeff',csv], {type:'text/csv;charset=utf-8;'})); const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); URL.revokeObjectURL(url); }
