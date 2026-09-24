// Sets the public Stripe publishable key used by the website and mobile app checkout.
// Never handles the secret key (that is stored only as a Cloud Functions secret).
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');

const PROJECT = 'box-jbb';
const KEY = process.argv[2];
if (!/^pk_(test|live)_[A-Za-z0-9]+$/.test(KEY || '')) {
  console.error('Usage: node set-stripe-publishable-key.cjs pk_test_or_live_...');
  process.exit(1);
}

async function main() {
  await requireAuth({ ...getGlobalDefaultAccount(), project: PROJECT });
  const api = new Client({ urlPrefix: 'https://firestore.googleapis.com' });
  const path = `/v1/projects/${PROJECT}/databases/(default)/documents/gymSettings/config`;
  await api.patch(`${path}?updateMask.fieldPaths=stripePublishableKey&updateMask.fieldPaths=updatedAt`, {
    fields: { stripePublishableKey: { stringValue: KEY }, updatedAt: { timestampValue: new Date().toISOString() } },
  });
  console.log('stripePublishableKey set.');
}
main().catch(e => { console.error(e.message || e); process.exitCode = 1; });
