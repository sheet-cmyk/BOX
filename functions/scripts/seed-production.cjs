// Seeds real membership plans, programs, gym contact info and the Mon/Wed/Fri 4pm
// schedule into production Firestore. Reuses the already-authorized Firebase CLI
// login (never reads or prints any credential) and only creates documents that do
// not already exist — existing data is always preserved.
const { DateTime } = require('luxon');
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');

const PROJECT = 'box-jbb';
const ZONE = 'America/Los_Angeles';

const str = v => ({ stringValue: v });
const int = v => ({ integerValue: String(v) });
const bool = v => ({ booleanValue: v });
const ts = dt => ({ timestampValue: dt.toUTC().toISO() });
const nul = () => ({ nullValue: null });

function nextWeekOccurrence(now, weekday, time) {
  const [hour, minute] = time.split(':').map(Number);
  const start = now.setZone(ZONE).startOf('week').plus({ weeks: 1 });
  return start.plus({ days: (weekday + 6) % 7 }).set({ hour, minute, second: 0, millisecond: 0 });
}

async function main() {
  await requireAuth({ ...getGlobalDefaultAccount(), project: PROJECT });
  const api = new Client({ urlPrefix: 'https://firestore.googleapis.com' });
  const base = `/v1/projects/${PROJECT}/databases/(default)/documents`;

  async function createIfAbsent(path, fields) {
    const parent = path.split('/').slice(0, -1).join('/');
    const id = path.split('/').pop();
    try {
      await api.post(`${base}/${parent}?documentId=${id}`, { fields });
      return 'created';
    } catch (e) {
      if (e.status === 409) return 'exists';
      throw e;
    }
  }

  const plans = [
    { id: 'single', name: 'Single Session', price: 8000, priceLabel: '$80', perSessionLabel: '$80 / session', sessionCount: 1, planType: 'package' },
    { id: 'five', name: '5 Session Pack', price: 35000, priceLabel: '$350', perSessionLabel: '$70 / session', sessionCount: 5, planType: 'package' },
    { id: 'ten', name: '10 Session Pack', price: 60000, priceLabel: '$600', perSessionLabel: '$60 / session', sessionCount: 10, planType: 'package' },
    { id: 'group', name: 'Small Group Training', price: 3500, priceLabel: '$35', perSessionLabel: '/ hour per person', sessionCount: null, creditsPerPurchase: 1, planType: 'hourly' },
    { id: 'partner', name: 'Partner Training', price: 6000, priceLabel: '$60', perSessionLabel: '/ hour per person', sessionCount: null, creditsPerPurchase: 1, planType: 'hourly' },
  ];
  for (const [sortOrder, p] of plans.entries()) {
    const fields = {
      name: str(p.name), price: int(p.price), priceLabel: str(p.priceLabel), perSessionLabel: str(p.perSessionLabel),
      sessionCount: p.sessionCount == null ? nul() : int(p.sessionCount), planType: str(p.planType),
      description: str(p.planType === 'hourly' ? 'One 60-minute session per person.' : 'Build confidence, get stronger, make real progress.'),
      sortOrder: int(sortOrder), isRecommended: bool(p.id === 'ten'), isActive: bool(true), createdAt: ts(DateTime.now()),
      ...(p.creditsPerPurchase ? { creditsPerPurchase: int(p.creditsPerPurchase) } : {}),
    };
    console.log('membershipPlans/' + p.id, await createIfAbsent(`membershipPlans/${p.id}`, fields));
  }

  const classes = [
    { id: 'junior', className: 'Junior Boxing', description: 'Boxing fundamentals, confidence and discipline for kids and teens.', ageGroup: 'Ages 8–14', maxSpots: 12, imageUrl: '/assets/images/cards/card_program_junior.png' },
    { id: 'group', className: 'Group Training', description: 'Small group boxing sessions focused on technique and conditioning.', ageGroup: 'Ages 14+', maxSpots: 4, imageUrl: '/assets/images/cards/card_program_group.png' },
  ];
  for (const c of classes) {
    const fields = {
      className: str(c.className), description: str(c.description), ageGroup: str(c.ageGroup), maxSpots: int(c.maxSpots), imageUrl: str(c.imageUrl),
      coachName: str('Coach Sharif'), durationMinutes: int(60), location: str('Junior Boy Boxing'), address: str('3200 Naglee Rd, Tracy, CA'), isActive: bool(true), createdAt: ts(DateTime.now()),
    };
    console.log('classes/' + c.id, await createIfAbsent(`classes/${c.id}`, fields));
  }

  console.log('gymSettings/config', await createIfAbsent('gymSettings/config', {
    gymName: str('Junior Boy Boxing'), address: str('3200 Naglee Rd, Tracy, CA'), phone: str('415-290-0559'), email: str('juniorboyboxing@gmail.com'),
    coachName: str('Coach Sharif'), operatingHours: { mapValue: { fields: {} } }, socialLinks: { mapValue: { fields: { instagram: str(''), facebook: str(''), tiktok: str('') } } },
    aboutText: str('Discipline builds champions. Junior Boy Boxing helps kids and teens build confidence, strength and skills through boxing.'),
    cancellationPolicyHours: int(24), classRemindersEnabled: bool(true), membershipAlertsEnabled: bool(true), updatedAt: ts(DateTime.now()),
  }));

  const templates = [1, 3, 5].map(day => ({ id: `junior_${day}`, classId: 'junior', dayOfWeek: day, startTime: '16:00', maxSpots: 12 }));
  for (const t of templates) {
    console.log('recurringTemplates/' + t.id, await createIfAbsent(`recurringTemplates/${t.id}`, {
      classId: str(t.classId), dayOfWeek: int(t.dayOfWeek), startTime: str(t.startTime), maxSpots: int(t.maxSpots), isActive: bool(true),
    }));
  }

  for (let i = 0; i < 4; i++) {
    const reference = DateTime.now().setZone(ZONE).plus({ weeks: i });
    for (const t of templates) {
      const start = nextWeekOccurrence(reference, t.dayOfWeek, t.startTime);
      const end = start.plus({ minutes: 60 });
      const docId = `${t.id}_${start.toFormat('yyyy-MM-dd')}`;
      const result = await createIfAbsent(`schedule/${docId}`, {
        classId: str(t.classId), date: ts(start), endAt: ts(end), dayOfWeek: str(start.toFormat('cccc').toLowerCase()),
        startTime: str(start.toFormat('HH:mm')), endTime: str(end.toFormat('HH:mm')), maxSpots: int(t.maxSpots), bookedSpots: int(0),
        isRecurring: bool(true), recurringDayOfWeek: int(t.dayOfWeek), templateId: str(t.id), isCancelled: bool(false), createdAt: ts(DateTime.now()),
      });
      console.log('schedule/' + docId, result);
    }
  }
  console.log('Production seed complete. Existing documents were preserved.');
}
main().catch(e => { console.error(e.message || e); process.exitCode = 1; });
