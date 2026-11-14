# মাসিক লাইনম্যান লিগ (Monthly lineman league) and cloud save

Owner-approved 2026-11-13; storage model "two rows per player, replaced on every play" approved
2026-11-14. The Rank screen is a league of **verified linemen** that counts **only level clears**.
No cash, no gifts and no real prizes anywhere in the app.

## Rules in plain words

**Who is on the board**
- Only verified linemen: the admin verified them, their role is not `pending`, they are not blocked
  (all read from the website's `public.profiles`), they are not hidden (`slm_app.league_settings.hidden`),
  and they are not an admin account.
- Guests and members not yet verified can **look** at the board but never appear on it. They see
  "যাচাই হলে আপনিও বোর্ডে উঠবেন" and, if signed in, their verification status.
- Blocking someone, or hiding them (`slm_app.admin_set_league_hidden`), takes them off every board at
  once (eligibility is checked every time a board is read).

**What counts**
- Only finished levels. For every person and every rung (level) the **best stars** are kept: the best of
  this month and the best ever.
- League points = **10 × the sum of best stars**, minus 5 for each deadly death reported with a play,
  never below 0. A play's deaths can only take back what that play added (at most 2 deaths per new
  star are counted), so a rung never goes below 0 and a better play never lowers the total. The app
  reports no deaths today (a play that ends in a death never reaches the result).
- A rung counts once a month, so replaying an easy level gives nothing more; doing it better does.
- Do levels and module gates: the stars the level already gives (1 = passed, 2 = no slips,
  3 = no slips and quick).
- Learn levels have no stars in the game, so the mark gives them: below 60 % nothing,
  a pass 1 star, 80 % or more 2 stars, a clean 100 % 3 stars.
- **Never counted:** the hourly quiz, lucky-toolbox ◆, any other ◆ total, and anything played as a guest.
- Months follow India time (Asia/Kolkata). A new month starts at 0.

**Monthly boards need 3 levels.** A player is on the monthly board once they have points and at least
**3 rungs cleared** that month. The all-time board has no minimum.

**Ties.** Points (high first), then **who reached those points first** (`reached_at`, set only when the
points go up), then fewer deaths. The screen says "সমান পয়েন্ট হলে যিনি আগে পৌঁছেছেন তিনি আগে।".

**The tabs**
- **আমার জেলা** – this month, people in the same district as you (hidden if your profile has no district).
- **সারা রাজ্য** – this month, the whole state.
- **সর্বকালের সেরা** (all-time best) – best stars on every rung ever, never reset.
- Each board shows the top 50. Your own row ("আপনি") is added below if you are lower, and the card at
  the bottom shows your place and the points to the next place.

**Districts.** `slm_app.districts` holds the 23 districts of `assets/data/wb_locations.json` with their
Bangla names and common spellings (Burdwan/Bardhaman, 24 Pgs North, Midnapore East, Calcutta, Bangla
spellings, …). The profile's district text is matched against them (case, spaces and punctuation
ignored) to one `district_key`. A spelling that matches nothing still gets a stable key
(`other:` + the cleaned text), so people who typed it the same way share a board. Add new spellings to
the `aliases` arrays in `slm_app_10_league.sql` and run it again.

**Names**
- The board shows the **approved name** (`league_settings.approved_name`) when an admin set one,
  otherwise the profile's `full_name`, as long as the member shows their name. Otherwise
  "লাইনম্যান #" and the last 4 characters of their SLM id (or of their account id).
- **First visit:** a signed-in member who never answered sees one question on the Rank screen,
  "বোর্ডে আপনার নাম দেখাবেন?" (হ্যাঁ / না). The answer is saved by `set_league_show_name`, which also
  sets `league_settings.name_asked = true`, so it is never asked again. Settings → লাইনম্যান লিগ keeps the
  switch "বোর্ডে আমার নাম দেখান".

**Monthly winners**
- When a month ends, the top 3 state-wide and the top 3 of each district are written into
  `slm_app.league_winners` (kept 24 months). They show as badges in Settings: "মাসের সেরা লাইনম্যান ·
  অক্টোবর 2026", with the place. Honour only.
- Each player's row also keeps last month's points and district/state rank. On the first 7 days of a
  month, until the player opens the Rank screen, Home shows the chip
  "নতুন মাস, নতুন লিগ · গত মাসে জেলায় #k" (without the rank part if they were not ranked).

## How it is stored (two rows per player)

| Table | Rows | What |
|---|---|---|
| `league_rungs` | one per rung, **append-only** | `rung_id`, `idx` (position in the packed stars), `min_ms`, `added_at` |
| `league_month` | **one per player** | `month`, packed `stars`, `points`, `rungs_cleared`, `deaths`, `district_key`, last month's points and ranks, `plays`, burst window, `updated_at`, `reached_at` |
| `league_all` | **one per player** | packed best-ever `stars`, `points`, `rungs_cleared`, `deaths`, `district_key`, `plays`, `reached_at`, and the **cloud save** (`cloud_save`, `cloud_save_version`, `cloud_save_at`, `cloud_progress_rank`) |
| `league_winners` | 3 per scope per month | `month`, `scope` ('state' or a district key), `rank`, `user_id`, `display_name`, `points` |
| `league_rung_counts` | one per rung per month | clears per rung, for the admin (`admin_rung_counts`) |
| `league_settings` | one per member who changed something | `show_name`, `name_asked`, `hidden`, `approved_name` |
| `districts` | 23 | `key`, `name_bn`, `name_en`, `aliases` |
| `league_meta` | 1 | the month the rollover last finished |

**Packed stars.** `stars` is a text with one character `'0'`..`'3'` per rung, at position `idx` of
`league_rungs`. 327 rungs are 327 characters. Every play rewrites the player's two rows; nothing grows.

**Append-only rung rule.** A rung keeps its `idx` forever. New levels get the next idx at the **end** of
`supabase/slm_app_11_league_rungs_seed.sql` (327, 328, …); a removed or moved level keeps its row. A
trigger refuses any UPDATE of `idx`/`rung_id` and any DELETE. `test/league_rungs_seed_test.dart`
compares the seed with the frozen list `test/fixtures/league_rungs_v1.txt` and with the catalog.
`min_ms` may be tuned at any time:
`UPDATE slm_app.league_rungs SET min_ms = 20000 WHERE rung_id = '1.1/do/0';`

Indexes: `league_month (month, district_key, points DESC, reached_at)` and
`league_all (district_key, points DESC, reached_at)` (plus state-wide ones without the district).

## Server functions (schema `slm_app`, all `SECURITY DEFINER`, RLS on every table, no table grants)

| Function | Who | What |
|---|---|---|
| `submit_level_results(p_items jsonb)` | signed in | a batch (≤ 50) of `{rung_id, stars, deaths, ms}`; returns new totals and the refused items |
| `league_board(p_scope 'district'\|'state', p_month)` | anyone | this month's top 50 (+ own row, gap to next); a finished month shows its saved top 3 |
| `league_board_all(p_scope)` | anyone | the same over best stars ever |
| `my_league()` | signed in | own month and all-time totals, last month's points and ranks, settings, `name_asked` |
| `set_league_show_name(bool)` | signed in | the name switch; also `name_asked = true` |
| `my_wins()` | signed in | own rows of `league_winners` |
| `save_progress(p_blob, p_version, p_progress_rank)` | signed in | cloud save (see below) |
| `load_progress()` | signed in | blob, version, rank, saved time |
| `admin_set_league_hidden`, `admin_set_approved_name`, `admin_rung_counts(month)` | admin email | moderation and per-level counts |

Internal only (no phone access): `league_rollover()`, `league_refusal()`, `district_key()`,
`my_district_key()`, the view `league_people`.

## Anti-cheat

Stars are still reported by the phone, as all game data is today. The server limits what a forged
client can do:
- **Eligibility** (verified, not blocked, not hidden, not admin) is checked on every submit.
- **Known rungs only**: an id not in `league_rungs` is refused (`unknown_rung`).
- **Speed**: a play faster than the rung's `min_ms` is refused (`too_fast`). The app sends the time
  from level start to result (`ms`). Seeded: Learn 8000 ms (the Learn board clock counts thinking time
  only), Do 15000 ms (the Do levels' quick-bonus times start at about 40 s), gates 30000 ms.
- **Burst cap**: about 40 accepted clears per rolling hour per player (`too_many`), counted in the
  player's own row (no extra rows).
- At most 30 points per rung, once per month. The admin can hide or block anyone whose numbers look wrong
  and can read per-level clear counts (`admin_rung_counts`).

## Traffic from the app

- A play is queued only when its stars **beat this phone's known best for that rung this month**
  (`league_known_v1`). Replays that do not improve send nothing.
- The queue is sent in **batches**: at once if nothing went in the last 30 s, otherwise when 30 s have
  passed, and whenever the app goes to the background. Offline, it waits on the phone
  (`league_queue_v1`). Plays of an earlier month or another account are dropped.
- Boards are reused for **15 minutes** (also across app starts); pull-to-refresh asks again at most
  **once a minute** per board. `my_league()` is reused for 15 minutes too.

## Monthly rollover (lazy, no cron)

The first `submit_level_results`, `league_board` or `my_league` call of a new month (India time) runs
`league_rollover()` once, under an advisory lock and guarded by `league_meta.rolled_month`:
1. for every `league_month` row of an older month: `last_month`, `last_month_points` and the district
   and state ranks (eligible players with points and ≥ 3 rungs, board order) are stored in the row;
2. that month's top 3 (state + every district) go into `league_winners`;
3. stars, points, rungs cleared, deaths and plays are reset and `month` becomes the new month;
4. winners and rung counts older than 24 months are deleted.
Running it again does nothing. A player whose row was never rolled (should not happen) is rolled by
their own next submit, without ranks.

## Cloud save (progress backup)

- What: the GameSave JSON (ladder progress, stars, ◆, deaths, mistake book, toolbox and life skills)
  plus the duty-slip progress key (`ds_progress_v2`), gzip + base64, version 1. At most **16 KB**; if it
  is bigger the oldest death-log and mistake-book entries are dropped (progress always stays), and a save
  that still does not fit is not sent. The server also refuses anything over 16 KB.
- Where: the player's one `league_all` row, written **only** by `save_progress`.
- When: at most every **3 minutes** after a level result, and when the app goes to the background.
  Signed-in members only, never guests.
- **The more advanced save wins.** `progress_rank` = furthest passed ladder position × 10000 + total
  stars. The server writes only if the new rank is at least the stored one; otherwise it answers with the
  stored rank and keeps its save.
- **Restore:** after sign-in the app calls `load_progress()`. If the server's rank is higher than this
  phone's, it asks "আগের অগ্রগতি ফিরিয়ে আনবেন?" (হ্যাঁ / এখন না). Yes writes the save on the phone and
  reloads the game. Asked once per account per app run.
- Deleted with the account (`slm_app_30_delete_account.sql`).

## SQL to run (Supabase dashboard → SQL editor)

Owner decision "Option B" (2026-11-13): everything lives in schema **`slm_app`**; the website's objects
in `public` are never changed. The league only reads `public.profiles` (verified, role, blocked,
district, full_name, slm_id) and `auth.users`, inside `SECURITY DEFINER` functions.

Run in this order. Every file is safe to run again. Nothing has been run yet.

1. `supabase/slm_app_00_schema.sql` – schema, grants, `is_admin()`, `me_verified()`.
2. `supabase/slm_app_10_league.sql` – all league tables, districts, functions above, cloud save.
3. `supabase/slm_app_11_league_rungs_seed.sql` – the 327 rungs with idx and min_ms. **Without it every
   play is refused (`unknown_rung`).** When new levels ship: append their ids with the next idx, run again.
4. `supabase/slm_app_20_toolbox_quiz.sql`, then `supabase/slm_app_30_delete_account.sql` (run its CHECK
   query first).
5. **Dashboard → Project Settings → API (Data API) → Exposed schemas: add `slm_app`.**

Until these are run, the Rank screen shows its offline state (or the last board saved on the phone),
plays wait in the phone's queue and cloud saves silently fail.

### Owner tasks

In the SQL editor (it runs as the owner, so it may write the tables directly):

```sql
-- Hide the Play reviewer test account (and any account that should not be on the board):
INSERT INTO slm_app.league_settings (user_id, hidden)
SELECT id, true FROM auth.users WHERE email = 'reviewer@example.com'
ON CONFLICT (user_id) DO UPDATE SET hidden = true, updated_at = now();

-- Pin a member's board name (NULL = use the profile's full_name again):
INSERT INTO slm_app.league_settings (user_id, approved_name)
VALUES ('<user id>', 'Rahim Mia')
ON CONFLICT (user_id) DO UPDATE SET approved_name = EXCLUDED.approved_name, updated_at = now();

-- Profiles whose district matched no known spelling (add them as aliases):
SELECT DISTINCT district_key FROM slm_app.league_month WHERE district_key LIKE 'other:%';
```

## Play Store notes

- **No prizes.** Badges are honour only. No prize wording in the store listing.
- **Moderation.** Only admin-verified people appear, with admin-approved names; the admin can block or
  hide anyone at once; the member can hide their own name.
- **Data shown publicly** (anyone with the app, including guests): display name (or "লাইনম্যান #1234"),
  district, league points and number of levels cleared. Not shown: email, phone, SLM id, account id, photo.
- **Progress backup** is stored on the server for signed-in members and deleted with the account
  (data-safety form: "App activity → other actions / game progress", collected, not shared).
- The Play reviewer test account should be hidden so it never appears.

## Limits to know

- Stars come from the phone; the checks above make forging slow and visible, not impossible.
- Two Do levels give no stars in the game (distance spot, tool tip), and the legacy duty-slip field
  nights give none either, so they add no league points yet.
- Winners and district boards use the district stored with the player's row, refreshed on every submit
  and every `my_league()` call.
- The old "this month's total points" board (`monthly_leaderboard_view`, hourly quiz) is not used by
  the Rank screen.

## Where the code is

- `lib/features/rank/league_service.dart` – rules (month, points, Learn stars, hidden name, month
  label), improvement-only queue, 30 s batching, `submit_level_results`. Wired in `main.dart`
  (`LeagueService.install()`); hears plays through `GameSaveController.onPlayResult` with the play time
  (`recordBestTime` → `recordStars` for Do/gate, the two Learn runners for marks).
- `lib/features/rank/league_board.dart` – boards (15 min cache, refresh once a minute), `my_league`,
  wins, the name switch, the Home new-month chip rule.
- `lib/features/rank/rank_screen.dart` – the three tabs, pull-to-refresh, the one-time name question.
- `lib/features/rank/league_profile.dart` – badges and the name switch in Settings.
- `lib/features/rank/cloud_save.dart` – the backup (`CloudSaveService`, `CloudSaveHost` in `main.dart`).
- Tests: `test/league_service_test.dart`, `test/rank_screen_test.dart`, `test/cloud_save_test.dart`,
  `test/league_rungs_seed_test.dart`, `test/home_screen_test.dart`, `test/more_screen_test.dart`,
  `test/slm_app_schema_guard_test.dart` (schema rule).
