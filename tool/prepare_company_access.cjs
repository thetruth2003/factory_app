// Applies a locally supplied, owner-confirmed mapping for the original nine
// machines. No calls or passwords are changed. Always run preview first.
const fs = require('node:fs');
const path = require('node:path');
const cliAuth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = require('./firebase_project.cjs')();
const root = `projects/${project}/databases/(default)/documents`;
const endpoint = `https://firestore.googleapis.com/v1/${root}`;
const settings = JSON.parse(fs.readFileSync(path.join(__dirname, 'company_access.local.json'), 'utf8'));
const companyId = settings.companyId;
const mapping = settings.users;
if (typeof companyId !== 'string' || !companyId || !Array.isArray(mapping) ||
    !mapping.every(row => Array.isArray(row) && row.length === 3 && row.every(v => typeof v === 'string' && v.length > 0))) {
  throw new Error('Invalid company_access.local.json; copy and edit the example first.');
}
async function main() {
  const apply = process.argv.includes('--apply');
  const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '..'));
  if (!account?.tokens.refresh_token) throw new Error('Firebase login required.');
  const token = await cliAuth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
  async function request(url, body) {
    const response = await fetch(url, {method: body ? 'POST' : 'GET',
      headers: {'Content-Type': 'application/json', Authorization: `Bearer ${token.access_token}`},
      body: body ? JSON.stringify(body) : undefined});
    const data = await response.json();
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${data.error?.status}`);
    return data;
  }
  const original = [], writes = [];
  async function prepare(docPath, values) {
    const doc = await request(`${endpoint}/${docPath}`);
    const fields = {};
    if (doc.fields.companyId && doc.fields.companyId.stringValue !== companyId) {
      throw new Error(`Unexpected company on ${docPath}; nothing changed.`);
    }
    for (const [key, value] of Object.entries(values)) {
      if (doc.fields[key] == null) fields[key] = {stringValue: value};
    }
    if (Object.keys(fields).length) {
      original.push(doc);
      writes.push({update: {name: doc.name, fields}, updateMask: {fieldPaths: Object.keys(fields)},
        currentDocument: {updateTime: doc.updateTime}});
    }
    return doc;
  }
  for (const [uid, code, role] of mapping) {
    const p = await request(`${endpoint}/users/${uid}`);
    if (p.fields.role?.stringValue !== role) throw new Error(`Unexpected role for ${code}.`);
    await prepare(`users/${uid}`, {companyId: companyId, environment: 'production',
      displayName: p.fields.name?.stringValue || code});
  }
  for (const section of [1, 2, 3]) for (const letter of ['A', 'B', 'C']) {
    const machine = await prepare(`machines/${section}${letter}`, {companyId: companyId, environment: 'production'});
    const callId = machine.fields.activeIncidentId?.stringValue;
    if (callId) {
      const call = await request(`${endpoint}/incidents/${callId}`);
      if (call.fields.createdByCompanyId?.stringValue !== companyId) {
        throw new Error('Active call belongs to another company; nothing changed.');
      }
    }
  }
  console.log(JSON.stringify({mode: apply ? 'apply' : 'preview', companyId: companyId,
    documents: writes.map(w => ({path: w.update.name.replace(`${root}/`, ''), fields: w.updateMask.fieldPaths}))}));
  if (!apply || !writes.length) return;
  const backupDir = path.resolve(__dirname, '../../factory_check_app_backups');
  fs.mkdirSync(backupDir, {recursive: true});
  const backup = path.join(backupDir, `company-access-${Date.now()}.json`);
  fs.writeFileSync(backup, JSON.stringify({project, original, writes}, null, 2), {flag: 'wx'});
  const result = await request(`${endpoint}:commit`, {writes});
  fs.writeFileSync(`${backup}.result.json`, JSON.stringify(result, null, 2));
  console.log(JSON.stringify({updated: result.writeResults.length, backup}));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
