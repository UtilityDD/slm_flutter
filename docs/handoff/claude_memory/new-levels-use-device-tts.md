---
name: new-levels-use-device-tts
description: "From 2026-11-06, new game levels must NOT get recorded voice clips; new lines are read aloud by Android device TTS until the user makes audio later"
metadata:
  node_type: memory
  type: project
  originSessionId: 99a527a5-89b0-485c-8931-22bf2def4dc4
  modified: 2026-11-08T02:48:49.619Z
---

**SUPERSEDED 2026-11-14:** the owner now wants every spoken line recorded in the Subrata voice system — see [[voice-and-new-text-rules]]. Kept for history.

On 2026-11-06 the user said: for all further levels, do not record audio (do not run `tool/make_learn_voice.py` / the voice dump for new lines); let the lines be read aloud by Android TTS. The user plans to create the audio later.

**Why:** the user wants to own the final voice recordings; generated Edge-TTS clips are not wanted for new content.

**How to apply:** new levels speak through `MascotSpeechLibrary.speak`, which already falls back to device TTS (`bn-IN`) when no clip exists — just don't generate clips. Keep every new fixed line in one place (a `*Lines` class / pack data) so the user can record them later; tell them which lines are unrecorded. Levels built before this date (Learn 1.1 board, kit check 1.1 কাজ 1) keep their existing clips. Related: [[duty-slip-improvement-plan]].

**Exception (2026-11-08, user approved):** the careless coworker (level 1's rival) must sound like level 1, so his lines get clips in the level 1 rival voice (`bn-BD-PradeepNeural`, -6%, -14Hz, named `r_<sha1>.mp3`, registered in `learnRivalVoice`). Make only those clips directly; do not rerun `tool/make_learn_voice.py` wholesale (it deletes clips missing from a fresh dump, which samples random lines). The guide's own new lines stay on device TTS.
