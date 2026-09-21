import { DateTime } from 'luxon';
import { db, now } from '../src/platform';
import { generateSchedule } from '../src/schedule';

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST && !process.argv.includes('--production')) throw new Error('Set FIRESTORE_EMULATOR_HOST for local seed, or explicitly pass --production with application default credentials.');
  const plans = [
    { id: 'single', name: 'Single Session', price: 8000, priceLabel: '$80', perSessionLabel: '$80 / session', sessionCount: 1, planType: 'package' },
    { id: 'five', name: '5 Session Pack', price: 35000, priceLabel: '$350', perSessionLabel: '$70 / session', sessionCount: 5, planType: 'package' },
    { id: 'ten', name: '10 Session Pack', price: 60000, priceLabel: '$600', perSessionLabel: '$60 / session', sessionCount: 10, planType: 'package' },
    { id: 'group', name: 'Small Group Training', price: 3500, priceLabel: '$35', perSessionLabel: '/ hour per person', sessionCount: null, creditsPerPurchase: 1, planType: 'hourly' },
    { id: 'partner', name: 'Partner Training', price: 6000, priceLabel: '$60', perSessionLabel: '/ hour per person', sessionCount: null, creditsPerPurchase: 1, planType: 'hourly' },
  ];
  for (const [sortOrder, p] of plans.entries()) await createIfAbsent(`membershipPlans/${p.id}`, { ...p, description: p.planType === 'hourly' ? 'One 60-minute session per person.' : 'Build confidence, get stronger, make real progress.', sortOrder, isRecommended: p.id === 'ten', isActive: true, createdAt: now() });
  for (const c of [
    { id: 'junior', className: 'Junior Boxing', description: 'Boxing fundamentals, confidence and discipline for kids and teens.', ageGroup: 'Ages 8–14', maxSpots: 12, imageUrl: '/assets/images/cards/card_program_junior.png' },
    { id: 'group', className: 'Group Training', description: 'Small group boxing sessions focused on technique and conditioning.', ageGroup: 'Ages 14+', maxSpots: 4, imageUrl: '/assets/images/cards/card_program_group.png' },
  ]) await createIfAbsent(`classes/${c.id}`, { ...c, coachName: 'Coach Sharif', durationMinutes: 60, location: 'Junior Boy Boxing', address: '3200 Naglee Rd, Tracy, CA', isActive: true, createdAt: now() });
  await createIfAbsent('gymSettings/config', { gymName: 'Junior Boy Boxing', address: '3200 Naglee Rd, Tracy, CA', phone: '', email: '', coachName: 'Coach Sharif', operatingHours: {}, socialLinks: { instagram: '', facebook: '', tiktok: '' }, aboutText: 'Discipline builds champions. Junior Boy Boxing helps kids and teens build confidence, strength and skills through boxing.', cancellationPolicyHours: 24, classRemindersEnabled: true, membershipAlertsEnabled: true, updatedAt: now() });
  // Sample weekly times are seeded only in the emulator; production times must be entered by the gym.
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    for (const day of [1, 3, 5]) await createIfAbsent(`recurringTemplates/junior_${day}`, { classId: 'junior', dayOfWeek: day, startTime: '16:00', maxSpots: 12, isActive: true });
    for (const day of [2, 4, 6]) await createIfAbsent(`recurringTemplates/group_${day}`, { classId: 'group', dayOfWeek: day, startTime: '17:00', maxSpots: 4, isActive: true });
    await generateSchedule(DateTime.now().minus({ weeks: 1 }));
    await generateSchedule();
  }
  console.log('Seed complete. Existing documents were preserved.');
}
async function createIfAbsent(path: string, data: object) {
  await db.runTransaction(async tx => { const ref = db.doc(path); if (!(await tx.get(ref)).exists) tx.create(ref, data); });
}
main().catch(error => { console.error(error); process.exitCode = 1; });
