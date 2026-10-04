// Evaluates firestore.rules against sample requests using Google's rules
// test API (reads live data for get()/exists()). Usage: node scripts/test_rules.js
const fs = require('fs');
const { PROJECT, token } = require('./_firestore');

const P = '/databases/(default)/documents';
const str = (v) => ({ stringValue: v });

async function run(cases) {
  const t = token();
  const body = {
    source: { files: [{ name: 'firestore.rules', content: fs.readFileSync('firestore.rules', 'utf8') }] },
    testSuite: { testCases: cases.map((c) => ({
      expectation: c.expect, request: { auth: c.auth, path: c.path, method: c.method, ...(c.data ? { resource: { data: c.data } } : {}) },
      ...(c.mocks ? { functionMocks: c.mocks } : {}),
    })) },
  };
  const r = await fetch(`https://firebaserules.googleapis.com/v1/projects/${PROJECT}:test`, {
    method: 'POST', headers: { Authorization: 'Bearer ' + t, 'Content-Type': 'application/json', 'X-Goog-User-Project': PROJECT },
    body: JSON.stringify(body),
  });
  const d = await r.json();
  if (!r.ok) { console.log(JSON.stringify(d).slice(0, 800)); return; }
  (d.testResults || []).forEach((res, i) => {
    console.log(res.state === 'SUCCESS' ? 'PASS' : 'FAIL', '-', cases[i].name, res.state === 'SUCCESS' ? '' : JSON.stringify(res.debugMessages || res.errorPosition || '').slice(0, 300));
  });
  if (d.issues) console.log('ISSUES', JSON.stringify(d.issues).slice(0, 600));
}
const memberMocks = (cid, uid, data) => [
  { function: 'exists', args: [{ exactValue: `${P}/circles/${cid}/members/${uid}` }], result: { value: true } },
  { function: 'get', args: [{ exactValue: `${P}/circles/${cid}/members/${uid}` }], result: { value: { data } } },
];
module.exports = { run, P, str, memberMocks };

if (require.main === module) {
  const CID = process.argv[2], UID = process.argv[3];
  const post = { authorId: UID, text: 'hi', createdAt: new Date().toISOString(), type: 'normal',
    reactions: { like: [], love: [], laugh: [], celebrate: [] }, reportedCount: 0, hidden: false };
  const mocks = memberMocks(CID, UID, { status: 'approved', role: 'admin' });
  run([
    { name: 'member can create own post', mocks, expect: 'ALLOW', auth: { uid: UID }, method: 'create', path: `${P}/circles/${CID}/posts/test1`, data: post },
    { name: 'member can read posts', mocks, expect: 'ALLOW', auth: { uid: UID }, method: 'list', path: `${P}/circles/${CID}/posts` },
    { name: 'stranger cannot read posts', expect: 'DENY', auth: { uid: 'someoneElse' }, method: 'list', path: `${P}/circles/${CID}/posts` },
  ]);
}
