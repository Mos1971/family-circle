// One-off: gives pre-group-chat messages a chatId and readBy list.
//   node scripts/migrate_messages.js
const { BASE, token, headers } = require('./_firestore');

(async () => {
  const h = headers(token());
  const circles = (await fetch(`${BASE}/circles?pageSize=300`, { headers: h }).then((r) => r.json())).documents || [];
  let n = 0;
  for (const c of circles) {
    const cid = c.name.split('/').pop();
    const msgs = (await fetch(`${BASE}/circles/${cid}/messages?pageSize=500`, { headers: h }).then((r) => r.json())).documents || [];
    for (const m of msgs) {
      const f = m.fields;
      if (f.chatId) continue;
      const sender = f.senderId.stringValue;
      const recipient = f.recipientId.stringValue;
      const ids = [sender, recipient].sort();
      const read = f.read && f.read.booleanValue === true;
      const readBy = [sender, ...(read ? [recipient] : [])].map((v) => ({ stringValue: v }));
      const id = m.name.split('/').pop();
      await fetch(`${BASE}/circles/${cid}/messages/${id}?updateMask.fieldPaths=chatId&updateMask.fieldPaths=readBy`, {
        method: 'PATCH', headers: h,
        body: JSON.stringify({ fields: { chatId: { stringValue: `dm|${ids[0]}|${ids[1]}` }, readBy: { arrayValue: { values: readBy } } } }),
      });
      n++;
    }
  }
  console.log(`Upgraded ${n} messages.`);
})();
