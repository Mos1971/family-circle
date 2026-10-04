# Calendar sync setup (Google + Outlook)

The code for syncing a person's **Google Calendar** and **Outlook** calendar
into "My calendar" is built. It switches on when you paste two public IDs into
`lib/calendar_sync/calendar_sync_config.dart`:

```dart
static const googleClientId = '123456-abc.apps.googleusercontent.com';
static const microsoftClientId = '11111111-2222-3333-4444-555555555555';
```

Leave one empty to hide that provider. Both IDs are public identifiers, not
secrets.

How it works: when someone taps **Connect**, a sign-in pop-up from Google or
Microsoft asks them to allow *read-only* access to their own calendar. The app
then fetches events from about a month ago to four months ahead and shows them
in blue on **My calendar** only. Nothing is stored on our servers; events live in
the browser's memory and are refreshed with the **Sync now** button.

Calendar sync works in the **web app**. (Phones using the website are fine.)

---

## Google (Gmail / Google Calendar)

Use the Google Cloud project that already exists behind your Firebase project
(`family-circle-mos71`).

1. Open https://console.cloud.google.com/ and select project `family-circle-mos71`.
2. **APIs & Services -> Library** -> search **Google Calendar API** -> **Enable**.
3. **APIs & Services -> OAuth consent screen** (also called "Google Auth
   platform"):
   - User type **External**.
   - App name `Family Circle`, your support email, developer contact email.
   - **Scopes**: add `.../auth/calendar.readonly`.
   - Leave publishing status as **Testing** for now and add the Google accounts
     that should be able to try it under **Test users** (up to 100).
4. **APIs & Services -> Credentials -> Create credentials -> OAuth client ID**
   - Application type: **Web application**
   - **Authorised JavaScript origins**: `https://family-circle-mos71.web.app`
     (add your own domain here later, and `http://localhost:8941` if you test
     locally). No redirect URI is needed.
5. Copy the **Client ID** into `googleClientId`.

**Before selling:** while the consent screen is in *Testing*, only the listed
test users can connect, and Google shows an "unverified app" warning. To let
any customer connect you must click **Publish app** and pass Google's
verification for the sensitive calendar scope. That needs a public home page, a
privacy policy URL and a short demo video, and is free but can take days to
weeks.

---

## Microsoft (Outlook.com, Hotmail, Microsoft 365)

1. Open https://portal.azure.com/ (a free Microsoft account is enough) ->
   **Microsoft Entra ID -> App registrations -> New registration**.
2. Name `Family Circle`. Supported account types: **Accounts in any
   organizational directory and personal Microsoft accounts**.
3. Redirect URI: platform **Single-page application (SPA)**, value
   `https://family-circle-mos71.web.app` (add your own domain later).
4. After it is created, open **API permissions -> Add a permission ->
   Microsoft Graph -> Delegated permissions** -> tick **Calendars.Read** ->
   Add. (`User.Read` is added automatically; leave it.)
5. Copy the **Application (client) ID** from the Overview page into
   `microsoftClientId`.

Personal Outlook accounts work straight away. Some company (Microsoft 365)
tenants require their IT admin to approve the app first; that is controlled by
the customer's organisation, not by us.

---

## After adding the IDs

```
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting
```

Then open **Plan -> Calendar -> My calendar**. A "Sync your other calendars"
card appears with **Connect** buttons.
