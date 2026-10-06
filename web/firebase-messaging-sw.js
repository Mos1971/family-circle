// Receives push alerts while Family Circle is closed or in the background.
// Firebase shows the notification itself; tapping it opens the link the
// server attached (see functions/index.js).
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDorIcn3yU5VqTXazzVnFDx1E0n7OxyIuo',
  appId: '1:926394248212:web:719bb450ce99f89321cb01',
  messagingSenderId: '926394248212',
  projectId: 'family-circle-mos71',
  authDomain: 'family-circle-mos71.firebaseapp.com',
  storageBucket: 'family-circle-mos71.firebasestorage.app',
});

// Having a handler registered keeps the worker active for background alerts.
firebase.messaging().onBackgroundMessage(function () {});
