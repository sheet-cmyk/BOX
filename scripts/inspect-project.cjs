// Uses the existing Firebase CLI login; never prints credentials or member data.
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');
async function main() {
  const account = getGlobalDefaultAccount();
  await requireAuth({ ...account, project: 'box-jbb' });
  const tasks = [
    ['paymentConfig', 'https://firestore.googleapis.com', '/v1/projects/box-jbb/databases/(default)/documents/gymSettings/config', b => ({publishableKeyConfigured:/^pk_(test|live)_/.test(b.fields?.stripePublishableKey?.stringValue || '')})],
    ['webAppCheck', 'https://firebaseappcheck.googleapis.com', '/v1/projects/772438105367/apps/1:772438105367:web:fc382ddbe5c2d121a66b52/recaptchaEnterpriseConfig', b => ({configured: !!b.siteKey, siteKey: b.siteKey})],
    ['recaptchaKeys', 'https://recaptchaenterprise.googleapis.com', '/v1/projects/box-jbb/keys', b => ({keys: (b.keys || []).map(k => ({name:k.name,displayName:k.displayName,domains:k.webSettings?.allowedDomains}))})],
    ['authProviders', 'https://identitytoolkit.googleapis.com', '/admin/v2/projects/box-jbb/config', b => ({authorizedDomains:b.authorizedDomains,emailEnabled:b.signIn?.email?.enabled,phoneEnabled:b.signIn?.phoneNumber?.enabled,anonymousEnabled:b.signIn?.anonymous?.enabled})],
    ['hostingReleases', 'https://firebasehosting.googleapis.com', '/v1beta1/sites/box-jbb/releases?pageSize=1', b => ({releases:(b.releases||[]).map(r=>({releaseTime:r.releaseTime,version:r.version?.name,status:r.version?.status}))})],
  ];
  for (const [name, urlPrefix, path, summarize] of tasks) {
    try { const response = await new Client({urlPrefix}).get(path); console.log(JSON.stringify({name,...summarize(response.body)})); }
    catch(e) { console.log(JSON.stringify({name,error:e.message})); }
  }
}
main().catch(() => {console.error('Project inspection failed. Check Firebase CLI authentication.');process.exitCode=1;});
