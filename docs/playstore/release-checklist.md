# SmartLineman: Play Store release checklist (now → production)

App id `com.smartlineman.lineman` · personal developer account · launch with Modules 1–5.
Work top to bottom. ⚠ = the owner must decide or check something.

Related docs in this folder: `privacy-policy.*`, `account-deletion.*`, `account-deletion-app.md`,
`data-safety.md`, `store-listing.md`, `content-rating-and-audience.md`.
Placeholders used in them: `[OWNER_NAME]`, `[CONTACT_EMAIL]`, `[EFFECTIVE_DATE]`, `[SUPABASE_REGION]`,
`[BACKUP_DAYS]`, `[PRIVACY_POLICY_URL]`, `[ACCOUNT_DELETION_URL]`, `[DELETION_FORM_URL]`.

---

## 0. Code and server blockers (before the first AAB you upload)

- [ ] **Online voice off.** `learn_runner.dart` calls `NeuralTtsService.play`, which still reaches
      Microsoft's unofficial Edge "Read Aloud" endpoint even though `neuralVoiceEnabled = false`
      (AGENTS.md §7). Make it honour the flag (device TTS only). The privacy policy and Data safety
      answers assume this.
- [ ] **Delete-account button** in Settings (`account-deletion-app.md`), and run
      `supabase/slm_app_30_delete_account.sql` (its CHECK query first). Play rejects apps with account creation
      but no in-app deletion.
- [ ] **Supabase RLS on `profiles`** (AGENTS.md §7): a signed-in user may read/update only their own
      row; anon cannot read profiles. Otherwise phone numbers leak and the privacy policy is wrong.
      This is the website's table: `supabase/HOLD_profiles_privacy.sql` is **on hold** (do not run)
      until the website reads other people's profiles through safe functions; agree it with the web
      owner. The app itself reads other people only through `slm_app` functions.
- [ ] `submit_flutter_hourly_quiz` ends with `json || json` (likely fails every submit). Fix it or hide
      the hourly quiz in this release.
- [ ] App SQL run in Supabase, in order: `slm_app_00_schema.sql` → `slm_app_10_league.sql` →
      `slm_app_11_league_rungs_seed.sql` → `slm_app_20_toolbox_quiz.sql` → `slm_app_30_delete_account.sql`,
      and `slm_app` added under Dashboard → Project Settings → API → Exposed schemas
      (see `supabase/README.md`, `docs/LEAGUE.md`).
- [ ] Modules 6–10 show "শীঘ্রই আসছে"; nothing unfinished is reachable. Radio player stays unreachable.
- [ ] Version: bump `version:` in `pubspec.yaml` (e.g. `1.0.0+1`; every upload needs a higher `+build`)
      (the pubspec comment mentions `AppConfig.appVersion`, but `app_config.dart` has no such field today).
- [ ] ⚠ **Target API level.** Play requires new apps to target a recent Android API (API 35 since
      Aug 2025; API 36 is expected from Aug 2026). Check what `flutter.targetSdkVersion` resolves to
      with the installed Flutter, and set `targetSdk` explicitly in `android/app/build.gradle.kts`
      if it is lower than Play Console asks for.
- [ ] ⚠ **16 KB page size** (required for new apps targeting Android 15+): use a current Flutter stable;
      after upload, check Play Console → App bundle explorer for a 16 KB warning.
- [ ] AGENTS.md gate: `flutter analyze` (0 errors), `flutter test` (all pass),
      `python3 -I tool/check_asset_refs.py .` (exit 0).

## 1. Upload key: verify and back up

- [ ] `android/key.properties` points to `C:/Users/rouma/keys/smartlineman/smartlineman-upload.jks`,
      alias `upload` (file exists, git-ignored). Print its fingerprint and confirm the SHA-1 is
      **D5:B1:76:E8:BD:39:EB:B6:5A:69:C0:EB:78:0B:26:2F:2F:E1:AD:82**:
      ```powershell
      keytool -list -v -keystore C:\Users\rouma\keys\smartlineman\smartlineman-upload.jks -alias upload
      ```
- [ ] **Back up** the `.jks` and both passwords in two places that are not this laptop (e.g. an
      encrypted USB stick kept at home + a password manager / encrypted cloud vault). With Play App
      Signing a lost upload key can be reset through Play support, but it takes days.
- [ ] ⚠ `PASSWORD-README.txt` sits next to the keystore in plain text. Move the passwords into a
      password manager and delete that file (and the old `key.properties.old-debug` if unneeded).
- [ ] Never commit `key.properties`, `*.jks`, `*.keystore` (already in `.gitignore`).

## 2. Google sign-in: OAuth clients for `com.smartlineman.lineman`

In Google Cloud Console, **in the same project as the Web client** used in
`AppConfig.googleWebClientId` (APIs & Services → Credentials):

- [ ] Android OAuth client: package `com.smartlineman.lineman`, SHA-1 **debug**
      `01:9A:18:77:FD:85:53:A0:44:E1:4A:81:A0:68:F0:66:D9:AF:D3:C7` (dev builds).
- [ ] Android OAuth client: package `com.smartlineman.lineman`, SHA-1 **upload**
      `D5:B1:76:E8:BD:39:EB:B6:5A:69:C0:EB:78:0B:26:2F:2F:E1:AD:82` (release builds you install yourself).
- [ ] Later (step 4): Android OAuth client with the **Play app-signing** SHA-1 (builds installed from Play).
      Without it, sign-in fails for every Play user with the "package name and SHA-1" error.
- [ ] (One client per package+SHA-1 pair; the old `com.smartlineman.app.slm_flutter` clients can stay.)
- [ ] **OAuth consent screen / Google Auth Platform → Branding:** app name SmartLineman, support email,
      logo (optional), home page `https://smartlineman.in`, privacy policy `[PRIVACY_POLICY_URL]`,
      authorised domain `smartlineman.in` (and the policy host's domain if different).
      Scopes: `openid`, `email`, `profile` only (non-sensitive).
- [ ] **Audience → Publishing status = "In production".** In "Testing" only listed test users can sign in,
      so testers and reviewers would fail.
- [ ] Supabase → Authentication → Providers → Google: enabled; **Client IDs** contains the Web client id
      (the id token's audience); "Skip nonce checks" on (the app shows this hint if it is off).
      URL Configuration → Redirect URLs contains `com.smartlineman.lineman://login-callback`.
- [ ] Test: release APK signed with the upload key → Google sign-in works on the Oppo phone.

## 3. Play Console: create the app

- [ ] Developer account: identity and phone verified (personal account).
- [ ] Create app: name **SmartLineman** (store name can be longer later), default language ⚠ Bengali
      (pick the Bengali locale Play offers; if only `bn-BD` exists, use English (India) as default and add
      Bengali as a translation), **App**, **Free**, accept declarations.
- [ ] Free is permanent: a free app cannot later become paid.

## 4. Play App Signing

- [ ] Keep the default: **Google generates and holds the app-signing key**; you upload with the upload key.
- [ ] After the first AAB is uploaded (step 6): Setup → App signing → copy the **App signing key
      certificate SHA-1** → add the third Android OAuth client (step 2). Also note the upload key SHA-1
      shown there matches D5:B1:…:AD:82.
- [ ] Record the app-signing SHA-1 here: `__:__:…` ⚠

## 5. Build the bundle

```powershell
$env:Path = "$env:USERPROFILE\flutter\bin;" + $env:Path
flutter clean
flutter pub get
flutter build appbundle --release
```

- [ ] Output: `build/app/outputs/bundle/release/app-release.aab`.
- [ ] **Check it is signed with the upload key, not the debug key** (the Gradle file silently falls back
      to debug if `key.properties` is missing):
      ```powershell
      keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
      ```
      SHA-1 must be D5:B1:…:AD:82, never 01:9A:…:C3:C7.
- [ ] Check the merged manifest has only `INTERNET` (no `RECORD_AUDIO`, no `AD_ID`): Android Studio →
      Build → Analyze APK → open the AAB.
- [ ] Smoke test a release build on the phone (R8 minify is on): sign-in, a Learn level with video,
      a Do level, league board, offline start, delete account with a throwaway account.

## 6. Internal testing

- [ ] Testing → Internal testing → create release → upload the AAB → release notes (Bangla + English).
- [ ] Testers: an email list with the owner and 2–3 helpers. Share the opt-in link; install from Play.
- [ ] Do step 4 (app-signing SHA-1 → OAuth client), then confirm **Google sign-in works on the
      Play-installed build**.
- [ ] Check Play Console → Pre-launch report for crashes and accessibility warnings.

## 7. App content (can be filled while testing runs; needed before closed testing review)

- [ ] **Privacy policy:** host `privacy-policy.html` (GitHub Pages, Google Sites, or
      `https://smartlineman.in/privacy`), public, no login, not a PDF. Fill all placeholders first.
      Paste the URL in App content → Privacy policy and in the store listing.
- [ ] **Data deletion:** host `account-deletion.html`; create the Google Form (fields in the page's
      comment); paste URL in App content → Data safety → Delete account URL.
- [ ] **App access:** "All or some functionality is restricted". Create the reviewer account:
  - [ ] A new Gmail account just for reviewers (e.g. `smartlineman.review@gmail.com` ⚠ name), strong
        password, **2-Step Verification off** (reviewers cannot receive codes) and a recovery
        phone/email the owner controls.
  - [ ] Sign in once in the app so the profile row exists, then in Supabase SQL editor:
        ```sql
        UPDATE public.profiles
        SET verified = true, role = 'lineman', district = 'Kolkata', job = 'Others',
            full_name = 'Play Reviewer'
        WHERE id = (SELECT id FROM auth.users WHERE email = 'smartlineman.review@gmail.com');

        INSERT INTO slm_app.league_settings (user_id, hidden)
        SELECT id, true FROM auth.users WHERE email = 'smartlineman.review@gmail.com'
        ON CONFLICT (user_id) DO UPDATE SET hidden = true, updated_at = now();
        ```
        (`hidden` keeps it off every board; phones cannot change it, only the dashboard or an admin.)
        ⚠ Use a district value that exists in `assets/data/wb_locations.json`.
  - [ ] Instructions for Play: "Guest mode needs no login: tap Home → মৃত্যুহীন পথ. To test sign-in:
        Home toolbox → Settings → Sign in with Google → use the account below. The account is
        pre-verified and hidden from the public league. Account deletion: Settings → Delete account
        (please do not delete this account; or tell us and we will recreate it)."
  - [ ] Never delete or change this account while a review is pending.
- [ ] **Ads:** No ads.
- [ ] **Content rating:** `content-rating-and-audience.md` §1.
- [ ] **Target audience:** 18+ only (§2).
- [ ] **Data safety:** `data-safety.md` (resolve its ⚠ notes first).
- [ ] **Government apps:** No. **Financial features:** none. **Health:** none ⚠. **News:** No.
- [ ] **Advertising ID:** does not use.

## 8. Store listing

- [ ] `store-listing.md`: name, short and full description (Bangla default + English translation).
- [ ] App icon 512×512, feature graphic 1024×500, 8 phone screenshots (shot list in the file).
- [ ] Category **Education**, tags, contact email, website.
- [ ] Store settings → countries: **India** only for the first release ⚠.

## 9. Closed testing: 12 testers × 14 days (personal accounts)

- [ ] Testing → Closed testing → create a track (e.g. "Linemen beta") → promote the internal build
      or upload a new one → send for review (first closed release is reviewed: allow a few days).
- [ ] Testers: **at least 12 people opted in continuously for 14 days** (aim for 20 to be safe, since
      people drop out). Use a Google Group (easiest to manage) or an email list; real linemen and
      colleagues are ideal. Each must accept the opt-in link **and install from Play**.
- [ ] Keep a simple log: tester count per day, feedback received, what you changed. You need it for
      the production questions.
- [ ] Ship at least one update during the 14 days in response to feedback (bump `+build`).
- [ ] Day 14 passes only after 14 days with ≥ 12 opted-in testers; the Dashboard shows the progress.

## 10. Apply for production (personal account questions)

Dashboard → "Apply for production" unlocks after step 9. Expect questions like these; answer from
your log, in plain English:

- [ ] How did you recruit testers? (e.g. linemen colleagues in [districts], via a WhatsApp group and a
      Google Group.)
- [ ] How easy was it to recruit? How engaged were testers (installs, sessions, feedback)?
- [ ] Summary of feedback and how you collected it (WhatsApp group, email, Play private feedback).
- [ ] Who is the intended audience? (Adult electricity distribution linemen in West Bengal.)
- [ ] How does the app provide value? (Bangla, offline-friendly job-safety training as a game.)
- [ ] Expected installs in the first year. ⚠
- [ ] What changed based on testing? (List the updates.)
- [ ] How did you decide the app is ready for production?
- [ ] Production review can take up to 7 days or more.

## 11. Production rollout

- [ ] Production → create release → promote the tested build.
- [ ] **Staged rollout:** 10 % → watch Android vitals (crash rate, ANR) and sign-in for 2–3 days →
      50 % → 100 %.
- [ ] Watch: Supabase Auth logs (sign-in errors), new profiles waiting for verification (admin panel),
      league submits (`unknown_rung` means `slm_app_11_league_rungs_seed.sql` needs new ids).
- [ ] Reply to reviews; keep `[CONTACT_EMAIL]` monitored (deletion requests: answer within 30 days,
      run `SELECT slm_app.delete_user_data(...)` from `supabase/slm_app_30_delete_account.sql`).

## After launch (keep in mind)

- Every new level id must be added to `slm_app_11_league_rungs_seed.sql` (and that file run) before the build ships.
- Any new data collected, SDK added, or permission requested → update `privacy-policy.*` and
  Data safety **before** releasing that build.
- Keep the target API level current every August (Play's yearly deadline).
- Edge-TTS voice licence (memory note): recorded clips made with edge-tts need a licence check before
  wider release ⚠.
