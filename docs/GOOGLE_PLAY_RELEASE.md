# Publishing Family Circle on Google Play

Branch: `release/google-play`. The signed app bundle is built from this branch.

## What is already set up

- **Upload key** created at `C:\Users\Maurice\FamilyCircleKeys\family-circle-upload.jks`
  (outside the project). Its passwords are in `android/key.properties`, which is
  ignored by git. **Back up both files somewhere safe (e.g. a password manager and a
  USB stick).** If the key is lost you can ask Google to reset it, but it takes days.
- `android/app/build.gradle.kts` signs release builds with that key. Without
  `key.properties` (fresh checkout, CI) it falls back to the debug key.
- App id: `com.familycircle.app` - this can never change once published.
- Version: `1.0.0+1` in `pubspec.yaml`. **Every upload to Google Play needs a higher
  number after the `+`** (1.0.1+2, 1.0.2+3, ...).
- Privacy policy page: `web/privacy.html`, published at
  `https://family-circle-mos71.web.app/privacy.html` after the next web deploy.
  **Replace the `[YOUR NAME OR BUSINESS NAME]` and `[YOUR CONTACT EMAIL]` placeholders
  first.**
- Store icon: `web/icons/Icon-512.png` (512x512).

## Build the file to upload

```
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Google Play takes this
`.aab` file, not the `.apk` testers have been using.

## Steps in Play Console (https://play.google.com/console)

1. **Create a developer account** - one-off US$25 fee, identity verification
   (ID, and for organisations a D-U-N-S number). Choose "Personal" or "Organisation";
   if you plan to sell the app as a business, Organisation is the better fit.
2. **Create app** - name "Family Circle", default language English (UK), App (not game),
   Free (or paid - this cannot be changed from free to paid later).
3. **Set up your app** (Dashboard checklist):
   - Privacy policy URL (the page above)
   - App access: tell Google how to log in - provide a demo account in the
     "Instructions" box (the reviewers cannot join without an invite code). Create a
     test circle and give them its email and password.
   - Ads: No
   - Content rating questionnaire (social app with user-generated content, messaging)
   - Target audience: pick 18+ unless you want the Families policy (much stricter)
   - Data safety form: collected = name, email, messages, photos/none, user content,
     device ID (push token); encrypted in transit = yes; users can request deletion = yes
   - Account deletion: link to the deletion section of the privacy page (see below)
   - Government app / financial features / health: No
4. **Store listing**: short description (80 chars), full description (4000 chars),
   icon 512x512, feature graphic 1024x500, at least 2 phone screenshots.
5. **Closing testing (required for new personal accounts)**: Google requires 12 testers
   opted in for 14 continuous days before you can apply for production access.
   Create a closed-testing track, upload the `.aab`, add testers by email
   (Google Group or list), and send them the opt-in link. Organisation accounts
   are normally exempt.
6. **Production**: apply for production access, create a release, upload the `.aab`,
   write release notes, submit for review (typically a few days).

## Before you submit - important

- **Account deletion is required.** Google Play requires apps that let people create
  an account to offer account deletion inside the app and on a web page. Family
  Circle does not have this yet (the privacy page currently says to email you). Build
  an in-app "Delete my account" before submitting for production.
- **Testers on the current APK must reinstall.** Earlier APKs were signed with a debug
  key; Google Play builds use the upload key, so Android will not update across the
  two. Testers must uninstall the old app first.
- **Google Sign-In / calendar sync** on Android is not set up (calendar sync is
  web-only), so nothing to change for Play.
- Add the Play app signing SHA-1 (shown in Play Console > App integrity) to the
  Firebase project's Android app if you later add Google Sign-In or phone auth.
  Upload key SHA-1: `BE:C0:D8:DD:04:61:CA:D3:3D:75:84:19:F0:78:73:90:79:CC:EB:24`
