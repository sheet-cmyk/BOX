import { createHash } from 'node:crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit, callable, db, emulator, enforceAppCheck, now, rateLimit, requireMember, requireRegistered } from './platform';

export const publishWaiver = callable(z.object({ title: z.string().trim().min(5).max(120), body: z.string().trim().min(200).max(30000), approved: z.literal(true), requiredOnBooking: z.boolean() }), 'publishWaiver', async (input, uid) => {
  const version = createHash('sha256').update(`${input.title}\n${input.body}`).digest('hex');
  await db.runTransaction(async tx => {
    const revision = db.doc(`waiverVersions/${version}`);
    const old = await tx.get(revision);
    const data = { title: input.title, body: input.body, version, published: true, requiredOnBooking: input.requiredOnBooking, publishedAt: now(), publishedBy: uid };
    if (!old.exists) tx.create(revision, data);
    tx.set(db.doc('legalDocuments/waiver'), data);
    audit(tx, uid, 'publishWaiver', version);
  });
  return { version };
}, true);

export async function recordWaiver(uid: string, input: { version: string; signerName: string; capacity: 'participant' | 'guardian'; adult: true; agree: true }) {
  return db.runTransaction(async tx => {
    const [document, member] = await Promise.all([tx.get(db.doc('legalDocuments/waiver')), tx.get(db.doc(`users/${uid}`))]);
    const waiver = document.data(), profile = member.data();
    if (!profile?.isActive) throw new HttpsError('permission-denied', 'Account is not active.');
    if (!waiver?.published || waiver.version !== input.version) throw new HttpsError('failed-precondition', 'The waiver has changed or is not published. Read the current version.');
    if (!profile.childName?.trim() || !Number.isInteger(profile.childAge) || profile.childAge < 1) throw new HttpsError('failed-precondition', 'Complete your participant details first.');
    if (profile.childAge < 18 && input.capacity !== 'guardian') throw new HttpsError('failed-precondition', 'A parent or legal guardian must sign for a participant under 18.');
    const participant = { name: profile.childName.trim(), age: profile.childAge };
    const fingerprint = createHash('sha256').update(JSON.stringify({ version: input.version, participant })).digest('hex');
    const ref = db.doc(`waiverAcceptances/${uid}_${fingerprint}`);
    const previous = await tx.get(ref);
    if (!previous.exists) {
      tx.create(ref, { userId: uid, version: input.version, participant, signerName: input.signerName, capacity: input.capacity, adult: true, agree: true, acceptedAt: now() });
      audit(tx, uid, 'acceptWaiver', ref.id);
    }
    tx.update(member.ref, { waiverVersion: input.version, waiverParticipantName: participant.name, waiverParticipantAge: participant.age, updatedAt: now() });
    return { acceptanceId: ref.id, version: input.version };
  });
}
export const acceptWaiver = onCall({ enforceAppCheck }, async request => {
  const uid = requireRegistered(request);
  await requireMember(uid); await rateLimit(uid, 'acceptWaiver', 10);
  const input = z.object({ version: z.string().regex(/^[a-f0-9]{64}$/), signerName: z.string().trim().min(2).max(100), capacity: z.enum(['participant', 'guardian']), adult: z.literal(true), agree: z.literal(true) }).safeParse(request.data);
  if (!input.success) throw new HttpsError('invalid-argument', 'Your name, signing capacity and explicit agreement are required.');
  return recordWaiver(uid, input.data);
});
