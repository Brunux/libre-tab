# App Store submission — Libre Tab 1.0.0

Checked against the App Store Review Guidelines and Apple's upcoming
requirements (September 2026). Everything the reviewer will look at, what
to enter in App Store Connect, and the notes for the reviewer.

## Build

| Requirement | Status |
|---|---|
| Built with Xcode 26 / iOS 26 SDK (required since 28 April 2026) | Xcode 26.5 ✅ |
| Minimum iOS 13 or later (since 9 September 2026) | iOS 15.0 ✅ (Flutter 3.47) |
| Universal: iPhone and iPad, all iPad orientations (2.4.1) | ✅ |
| Version 1.0.0, build 1 (`pubspec.yaml`) | ✅ |
| `ITSAppUsesNonExemptEncryption = NO` (no export-compliance prompt) | ✅ |
| App privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`): no tracking, no data collected; required-reason APIs: file timestamps `C617.1` (SQLite, own container), UserDefaults `CA92.1`, disk space `E174.1` (SQLite checks free space before writing its files; found by scanning the built binaries for `statfs`). Every plugin ships its own manifest; the SQLite and Objective-C frameworks built from source have none, so the app's declares what they use. | ✅ |
| Launch screen: dark, with the logo (no white flash) | ✅ |
| Icon: 1024 × 1024, opaque, no alpha | ✅ |

Upload: `flutter build ipa --release`, then Transporter or Xcode →
Organizer. Signing uses the team in the Xcode project; the bundle ID
`com.libretab.libreTab` is permanent once the app exists in App Store
Connect.

## App Store Connect answers

**App information**
- Name: *Libre Tab: Songbook & Tuner* (27/30) · Subtitle: see
  [listing.md](listing.md)
- Primary category: **Music** · Secondary: **Utilities**
- Primary language: English (U.S.); add Spanish (Mexico) and/or Spanish
  (Spain) localizations with the Spanish text from listing.md.
- Content rights: *Does your app contain, show, or access third-party
  content?* → **No**. The bundled songs are public domain in every
  storefront: traditional (Red River Valley, Clementine, She'll Be Coming
  'Round the Mountain, De Colores, La Cucaracha) or by authors who died
  before 1900 (John Newton 1807, Stephen Foster 1864). Cielito Lindo was
  dropped: its author died in 1957, so it's still protected under life+70
  (EU) and life+100 (Mexico). (List in
  `lib/features/library/data/starter_songs.dart`); everything else is what
  users add themselves, stored only on their device.
- Price: Free · no in-app purchases.

**App Privacy** → *Data Not Collected*. No tracking. Privacy policy URL:
`https://github.com/Brunux/libre-tab/blob/main/PRIVACY.md` (push the repo
first so the link works).

**Accessibility** (the App Store's accessibility labels, per device):
VoiceOver ✅, Voice Control ✅, Larger Text ✅, Dark Interface ✅ (dark by
default), Differentiate Without Color Alone ✅ (states also shown by text
or icons: ✓, "In tune"), Sufficient Contrast ✅ (tested), Reduced Motion ✅.
Captions and Audio Descriptions: not applicable (no video).

**Age rating** (the questionnaire updated in 2026): answer **None / No**
to everything — no violence, sexual content, profanity, drugs, gambling,
horror, medical information, unrestricted web access, messaging or chat,
user-to-user sharing, advertising, or purchases. Result: **4+**.
(Sharing a song file through the system share sheet is the user's own
action, not an in-app social feature.)

**URLs**
- Support: `https://github.com/Brunux/libre-tab/issues`
- Marketing (optional): `https://github.com/Brunux/libre-tab`
- Copyright: `2026 Bruno Fosados`

**Screenshots**
- iPhone 6.5" (1284 × 2778, the size App Store Connect asks for): `docs/store/screenshots/*.png` (7)
- iPad 13" (2064 × 2752): `docs/store/screenshots/ipad/*.png` (4)

## Notes for the reviewer

Paste into *App Review Information → Notes*, and attach
`docs/store/review-sample.png` (a chord sheet to try Scan photo):

> Libre Tab is an offline songbook and guitar tuner. No account or sign-in;
> no network access; no data collected.
>
> To try it:
> 1. Songbook: open any of the included public-domain songs (e.g. "Amazing
>    Grace"). Chords appear over the lyrics. Use the bar at the bottom to
>    transpose, set a capo, change the text size and start auto-scroll; tap
>    a chord to see its diagram. Swipe a song left in the list for quick
>    actions.
> 2. Scan photo: Add song → Scan photo → Choose from photos, and pick the
>    attached chord sheet (or a screenshot of any chord sheet). The text is
>    read on the device with Apple's Vision framework and shown for review
>    before saving.
> 3. Tuner: the Tuner tab explains why it needs the microphone before
>    asking. Play or hum a note (or play a tone, e.g. 110 Hz for the A
>    string). Audio is analyzed on the device and never recorded or sent.
>    If the microphone is refused, the tuner says how to allow it; the rest
>    of the app keeps working.
> 4. Settings → Privacy shows the privacy policy inside the app.
> 5. Settings → Support Libre Tab: rate, share, GitHub; on the US
>    storefront also an optional "Buy me a coffee" tip link (guideline
>    3.1.1(a)); it's hidden in other storefronts.

## Guideline check

| Guideline | How Libre Tab meets it |
|---|---|
| 1.2 User-generated content | No in-app sharing, posting or social features; songs stay on the device. Not a UGC platform. |
| 2.5.15 Files | Open file and Import use the system document picker: Files and iCloud Drive included. |
| 2.1 Completeness | No placeholders; starter songs make the first launch useful. Tested on a real iPhone (24 Sep 2026: tuning a guitar, setlist auto-advance, Open in Libre Tab from Files, Paste) and the iPad simulator. Test on a real iPad too if possible — reviewers often use one. |
| 2.3.1 Hidden features | None. |
| 2.3.3 Screenshots | All show the app in use (no splash or intro screens). |
| 2.3.7 Name/keywords | Unique name ≤ 30; keywords describe the app, no brand names. |
| 2.3.8 4+ metadata | ✅ |
| 2.3.10 Other platforms | No mention of other platforms in the iOS app or its metadata; the Android-only licenses entry (Tesseract) isn't shown on iOS; PRIVACY.md is platform-neutral. |
| 2.4.1 iPad | Adaptive layout: side rail, readable widths, all orientations, Split View / Slide Over. |
| 2.4.2 Power | Tuner listens only while its tab is visible and the app is in front; screen-awake only in the song view and tuner. |
| 2.5.1 Public APIs | Only public frameworks (AVFoundation via `record`, Vision, PhotosUI via `image_picker`). |
| 2.5.2 Self-contained | No downloaded code; all resources bundled. |
| 2.5.14 Recording consent | Explanation screen before the microphone prompt; the tuner visibly listens (needle, note); iOS shows its microphone indicator. |
| Accessibility | VoiceOver labels on every control (custom actions for swipe actions and the theme menu); Dynamic Type; follows Reduce Motion (no title flight, no folding or springing); contrast and tap sizes checked by tests on every screen and theme. |
| 4.2 Minimum functionality | Native songbook with transposition, capo, auto-scroll, setlists, chord diagrams, on-device OCR, and a tuner. |
| 5.1.1(i) Privacy policy | In App Store Connect **and** in the app (Settings → Privacy), both saying what stays on the device, how long it's kept, how to delete it (a song, all songs, or the app) and how to withdraw the microphone and camera permissions. |
| 5.1.1(ii)/(iv) Permissions | Purpose strings in English and Spanish; asked only when a feature is used; refusal handled gracefully. |
| 5.1.1(iv) Permission prompts | Neutral pre-prompt ("Start tuner"), no "Allow" wording or skip button; refusals offer Open Settings and an alternative (docs/DESIGN.md § Permissions). |
| 5.1.1(iii) Data minimization | Photos through the system picker (no library permission); only the camera and microphone are requested. |
| 5.1.2 Data use | Nothing collected or shared; no third-party analytics/ads SDKs. |
| 5.2 Intellectual property | Bundled songs are public domain worldwide (see Content rights); the logo is original; fonts are OFL; open-source licenses in the app. There's no catalog, search or download of lyrics: songs users add come from their own files, clipboard or photos and stay private to them, like notes. |
| 5.2.3 Third-party media | No saving, converting or downloading from other services. |
| 3.1 Payments | Free, no In-App Purchase, no ads. A "Buy me a coffee" tip link (Settings → Support Libre Tab) is shown only when StoreKit's `Storefront.current` is the United States, the one storefront where 3.1.1(a) allows buttons and links to outside payment; everywhere else it's hidden, and the store listing doesn't mention it. |
| 5.6.1 Reviews | "Rate Libre Tab" opens the app's App Store review page (Apple ID 6815950837), only when tapped; no incentive, no custom prompt. |
| GPL and the App Store | All the app's GPL code is the developer's own, so publishing it on the App Store is the copyright holder's call; every third-party package is MIT, BSD or Apache (the one LGPL package, `dbus`, is Linux-only and not in the iOS app). Before accepting outside contributions, add an App Store permission (GPL section 7) or a contributor agreement. |

## Before pressing Submit

1. ✅ Push the repository (privacy and support URLs must load) — pushed.
2. Upload the build, answer the questionnaires above, add screenshots and
   Spanish localization.
3. ✅ Final check on a real iPhone — done 24 Sep 2026. Still worth doing on
   a real iPad if one is available: first launch with starter songs, tuner
   permission prompt, Scan photo, Open in Libre Tab from Files.
