# In-app "Delete account" button: spec for the Dart change

Play requires that a user who can create an account in the app can also start account deletion
**inside the app**. This is the brief for whoever adds the button. Server side is ready in
`supabase/delete_account.sql` (`public.delete_my_account()`); the owner must run it before this
build ships. Public page: `docs/playstore/account-deletion.md` (its step list must match what you build).

Follow AGENTS.md: Bangla copy rules, `tr(bn, ...)`, no raw exception text, small diffs in shared
files, tests.

## Where

- `lib/features/more/more_screen.dart` (the Settings screen). Under the existing **লগআউট / Log out**
  button, only when `auth.isAuthenticated` (not for guests, not while `auth.offline`).
- A quiet text button, not a second big red button: `SlmButton.ghost`, label
  **অ্যাকাউন্ট মুছুন / Delete account**, icon `Icons.delete_forever_rounded`, colour `SlmColors.mist`
  so it is findable but not tapped by mistake.
- Put the dialog and the flow in a new file, e.g. `lib/features/auth/delete_account.dart`, styled
  like `sign_out_confirm.dart` (same navy dialog, `SlmButtonVariant.danger` for the confirm).

## Confirm dialog text

Title: **অ্যাকাউন্ট মুছবেন?** / **Delete your account?**

Body:
> আপনার প্রোফাইল, পয়েন্ট, শেষ করা লেভেল, লিগের সব ফল ও ব্যাজ চিরতরে মুছে যাবে। এই ফোনে রাখা খেলার তথ্যও মুছে যাবে। এটা আর ফেরানো যাবে না। একই অ্যাকাউন্ট smartlineman.in ওয়েবসাইটেও মুছে যাবে।
>
> Your profile, points, finished levels, all league results and badges will be deleted for good. Game data saved on this phone is cleared too. This cannot be undone. The same account is deleted on the smartlineman.in website.

Buttons: **হ্যাঁ, মুছুন** / **Yes, delete** (danger) and **থাক** / **Keep my account** (ghost).

Two-step safety: the danger button is disabled for 3 seconds after the dialog opens (show a small
countdown `3`, `2`, `1` with `enDigits`), or ask the user to type `DELETE` / `মুছুন`. Pick one; the
3-second hold is friendlier for field staff.

While the call runs: button shows a spinner, both buttons disabled, dialog cannot be dismissed.

## Flow

```dart
// 1. Call the RPC (needs network).
final res = await SupabaseService.client.rpc('delete_my_account');
// res is a Map: {'success': true, 'deleted': {...}}
//   or {'success': false, 'reason': 'not_signed_in' | 'admin_account' | 'no_user'}
```

1. If there is no network, or the call throws: close the spinner, keep the account, show
   **ইন্টারনেট নেই বা সার্ভারে সমস্যা। পরে আবার চেষ্টা করুন, অথবা [CONTACT_EMAIL]-এ লিখুন।** /
   **No internet or a server problem. Try again later, or write to [CONTACT_EMAIL].**
   Never show the exception text. Do not sign out.
2. `reason == 'admin_account'`: show **অ্যাডমিন অ্যাকাউন্ট অ্যাপ থেকে মোছা যায় না।** /
   **Admin accounts cannot be deleted from the app.** Stop.
3. `success == true`:
   1. Sign out locally. The server user is gone, so `auth.signOut()` to the server may fail; use
      `SupabaseService.client.auth.signOut(scope: SignOutScope.local)` inside try/catch, plus
      `GoogleSignIn.instance.signOut()` (and `disconnect()` if available, so the Google account
      picker shows again). Reuse/extend `AuthNotifier._signOutQuiet()`: add a public
      `AuthNotifier.deleteAccount()` there rather than duplicating the sign-out code.
   2. Clear local data (see below).
   3. Reset in-memory state: set auth state to guest (as `signOut()` does) and
      `ref.invalidate(gameSaveProvider)` plus any other provider that cached the old player
      (league board, lesson progress), so nothing of the old account stays on screen.
   4. Go to Home and show a toast/snackbar: **অ্যাকাউন্ট মুছে ফেলা হয়েছে।** / **Your account has been deleted.**
      Only after steps 1–3 succeeded (AGENTS.md §3: show only what really happened).

## Local data to clear

SharedPreferences (clear these keys, or `prefs.clear()` and then write the language choice back):

- `auth_profile_cache_v1` (`ProfileCache.clear()`)
- `game_save_v1`, `ds_career_score`, `ds_progress_v2` and other `ds_*` game keys (via `GameSaveController`;
  do not write `game_save_v1` from a second place, AGENTS.md §3: add a `wipe()` on the controller)
- `league_queue_v1` (unsent plays must not be sent for a deleted account), `league_wins_cache_v1`,
  `leaderboard_cache_v1`
- `local_completed_lessons`, `local_celebrated_modules`, `local_read_position`
- `identify_life_correct_v1`, `identify_life_total_v1`, `identify_best_percent_v1`
- `guide_last_welcome_day_v1` and any toolbox/key/chest keys added since

Search for every `SharedPreferences` key before you finish (`grep -rn "prefs\.\(set\|get\)" lib`).
Keep the language setting so the user is not thrown into English.

Files: the downloaded lesson and quiz packs (`<appSupport>/lesson_quiz_v1`, `<appSupport>/training_v1`)
and voice cache (`<appDocs>/neural_tts`) are public lesson content, not personal data. They may stay
(saves the user's mobile data if they sign up again). If you remove them, do it in try/catch.

## Tests

- Widget test: the button is hidden for guests and offline, shown for a signed-in profile.
- Dialog: confirm disabled for 3 s, cancel keeps everything.
- Flow with a fake client: failure keeps the session and shows the offline line; success clears
  the listed keys, ends as guest, and shows the toast once.
- No perf regression: the dialog's countdown must not rebuild the whole screen every frame
  (a `Timer` updating only the button label).

## After it ships

- Update `docs/playstore/account-deletion.md/.html` if the path or button text differs.
- In Play Console → App content → Data deletion: in-app path = Settings → Delete account;
  web URL = the hosted `account-deletion.html`.
