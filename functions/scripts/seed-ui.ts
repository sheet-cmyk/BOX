import { auth, db, now } from '../src/platform';
if (process.env.GCLOUD_PROJECT !== 'demo-jbb' || !process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('UI fixtures require demo-jbb emulators.');
async function main() {
  for (const role of ['member','admin']) {
    const uid = `ui-${role}`;
    try { await auth.createUser({uid,email:`${role}@example.test`,password:'UiTestPass123!',displayName:`UI ${role}`}); } catch(e:any) { if(e.code!=='auth/uid-already-exists') throw e; }
    await db.doc(`users/${uid}`).set({fullName:`UI ${role}`,email:`${role}@example.test`,phone:'4152900559',childName:'Test Boxer',childAge:12,role,isActive:true,sessionsRemaining:3,sessionsReserved:0,avatarUrl:'',notificationPreferences:{push:false,email:false},createdAt:now(),updatedAt:now(),memberSince:now()});
  }
  console.log('Emulator-only UI accounts prepared.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
