import { z } from 'zod';
import { callable, db, now } from './platform';

// A user may have at most one review (doc id = uid). Re-submitting updates
// it in place and adjusts the aggregate stats instead of creating a duplicate.
const reviewSchema = z.object({ rating: z.number().int().min(1).max(5), comment: z.string().trim().max(500).default('') });

type Distribution = Record<'1' | '2' | '3' | '4' | '5', number>;
const emptyDistribution = (): Distribution => ({ '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 });

export const submitReview = callable(reviewSchema, 'submitReview', async (input, uid) => {
  const ref = db.doc(`reviews/${uid}`);
  const statsRef = db.doc('reviewStats/summary');
  await db.runTransaction(async tx => {
    const [existing, user, stats] = await Promise.all([tx.get(ref), tx.get(db.doc(`users/${uid}`)), tx.get(statsRef)]);
    const profile = user.data();
    const previous = existing.exists ? (existing.data()!.rating as number) : null;
    const s = stats.data() as { count: number; total: number; distribution: Distribution } | undefined ?? { count: 0, total: 0, distribution: emptyDistribution() };
    if (previous != null) {
      s.total -= previous;
      s.distribution[String(previous) as keyof Distribution] = Math.max(0, (s.distribution[String(previous) as keyof Distribution] ?? 0) - 1);
    } else {
      s.count += 1;
    }
    s.total += input.rating;
    const key = String(input.rating) as keyof Distribution;
    s.distribution[key] = (s.distribution[key] ?? 0) + 1;
    tx.set(ref, {
      userId: uid,
      userName: profile?.fullName || 'Member',
      userAvatarUrl: profile?.avatarUrl || '',
      rating: input.rating,
      comment: input.comment,
      createdAt: existing.exists ? existing.data()!.createdAt : now(),
      updatedAt: now(),
    });
    tx.set(statsRef, { count: s.count, total: s.total, average: s.count ? s.total / s.count : 0, distribution: s.distribution, updatedAt: now() });
  });
  return { success: true };
});

export const deleteReview = callable(z.object({}), 'deleteReview', async (_input, uid) => {
  const ref = db.doc(`reviews/${uid}`);
  const statsRef = db.doc('reviewStats/summary');
  await db.runTransaction(async tx => {
    const [existing, stats] = await Promise.all([tx.get(ref), tx.get(statsRef)]);
    if (!existing.exists) return;
    const rating = existing.data()!.rating as number;
    const s = stats.data() as { count: number; total: number; distribution: Distribution } | undefined;
    if (s) {
      const key = String(rating) as keyof Distribution;
      s.count = Math.max(0, s.count - 1);
      s.total -= rating;
      s.distribution[key] = Math.max(0, (s.distribution[key] ?? 0) - 1);
      tx.set(statsRef, { count: s.count, total: s.total, average: s.count ? s.total / s.count : 0, distribution: s.distribution, updatedAt: now() });
    }
    tx.delete(ref);
  });
  return { success: true };
});
