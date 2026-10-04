// Shared helpers for the owner-only admin scripts. These talk to Firestore
// using YOUR firebase-tools login (run `firebase login` first), which has
// full access and bypasses the security rules. Never ship these to customers.
const { execSync } = require('child_process');
const os = require('os');
const path = require('path');

const PROJECT = 'family-circle-mos71';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

function token() {
  // Any firebase command refreshes the stored access token.
  try { execSync('firebase projects:list', { stdio: 'ignore', shell: true }); } catch (_) {}
  const cfg = require(path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json'));
  return cfg.tokens.access_token;
}

function headers(t) {
  return { Authorization: 'Bearer ' + t, 'Content-Type': 'application/json', 'X-Goog-User-Project': PROJECT };
}

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function randomCode(n) {
  const crypto = require('crypto');
  return Array.from(crypto.randomBytes(n), (b) => ALPHABET[b % ALPHABET.length]).join('');
}

module.exports = { PROJECT, BASE, token, headers, randomCode };
