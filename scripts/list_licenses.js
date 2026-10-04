// Show every licence code and whether it has been used.
//   node scripts/list_licenses.js
const { BASE, token, headers } = require('./_firestore');

(async () => {
  const t = token();
  const r = await fetch(`${BASE}/licenses?pageSize=300`, { headers: headers(t) });
  const d = await r.json();
  for (const doc of d.documents || []) {
    const f = doc.fields;
    const id = doc.name.split('/').pop();
    console.log(id, f.used.booleanValue ? 'USED  ' : 'unused', f.note ? f.note.stringValue : '');
  }
  if (!(d.documents || []).length) console.log('No licences yet.');
})();
