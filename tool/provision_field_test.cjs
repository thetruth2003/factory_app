// Creates the isolated field-test records without touching existing factory data.
// $env:FIELD_TEST_PASSWORD='<test password>'; node tool/provision_field_test.cjs
// Re-runs preserve existing test passwords, calls and machine states.
const fs = require('node:fs');
const path = require('node:path');
const {createRequire} = require('node:module');
const functionsRequire = createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp} = functionsRequire('firebase-admin/app');
const {getAuth} = functionsRequire('firebase-admin/auth');
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = require('./firebase_project.cjs')();
const companyId = 'factory-check-pilot';
const root = `projects/${project}/databases/(default)/documents`;
const endpoint = `https://firestore.googleapis.com/v1/${root}`;

async function main() {
  const password = process.env.FIELD_TEST_PASSWORD;
  if (!password || password.length < 6) throw new Error('Set FIELD_TEST_PASSWORD with at least 6 characters.');
  const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '..'));
  if (!account?.tokens.refresh_token) throw new Error('Run firebase login --reauth.');
  const token = await cliAuth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase',
  ]);
  async function request(url, {method = 'GET', body, bearer = token.access_token, optional = false} = {}) {
    const response = await fetch(url, {method,
      headers: {'Content-Type': 'application/json', Authorization: `Bearer ${bearer}`},
      body: body ? JSON.stringify(body) : undefined});
    const data = await response.json();
    if (optional && response.status === 404) return null;
    if (!response.ok) throw new Error(`Firebase HTTP ${response.status}: ${data.error?.status || 'request failed'}`);
    return data;
  }
  await request(`https://firebase.googleapis.com/v1beta1/projects/${project}`);
  const auth = getAuth(initializeApp({projectId: project, credential: {
    getAccessToken: async () => ({access_token: token.access_token, expires_in: 3600}),
  }}));
  const users = [
    {email: 'testizleme@company.local', role: 'watcher', name: 'Test İzleme'},
    {email: 'testoperator@company.local', role: 'operator', name: 'Test Operatör'},
    {email: 'testadmin@company.local', role: 'admin', name: 'Test Yöneticisi'},
    {email: 'testoperator2@company.local', role: 'operator', name: 'Test Operatör 2'},
  ];
  const writes = [];
  const created = [];
  let commitAttempted = false;
  function fields(data) {
    return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, {stringValue: value}]));
  }
  function createDoc(docPath, data) {
    writes.push({update: {name: `${root}/${docPath}`, fields: fields(data)}, currentDocument: {exists: false}});
  }
  try {
    for (const user of users) {
      let found;
      try { found = await auth.getUserByEmail(user.email); } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
      if (!found) {
        found = await auth.createUser({email: user.email, password, displayName: user.name});
        created.push(found.uid);
      }
      user.uid = found.uid;
      if (found.disabled) throw new Error('An existing test account is disabled; nothing reactivated.');
      const profile = await request(`${endpoint}/users/${user.uid}`, {optional: true});
      if (profile) {
        if (profile.fields?.companyId?.stringValue !== companyId ||
            profile.fields?.environment?.stringValue !== 'training' ||
            profile.fields?.role?.stringValue !== user.role ||
            profile.fields?.isActive?.booleanValue === false) {
          throw new Error('Existing test login has a different profile; no existing profile changed.');
        }
      } else {
        if (!created.includes(user.uid)) throw new Error('Existing account lacks a test profile; no existing account changed.');
        createDoc(`users/${user.uid}`, {companyId, environment: 'training', displayName: user.name, role: user.role});
      }
    }
    for (const [i, name] of ['Paketleme', 'Pişirme', 'Soğutma'].entries()) {
      const docPath = `machines/fieldtest_${i + 1}`;
      const existing = await request(`${endpoint}/${docPath}`, {optional: true});
      if (existing) {
        if (existing.fields?.companyId?.stringValue !== companyId ||
            existing.fields?.environment?.stringValue !== 'training') {
          throw new Error('Machine ID belongs to another environment; nothing overwritten.');
        }
      } else {
        createDoc(docPath, {companyId, environment: 'training', name: `TEST-${i + 1} · ${name}`,
          section: 'TEST', reportedState: 'unknown', activeStatus: 'none', activeCategory: 'green'});
      }
    }
    if (writes.length) {
      commitAttempted = true;
      await request(`${endpoint}:commit`, {method: 'POST', body: {writes}});
    }
  } catch (error) {
    // A lost commit response may mean Firestore saved, or is still saving,
    // profiles. Preserve the new accounts if that outcome is unknown.
    if (commitAttempted && created.length) {
      console.error('Profile commit was not confirmed; newly created accounts preserved for inspection.');
    }
    for (const uid of commitAttempted ? [] : created) {
      try {
        const profile = await request(`${endpoint}/users/${uid}`, {optional: true});
        if (!profile) await auth.deleteUser(uid);
      } catch (_) {
        console.error('Could not confirm cleanup; newly created account preserved for inspection.');
      }
    }
    throw error;
  }
  console.log(JSON.stringify({provisioned: true, companyId, createdDocuments: writes.length}));
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../android/app/google-services.json'), 'utf8'));
  const key = config.client[0].api_key[0].current_key;
  for (const user of users) {
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(key)}`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email: user.email, password, returnSecureToken: true}),
    });
    const login = await response.json();
    if (!response.ok || !login.idToken) throw new Error(`Provisioned but login verification failed for ${user.email}.`);
    await request(`${endpoint}/users/${user.uid}`, {bearer: login.idToken});
    const rows = await request(`${endpoint}:runQuery`, {method: 'POST', bearer: login.idToken, body: {structuredQuery: {
      from: [{collectionId: 'machines'}], where: {fieldFilter: {
        field: {fieldPath: 'companyId'}, op: 'EQUAL', value: {stringValue: companyId},
      }},
    }}});
    console.log(JSON.stringify({account: user.email, role: user.role, loginVerified: true,
      testMachinesVisible: rows.filter(row => row.document).length}));
  }
}
main().catch(error => {console.error(error.code || error.message); process.exitCode = 1;});
