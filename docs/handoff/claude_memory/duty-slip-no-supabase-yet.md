---
name: duty-slip-no-supabase-yet
description: মৃত্যুহীন (duty slip) work must stay local-only for now; design storage behind an interface so Supabase can be added later
metadata:
  node_type: memory
  type: project
  originSessionId: 93dabdae-636a-44e8-ac13-8f6ec5179a6f
  modified: 2026-10-15T04:10:28.251Z
---

As of 2026-10-15 the user said: do not add মৃত্যুহীন (duty slip) scores/progress to Supabase now — "keep the structure for future implementation".

**Why:** they want the game UX solid first; server scoring/leaderboards come later.

**How to apply:** persist progress/event logs locally (shared_preferences) behind a repository interface (local impl now, Supabase impl later). Don't add RPCs, tables or network calls for duty slip until asked.

Order the user chose: improve UI/UX of the first part (cover → ladder → review sheet → play → result) BEFORE touching the field-work (level 19) page. See [[duty-slip-improvement-plan]].
