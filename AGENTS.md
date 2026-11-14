# AGENTS.md — read this before you change anything

**For every AI coding agent (Cursor, Claude, Codex, …) and every human working on this repo.**
These rules come from a full code audit and performance pass (Nov 2026). Breaking them has already
cost days of rework: the same per-frame slowdowns were re-introduced three times by new features.

---

## 0. The non-negotiables

1. **Pull first.** `git pull` before you start and again before you push. Never build on a stale tree. Never force-push.
2. **Green before push.** Every push must pass:
   ```bash
   flutter analyze              # 0 errors, no new warnings
   flutter test                 # ALL tests pass (test/perf, test/offline, test/duty_engine_test.dart)
   python3 -I tool/check_asset_refs.py .   # every referenced asset exists (exit 0)
   ```
   If a `test/perf` guard fails, **fix your code, not the test.** Only change a guard when the design
   genuinely changed, and then say why in a comment in the same commit.
3. **Small diffs in shared files.** `adventure_map.dart`, `ai_lineman_guide.dart`, `ladder_guide_host.dart`,
   `duty_slip_page.dart`, `ds_dress_up.dart` are edited by several people/agents. Add features surgically;
   don't reformat or restructure whole files.
4. **Never commit secrets** (service-role keys, keystores, `key.properties`, `tool/hourly_answer_keys*`).
   The Supabase anon key in `app_config.dart` is public by design; nothing else is.
5. **Game levels follow [GAME_LEVEL_PLAYBOOK.md](GAME_LEVEL_PLAYBOOK.md).** Read it before you generate, rebuild or
   change any game level: guide first (the existing mascot, no start button), full-screen scene, hints only after
   mistakes, level 1's success and reason deck, the careless coworker, existing scoring functions only, tests.

## 1. Performance rules (target: 3–4 GB Android phones)

An **idle screen must draw zero frames.** Measured before the cleanup: the ladder rebuilt 324 widgets
every frame, the mascot redrew 600/600 frames while idle, a dress-up level held 46 MB of images.

| Do | Don't |
|---|---|
| Put `AnimatedBuilder` around **only the widget that moves**; pass static subtrees as `child:` | Wrap a whole screen/page in one `AnimatedBuilder(Listenable.merge([...]))` |
| Use `CustomPaint(painter: P(repaint: controller))` for things that only repaint | `setState` every frame / every tick of a timer |
| Gate every looping controller with `slmSyncLoop(context, controller, enabled: …)` (`lib/design/motion/slm_motion_scope.dart`) — it stops loops under the OS "remove animations" setting and when the route is hidden | `AnimationController(...)..repeat()` in `initState` with no gate |
| Blink/glance/idle beats on a `Timer`, rebuilding only the face | A forever-repeating 60 fps controller for something that changes twice a second |
| `RepaintBoundary` around an animated island (mascot sprite, coin glow, background) | Let a small animation repaint the whole page |
| Decode images at display size: `cacheWidth`/`cacheHeight`, `ResizeImage`, helpers `fitImage` (`lib/features/identify/fit_image.dart`), `DsBoxDecode`, `dsThumb`; `memCacheWidth` for `CachedNetworkImage` | `Image.asset(bigPhoto)` for a 42 dp tile (that was 15 MB → now 28 KB) |
| Parse big JSON once, off the UI isolate (`compute`/`Isolate.run`), keep it in memory | `jsonDecode` an 800 KB asset on every screen open |
| Sound: `ZlFx.cue(...)` / `SlmSfx` (pooled, preloaded) | `AudioPlayer()` per tap |
| Speech: the shared TTS in `BanglaReadAloud`; lip-sync only while `MascotTalk.active` | A new `FlutterTts` per widget |
| Pause clocks/music in background (`AppLifecycleListener`, already wired in `ZlFx`/duty page) | Timers that keep running when the app is hidden |

`BackdropFilter`/blur over scrolling content is banned (use a solid translucent fill).

## 2. Assets

- **Every referenced asset must exist** — run `tool/check_asset_refs.py`. Missing sounds fail silently on
  phones (three were missing until Nov 2026).
- `pubspec.yaml` folder entries bundle **only direct children**, and everything in them ships in the APK.
  Never put READMEs, source art, PSDs or unused files inside `assets/`. Tool-only media goes in `tool/media_src/`.
- Size budget: full-screen backgrounds ≤ ~1080 px tall, tray/thumb art ≤ 512 px, JPEG q≈82, WebP q≈78,
  voice MP3 mono 24 kHz 32 kbps (`tool/voice_32k.py`), short effects Ogg Opus mono (no WAV). Re-encode **in place, keeping the filename and real format**.
- `lib/features/duty_slip/duty_slip_voice.dart` is **generated** by `tool/update_duty_slip_voice_dart.py` —
  don't hand-edit; every key that `lib/features/guide/mascot_speech_library.dart` uses must stay.

## 3. Game state, scoring, progress

- Points go through **`GameSave.addPoints`** only. Never write `ds_career_score` / `game_save_v1` from a second place.
- Save progress by **stable id** (lesson id, rung id, level number — see `ds_progress_v2`), **never by list index**.
  Adding or reordering content must never move a player's progress.
- Only show a reward (`+20`, toast, stamp) **after** the real result is saved, and only what was saved.

## 4. Offline (most users are often offline)

- **Never pass a lesson or award points without its quiz/data.** If it can't load, show a Bangla offline
  message with retry (`lesson_quiz_store.dart` caches quizzes on disk after the first download).
- **Never invent data** (no fake leaderboard people, no made-up progress). Show the last real cached data
  or an honest empty/offline state.
- No raw exception text in the UI.

## 5. Navigation and screens

- Android back must pop the nested navigator (handled by `NavigatorPopHandler` in `MainShell`) — don't
  add another root `WillPopScope`/`PopScope` that swallows it.
- Deleted on purpose — **do not re-add**: the Zero Loss game screens/engine (only `zero_loss_fx.dart` and
  `ZlColors`/`zlText` remain), the bottom tab bar/dock, hero card carousel, LevelZeroPage, the lesson shelf,
  SAFE HOME walk/quiz, Life Skill UI. Check `git log` before resurrecting anything.
- Every new screen gets a perf test in `test/perf/` if it animates.

## 6. Bangla text

UTF-8 only (never PowerShell `Set-Content`). English digits through `enDigits`. Words: ডকেট, শাটডাউন, জল,
গ্লাভস. When animating text letter-by-letter, split **by word** for Bangla, never by code point
(it breaks conjuncts and vowel signs).

## 7. Still open from the audit (pick these up, don't work around them)

- **Supabase security:** clients write `profiles.points / training_level / completed_lessons` directly
  (forgeable, and lesson completion overwrites hourly-quiz points); `profiles` may be readable across users
  (check the SELECT policy); blocking is client-side only; `submit_flutter_hourly_quiz` ends with `json || json`
  (likely errors on every submit). Fix server-side (RPCs + column grants) — coordinate with the web app.
- **Voice:** there is no online TTS (the Edge client, `NeuralTtsService` and the old `learn_runner.dart` are gone;
  `test/no_online_tts_test.dart` guards it). A better voice ships as pre-generated packs + the on-device fallback.
- **Release:** release build is signed with the debug key; no AAB / ABI split yet.
- Consolidation: 5 quiz players → one QuizRunner; SharedPreferences keys → one store; 3 colour systems → `SlmColors`.

The full audit (219 findings with file:line evidence) lives outside the repo with the maintainers; ask
before large refactors.
