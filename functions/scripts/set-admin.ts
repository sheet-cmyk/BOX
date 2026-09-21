import { auth, db, now } from '../src/platform';
import { ensureUser } from '../src/users';

async function main() {
  const email = process.argv[2];
  if (!email?.includes('@')) throw new Error('Usage: npm run admin -- coach@example.com');
  const user = await auth.getUserByEmail(email);
  await ensureUser(user);
  await db.doc(`users/${user.uid}`).update({ role: 'admin', updatedAt: now() });
  console.log(`Administrator access assigned to ${email}.`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
