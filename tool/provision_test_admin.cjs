// Run after `firebase login --reauth`. Passwords/tokens are never written to disk.
// Inspect: node tool/provision_test_admin.cjs inspect
// Create:  $env:TEST_ADMIN_PASSWORD = '<password>'
//          node tool/provision_test_admin.cjs create <companyId>
// Creates only admin@company.local; refuses to replace any existing account.
const fs = require('node:fs');
const path = require('node:path');
const {createRequire} = require('node:module');
const functionsRequire = createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp} = functionsRequire('firebase-admin/app');
const {getAuth} = functionsRequire('firebase-admin/auth');

const project = require('./firebase_project.cjs')();
const email = 'admin@company.local';
const firestore = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));

async function main() {
  const [mode, companyId] = process.argv.slice(2);
  if (!['inspect', 'create'].includes(mode)) throw new Error('Use inspect or create <companyId>.');
  const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '..'));
  if (!account?.tokens.refresh_token) throw new Error('Run firebase login --reauth first.');
  const token = await cliAuth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
    'https://www.googleapis.com/auth/userinfo.email',
  ]);
  async function request(url, {method = 'GET', body, bearer = token.access_token} = {}) {
    const response = await fetch(url, {
      method, headers: {'Content-Type': 'application/json', Authorization: `Bearer ${bearer}`},
      body: body ? JSON.stringify(body) : undefined,
    });
    const result = await response.json();
    if (!response.ok) {
      const error = new Error(`Firebase request failed: HTTP ${response.status} (${result.error?.status || 'unknown'}).`);
      error.status = response.status;
      throw error;
    }
    return result;
  }
  // Verify the exact configured project before any writes.
  await request(`https://firebase.googleapis.com/v1beta1/projects/${project}`);
  const app = initializeApp({projectId: project, credential: {getAccessToken: async () => ({
    access_token: token.access_token, expires_in: 3600,
  })}});
  const auth = getAuth(app);
  let existing;
  try { existing = await auth.getUserByEmail(email); } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  if (mode === 'inspect') {
    const sources = {};
    for (const [collection, field] of [['users', 'companyId'], ['incidents', 'createdByCompanyId'], ['machines', 'companyId']]) {
      const rows = await request(`${firestore}:runQuery`, {method: 'POST', body: {
        structuredQuery: {from: [{collectionId: collection}], select: {fields: [{fieldPath: field}]}, limit: 100},
      }});
      const counts = {};
      for (const row of rows) {
        if (!row.document) continue;
        const value = row.document.fields?.[field]?.stringValue || '(missing)';
        counts[value] = (counts[value] || 0) + 1;
      }
      sources[collection] = counts;
    }
    console.log(JSON.stringify({project, accountExists: !!existing, companySamples: sources}, null, 2));
    return;
  }
  if (existing) throw new Error('admin@company.local already exists; no password or profile was changed.');
  if (!companyId?.trim() || companyId.includes('/')) throw new Error('An explicit companyId is required.');
  const password = process.env.TEST_ADMIN_PASSWORD;
  if (!password || password.length < 6) throw new Error('TEST_ADMIN_PASSWORD must contain at least 6 characters.');

  const user = await auth.createUser({email, password, displayName: 'Test Admin'});
  const profilePath = `${firestore}/users/${user.uid}`;
  try {
    // exists=false prevents overwriting even an unexpected orphan profile.
    await request(`${profilePath}?currentDocument.exists=false`, {method: 'PATCH', body: {fields: {
      companyId: {stringValue: companyId.trim()},
      displayName: {stringValue: 'Test Admin'},
      role: {stringValue: 'admin'},
      testAccount: {booleanValue: true},
      createdAt: {timestampValue: new Date().toISOString()},
    }}});
  } catch (error) {
    await auth.deleteUser(user.uid);
    throw new Error(`Profile creation failed; the newly created Auth account was removed. ${error.message}`);
  }
  console.log(JSON.stringify({created: true, email, uid: user.uid, companyId, role: 'admin'}));

  // Verify the real email/password path and profile read as the new user.
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../android/app/google-services.json'), 'utf8'));
  const apiKey = config.client[0].api_key[0].current_key;
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email, password, returnSecureToken: true}),
  });
  const login = await response.json();
  if (!response.ok || !login.idToken) throw new Error(`Account created, but login verification failed (HTTP ${response.status}).`);
  await request(profilePath, {bearer: login.idToken});
  console.log(JSON.stringify({loginVerified: true, profileReadableAsUser: true}));
}

main().catch(error => {
  // Never print SDK request objects, credentials or password-bearing payloads.
  console.error(error.code || error.message);
  process.exitCode = 1;
});
