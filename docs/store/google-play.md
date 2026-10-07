# Google Play submission — Libre Tab 1.0.0

How to put Libre Tab on Google Play: signing, the build, and what to
enter in the Play Console. Text and graphics are in [listing.md](listing.md).

## Build

| Requirement | Status |
|---|---|
| Android App Bundle (`.aab`), signed with the upload key | `flutter build appbundle` |
| Target API 36 (required for new apps from 31 August 2026) | Flutter 3.47 default ✅ |
| 64-bit native code with 16 KB page alignment (required since November 2025) | ✅ checked with `llvm-readelf`: every arm64-v8a and x86_64 library is aligned to 16 KB or more |
| Application ID `com.libretab.libre_tab` (permanent once published) | ✅ |
| Version 1.0.0, versionCode from `pubspec.yaml` (`+N`); raise it for every upload | ✅ |
| Permissions in the release manifest: `RECORD_AUDIO` only. No `INTERNET`; photos are taken with the system camera app, so no `CAMERA` either | ✅ |

The bundle is ~77 MB because it carries three architectures; Play sends
each phone only its own (~25 MB download).

## Signing

Google Play signs the app for users (Play App Signing). You sign each
upload with your own **upload key**. If you lose it, Google can reset it,
but that takes a support request, so keep a backup.

1. Create the key, outside the repository. `keytool` asks for a password
   and your name. Type them yourself:

   ```bash
   mkdir -p ~/keys && keytool -genkey -v -keystore ~/keys/libre-tab-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`. It's ignored by git; never commit it:

   ```properties
   storeFile=/Users/<you>/keys/libre-tab-upload.jks
   storePassword=<the password>
   keyAlias=upload
   keyPassword=<the password>
   ```

3. Back up `libre-tab-upload.jks` and the password, for example in a
   password manager.

`android/app/build.gradle.kts` signs release builds with this key when
`key.properties` exists, and with the debug key otherwise (so
`flutter run --release` still works on a machine without it). Play rejects
an upload signed with the debug key, so a missing key can't slip through.

## Play Console

**Account.** play.google.com/console: a one-time $25 fee and identity
verification. A *personal* account created after November 2023 has to run
a **closed test with at least 12 testers for 14 days in a row** before it
can apply for production. An *organization* account (needs a D-U-N-S
number) skips that step.

**Create app.** Name *Libre Tab: Songbook & Tuner* · default language
English (United States) · App · Free. Accept the declarations.

**App content** (Policy → App content):
- Privacy policy: `https://github.com/Brunux/libre-tab/blob/main/PRIVACY.md`
- Ads: **No**
- App access: **All functionality is available without special access**
- Content rating (IARC questionnaire): category *All Other App Types*;
  answer **No** to violence, sexuality, language, controlled substances,
  gambling, user interaction, and sharing of location or personal
  information. Result: **Everyone / PEGI 3**.
- Target audience: **13 and over**. The app suits every age, but choosing
  under-13 groups brings in the Families policy (extra review and
  requirements) with no benefit for a songbook without ads or accounts.
- Data safety: **No data collected, no data shared**. The microphone is
  used on the device only (see listing.md § Privacy answers).
- Government app, financial features, health: **No**.

**Store listing** (Grow → Store presence → Main store listing): the
English and Spanish (es-419, es-ES) text from listing.md; icon
`branding/png/play-icon-512.png`; feature graphic
`branding/png/play-feature-1024x500.png`; phone screenshots
`docs/store/screenshots/android/` (7). Category **Music & Audio**;
contact email; website `https://github.com/Brunux/libre-tab`.

**Release** (personal account):
1. Testing → Closed testing → create a track, add testers (an email list
   or a Google Group) and upload the `.aab`. Share the opt-in link; each
   tester joins and installs from Play.
2. After 14 days with at least 12 testers opted in, Dashboard → *Apply for
   production*: a few questions about the test and the app.
3. Once approved: Production → Create release → reuse the same build
   (or a newer one) → roll out. The first review can take up to about a
   week.

## Differences from iOS

- No "Buy me a coffee": Google Play only allows outside payment links
  through its enrollment programs, so Android shows Rate, Share and GitHub
  only.
- Text in photos is read with Tesseract (Apache-2.0), bundled with English
  and Spanish models; its license appears in Settings → Licenses.
