/**
 * Sends a push alert to a person's phones/browsers whenever an in-app
 * notification is created for them.
 *
 * The app already writes one notification document per event (new message,
 * comment, calendar event, shared list, announcement...) and has already
 * applied each person's notification preferences, so this single function
 * covers every kind of alert.
 *
 * Devices register their push token in users/{uid}/devices/{token}.
 */
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const SITE = 'https://family-circle-mos71.web.app';

// Where tapping the alert should land.
const LINKS = {
  message: '/#/messages',
  event: '/#/plan',
  todo: '/#/plan?tab=lists',
  announcement: '/#/announcements',
  comment: '/#/feed',
  reaction: '/#/feed',
  community: '/#/notifications',
};

exports.sendPushForNotification = onDocumentCreated(
  {
    // Must match the Firestore database location (europe-west2, London).
    region: 'europe-west2',
    document: 'circles/{circleId}/notifications/{notificationId}',
  },
  async (event) => {
    const n = event.data && event.data.data();
    if (!n || !n.userId) return;

    const db = getFirestore();
    const devices = await db.collection('users').doc(n.userId).collection('devices').get();
    if (devices.empty) return;

    const tokens = devices.docs.map((d) => d.id);
    const path = LINKS[n.type] || '/#/notifications';
    const title = String(n.title || 'Family Circle').slice(0, 100);
    const body = String(n.body || '').slice(0, 140);

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type: String(n.type || ''), circleId: event.params.circleId, path },
      android: { priority: 'high' },
      webpush: {
        notification: { icon: SITE + '/icons/Icon-192.png' },
        fcmOptions: { link: SITE + path },
      },
    });

    // Tidy up devices that have uninstalled or revoked permission.
    const dead = [];
    res.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) dead.push(tokens[i]);
    });
    await Promise.all(
      dead.map((t) => db.collection('users').doc(n.userId).collection('devices').doc(t).delete())
    );
  }
);
