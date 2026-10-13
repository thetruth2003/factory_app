// Exercises only temporary feedback documents in the dedicated pilot company.
const fs = require('node:fs');
const path = require('node:path');
const {randomUUID} = require('node:crypto');
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const companyId = 'factory-check-pilot';
const project = require('./firebase_project.cjs')();
const root = `projects/${project}/databases/(default)/documents`;
const endpoint = `https://firestore.googleapis.com/v1/${root}`;

async function main() {
  const password = process.env.FIELD_TEST_PASSWORD;
  if (!password) throw new Error('Set FIELD_TEST_PASSWORD.');
  const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '..'));
  if (!account?.tokens.refresh_token) throw new Error('Firebase login required for temporary-record cleanup.');
  const cleanupToken = await cliAuth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
  const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../android/app/google-services.json'), 'utf8'));
  const key = config.client[0].api_key[0].current_key;
  for (const email of ['testizleme@company.local', 'testoperator@company.local']) {
    const loginResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(key)}`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    });
    const login = await loginResponse.json();
    if (!loginResponse.ok || !login.idToken) throw new Error(`Login failed for ${email}.`);
    async function request(url, method = 'GET', body, missing = false) {
      const response = await fetch(url, {method,
        headers: {'Content-Type': 'application/json', Authorization: `Bearer ${login.idToken}`},
        body: body ? JSON.stringify(body) : undefined});
      const data = await response.json();
      if (missing && response.status === 404) return null;
      if (!response.ok) throw new Error(`Firebase HTTP ${response.status}: ${data.error?.status || 'failed'} (${method} ${url.split('?')[0].replace(endpoint, '')})`);
      return data;
    }
    const profile = (await request(`${endpoint}/users/${login.localId}`)).fields;
    if (profile.companyId?.stringValue !== companyId || profile.environment?.stringValue !== 'training') {
      throw new Error('Account is not a pilot account.');
    }
    const docPath = `companies/${companyId}/test_feedback/smoke_${randomUUID()}`;
    const docName = `${root}/${docPath}`;
    const docUrl = `${endpoint}/${docPath}`;
    if (await request(docUrl, 'GET', undefined, true)) {
      throw new Error('Temporary document unexpectedly exists.');
    }
    const strings = {environment: 'training', companyId, createdByUid: login.localId,
      createdByName: profile.displayName.stringValue, createdByRole: profile.role.stringValue,
      notes: 'AUTOMATED CHECK — temporary feedback, removed after verification',
      locale: 'tr', appVersion: '1.2.2+5'};
    const fields = Object.fromEntries(Object.entries(strings).map(([k,v]) => [k, {stringValue: v}]));
    fields.ease = {integerValue: '4'};
    fields.schemaVersion = {integerValue: '1'};
    let updateTime;
    try {
      const committed = await request(`${endpoint}:commit`, 'POST', {writes: [{
        update: {name: docName, fields}, currentDocument: {exists: false},
        updateTransforms: [{fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME'}],
      }]});
      updateTime = committed.writeResults[0].updateTime;
      const saved = await request(docUrl);
      if (saved.fields.createdByUid.stringValue !== login.localId || !saved.fields.createdAt.timestampValue) {
        throw new Error('Stored feedback did not match.');
      }
    } finally {
      if (updateTime) {
        const cleanup = await fetch(`${endpoint}:commit`, {method: 'POST',
          headers: {'Content-Type': 'application/json', Authorization: `Bearer ${cleanupToken.access_token}`},
          body: JSON.stringify({writes: [{delete: docName, currentDocument: {updateTime}}]})});
        if (!cleanup.ok) throw new Error(`Temporary feedback cleanup failed: HTTP ${cleanup.status}`);
      }
    }
    console.log(JSON.stringify({account: email, feedbackWriteVerified: true,
      feedbackReadVerified: true, temporaryRecordRemoved: true}));
  }
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
