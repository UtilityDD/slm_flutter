# মাসিক লাইনম্যান লিগ (Monthly lineman league)

Owner-approved 2026-11-13. The Rank screen is now a league of **verified linemen** that counts
**only level clears**. No cash, no gifts and no real prizes anywhere in the app.

## Rules in plain words

**Who is on the board**
- Only verified linemen: the admin verified them, their role is not `pending`, they are not blocked,
  `league_hidden` is off, and they are not an admin account.
- Guests and members not yet verified can **look** at the board but never appear on it. They see
  "যাচাই হলে আপনিও বোর্ডে উঠবেন" and, if signed in, their verification status.
- Blocking someone, or turning `league_hidden` on, takes them off every board at once (the board is
  worked out every time it is read).

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
- The board shows the **admin-approved name**: the name the person had when the admin verified them
  (people verified before the league keep their current name). If they change their name later, the
  board keeps the approved one until an admin approves the new one (see below).
- Anyone can turn off "বোর্ডে আমার নাম দেখান" in Settings → লাইনম্যান লিগ. The board then shows
  "লাইনম্যান #" and the last 4 characters of their SLM id (or of their account id).
- District comes from the profile.

**Monthly winners**
- After a month ends, the top 3 state-wide and the top 3 of each district get a badge row on their
  profile (Settings): "মাসের সেরা লাইনম্যান · অক্টোবর 2026", with the place. This is honour only.
- Worked out from the saved results when the profile opens; no scheduled job is needed.

## SQL to run (Supabase dashboard → SQL editor)

Run in this order. Every file is safe to run again.

1. `supabase/verify_lineman.sql` and `supabase/block_user.sql` – already run before; needed for the
   `verified` and `blocked` columns (league.sql also adds them if missing, same defaults).
2. **`supabase/league.sql`** – profile columns `league_hidden`, `league_show_name`, `league_name`;
   the trigger that protects them; tables `league_level_best` (monthly) and `league_level_best_all`
   (all-time), both with RLS on and no direct access; `league_rungs`; the functions
   `submit_level_result`, `league_board`, `league_board_all`; the views `league_monthly_winners`
   (internal) and `league_my_wins` (each member reads only their own wins).
3. **`supabase/league_rungs_seed.sql`** – the 327 rung ids in today's catalog. While this table has rows,
   the server accepts only these ids. **When new levels ship, add their ids and run it again**, or plays
   of the new levels will be refused (`unknown_rung`). If the table is empty, any id matching the rung
   pattern is accepted.

Until league.sql is run, the Rank screen shows its offline state (or the last board saved on the phone),
and finished plays wait in the phone's queue.

### Owner tasks in the dashboard

```sql
-- Hide the Play reviewer test account (and any account that should not be on the board):
UPDATE public.profiles SET league_hidden = true
WHERE id = (SELECT id FROM auth.users WHERE email = 'reviewer@example.com');

-- Approve a member's new name for the board:
UPDATE public.profiles SET league_name = btrim(full_name) WHERE id = '<user id>';

-- Or set the board name directly:
UPDATE public.profiles SET league_name = 'Rahim Mia' WHERE id = '<user id>';
```

Phones cannot change `league_hidden` or `league_name` (the trigger puts them back); the dashboard, the
admin accounts and the admin functions can. Members can change `league_show_name` themselves.

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
- The Play reviewer test account should have `league_hidden = true` so it never appears.

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
  the offline queue and `submit_level_result`. Wired in `main.dart` (`LeagueService.install()`); hears plays
  through `GameSaveController.onPlayResult` (`recordStars` for Do/gate, the two Learn runners for marks).
- `lib/features/rank/league_board.dart` – reads the boards and wins, keeps the last real copy offline.
- `lib/features/rank/rank_screen.dart` – the three tabs.
- `lib/features/rank/league_profile.dart` – badges and the name switch in Settings.
- Tests: `test/league_service_test.dart`, `test/rank_screen_test.dart`.
