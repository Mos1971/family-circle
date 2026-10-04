// Mint a one-time licence code for a new customer.
//   node scripts/new_license.js "Smith family"      (note is optional)
// Give the printed code to the customer; they enter it under
// "Start a circle" when they sign up. Each code works exactly once.
const { BASE, token, headers, randomCode } = require('./_firestore');

(async () => {
  const note = process.argv[2] || '';
  const t = token();
  const raw = randomCode(12);
  const code = `${raw.slice(0, 4)}-${raw.slice(4, 8)}-${raw.slice(8, 12)}`;
  const r = await fetch(`${BASE}/licenses/${code}`, {
    method: 'PATCH',
    headers: headers(t),
    body: JSON.stringify({
      fields: {
        used: { booleanValue: false },
        note: { stringValue: note },
        createdAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });
  if (!r.ok) { console.error('Failed:', r.status, await r.text()); process.exit(1); }
  console.log('Licence code:', code, note ? `(${note})` : '');
})();
