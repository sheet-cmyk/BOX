import { readFileSync } from 'node:fs';
import { before, after, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp, collection, query, where, getDocs } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env: RulesTestEnvironment;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-jbb', firestore: { rules: readFileSync('../firestore.rules', 'utf8') }, storage: { rules: readFileSync('../storage.rules', 'utf8') } });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    for (const uid of ['alice', 'bob', 'admin', 'inactive']) await setDoc(doc(context.firestore(), 'users', uid), { fullName: uid, email: `${uid}@example.com`, phone: '', childName: '', childAge: 0, avatarUrl: '', role: uid === 'admin' ? 'admin' : 'member', isActive: uid !== 'inactive', sessionsRemaining: 10, sessionsReserved: 0, notificationPreferences: { push: true, email: true } });
    await setDoc(doc(context.firestore(), 'bookings', 'alice_one'), { userId: 'alice', status: 'confirmed' });
    await setDoc(doc(context.firestore(), 'membershipPlans', 'ten'), { isActive: true, price: 60000 });
    await setDoc(doc(context.firestore(), 'membershipPlans', 'hidden'), { isActive: false, price: 1 });
    await setDoc(doc(context.firestore(), 'gymSettings', 'config'), { gymName: 'Junior Boy Boxing' });
    await setDoc(doc(context.firestore(), 'notifications', 'n'), { userId: 'alice', isRead: false, body: 'Hello' });
  });
});
after(async () => { await env.cleanup(); });
test('anonymous access is limited to public config and active plans', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'gymSettings', 'config')));
  await assertSucceeds(getDoc(doc(db, 'membershipPlans', 'ten')));
  await assertFails(getDoc(doc(db, 'membershipPlans', 'hidden')));
  await assertFails(getDoc(doc(db, 'users', 'alice')));
  await assertFails(getDocs(collection(db, 'schedule')));
});
test('members cannot read other users or forge booking and payment writes', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(db, 'users', 'alice')));
  await assertFails(getDoc(doc(db, 'users', 'bob')));
  await assertFails(setDoc(doc(db, 'bookings', 'fake'), { userId: 'alice' }));
  await assertFails(setDoc(doc(db, 'payments', 'fake'), { userId: 'alice', status: 'completed' }));
  await assertSucceeds(getDocs(query(collection(db, 'bookings'), where('userId', '==', 'alice'))));
  await assertFails(getDocs(collection(db, 'bookings')));
});
test('users cannot elevate roles, add credits, change email or reactivate accounts', async () => {
  const db = env.authenticatedContext('alice').firestore();
  for (const patch of [{ role: 'admin' }, { sessionsRemaining: 10000 }, { sessionsReserved: 0 }, { email: 'evil@example.com' }, { isActive: false }]) await assertFails(updateDoc(doc(db, 'users', 'alice'), patch));
  await assertFails(updateDoc(doc(env.authenticatedContext('inactive').firestore(), 'users', 'inactive'), { isActive: true }));
  await assertSucceeds(updateDoc(doc(db, 'users', 'alice'), { fullName: 'Alice Smith', updatedAt: serverTimestamp() }));
});
test('notification recipients can mark read but cannot alter contents', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(updateDoc(doc(db, 'notifications', 'n'), { isRead: true }));
  await assertFails(updateDoc(doc(db, 'notifications', 'n'), { body: 'Forged' }));
});

test('waivers are public to read, but publication and acceptance cannot be forged', async () => {
  const member = env.authenticatedContext('alice').firestore();
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(),'legalDocuments','waiver')));
  await assertFails(setDoc(doc(member,'legalDocuments','waiver'),{published:true}));
  await assertFails(setDoc(doc(member,'waiverAcceptances','forged'),{userId:'alice',acceptedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(member,'users','alice'),{waiverVersion:'forged'}));
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'waiverAcceptances','real'),{userId:'alice',version:'test'});
  });
  await assertSucceeds(getDoc(doc(member,'waiverAcceptances','real')));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(),'waiverAcceptances','real')));
  await assertFails(updateDoc(doc(member,'waiverAcceptances','real'),{version:'changed'}));
});
test('admin reads are allowed but accounting writes still require trusted functions', async () => {
  const db = env.authenticatedContext('admin').firestore();
  await assertSucceeds(getDoc(doc(db, 'users', 'alice')));
  await assertFails(updateDoc(doc(db, 'users', 'alice'), { sessionsRemaining: 200 }));
  await assertFails(setDoc(doc(db, 'schedule', 'bad'), { bookedSpots: -1 }));
});
test('storage rejects non-images and cross-user avatar writes', async () => {
  const storage = env.authenticatedContext('alice').storage();
  await assertFails(uploadBytes(ref(storage, 'avatars/bob/photo.png'), new Uint8Array([1, 2]), { contentType: 'image/png' }));
  await assertFails(uploadBytes(ref(storage, 'avatars/alice/file.html'), new Uint8Array([1, 2]), { contentType: 'text/html' }));
  await assertSucceeds(uploadBytes(ref(storage, 'avatars/alice/photo.png'), new Uint8Array([1, 2]), { contentType: 'image/png' }));
});
