# মাসিক লাইনম্যান লিগ (Monthly lineman league)

Owner-approved 2026-11-13. The Rank screen is now a league of **verified linemen** that counts
**only level clears**. No cash, no gifts and no real prizes anywhere in the app.

## Rules in plain words

**Who is on the board**
- Only verified linemen: the admin verified them, their role is not `pending`, they are not blocked
  (all read from the website's `public.profiles`), they are not hidden (`slm_app.league_settings.hidden`),
  and they are not an admin account.
- Guests and members not yet verified can **look** at the board but never appear on it. They see
  "যাচাই হলে আপনিও বোর্ডে উঠবেন" and, if signed in, their verification status.
- Blocking someone, or hiding them (`slm_app.admin_set_league_hidden`), takes them off every board at
  once (the board is worked out every time it is read).

**What counts**
- Only finished levels. For every person and every rung (level), the **best play of the month** is kept.
- League points of a rung = **stars × 10**, minus 5 for each deadly death in that play, never below 0.
  A rung counts once a month, so replaying an easy level gives nothing more; doing it better does.
- Do levels and module gates: the stars the level already gives (1 = passed, 2 = no slips,
  3 = no slips and quick).
- Learn levels have no stars in the game, so the mark gives them: below 60 % nothing,
  a pass 1 star, 80 % or more 2 stars, a clean 100 % 3 stars.
- A play that ends in a death never reaches the result, so it scores nothing. The −5 rule is in the
  server for plays that report deaths.
- **Never counted:** the hourly quiz, lucky-toolbox ◆, any other ◆ total, and anything played as a guest.
- Months follow India time (Asia/Kolkata). A new month starts empty; nothing carries over.
- Plays made offline wait on the phone and are sent on the next app start or the next finished level.
  A play still waiting when the month ends is dropped, because the server would count it in the wrong month.

**The tabs**
- **আমার জেলা** – this month, people whose profile district is the same as yours (hidden if you
  have no district).
- **সারা রাজ্য** – this month, the whole state.
- **সর্বকালের সেরা** (all-time best) – best stars on every rung ever, never reset:
  best stars × 10 per rung. The same people are eligible, and the quiz and ◆ do not count here either.
- Each board shows the top 100. Your own row ("আপনি") is added below if you are lower, and the card at
  the bottom shows your place and the points to the next place.
- Ties: more rungs cleared first, then whoever got there first.

**Names**
- The board shows the **approved name**: `slm_app.league_settings.approved_name` when an admin set one,
  otherwise the profile's `full_name` (only verified people are on the board, so it is the name the admin
  saw when verifying). Nothing on the website has to change for this.
- Trade-off of Option B: there is no trigger on `public.profiles` any more, so a name edited after
  verification reaches the board unless an admin pins one with `slm_app.admin_set_approved_name`.
  The admin can block or hide anyone at once.
- Anyone can turn off "বোর্ডে আমার নাম দেখান" in Settings → লাইনম্যান লিগ
  (`slm_app.set_league_show_name`, read back with `slm_app.my_league_settings`). The board then shows
  "লাইনম্যান #" and the last 4 characters of their SLM id (or of their account id).
- District comes from the profile.

**Monthly winners**
- After a month ends, the top 3 state-wide and the top 3 of each district get a badge row on their
  profile (Settings): "মাসের সেরা লাইনম্যান · অক্টোবর 2026", with the place. This is honour only.
- Worked out from the saved results when the profile opens; no scheduled job is needed.

## SQL to run (Supabase dashboard → SQL editor)

Owner decision "Option B" (2026-11-13): everything the league needs lives in the schema **`slm_app`**;
the website's objects in `public` are never changed. The league only reads `public.profiles`
(verified, role, blocked, district, full_name, slm_id) and `auth.users`, inside `SECURITY DEFINER`
functions. See `supabase/README.md`.

Run in this order. Every file is safe to run again. Nothing has been run yet.

1. **`supabase/slm_app_00_schema.sql`** – the schema, grants, default privileges, `slm_app.is_admin()`
   and `slm_app.me_verified()`.
2. **`supabase/slm_app_10_league.sql`** – tables `league_level_best` (monthly), `league_level_best_all`
   (all-time), `league_rungs` and `league_settings` (name switch, hidden, approved name), all with RLS on
   and no direct access; the functions `submit_level_result`, `league_board`, `league_board_all`,
   `set_league_show_name`, `my_league_settings`, `league_my_wins`, and the admin-only
   `admin_set_league_hidden`, `admin_set_approved_name`; the internal views `league_people` and
   `league_monthly_winners`.
3. **`supabase/slm_app_11_league_rungs_seed.sql`** – the 327 rung ids in today's catalog. While this table
   has rows, the server accepts only these ids. **When new levels ship, add their ids and run it again**,
   or plays of the new levels will be refused (`unknown_rung`). If the table is empty, any id matching the
   rung pattern is accepted.
4. `supabase/slm_app_20_toolbox_quiz.sql`, `supabase/slm_app_30_delete_account.sql` – not league, but
   the same run (00 → 10 → 11 → 20 → 30).
5. **Dashboard → Project Settings → API (Data API) → Exposed schemas: add `slm_app`.** Without it the
   app cannot reach any of these functions.

`supabase/HOLD_profiles_privacy.sql` is **on hold, do not run** (it would change the website's
`profiles` policies; see its header and `supabase/README.md`). The league does not need it.

Until these are run, the Rank screen shows its offline state (or the last board saved on the phone),
and finished plays wait in the phone's queue.

### Owner tasks

In the SQL editor (it runs as the owner, so it may write the table directly; the admin functions
refuse there because `auth.jwt()` is empty):

```sql
-- Hide the Play reviewer test account (and any account that should not be on the board):
INSERT INTO slm_app.league_settings (user_id, hidden)
SELECT id, true FROM auth.users WHERE email = 'reviewer@example.com'
ON CONFLICT (user_id) DO UPDATE SET hidden = true, updated_at = now();

-- Pin a member's board name (NULL = use the profile's full_name again):
INSERT INTO slm_app.league_settings (user_id, approved_name)
VALUES ('<user id>', 'Rahim Mia')
ON CONFLICT (user_id) DO UPDATE SET approved_name = EXCLUDED.approved_name, updated_at = now();
```

For a future admin screen (an admin email's session): `slm_app.admin_set_league_hidden(p_user_id, p_hidden)`
and `slm_app.admin_set_approved_name(p_user_id, p_name)`. The admin screen does not call them yet. Phones cannot change `hidden` or `approved_name`
(no table access, and those functions check `slm_app.is_admin()`). Members change only their own
`show_name`.

## Play Store notes

- **No prizes.** No cash, vouchers, gifts or real-world rewards. Badges are honour only. Do not add
  prize wording in the store listing either (a prize contest would need official rules and more review).
- **Moderation.** Only admin-verified people appear. Names are the admin-approved ones, not free text
  typed later. The admin can block a person or hide them from the board at once. The member can hide
  their own name.
- **Data shown publicly** (anyone with the app, including guests, can see it): display name (or
  "লাইনম্যান #1234"), district, league points and number of levels cleared. Not shown: email, phone,
  SLM id, account id, photo. Mention this in the Data safety form ("name and district are shown on a
  public in-app leaderboard; the user can hide the name").
- The Play reviewer test account should be hidden (`slm_app.league_settings.hidden = true`) so it never appears.

## Limits to know

- Stars are reported by the phone, as all game data is today. A verified person could still send fake
  stars for real rungs (at most 30 points per rung). The rung whitelist stops made-up rungs, and the admin
  can block anyone whose numbers look wrong.
- Two Do levels give no stars in the game (distance spot, tool tip), and the legacy duty-slip field nights
  give none either, so they add no league points yet. Giving them stars would fix that.
- Winners and district boards use the person's **current** district and eligibility.
- The old "this month's total points" board (`monthly_leaderboard_view`, hourly quiz) is no longer used
  by the Rank screen. The quiz code is kept; another change hides the quiz screen.

## Where the code is

- `lib/features/rank/league_service.dart` – rules (month, points, Learn stars, hidden name, month label),
  the offline queue and `slm_app.submit_level_result`. Wired in `main.dart` (`LeagueService.install()`); hears plays
  through `GameSaveController.onPlayResult` (`recordStars` for Do/gate, the two Learn runners for marks).
- `lib/features/rank/league_board.dart` – reads the boards, wins and the name switch
  (`leagueShowNameProvider`), keeps the last real copy offline. Every call is
  `SupabaseService.client.schema('slm_app').rpc(...)`.
- `lib/features/rank/rank_screen.dart` – the three tabs.
- `lib/features/rank/league_profile.dart` – badges and the name switch in Settings.
- Tests: `test/league_service_test.dart`, `test/rank_screen_test.dart`, `test/more_screen_test.dart`,
  `test/slm_app_schema_guard_test.dart` (schema rule).
