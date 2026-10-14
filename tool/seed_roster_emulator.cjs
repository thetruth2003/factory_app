// Local emulator fixtures only. Refuse real project/host settings.
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
if (authHost !== '127.0.0.1:9099' || firestoreHost !== '127.0.0.1:8180') {
  throw new Error('Run with security/firebase.json and local Auth/Firestore emulators.');
}
const project = 'demo-factory-check';
const base = `http://${firestoreHost}/v1/projects/${project}/databases/(default)/documents`;
async function request(url, method, body, owner = false) {
  const response = await fetch(url, {method, headers: {'Content-Type': 'application/json',
    ...(owner ? {Authorization: 'Bearer owner'} : {})}, body: JSON.stringify(body)});
  if (!response.ok) throw new Error(`Emulator request failed: HTTP ${response.status}`);
  return response.json();
}
async function main() {
  const people = [
    ['admin', 'Test Admin', 'admin', 'roster-test'],
    ['operator1', 'Test Operator 1', 'operator', 'roster-test'],
    ['operator2', 'Test Operator 2', 'operator', 'roster-test'],
    ['watcher', 'Test Watcher', 'watcher', 'roster-test'],
    ['outsider', 'Other Company', 'operator', 'roster-other'],
  ];
  for (const [id, name, role, company] of people) {
    const user = await request(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only`,
      'POST', {email: `${id}@roster.test`, password: 'local-emulator-only', returnSecureToken: true});
    const data = {displayName: name, role, companyId: company, environment: 'training'};
    await request(`${base}/users/${user.localId}`, 'PATCH', {fields: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, {stringValue: value}]))}, true);
  }
  console.log('Five isolated roster emulator accounts ready.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
