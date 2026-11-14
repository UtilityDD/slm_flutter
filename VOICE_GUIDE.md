# VOICE_GUIDE.md — how every spoken line is made (strict)

Owner rules (2026-11-14). Every agent follows this before adding, changing or recording any line.

## 1. Two rules that come first
1. **New Bangla text → ask the owner first.** Any new on-screen or spoken line (new level, card, button,
   reworded line) is sent to the owner as a draft list. The owner writes the natural version; use it verbatim
   (only fix `${...}` placeholders and English digits, and say so).
2. **Every spoken line is a recorded clip in the owner's voice system.** The phone's TTS is only an emergency
   fallback (offline voice pack not yet downloaded). No mix of old clips and phone voice for guide lines.

## 2. Speakers (tool/voice_system/speakers.py — the single source)
| Speaker | Who | Edge voice | Rate | Pitch |
|---|---|---|---|---|
| `subrata` | the guide / coach (all guide lines, duty slip, praise, warnings, mistake cards read aloud) | bn-IN-BashkarNeural | +14% | +0Hz |
| `coworker` | the careless coworker / rival (two-beat pressure lines) | bn-BD-PradeepNeural | -6% | -14Hz |
| `radio` | control-room radio | bn-IN-BashkarNeural | +6% | +0Hz |

Spoken text always goes through `tool/voice_system/normalizer.py` (`normalize_speech_text`): PTW → পি টি ডাবলু,
kV → কেভি, DO → ডি-ও … The **screen keeps the original text**; only the audio uses the normalised words.

## 3. Where clips live and how they are found
- Guide/coach lines keyed by text: `assets/sounds/learn_voice/c_<sha1(text)[:10]>.mp3`, listed in
  `learnCoachVoice` (`lib/features/game/learn_voice_map.dart`).
- Coworker lines keyed by text: `r_<sha1>.mp3`, listed in `learnRivalVoice` (record with `tool/rival_clip.py`).
- Duty-slip / guide-voice cues: `assets/sounds/voice/ds_*.mp3` and `assets/sounds/guide_voice/*.mp3`, listed in
  `lib/features/duty_slip/duty_slip_voice.dart` (generated from `tool/game_voice_catalog.json` by
  `tool/update_duty_slip_voice_dart.py` — edit the catalog, never the generated file by hand).
- `MascotSpeechLibrary.speak` looks up the clip by voiceKey or exact text; only when none exists does it fall
  back to the phone voice (guide) or a silent caption (coworker).
- Format: MP3 mono 24 kHz 48 kbps (Edge default). Keep file names when re-recording the same line.

## 4. The pipeline (in this order)
1. **Inventory** — run the suite with the switch on:
   `flutter test --concurrency=3 --dart-define=SLM_VOICE_INVENTORY=<file.jsonl>`
   Every line the app asks to speak is logged with whether a clip covers it.
2. **Review sheet** — `tool/bangla_review_export.py` + the inventory → a sheet with a Voice remark per line
   (✅ recorded · 🎙 needs recording · ❓ possibly spoken · 🖥 screen only). The owner fills "Natural version".
3. **Apply wording** — change the code text first (by file + line), keep placeholders, English digits.
4. **Record** — only lines the owner approved; correct speaker; normalised spoken text; add map entries;
   delete clips whose text is gone (no unused assets).
5. **Check** — `python -I tool/check_asset_refs.py .`, `test/voice_coverage_test.dart`, then the full suite.
6. **Update** `tool/voice_inventory.json` (the committed list of spoken lines) and `tool/voice_pending.json`.

## 5. Never
- Never re-run `tool/make_learn_voice.py` wholesale (it deletes clips for lines missing from its old list).
- Never run `tool/slm_voice.py update-dart` or `generate --target all --force` while its catalog is built from
  the stale `tool/learn_voice_lines.json` — it would drop hundreds of coworker/guide clips.
- Never record a line whose wording the owner has not approved.
- Never ship a guide line that is spoken but has no clip unless it is listed in `tool/voice_pending.json`
  (the to-do list that must only shrink).

## 6. Size budget
Bundled clips stay under ~60 MB in the app. If the approved list is larger, the rest ships as one voice pack
per module (downloaded once when the module opens, cached for offline; phone voice only until it arrives).

## 7. Out of scope
Full lesson read-aloud in the lesson reader (long, changing lesson text) uses the phone voice. Life-skill
lessons have their own full audio tracks (streamed from GitHub, cached).
