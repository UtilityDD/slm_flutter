---
name: voice-and-new-text-rules
description: Owner rule 2026-11-14 — ask the owner for the natural Bangla wording of ANY new text before using it; every spoken line must be a recorded clip in the Subrata voice system
metadata:
  node_type: memory
  type: feedback
  originSessionId: 99a527a5-89b0-485c-8931-22bf2def4dc4
  modified: 2026-11-14T07:38:18.417Z
---

1. **New Bangla text:** before adding any new on-screen or spoken Bangla line (new level, new card, new button, reworded line), send the owner the draft list and ask for the natural version first. Use the owner's wording verbatim (only fix placeholders/digits and tell them).
2. **Voice:** every line the app speaks must be a recorded clip from the owner's voice system (tool/voice_system: speaker "subrata" = bn-IN-BashkarNeural +14%; coworker = bn-BD-PradeepNeural -6% -14Hz; radio = Bashkar +6%; spoken text through tool/voice_system/normalizer.py). No mix of old clips and phone TTS for guide lines.
3. Re-recording existing approved text does not need asking; changing words does.

**Why:** owner heard old text/voice (welcome screen, "এই ভিডিও মন দিয়ে শুনুন") after a partial re-record and asked for a strict voice generation guide (2026-11-14).

**How to apply:** follow VOICE_GUIDE.md in the repo; run the voice inventory + missing-clip test before any release; see [[new-levels-use-device-tts]] (superseded for guide lines by this rule) and [[playstore-release-decisions]].
