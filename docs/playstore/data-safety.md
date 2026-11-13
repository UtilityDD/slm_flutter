# Play Console: Data safety answers

Play Console → App content → Data safety. Answers below match the code as of 2026-11-13
(branch `fix/audit-2026-11-11`). ⚠ marks something to check or decide before you submit.

Play rules used: transfers to **service providers** that process data for you (Supabase, Google
Sign-In) are not "sharing". Data that never leaves the phone is not "collected". Data is
"required" if a signed-in user cannot avoid giving it.

## Step 1: Overview

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (Supabase, smartlineman.in, Google and YouTube are all HTTPS) ⚠ see note A |
| Which account creation methods does your app support? | **OAuth** (Sign in with Google). Not username/password, not "other". |
| Delete account URL | The hosted `account-deletion.html` (see `account-deletion.md`) |
| Do you provide a way for users to request that some or all of their data is deleted, without requiring them to delete their account? | **Yes** (clear phone/district/block/job in Settings, hide name on the league, or email) |
| Has your app successfully completed an independent security review (MASA)? | **No** |
| Is your app designed for families / children? | **No** (target audience 18+; see `content-rating-and-audience.md`) |

## Step 2: Data types

### Collected

| Category → type | Collected | Shared | Required / optional | Processed ephemerally? | Purposes |
|---|---|---|---|---|---|
| Personal info → **Name** | Yes | No ⚠ B | Required | No | App functionality, Account management, Fraud prevention, security & compliance |
| Personal info → **Email address** | Yes | No | Required | No | App functionality, Account management, Fraud prevention, security & compliance |
| Personal info → **User IDs** (Supabase account id, SLM id) | Yes | No | Required | No | App functionality, Account management, Fraud prevention, security & compliance |
| Personal info → **Phone number** | Yes | No | **Optional** | No | Account management, Fraud prevention, security & compliance (admin verification) |
| Personal info → **Other info** (district, block, job type, role, verification/blocked status, league name choice) | Yes | No ⚠ B | **Optional** ⚠ C | No | App functionality, Account management, Fraud prevention, security & compliance |
| App activity → **App interactions** (levels cleared, stars, deaths in a level, points, lessons finished, quiz answers) | Yes | No | Required (for signed-in users; guest play stays on the phone) | No | App functionality |

Purposes **not** used for any type: Analytics, Developer communications, Advertising or marketing,
Personalization.

How the main reasons map to the code:

- Name, email, photo link come from Google at sign-in (`auth_provider.dart`, `handle_new_user` trigger
  in `supabase/fix_new_google_signup.sql`); stored in `public.profiles`.
- Phone, district, block, job are typed/picked in Settings (`profile_edit.dart`) and used by admins to
  verify linemen (`verify_lineman.sql`, admin screen) and for the district league board.
- Level results go to `slm_app.submit_level_result` (`slm_app_10_league.sql`); points/lessons to `profiles`; hourly quiz
  answers to `submit_flutter_hourly_quiz`.

### Not collected (answer "No" for each)

- **Location** (approximate and precise): no location permission, no IP-to-location. ⚠ C
- **Photos and videos**: the app stores only the Google profile-photo **link**, never uploads photos. ⚠ D
- **Audio**: microphone removed (RECORD_AUDIO stripped in the manifest). Read-aloud uses device TTS.
- **Financial info, Health and fitness, Messages, Contacts, Calendar, Files and docs,
  Web browsing, Installed apps, In-app search history, Other user-generated content.**
- **App info and performance** (crash logs, diagnostics): no Crashlytics/Sentry/analytics SDK in
  `pubspec.yaml`. ⚠ E
- **Device or other IDs**: no advertising ID, no device ID read by the app. ⚠ E

## Step 3: What the listing will say (preview check)

After saving, the store listing should show roughly: "No data shared with third parties",
"This app may collect these data types: Personal info and App activity", "Data is encrypted in
transit", "You can request that data be deleted". If it shows Location or Device IDs, something
above was ticked by mistake.

## ⚠ Notes to resolve

**A. Encryption in transit / the online voice.** `learn_runner.dart` still calls
`NeuralTtsService.play`, which opens a secure WebSocket to Microsoft's unofficial Edge "Read Aloud"
endpoint (`speech.platform.bing.com`) and ignores `neuralVoiceEnabled = false` (AGENTS.md §7).
It sends lesson/quiz text only (no personal data), but it is an undisclosed third-party call and
an unofficial API. **Fix before release:** make the Learn runner honour `neuralVoiceEnabled` so it
uses device TTS only (the privacy policy already says voices are made on the phone). Also the
`radio` feature streams from `stream.zeno.fm` but nothing opens it today (`showPlayer()` has no
caller); keep it unreachable or mention it.

**B. Public league board.** Name (admin-approved, or masked "লাইনম্যান #1234") and district are shown
to every app user. Play defines "sharing" as transfer to a third party, so in-app display to other
users is normally **not** declared as sharing. The privacy policy explains the board and how to hide
the name. If you prefer to be extra cautious, tick Name and Other info as **Shared → App
functionality**; that only adds a "Data shared" line to the listing.

**C. District/block.** Typed by the user as the place they work, not read from the device. Declared
under Personal info → Other info, not Location. If a reviewer pushes back, move District/Block to
Location → **Approximate location** (Optional, App functionality). Also confirm district is truly
optional: the profile can be saved without it (it is today: the field shows "—").

**D. Profile photo.** Only Google's photo URL (`avatar_url`) is stored, and the photo loads from
Google's servers. Not declared as Photos. Decide whether the app should keep `avatar_url` at all.

**E. Check the release build's merged manifest** for `com.google.android.gms.permission.AD_ID` or
other permissions added by plugins: open the AAB in Android Studio → Build → Analyze APK →
`base/manifest/AndroidManifest.xml`, or build a release APK once and run
`aapt dump permissions build/app/outputs/flutter-apk/app-release.apk`. (The merged manifests in
`build/` today are stale debug/profile ones from before the microphone was removed.) Expected: only
`INTERNET` (+ the dynamic-receiver permission). If `AD_ID` appears, answer the Advertising ID
declaration "No, my app does not use advertising ID" and remove it with
`tools:node="remove"` in `AndroidManifest.xml`.

**F. YouTube embeds.** `learn_video_gate.dart` plays YouTube videos via `youtube_player_flutter`
(a WebView with YouTube's player). YouTube may collect device/usage data under Google's policies;
this is disclosed in the privacy policy. Play's form covers data your app or its SDKs collect;
YouTube's own collection inside its player is generally not declared by apps that embed it, but
if you want to be cautious declare App activity → App interactions as also collected for
App functionality (already declared above, so no new line is needed).

**G. Server security (affects the "encrypted / protected" claims).** AGENTS.md §7 says `profiles`
may be readable across users (check the SELECT policy) and clients write points directly. Before
release, confirm in Supabase → Authentication → Policies that a signed-in user can read and update
only their own `profiles` row (admins via the admin functions). Otherwise other users' phone
numbers could be read, which would contradict the privacy policy. `profiles` is the website's table:
the fix (`supabase/HOLD_profiles_privacy.sql`) is on hold until the website reads other people through
safe functions. The app reads other people only through `slm_app` functions (name, district, points).

**H. Website account.** The same Supabase project serves smartlineman.in. If the website collects
more (for example other tables or analytics), the privacy policy must cover it, and
`slm_app_30_delete_account.sql` must delete those tables (run its CHECK query). Deleting in the app
deletes the one shared account, so the website account goes too.
