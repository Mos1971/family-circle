// Browser-side sign-in for Google Calendar and Outlook/Microsoft 365.
// Tokens are requested on demand, kept in memory by the app, and only ever
// used to READ the person's own calendar. Nothing is stored on our servers.
(function () {
  var msalApp = null;
  var FLAGS_KEY = 'fc_calendar_sync_flags';

  window.fcCalendarSync = {
    // Google Identity Services: returns an access token (valid ~1 hour).
    googleToken: function (clientId, interactive) {
      return new Promise(function (resolve, reject) {
        if (!window.google || !google.accounts || !google.accounts.oauth2) {
          reject(new Error('Google sign-in is still loading. Try again in a moment.'));
          return;
        }
        var client = google.accounts.oauth2.initTokenClient({
          client_id: clientId,
          scope: 'https://www.googleapis.com/auth/calendar.readonly',
          callback: function (r) {
            if (r.error) reject(new Error(r.error));
            else resolve(r.access_token);
          },
          error_callback: function (e) {
            reject(new Error((e && e.type) || 'popup_closed'));
          },
        });
        // prompt 'none' re-uses an earlier consent without asking again.
        client.requestAccessToken({ prompt: interactive ? 'select_account' : 'none' });
      });
    },

    // Microsoft (MSAL.js): works for outlook.com / hotmail / work accounts.
    microsoftToken: async function (clientId, interactive) {
      if (!window.msal) throw new Error('Microsoft sign-in is still loading. Try again in a moment.');
      if (!msalApp) {
        msalApp = new msal.PublicClientApplication({
          auth: {
            clientId: clientId,
            authority: 'https://login.microsoftonline.com/common',
            redirectUri: window.location.origin,
          },
          cache: { cacheLocation: 'localStorage' },
        });
        if (msalApp.initialize) await msalApp.initialize();
      }
      var scopes = ['Calendars.Read'];
      var accounts = msalApp.getAllAccounts();
      if (accounts.length) {
        try {
          var silent = await msalApp.acquireTokenSilent({ scopes: scopes, account: accounts[0] });
          return silent.accessToken;
        } catch (e) { /* fall through to interactive */ }
      }
      if (!interactive) throw new Error('interaction_required');
      var result = await msalApp.loginPopup({ scopes: scopes, prompt: 'select_account' });
      return result.accessToken;
    },

    microsoftSignOut: async function () {
      if (!msalApp) return;
      var accounts = msalApp.getAllAccounts();
      for (var i = 0; i < accounts.length; i++) {
        try { await msalApp.clearCache({ account: accounts[i] }); } catch (e) {}
      }
    },

    // Which providers this browser has connected (not secrets, just flags).
    getFlags: function () {
      try { return window.localStorage.getItem(FLAGS_KEY) || ''; } catch (e) { return ''; }
    },
    setFlags: function (value) {
      try { window.localStorage.setItem(FLAGS_KEY, value); } catch (e) {}
    },
  };
})();
