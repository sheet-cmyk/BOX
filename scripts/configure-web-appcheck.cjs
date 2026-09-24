const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');
const { ensure } = require('firebase-tools/lib/ensureApiEnabled');
async function main() {
  await requireAuth({...getGlobalDefaultAccount(),project:'box-jbb'});
  await ensure('box-jbb','recaptchaenterprise.googleapis.com','App Check');
  const recaptcha = new Client({urlPrefix:'https://recaptchaenterprise.googleapis.com'});
  const keys = (await recaptcha.get('/v1/projects/box-jbb/keys')).body.keys || [];
  let key = keys.find(k=>k.displayName==='Junior Boy Boxing Website App Check');
  if (!key) key = (await recaptcha.post('/v1/projects/box-jbb/keys',{displayName:'Junior Boy Boxing Website App Check',webSettings:{allowedDomains:['box-jbb.web.app','box-jbb.firebaseapp.com'],integrationType:'SCORE',allowAllDomains:false}})).body;
  const siteKey = key.name.split('/').pop();
  const path = 'projects/772438105367/apps/1:772438105367:web:fc382ddbe5c2d121a66b52/recaptchaEnterpriseConfig';
  await new Client({urlPrefix:'https://firebaseappcheck.googleapis.com'}).patch('/v1/'+path+'?updateMask=siteKey,tokenTtl',{name:path,siteKey,tokenTtl:'3600s'});
  console.log(JSON.stringify({configured:true,siteKey}));
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
