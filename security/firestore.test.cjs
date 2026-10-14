const {before, after, beforeEach, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where,
  writeBatch, runTransaction, serverTimestamp: stamp, Timestamp, deleteField} = require('firebase/firestore');
let env;
const profiles = {
  watch: {companyId: 'factory', role: 'watcher', displayName: 'Watch'},
  op: {companyId: 'factory', role: 'operator', displayName: 'Operator'},
  op2: {companyId: 'factory', role: 'operator', displayName: 'Operator Two'},
  viewer: {companyId: 'factory', role: 'viewer', displayName: 'Viewer'},
  admin: {companyId: 'factory', role: 'admin', displayName: 'Admin'},
  pilot: {companyId: 'pilot', role: 'operator', displayName: 'Pilot', environment: 'training'},
};
const db = uid => env.authenticatedContext(uid).firestore();
const record = (store, p) => doc(store, p);
const event = (uid, type, extra = {}) => ({type, at: stamp(), byUid: uid,
  byName: profiles[uid].displayName, byRole: profiles[uid].role, message: '', ...extra});
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-factory-check',
    firestore: {host: '127.0.0.1', port: 8180,
      rules: fs.readFileSync(path.join(__dirname, 'firestore.rules'), 'utf8')}});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const store = context.firestore();
    const batch = writeBatch(store);
    for (const [uid, data] of Object.entries(profiles)) batch.set(doc(store, 'users', uid), data);
    batch.set(doc(store, 'machines/m'), {companyId: 'factory', environment: 'production', name: 'M'});
    batch.set(doc(store, 'machines/p'), {companyId: 'pilot', environment: 'training', name: 'P'});
    await batch.commit();
  });
});
async function create(uid = 'watch', id = 'call', machine = 'm', stopped = false) {
  const store = db(uid), p = profiles[uid], at = Timestamp.now();
  const batch = writeBatch(store);
  batch.set(doc(store, 'incidents', id), {
    schemaVersion: 3, environment: p.environment || 'production', machineId: machine, machineKey: machine,
    createdByCompanyId: p.companyId, createdByUid: uid, reportedByName: p.displayName, reportedByRole: p.role,
    description: 'Film jam', kind: 'fault', reasonCode: 'material_jam', targetTeam: 'operator', errorCode: '',
    category: stopped ? 'red' : 'yellow', status: 'open', canRun: !stopped,
    createdAt: stamp(), updatedAt: stamp(), reportedAt: at, openedAt: at, ackAt: null, resolvedAt: null,
    assignedToUid: null, assignedToName: null, downtimeStartedAt: stopped ? at : null,
    downtimeEndedAt: null, downtimeSeconds: 0, activeDowntimeId: stopped ? 'interval' : null,
  });
  batch.update(doc(store, 'machines', machine), {activeIncidentId: id, activeStatus: 'open',
    activeCategory: stopped ? 'red' : 'yellow', activeOpenedAt: at,
    reportedState: stopped ? 'stopped' : 'running', updatedAt: stamp()});
  batch.set(doc(store, `incidents/${id}/events/created`), event(uid, 'created'));
  if (stopped) batch.set(doc(store, 'downtime_intervals/interval'), {companyId: p.companyId,
    environment: p.environment || 'production', incidentId: id, machineId: machine, machineKey: machine,
    startAt: at, endAt: null});
  return batch.commit();
}
async function transition(uid, to, {id = 'call', team, notes = 'Done'} = {}) {
  const store = db(uid), ref = doc(store, 'incidents', id), data = (await getDoc(ref)).data();
  const changes = {status: to, updatedAt: stamp(), waitingReason: to === 'waiting' ? notes : null};
  if (to === 'acknowledged' || !data.assignedToUid) Object.assign(changes, {
    assignedToUid: uid, assignedToName: profiles[uid].displayName, ackAt: data.ackAt || stamp()});
  if (to === 'in_progress' && !data.workStartedAt) changes.workStartedAt = stamp();
  if (to === 'waiting' && team) Object.assign(changes, {targetTeam: team, assignedToUid: null, assignedToName: null});
  const machine = {activeStatus: to, reportedState: data.canRun === false ? 'stopped' : 'running', updatedAt: stamp()};
  if (to === 'resolved') {
    const end = Timestamp.now();
    Object.assign(changes, {resolvedAt: end, repairedAt: end, repairedByUid: uid,
      repairedByName: profiles[uid].displayName, repairedByRole: profiles[uid].role, repairNotes: notes,
      machineRunsAfter: true, canRun: true, needsTeam: false});
    Object.assign(machine, {activeIncidentId: deleteField(), activeOpenedAt: deleteField(),
      activeCategory: 'green', reportedState: 'running'});
  }
  const batch = writeBatch(store);
  batch.update(ref, changes); batch.update(doc(store, 'machines', data.machineId), machine);
  batch.set(doc(collection(store, `incidents/${id}/events`)), event(uid, 'status_changed', {fromStatus: data.status, toStatus: to}));
  return batch.commit();
}
test('anonymous access, profile impersonation and self promotion are denied', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'machines/m')));
  await assertSucceeds(getDoc(doc(db('op'), 'users/op')));
  await assertFails(getDoc(doc(db('op'), 'users/watch')));
  await assertFails(updateDoc(doc(db('op'), 'users/op'), {role: 'admin'}));
  await assertFails(setDoc(doc(db('unknown'), 'users/unknown'), profiles.admin));
});
test('filtered company reads work; unfiltered and foreign-company reads fail', async () => {
  await create();
  for (const uid of ['op', 'watch', 'viewer', 'admin']) {
    await assertSucceeds(getDocs(query(collection(db(uid), 'machines'), where('companyId', '==', 'factory'))));
    await assertSucceeds(getDocs(query(collection(db(uid), 'incidents'), where('createdByCompanyId', '==', 'factory'))));
  }
  await assertFails(getDocs(collection(db('op'), 'machines')));
  await assertFails(getDoc(doc(db('pilot'), 'machines/m')));
  await assertFails(getDoc(doc(db('pilot'), 'incidents/call')));
  await assertFails(getDocs(query(collection(db('pilot'), 'incidents'), where('createdByCompanyId', '==', 'factory'))));
  await assertFails(getDoc(doc(db('op'), 'machines/p')));
});
test('watcher creates a call; operator claims, works, waits, resumes and resolves', async () => {
  await assertSucceeds(create());
  await assertSucceeds(transition('op', 'acknowledged'));
  await assertSucceeds(transition('op', 'in_progress'));
  await assertSucceeds(transition('op', 'waiting', {team: 'maintenance'}));
  await assertSucceeds(transition('op', 'in_progress'));
  await assertSucceeds(transition('op', 'resolved'));
  assert.equal((await getDoc(doc(db('op'), 'incidents/call'))).data().status, 'resolved');
});
test('viewer cannot report, watcher cannot claim and operator cannot skip transitions', async () => {
  await assertFails(create('viewer'));
  await create();
  await assertFails(transition('watch', 'acknowledged'));
  await assertFails(transition('op', 'resolved'));
  await assertSucceeds(transition('op', 'acknowledged'));
  await assertFails(transition('op2', 'in_progress'));
  await assertSucceeds(transition('admin', 'in_progress'));
});
test('company, creator, machine identity, historical timestamps and deletes are protected', async () => {
  await create();
  const ref = doc(db('op'), 'incidents/call');
  for (const patch of [{createdByCompanyId: 'pilot'}, {machineId: 'p'}, {createdByUid: 'op'},
    {openedAt: Timestamp.now()}, {ackAt: Timestamp.now()}, {resolvedAt: Timestamp.now()},
    {description: 'Replace history'}]) await assertFails(updateDoc(ref, {...patch, updatedAt: stamp()}));
  await assertFails(deleteDoc(ref));
  await assertFails(updateDoc(doc(db('op'), 'machines/m'), {companyId: 'pilot'}));
  await assertFails(updateDoc(doc(db('op'), 'machines/m'), {activeIncidentId: 'fake', updatedAt: stamp()}));
});
test('creation requires matching machine transaction and cannot replace an active call', async () => {
  await create();
  await assertFails(create('watch', 'duplicate'));
  await assertFails(create('pilot', 'foreign', 'm'));
  const existing = (await getDoc(doc(db('op'), 'incidents/call'))).data();
  await assertFails(setDoc(doc(db('op'), 'incidents/fake'), {...existing,
    createdByUid: 'op', reportedByRole: 'operator', reportedByName: 'Operator',
    createdAt: stamp(), updatedAt: stamp()}));
});
test('note batches work and audit author cannot be forged or edited', async () => {
  await create();
  const store = db('watch');
  const batch = writeBatch(store);
  batch.update(doc(store, 'incidents/call'), {updatedAt: stamp()});
  batch.set(doc(store, 'incidents/call/events/note'), event('watch', 'note_added', {message: 'Seen'}));
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(doc(store, 'incidents/call/events/note'), {message: 'Rewritten'}));
  await assertFails(setDoc(doc(store, 'incidents/call/events/forged'), event('op', 'note_added')));
  await assertFails(getDoc(doc(db('pilot'), 'incidents/call/events/note')));
});
test('stop interval and resume are atomic; isolated or foreign intervals are rejected', async () => {
  await assertSucceeds(create('watch', 'call', 'm', true));
  await transition('op', 'acknowledged');
  const store = db('op'); const before = (await getDoc(doc(store, 'incidents/call'))).data();
  const end = Timestamp.now(); const batch = writeBatch(store);
  batch.update(doc(store, 'incidents/call'), {canRun: true, category: 'yellow', updatedAt: stamp(),
    activeDowntimeId: null, downtimeEndedAt: end, downtimeSeconds: 1});
  batch.update(doc(store, 'machines/m'), {reportedState: 'running', activeCategory: 'yellow', updatedAt: stamp()});
  batch.update(doc(store, 'downtime_intervals/interval'), {endAt: end});
  batch.set(doc(store, 'incidents/call/events/resume'), event('op', 'production_resumed'));
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(doc(store, 'downtime_intervals/interval'), {startAt: Timestamp.now()}));
  await assertFails(setDoc(doc(store, 'downtime_intervals/fake'), {companyId: 'factory',
    incidentId: 'call', machineId: 'm', startAt: before.downtimeStartedAt, endAt: null}));
  await assertFails(getDoc(doc(db('pilot'), 'downtime_intervals/interval')));
});
test('pilot feedback is immutable, attributed and restricted to the pilot company', async () => {
  const value = {companyId: 'pilot', environment: 'training', createdByUid: 'pilot',
    createdByRole: 'operator', createdByName: 'Pilot', createdAt: stamp(), notes: 'Easy', ease: 4};
  const ref = doc(db('pilot'), 'companies/pilot/test_feedback/form');
  await assertSucceeds(getDoc(ref)); // Transaction checks the absent form ID first.
  await assertSucceeds(setDoc(ref, value));
  await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref, {ease: 5}));
  await assertFails(deleteDoc(ref));
  await assertFails(getDoc(doc(db('op'), 'companies/pilot/test_feedback/form')));
  await assertFails(setDoc(doc(db('pilot'), 'companies/factory/test_feedback/form'), value));
});
async function handover(count = 1) {
  const ids = Array.from({length: count}, (_, i) => `call${i}`);
  await env.withSecurityRulesDisabled(async context => {
    const batch = writeBatch(context.firestore());
    for (const id of ids) batch.set(doc(context.firestore(), 'incidents', id), {
      createdByCompanyId: 'factory', status: 'in_progress', assignedToUid: 'op', assignedToName: 'Operator',
      updatedAt: Timestamp.now(), machineId: id, targetTeam: 'operator', canRun: true,
    });
    await batch.commit();
  });
  const value = {schemaVersion: 1, companyId: 'factory', environment: 'production',
    createdByUid: 'op', createdByName: 'Operator', createdByRole: 'operator', createdAt: stamp(),
    team: 'operator', shift: 'Night', notes: 'Follow up', calls: ids.map(id => ({incidentId: id})), incidentIds: ids,
    status: 'pending', acceptedByUid: null, acceptedAt: null};
  await setDoc(doc(db('op'), 'companies/factory/handovers/h'), value);
  return ids;
}
async function accept(uid, ids, extra = {}) {
  const store = db(uid); const batch = writeBatch(store);
  batch.update(doc(store, 'companies/factory/handovers/h'), {status: 'accepted', acceptedByUid: uid,
    acceptedByName: profiles[uid].displayName, acceptedAt: stamp(), transferredCalls: ids.length, ...extra});
  for (const id of ids) {
    batch.update(doc(store, 'incidents', id), {assignedToUid: uid, assignedToName: profiles[uid].displayName,
      updatedAt: stamp(), lastHandoverId: 'h'});
    batch.set(doc(store, `incidents/${id}/events/handover`), event(uid, 'handover_received', {handoverId: 'h'}));
  }
  return batch.commit();
}
test('six-call handover receipt fits access limits and transfers to the recipient', async () => {
  const ids = await handover(6);
  await assertSucceeds(accept('op2', ids));
  for (const id of ids) assert.equal((await getDoc(doc(db('op2'), 'incidents', id))).data().assignedToUid, 'op2');
});
test('handover cannot be received by its author, wrong team, or used to steal another call', async () => {
  const ids = await handover();
  await assertFails(accept('op', ids));
  await assertFails(accept('watch', ids));
  await assertFails(accept('op2', ids, {notes: 'Rewritten'}));
  await assertFails(updateDoc(doc(db('op2'), 'incidents', ids[0]), {
    assignedToUid: 'op2', assignedToName: 'Operator Two', updatedAt: stamp(), lastHandoverId: 'h'}));
  await assertSucceeds(accept('op2', ids));
  await assertFails(accept('admin', ids));
});
test('handover rejects more than six calls', async () => {
  await assertFails(handover(7));
});
test('a note cannot fabricate a status event or move an active machine pointer', async () => {
  await create();
  const store = db('op');
  const forged = writeBatch(store);
  forged.update(doc(store, 'incidents/call'), {updatedAt: stamp()});
  forged.set(doc(store, 'incidents/call/events/forged'), event('op', 'status_changed', {fromStatus: 'open', toStatus: 'resolved'}));
  await assertFails(forged.commit());
  await env.withSecurityRulesDisabled(async context => {
    const old = (await getDoc(doc(context.firestore(), 'incidents/call'))).data();
    await setDoc(doc(context.firestore(), 'incidents/old'), {...old, createdAt: Timestamp.fromMillis(1000)});
  });
  const pointer = writeBatch(store);
  pointer.update(doc(store, 'incidents/old'), {updatedAt: stamp()});
  pointer.update(doc(store, 'machines/m'), {activeIncidentId: 'old', updatedAt: stamp()});
  await assertFails(pointer.commit());
});
test('photo metadata uses the current author and supports retry without changing attribution', async () => {
  await create();
  const store = db('watch'); const batch = writeBatch(store);
  const metadata = {url: 'https://example.invalid/test.jpg', path: 'incidents/call/photo.jpg',
    createdAt: stamp(), byUid: 'watch', byName: 'Watch', byRole: 'watcher'};
  batch.set(doc(store, 'incidents/call/photos/photo'), metadata);
  batch.set(doc(store, 'incidents/call/events/photo_photo'), event('watch', 'photo_added'));
  batch.update(doc(store, 'incidents/call'), {updatedAt: stamp()});
  await assertSucceeds(batch.commit());
  await assertSucceeds(setDoc(doc(store, 'incidents/call/photos/photo'), metadata));
  await assertFails(updateDoc(doc(store, 'incidents/call/photos/photo'), {byUid: 'op'}));
  await assertFails(getDoc(doc(db('pilot'), 'incidents/call/photos/photo')));
});
test('legacy call without team, assignee or machine state can still be claimed and resolved', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const store = context.firestore();
    await setDoc(doc(store, 'incidents/call'), {createdByCompanyId: 'factory', machineId: 'm',
      status: 'open', category: 'red', canRun: true, createdAt: Timestamp.fromMillis(1000),
      reportedAt: Timestamp.fromMillis(1000), description: 'Legacy'});
    await updateDoc(doc(store, 'machines/m'), {activeIncidentId: 'call', activeStatus: 'open', activeCategory: 'red'});
  });
  await assertSucceeds(transition('op', 'acknowledged'));
  await assertSucceeds(transition('op', 'in_progress'));
  await assertSucceeds(transition('op', 'resolved'));
});
// Calendar access and report integrity regression tests.
const DAY = 86400000;
const dateInPoland = (value = new Date()) => {
  const parts = new Intl.DateTimeFormat('en-CA', {timeZone: 'Europe/Warsaw', year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(value);
  const get = type => Number(parts.find(p => p.type === type).value);
  return new Date(Date.UTC(get('year'),get('month')-1,get('day')));
};
function midnightPoland(day) {
  let candidate = day.getTime();
  for(let i=0;i<3;i++) {
    const text = new Intl.DateTimeFormat('en-US',{timeZone:'Europe/Warsaw',timeZoneName:'shortOffset'}).formatToParts(new Date(candidate)).find(p=>p.type==='timeZoneName').value;
    candidate = day.getTime() - Number(text.replace('GMT',''))*3600000;
  }
  return Timestamp.fromMillis(candidate);
}
function dates() {
  const day = dateInPoland();
  const monday = new Date(+day - ((day.getUTCDay()+6)%7)*DAY);
  return {day, monday};
}
function weekPath(monday) {return `companies/factory/roster_weeks/${monday.toISOString().slice(0,10)}`;}
function weekData(monday) {return {startAt:midnightPoland(monday),endAt:midnightPoland(new Date(+monday+7*DAY))};}
function shiftData(uid='op', day=dates().day) {
  const start=midnightPoland(day), p=profiles[uid];
  return {uid,name:p.displayName,team:p.role,day:Timestamp.fromDate(day),label:'Morning',startAt:start,endAt:Timestamp.fromMillis(start.toMillis()+8*3600000),cancelled:false,createdAt:stamp(),updatedAt:stamp(),updatedByUid:'admin'};
}
async function seedRoster(monday=dates().monday, uid='op') {
  const path=weekPath(monday), data=shiftData(uid, monday);
  await env.withSecurityRulesDisabled(async context=> {
    await setDoc(doc(context.firestore(),path),weekData(monday));
    await setDoc(doc(context.firestore(),`${path}/shifts/s`),data);
  });
  return path;
}
test('admin lists same-company staff, changes active status; workers cannot list or self-promote', async()=> {
  await assertSucceeds(getDocs(query(collection(db('admin'),'users'),where('companyId','==','factory'))));
  await assertFails(getDocs(collection(db('admin'),'users')));
  await assertFails(getDocs(query(collection(db('op'),'users'),where('companyId','==','factory'))));
  await assertFails(updateDoc(doc(db('admin'),'users/admin'),{isActive:false}));
  await assertFails(updateDoc(doc(db('admin'),'users/op'),{role:'admin'}));
  await assertSucceeds(updateDoc(doc(db('admin'),'users/op'),{isActive:false}));
  await assertFails(getDoc(doc(db('op'),'machines/m')));
  await assertSucceeds(updateDoc(doc(db('admin'),'users/op'),{isActive:true}));
  await assertSucceeds(getDoc(doc(db('op'),'machines/m')));
});
test('admin creates and edits a shift; immutable identity and worker write restrictions hold', async()=> {
  const {monday}=dates(), base=weekPath(monday), store=db('admin'), batch=writeBatch(store);
  await assertSucceeds(getDoc(doc(store,`${base}/shifts/empty`)));
  batch.set(doc(store,base),weekData(monday)); batch.set(doc(store,`${base}/shifts/s`),shiftData());
  await assertSucceeds(batch.commit());
  await assertSucceeds(updateDoc(doc(store,`${base}/shifts/s`),{label:'Packing',updatedAt:stamp()}));
  await assertFails(updateDoc(doc(db('op'),`${base}/shifts/s`),{label:'Forged',updatedAt:stamp(),updatedByUid:'op'}));
  await assertFails(updateDoc(doc(store,`${base}/shifts/s`),{uid:'op2',name:profiles.op2.displayName,updatedAt:stamp()}));
  await assertFails(deleteDoc(doc(store,`${base}/shifts/s`)));
});
test('worker sees only own team in the current week; admin reads every week', async()=> {
  const {monday}=dates(), current=await seedRoster(), old=await seedRoster(new Date(+monday-7*DAY)), future=await seedRoster(new Date(+monday+7*DAY));
  await assertSucceeds(getDocs(query(collection(db('op'),`${current}/shifts`),where('team','==','operator'))));
  await assertFails(getDocs(collection(db('op'),`${current}/shifts`)));
  await assertFails(getDocs(query(collection(db('watch'),`${current}/shifts`),where('team','==','operator'))));
  for(const path of [old,future]) {
    await assertFails(getDocs(query(collection(db('op'),`${path}/shifts`),where('team','==','operator'))));
    await assertFails(getDoc(doc(db('op'),`${path}/shifts/s`)));
    await assertSucceeds(getDocs(collection(db('admin'),`${path}/shifts`)));
  }
  await assertFails(getDoc(doc(db('pilot'),`${current}/shifts/s`)));
});
test('week windows correctly cover Poland spring/fall DST and cannot be widened', async()=> {
  for(const iso of ['2026-03-23','2026-10-19','2026-12-28']) {
    const monday=new Date(iso+'T00:00:00Z'), base=weekPath(monday);
    await assertSucceeds(setDoc(doc(db('admin'),base),weekData(monday)));
    await assertFails(updateDoc(doc(db('admin'),base),{endAt:Timestamp.fromMillis(+monday+30*DAY)}));
  }
  await assertFails(setDoc(doc(db('admin'),'companies/factory/roster_weeks/bad'),{startAt:Timestamp.now(),endAt:Timestamp.fromMillis(Date.now()+7*DAY)}));
});
test('shift report is own-only, immutable, and locks schedule edits and cancellation', async()=> {
  const path=await seedRoster(), ref=`${path}/shifts/s`;
  await env.withSecurityRulesDisabled(async c=>updateDoc(doc(c.firestore(),ref),{startAt:Timestamp.fromMillis(Date.now()-3600000),endAt:Timestamp.fromMillis(Date.now()+3600000)}));
  const report=uid=>({summary:'Line clear',problems:'Film jam',followUp:'Check roll',createdByUid:uid,createdByName:profiles[uid].displayName,createdAt:stamp()});
  await assertFails(setDoc(doc(db('op2'),`${ref}/reports/end`),report('op2')));
  await assertFails(setDoc(doc(db('admin'),`${ref}/reports/end`),report('admin')));
  await assertSucceeds(setDoc(doc(db('op'),`${ref}/reports/end`),report('op')));
  await assertSucceeds(getDocs(collection(db('op2'),`${ref}/reports`)));
  await assertSucceeds(getDoc(doc(db('admin'),`${ref}/reports/end`)));
  await assertFails(updateDoc(doc(db('op'),`${ref}/reports/end`),{summary:'Changed'}));
  await assertFails(updateDoc(doc(db('admin'),ref),{cancelled:true,updatedAt:stamp(),updatedByUid:'admin'}));
});
test('future or expired shifts cannot receive reports; own recent old-week detail is permitted', async()=> {
  const path=await seedRoster(), ref=`${path}/shifts/s`;
  const report={summary:'Done',problems:'',followUp:'',createdByUid:'op',createdByName:profiles.op.displayName,createdAt:stamp()};
  for(const shiftTime of [Date.now()+DAY,Date.now()-3*DAY]) {
    await env.withSecurityRulesDisabled(async c=>updateDoc(doc(c.firestore(),ref),{startAt:Timestamp.fromMillis(shiftTime),endAt:Timestamp.fromMillis(shiftTime+3600000)}));
    await assertFails(setDoc(doc(db('op'),`${ref}/reports/end`),report));
  }
  const old=await seedRoster(new Date(+dates().monday-7*DAY));
  await env.withSecurityRulesDisabled(async c=>updateDoc(doc(c.firestore(),`${old}/shifts/s`),{startAt:Timestamp.fromMillis(Date.now()-3600000),endAt:Timestamp.fromMillis(Date.now()+3600000)}));
  await assertSucceeds(getDoc(doc(db('op'),`${old}/shifts/s`)));
  await assertFails(getDoc(doc(db('op2'),`${old}/shifts/s`)));
  await assertFails(getDocs(query(collection(db('op'),`${old}/shifts`),where('team','==','operator'))));
});
test('team notes appear only for today/tomorrow and own team; read receipts are per-user', async()=> {
  const day=dates().day, p='companies/factory/team_notes/n', note={team:'operator',targetDay:Timestamp.fromDate(day),body:'Check conveyor',important:true,createdByUid:'op',createdByName:profiles.op.displayName,createdAt:stamp()};
  await assertSucceeds(getDoc(doc(db('op'),p)));
  await assertSucceeds(setDoc(doc(db('op'),p),note));
  await assertSucceeds(getDocs(query(collection(db('op2'),'companies/factory/team_notes'),where('targetDay','==',Timestamp.fromDate(day)),where('team','==','operator'))));
  await assertFails(getDoc(doc(db('watch'),p)));
  await assertFails(getDoc(doc(db('pilot'),p)));
  await assertFails(setDoc(doc(db('op'),p+'2'),{...note,team:'watcher'}));
  await assertFails(setDoc(doc(db('op'),p+'3'),{...note,targetDay:Timestamp.fromMillis(+day+2*DAY)}));
  await assertFails(updateDoc(doc(db('op'),p),{body:'Changed'}));
  await assertSucceeds(getDoc(doc(db('op2'),`${p}/reads/op2`)));
  await assertSucceeds(setDoc(doc(db('op2'),`${p}/reads/op2`),{name:profiles.op2.displayName,at:stamp()}));
  await assertFails(setDoc(doc(db('op2'),`${p}/reads/op`),{name:profiles.op.displayName,at:stamp()}));
  await assertSucceeds(getDocs(collection(db('op'),`${p}/reads`)));
  await assertSucceeds(getDocs(collection(db('admin'),`${p}/reads`)));
  await assertFails(getDocs(collection(db('op2'),`${p}/reads`)));
  await env.withSecurityRulesDisabled(async c=>updateDoc(doc(c.firestore(),p),{targetDay:Timestamp.fromMillis(+day-DAY)}));
  await assertFails(getDoc(doc(db('op2'),p)));
  await assertSucceeds(getDoc(doc(db('admin'),p)));
});
test('admin schedule transaction reads absent neighbors/reports before first assignment', async()=> {
  const {day,monday}=dates(), base=weekPath(monday), store=db('admin');
  await assertSucceeds(runTransaction(store,async tx=> {
    await tx.get(doc(store,'users/op'));
    await tx.get(doc(store,`${base}/shifts/new`));
    await tx.get(doc(store,`${base}/shifts/new/reports/end`));
    await tx.get(doc(store,`${base}/shifts/yesterday`));
    await tx.get(doc(store,`${base}/shifts/tomorrow`));
    tx.set(doc(store,base),weekData(monday));
    tx.set(doc(store,`${base}/shifts/new`),shiftData('op',day));
  }));
});
test('an unplanned week header reads as absent, without exposing unscoped shifts', async()=> {
  const base=weekPath(dates().monday);
  const result=await assertSucceeds(getDoc(doc(db('op'),base)));
  assert.equal(result.exists(),false);
  await assertFails(getDocs(collection(db('op'),`${base}/shifts`)));
});
