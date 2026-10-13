const {before, after, beforeEach, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where,
  writeBatch, serverTimestamp: stamp, Timestamp, deleteField} = require('firebase/firestore');
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
