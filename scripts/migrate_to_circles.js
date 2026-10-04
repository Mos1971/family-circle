// One-off: moves the original single-community data into a circle owned by
// the given user. Safe to read; run once.
//   node scripts/migrate_to_circles.js <ownerEmail> "<circle name>"
const { BASE, token, headers, randomCode } = require('./_firestore');

const COLLECTIONS = ['posts','comments','announcements','notifications','messages','events','todoLists','reports'];

(async () => {
  const [email, name] = [process.argv[2], process.argv[3] || 'Family Circle'];
  if (!email) { console.error('Usage: node scripts/migrate_to_circles.js <ownerEmail> "<circle name>"'); process.exit(1); }
  const t = token(); const h = headers(t);
  const j = (r) => r.json();

  const users = (await fetch(`${BASE}/users?pageSize=300`, { headers: h }).then(j)).documents || [];
  const owner = users.find((u) => u.fields.email.stringValue.toLowerCase() === email.toLowerCase());
  if (!owner) { console.error('No user with that email'); process.exit(1); }
  const ownerId = owner.name.split('/').pop();

  const cid = randomCode(20);
  const code = randomCode(8);
  const put = (path, fields) => fetch(`${BASE}/${path}`, { method: 'PATCH', headers: h, body: JSON.stringify({ fields }) });
  const ts = { timestampValue: new Date().toISOString() };

  await put(`circles/${cid}`, { name: { stringValue: name }, ownerId: { stringValue: ownerId }, code: { stringValue: code }, licenseCode: { stringValue: 'LEGACY' }, createdAt: ts });
  await put(`inviteCodes/${code}`, { circleId: { stringValue: cid } });
  for (const u of users) {
    const id = u.name.split('/').pop();
    await fetch(`${BASE}/users/${id}?updateMask.fieldPaths=circleId`, { method: 'PATCH', headers: h, body: JSON.stringify({ fields: { circleId: { stringValue: cid } } }) });
  }
  console.log(`Circle ${cid} created for ${email}; invite code ${code}; ${users.length} users moved.`);

  for (const c of COLLECTIONS) {
    const docs = (await fetch(`${BASE}/${c}?pageSize=500`, { headers: h }).then(j)).documents || [];
    for (const d of docs) {
      const id = d.name.split('/').pop();
      await put(`circles/${cid}/${c}/${id}`, d.fields);
      await fetch(`${BASE}/${c}/${id}`, { method: 'DELETE', headers: h });
    }
    console.log(`${c}: moved ${docs.length}`);
  }
})();
