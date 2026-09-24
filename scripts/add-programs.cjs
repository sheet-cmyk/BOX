// Add only the requested program records; never replace existing data or create sessions.
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');
async function main() {
  await requireAuth({...getGlobalDefaultAccount(),project:'box-jbb'});
  const api = new Client({urlPrefix:'https://firestore.googleapis.com'});
  const programs = [
    ['boxing','Boxing Training','Stance, footwork, defense and punching fundamentals.'],
    ['fitness','Fitness Training','Cardio, mobility and whole-body training.'],
    ['strength','Strength and Conditioning','Progressive strength, endurance and movement training.'],
    ['weight-loss','Weight Loss Training','Structured activity and sustainable exercise habits. Individual results vary.'],
    ['self-defense','Self Defense Training','Awareness, positioning, movement and defensive fundamentals.'],
  ];
  for(const [id,className,description] of programs) {
    const values={className,description,ageGroup:'Contact the coach for suitability',coachName:'Coach Sharif',location:'Junior Boy Boxing',address:'3200 Naglee Rd, Tracy, CA',imageUrl:'/assets/images/cards/card_program_group.png'};
    const fields=Object.fromEntries(Object.entries(values).map(([k,v])=>[k,{stringValue:v}]));
    Object.assign(fields,{durationMinutes:{integerValue:'60'},maxSpots:{integerValue:'12'},isActive:{booleanValue:true},createdAt:{timestampValue:new Date().toISOString()}});
    try { await api.post('/v1/projects/box-jbb/databases/(default)/documents/classes?documentId='+id,{fields});console.log(id+': added'); }
    catch(e) { if(e.status===409) console.log(id+': existing record preserved');else throw e; }
  }
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
