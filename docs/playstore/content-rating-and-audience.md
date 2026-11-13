# Play Console: Content rating (IARC) and Target audience

Play Console → App content. Answers match the app as of 2026-11-13. ⚠ = check before submitting.
Answer truthfully: a wrong IARC answer can get the rating changed or the app removed later.

## 1. Content rating questionnaire (IARC)

**Email:** `[CONTACT_EMAIL]` (IARC sends the certificate here).

**Category:** **Reference, News, or Educational** (matches the Education store category).
If you list it as a Game instead, pick **Game**; the answers below stay the same in substance.

| Topic | Answer | Why / what to write |
|---|---|---|
| **Violence** | **Yes**, limited | The app shows electrical accidents, shocks, falls and deaths **in a training context**: a death count, an accident sound, accident scenes in levels and lesson text about fatal accidents. No player-controlled violence against people or animals, no weapons, no combat. |
| ↳ Realistic or fantasy? | Realistic but non-graphic (stylised illustrations) | ⚠ Check the art in `assets/game/art/shock/`, `assets/game/art/aid_board/`, `assets/game/art/fire*/` and the duty-slip accident scenes: is any blood, burn injury or dead body shown in detail? |
| ↳ Blood / gore | **No** gore. ⚠ Some lesson text mentions bleeding (first aid). If any picture shows blood, answer "Yes, mild blood" in a medical/first-aid context. |
| ↳ Violence towards humans rewarded? | **No**. The game punishes unsafe acts (death count, back to checkpoint). |
| **Fear / horror** | No | Accident moments are short and instructive, not horror. |
| **Sexuality / nudity** | No | |
| **Language** (profanity, crude) | No | |
| **Controlled substances** (drugs, alcohol, tobacco) | No ⚠ | Confirm no level shows drinking or smoking on duty (a "careless coworker" smoking near a transformer would count as tobacco reference: answer "references" if so). |
| **Crude humour** | No | |
| **Gambling: real money** | **No** | No purchases of any kind, no cash, no prizes. |
| **Gambling: simulated** (casino games, betting) | **No** | The "ভাগ্যের টুলবক্স" (lucky toolbox) is a free reward chest earned by finishing levels: a quick quiz task, then pick 1 of 3 boxes holding in-game ◆ coins, a shield, a double-points token or a badge. Nothing is bought, nothing can be cashed out, there is no betting and no casino imagery. It is currently switched off (`ToolboxFlags.keysEnabled` false). ⚠ If it ships enabled, IARC may still treat randomised rewards as "loot boxes" only when bought; free ones do not need declaring. |
| **Digital purchases / in-app purchases** | **No** | No billing library, no ads. |
| **Users can interact or exchange content** | **No** | No chat, no messages, no free-text posting, no friend system. The league board only shows the admin-approved name (or "লাইনম্যান #1234"), district and points of **admin-verified** linemen; members cannot send anything to each other. ⚠ If Play asks specifically about leaderboards, answer that names are moderated (admin verification + admin-approved display name, block and hide controls). |
| **Shares user's location with other users** | **No** | No location permission. District (typed by the user) is shown on the board; that is not device location. |
| **Shares personal info with third parties** | **No** | See `data-safety.md`. |
| **Unrestricted internet access / web browser** | **No** | Embedded YouTube plays specific lesson videos. Links (WhatsApp group, a Google search of a quiz question, smartlineman.in) open in the external browser/app. ⚠ Make sure the YouTube player does not let users browse YouTube freely (related videos at the end, YouTube logo link). |

**Expected result:** roughly IARC 12+ / PEGI 12 / ESRB Teen / India's Play rating 12+, mostly
because of realistic depictions of death and injury. It may come out lower (PEGI 7) if the art is
clearly non-graphic. Either is fine for an 18+ audience; do not tune answers to get a lower rating.

## 2. Target audience and content

| Question | Answer |
|---|---|
| Target age groups | **18 and over only.** Do not tick any younger group. |
| Why | The app trains working electricity linemen (adult professionals); it covers hazardous high-voltage work. |
| Could the app unintentionally appeal to children? | **No.** The store listing and screenshots describe job training for linemen; there are no child-oriented themes. ⚠ The mascot is cartoon-style: keep it out of the first screenshot and the feature graphic is the brand shield, not the mascot. If Play's reviewer says the app may appeal to children, you will be asked for more info; answer with the adult professional purpose. |
| Ads | **No ads.** (App content → Ads: "No, my app does not contain ads".) |

## 3. Families policy note

Because only **18+** is selected, the app is **not** in the Designed for Families programme and the
Families policy requirements (Families Self-Certified Ads SDKs, COPPA-style data limits, teacher
approval) do not apply. Keep it that way: if any age group under 13 (or under 18) is ever ticked,
the Families policy applies and the following would need review first: Google sign-in for minors,
the public league board with names, the embedded YouTube player (must not show non-family content),
and the data-collection disclosures. The privacy policy already says the app is not directed at
under-18s.

## 4. Other App content declarations (same page)

| Declaration | Answer |
|---|---|
| Privacy policy | `[PRIVACY_POLICY_URL]` |
| App access | "All or some functionality is restricted" → reviewer test account (see `release-checklist.md`, App access) |
| Ads | No |
| Data safety | `data-safety.md` |
| Government apps | **No.** Not developed by or for a government body. (Listing says it is not affiliated with any utility or government.) |
| Financial features | None |
| Health apps | **No health features** ⚠ (first-aid steps are general safety training, not a medical or health-tracking feature; if the form offers "Medical: reference/education", leave it unticked unless Play insists) |
| News app | No |
| COVID-19 apps | No |
| Advertising ID | "No" (does not use advertising ID). ⚠ Confirm no `AD_ID` permission in the release manifest (`data-safety.md` note E). |
| Photo and video permissions / Foreground service / Full-screen intent / Exact alarm | Not used; no declaration needed (only `INTERNET` is requested). |
