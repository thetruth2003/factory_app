// Preview by default. --apply creates only missing pilot shifts; never overwrites.
// Requires the accounts from provision_field_test.cjs and a Firebase CLI login.
const path = require('node:path');
const {createRequire} = require('node:module');
const companyId = 'factory-check-pilot';
const zone = new Intl.DateTimeFormat('en-GB', {timeZone: 'Europe/Warsaw',
  year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit',
  minute: '2-digit', hourCycle: 'h23'});

function localParts(instant) {
  return Object.fromEntries(zone.formatToParts(instant).map(p => [p.type, p.value]));
}
function todayInWarsaw(now = new Date()) {
  const p = localParts(now);
  return `${p.year}-${p.month}-${p.day}`;
}
function addDays(day, count) {
  const d = new Date(`${day}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + count);
  return d.toISOString().slice(0, 10);
}
function monday(day) {
  return addDays(day, -((new Date(`${day}T00:00:00Z`).getUTCDay() + 6) % 7));
}
function instant(day, hour) {
  // Demo hours are unambiguous even on Poland's clock-change days.
  const wall = Date.parse(`${day}T${String(hour).padStart(2, '0')}:00:00Z`);
  const matches = [1, 2].map(offset => new Date(wall - offset * 3600000)).filter(d => {
    const p = localParts(d);
    return `${p.year}-${p.month}-${p.day}` === day && Number(p.hour) === hour && p.minute === '00';
  });
  if (matches.length !== 1) throw new Error('Demo time is invalid or ambiguous.');
  return matches[0];
}
function weekPath(day) {
  return `companies/${companyId}/roster_weeks/${monday(day)}`;
}
function shiftPath(day, uid) {
  return `${weekPath(day)}/shifts/${day}_${uid}`;
}
function overlaps(start, end, other) {
  return !!other && other.cancelled !== true &&
    start < other.endAt.toDate() && end > other.startAt.toDate();
}

async function main() {
  if (process.argv.slice(2).some(arg => arg !== '--apply')) throw new Error('Usage: node tool/prepare_roster_demo.cjs [--apply]');
  if (process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('This tool is for the isolated pilot company; clear emulator variables first.');
  }
  const apply = process.argv.includes('--apply');
  const project = require('./firebase_project.cjs')();
  const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '..'));
  if (!account?.tokens.refresh_token) throw new Error('Run firebase login --reauth.');
  const token = await cliAuth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase',
  ]);
  const req = createRequire(path.join(__dirname, '../functions/package.json'));
  const {initializeApp} = req('firebase-admin/app');
  const {getAuth} = req('firebase-admin/auth');
  const {Firestore, Timestamp, FieldValue} = req('firebase-admin/firestore');
  const {OAuth2Client} = req('google-auth-library');
  const app = initializeApp({projectId: project, credential: {
    getAccessToken: async () => ({access_token: token.access_token, expires_in: 3600}),
  }});
  // Admin Auth accepts a custom credential, while the Firestore client needs
  // an OAuth client. Use the same short-lived CLI token for both services.
  const authClient = new OAuth2Client();
  authClient.setCredentials({access_token: token.access_token});
  const db = new Firestore({projectId: project, authClient});
  try {
    const definitions = [
      ['testadmin', 'admin', null], ['testoperator', 'operator', 0],
      ['testoperator2', 'operator', 8], ['testizleme', 'watcher', 0],
    ];
    const people = await Promise.all(definitions.map(async ([login, role, hour]) => {
      const user = await getAuth(app).getUserByEmail(`${login}@company.local`);
      if (user.disabled) throw new Error('A pilot account is disabled.');
      return {uid: user.uid, role, hour};
    }));
    const today = todayInWarsaw();
    const days = [-1, 0, 1].map(n => addDays(today, n));
    const candidates = days.flatMap(day => people.filter(p => p.hour !== null).map(person => ({
      ...person, day, path: shiftPath(day, person.uid),
      start: instant(day, person.hour), end: instant(day, person.hour + 8),
    })));
    const weeks = [...new Set(days.map(monday))];
    const paths = new Set(people.map(p => `users/${p.uid}`));
    for (const week of weeks) paths.add(weekPath(week));
    for (const c of candidates) {
      for (const offset of [-1, 0, 1]) paths.add(shiftPath(addDays(c.day, offset), c.uid));
      paths.add(`${c.path}/reports/end`);
    }
    const result = await db.runTransaction(async tx => {
      const snapshots = await tx.getAll(...[...paths].map(p => db.doc(p)));
      const records = new Map(snapshots.map(s => [s.ref.path, s.data()]));
      for (const person of people) {
        const p = records.get(`users/${person.uid}`);
        if (!p || p.companyId !== companyId || p.environment !== 'training' ||
            p.role !== person.role || p.isActive === false || !p.displayName) {
          throw new Error('Pilot identity mismatch; no shifts written.');
        }
      }
      const missingWeeks = [];
      for (const week of weeks) {
        const data = {startAt: Timestamp.fromDate(instant(week, 0)),
          endAt: Timestamp.fromDate(instant(addDays(week, 7), 0))};
        const existing = records.get(weekPath(week));
        if (existing && (!data.startAt.isEqual(existing.startAt) || !data.endAt.isEqual(existing.endAt))) {
          throw new Error('Existing pilot week has different boundaries; nothing overwritten.');
        }
        if (!existing) missingWeeks.push({path: weekPath(week), data});
      }
      const planned = [];
      let preserved = 0, conflicts = 0;
      for (const c of candidates) {
        if (records.get(c.path)) { preserved++; continue; }
        if (records.get(`${c.path}/reports/end`) || [-1, 1].some(offset =>
          overlaps(c.start, c.end, records.get(shiftPath(addDays(c.day, offset), c.uid))))) {
          conflicts++; continue;
        }
        planned.push(c);
      }
      if (apply) {
        for (const w of missingWeeks) tx.create(db.doc(w.path), w.data);
        for (const c of planned) tx.create(db.doc(c.path), {
          uid: c.uid, name: records.get(`users/${c.uid}`).displayName, team: c.role,
          day: Timestamp.fromDate(new Date(`${c.day}T00:00:00Z`)),
          label: `DENEME · ${String(c.hour).padStart(2, '0')}:00–${String(c.hour + 8).padStart(2, '0')}:00`,
          startAt: Timestamp.fromDate(c.start), endAt: Timestamp.fromDate(c.end), cancelled: false,
          createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
          updatedByUid: people[0].uid,
        });
      }
      return {mode: apply ? 'applied' : 'preview', project, companyId, days,
        newWeeks: missingWeeks.length, newShifts: planned.length, preserved, conflicts};
    });
    console.log(JSON.stringify(result));
  } finally {
    await db.terminate();
  }
}

module.exports = {todayInWarsaw, addDays, monday, instant, overlaps};
if (require.main === module) main().catch(error => {
  console.error(error.code || error.message); process.exitCode = 1;
});
