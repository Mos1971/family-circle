// One-off: converts the earlier one-circle-per-account layout
//   users/{uid} {circleId, firstName, role, status, ...}
// to the multi-circle layout
//   users/{uid}                      {email, activeCircleId, circleIds, circleNames}
//   circles/{cid}/members/{uid}      {firstName, role, status, ...}
// and adds the circle name to each invite code.   Run once:
//   node scripts/migrate_to_members.js
const { BASE, token, headers } = require('./_firestore');

(async () => {
  const t = token(); const h = headers(t);
  const j = (r) => r.json();
  const users = (await fetch(`${BASE}/users?pageSize=300`, { headers: h }).then(j)).documents || [];
  const circleNames = {};
  const circles = (await fetch(`${BASE}/circles?pageSize=300`, { headers: h }).then(j)).documents || [];
  for (const c of circles) circleNames[c.name.split('/').pop()] = c.fields.name.stringValue;

  let moved = 0;
  for (const u of users) {
    const f = u.fields;
    const id = u.name.split('/').pop();
    const cid = f.circleId && f.circleId.stringValue;
    if (!cid) continue; // already migrated
    const member = { ...f }; delete member.circleId;
    await fetch(`${BASE}/circles/${cid}/members/${id}`, { method: 'PATCH', headers: h, body: JSON.stringify({ fields: member }) });
    // Overwrite the account doc with the new, smaller shape.
    await fetch(`${BASE}/users/${id}`, {
      method: 'PATCH', headers: h,
      body: JSON.stringify({ fields: {
        email: f.email,
        activeCircleId: { stringValue: cid },
        circleIds: { arrayValue: { values: [{ stringValue: cid }] } },
        circleNames: { mapValue: { fields: { [cid]: { stringValue: circleNames[cid] || 'Family Circle' } } } },
      } }),
    });
    moved++;
  }
  // Add circleName to invite codes so people can see where they are joining.
  for (const c of circles) {
    const cid = c.name.split('/').pop();
    const code = c.fields.code && c.fields.code.stringValue;
    if (!code) continue;
    await fetch(`${BASE}/inviteCodes/${code}`, { method: 'PATCH', headers: h, body: JSON.stringify({ fields: {
      circleId: { stringValue: cid }, circleName: { stringValue: circleNames[cid] },
    } }) });
  }
  console.log(`Migrated ${moved} accounts; updated ${circles.length} invite codes.`);
})();
