---
name: playstore-release-decisions
description: "Play Store launch state 2026-11-14 — com.smartlineman.lineman on KarmaPath account (no closed-test gate), OAuth clients, production draft for all countries"
metadata:
  node_type: memory
  type: project
  originSessionId: 99a527a5-89b0-485c-8931-22bf2def4dc4
  modified: 2026-11-14T13:59:09.410Z
---

Owner decisions / state for the first Play Store release:
- applicationId `com.smartlineman.lineman` (`com.smartlineman.app` is the slm_web Capacitor app). Kotlin namespace stays `com.smartlineman.app.slm_flutter`.
- Play Console developer account is "KarmaPath" (owner Google login dipnkr.das@gmail.com, account id 7297750916086113679, app id 4973552321423919953). It already has production apps, so **no 12-tester/14-day closed test gate** — production track is open directly (verified 2026-11-14).
- Google Cloud project "smartlineman" (crafty-helper-513013-k0, number 1062290108902) holds Android OAuth clients for package com.smartlineman.lineman: debug SHA-1 01:9A…, upload SHA-1 D5:B1…, Play app-signing SHA-1 B1:7D:42:21:34:37:E4:BD:88:D9:A8:65:26:E3:05:C7:9E:51:CB:EE (added 2026-11-14; fixed silent Play-build login). Consent screen left in "Testing" (name "SLM") on purpose: same project serves slm_web login; basic scopes work.
- Missing OAuth client on google_sign_in 7.x shows as `canceled [16] Account reauth failed` → app stays signed out silently.
- 2026-11-14: all App content forms, content rating (PEGI 18), data safety, Education category, contact smartlinemanapp@gmail.com, en-IN listing + 4 graphics done; production release "1.0.0 (2)" saved as draft for all countries. Owner presses Send for review.
- Reviewer account slm.playreview@gmail.com: verified + hidden in slm_app.league_settings.
- Microphone removed. Launch with Modules 1–5.

**Why:** owner wants Play Store ASAP; owner presses final submit buttons (declarations).
**How to apply:** for future releases bump versionCode, upload to production directly; never touch the shared consent screen without thinking of slm_web; see [[safety-references-wbsedcl-indian]].

- supabase/HOLD_profiles_privacy.sql must NOT be run until slm_web stops reading other users' rows from `profiles` directly.
