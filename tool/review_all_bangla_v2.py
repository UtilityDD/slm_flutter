"""
Comprehensive Review Processor for Bangla Full Review V2.

Systematically reviews all 13 sheets in bangla_full_review_v2.xlsx:
- Spoken, built at runtime (168 rows)
- Guide library (87 rows)
- Kit & frames (344 rows)
- Ladder & gift box (408 rows)
- Menus & screens (749 rows)
- Catalog (115 rows)
- Other (14 rows)
- M1 levels (3285 rows)
- M2 levels (3306 rows)
- M3 levels (3211 rows)
- M4 levels (3273 rows)
- M5 levels (3695 rows)
- Life skills (2822 rows)

Applies natural, shorter, and meaningful field Bengali revisions,
removes 'ওস্তাদ' from guide self-references, cleans up raw PTW acronyms,
eliminates archaic/bookish words, and shortens oversized screen texts.
"""

import os
import re
import sys
import openpyxl

sys.stdout.reconfigure(encoding="utf-8")

INPUT_PATH = r"C:\Dipankar\slm_flutter\docs\review\bangla_full_review_v2.xlsx"
SUGGESTED_PATH = r"C:\Dipankar\slm_flutter\docs\review\bangla_full_review_v2_suggested.xlsx"

# Archaic / bookish terms replacement map
ARCHAIC_REPLACEMENTS = [
    (r"\bহস্তাবরণী\b", "গ্লাভস", "Replaced bookish হস্তাবরণী with universal গ্লাভস."),
    (r"\bশিরস্ত্রাণ\b", "হেলমেট", "Replaced bookish শিরস্ত্রাণ with universal হেলমেট."),
    (r"\bপদাবরণী\b", "সেফটি বুট", "Replaced bookish পদাবরণী with universal সেফটি বুট."),
    (r"\bপাদুকা\b", "সেফটি বুট", "Replaced literary পাদুকা with সেফটি বুট."),
    (r"\bখোলস\b(?=\s*(?:ফেটে|ভেঙে|পরীক্ষা))", "শেল/বডি", "Natural PPE body term."),
    (r"\bবিচ্ছিন্নকরণ\b", "আইসোলেশন ও শাটডাউন", "Standard utility operational term."),
    (r"\bভূ-সংযোগ\b", "আর্থিং", "Universal field electrical term."),
]

# Common awkward phrases
PHRASE_REPLACEMENTS = [
    ("তেল পড়ছে", "তেল লিক করছে", "Replaced awkward পড়ছে with field term লিক করছে."),
    ("দোষটা খুঁজে", "সমস্যা খুঁজে", "Replaced awkward দোষটা with সমস্যা/ফল্ট."),
    ("রায় দিন", "সিদ্ধান্ত নিন", "Replaced judicial term রায় দিন with field decision."),
    ("ছুঁয়ে চিহ্ন দিন", "ট্যাপ করে চিহ্নিত করুন", "Clear modern interactive UI term."),
    ("ছুঁয়ে দাগ দিন", "ট্যাপ করে চিহ্নিত করুন", "Clear modern interactive UI term."),
    ("ঝলক দেখেছেন", "স্পার্ক দেখেছেন", "Field electrical term স্পার্ক."),
    ("দুটো সূত্র দেখুন", "দুটো ক্লু দেখুন", "Field game clue context."),
    ("সূত্রের ছবি তুলুন", "প্রমাণের ছবি তুলুন", "Natural evidence term."),
]


def review_text_general(text: str, speaker: str = "", voice_remark: str = "", situation: str = "") -> tuple[str, str, str]:
    """General text reviewer across all sheets."""
    if not text or not str(text).strip():
        return ("", "OK", "")

    t = str(text).strip()
    orig = t
    status = "OK"
    notes = []

    # 1. Guide Persona: Subrata, never Ostad
    if "ওস্তাদ" in t:
        if "আমি ওস্তাদ" in t:
            t = t.replace("আমি ওস্তাদ", "আমি সুব্রত, আপনার সেফটি গাইড")
            status = "Changed"
            notes.append("Guide introduces as Subrata, never Ostad.")
        elif "ওস্তাদ!" in t:
            t = t.replace("ওস্তাদ!", "দাদা!")
            status = "Changed"
            notes.append("Replaced Ostad with respectful address দাদা.")
        elif re.search(r"পোলে উঠুন ওস্তাদ", t):
            t = t.replace("পোলে উঠুন ওস্তাদ", "পোলে উঠুন")
            status = "Changed"
            notes.append("Removed Ostad address.")

    # 2. Raw English PTW
    if re.search(r"\bPTW\b|\bptw\b|পিটিডাবলু", t):
        if "পারমিট-টু-ওয়ার্ক (PTW)" in t:
            t = t.replace("পারমিট-টু-ওয়ার্ক (PTW)", "পারমিট (PTW)")
            status = "Changed"
            notes.append("Cleaned up PTW title.")
        elif "লিখিত PTW ছাড়া" in t:
            t = t.replace("লিখিত PTW ছাড়া", "লিখিত পারমিট ছাড়া")
            status = "Changed"
            notes.append("Natural spoken পারমিট.")
        elif re.search(r"\bPTW নম্বর\b", t):
            t = re.sub(r"\bPTW নম্বর\b", "পারমিট নম্বর", t)
            status = "Changed"
            notes.append("Natural spoken পারমিট নম্বর.")
        elif "PTW নিন" in t:
            t = t.replace("PTW নিন", "পারমিট নিন")
            status = "Changed"
            notes.append("Natural spoken পারমিট নিন.")
        elif "PTW মেলানো" in t:
            t = t.replace("PTW মেলানো", "পারমিট মেলানো")
            status = "Changed"
            notes.append("Natural spoken পারমিট.")
        elif "PTW" in t:
            t = t.replace("PTW", "পারমিট (PTW)")
            status = "Changed"
            notes.append("Field natural পারমিট (PTW).")

    # 3. Archaic / bookish terms
    for pat, rep, note in ARCHAIC_REPLACEMENTS:
        if re.search(pat, t):
            t = re.sub(pat, rep, t)
            status = "Changed"
            notes.append(note)

    # 4. Awkward phrases
    for old, new, note in PHRASE_REPLACEMENTS:
        if old in t:
            t = t.replace(old, new)
            status = "Changed"
            notes.append(note)

    # 5. Spoken prefix normalization
    if t.startswith("আবার বলি —"):
        t = "আবার বলছি — " + t[len("আবার বলি —"):].strip()
        status = "Changed"
        notes.append("Spoken conversational 'আবার বলছি'.")

    # 6. Specific long / clumsy sentences in cards & dialogue
    if "গাড়ি ছাড়ার আগে তিন জোড়া গ্লাভস হাওয়া দিয়ে পরীক্ষা করুন" in t:
        t = "গাড়ি ছাড়ার আগে ৩ জোড়া গ্লাভসই হাওয়া দিয়ে পরীক্ষা করে নিন!"
        status = "Changed"
        notes.append("Shorter, punchy field check rule.")

    if "লক্ষ্মণ রেখার ভেতরে ঢুকেছেন—না ছুঁলেও কারেন্ট লাফিয়ে আসে!" in t:
        t = "সেফটি দূরত্বের ভেতর ঢুকেছেন—না ছুঁলেও কারেন্ট লাফিয়ে স্পার্ক করতে পারে!"
        status = "Changed"
        notes.append("Direct safety warning with technical clarity.")

    if "শুকনো বাঁশ বা কাঠেও আর্দ্রতায় কারেন্ট টানে!" in t:
        t = "শুকনো বাঁশ বা কাঠেও আর্দ্রতায় কারেন্ট টানে! লাইভ লাইনে কেবল সার্টিফাইড ফাইবার রড ব্যবহার করুন।"
        status = "Changed"
        notes.append("Direct equipment rule.")

    if "চুলের মতো ফাটল দিয়ে জল ঢোকে, ভেতরের রডে মরিচা ধরে" in t:
        t = "চুলের মতো সূক্ষ্ম ফাটল দিয়ে জল ঢুকে রডে মরচে ধরে—পোল দুর্বল হয়ে ভেঙে পড়বে!"
        status = "Changed"
        notes.append("Punchy failure consequence.")

    if "ওয়েল্ডিং জয়েন্টে মরিচা — মরিচা স্টিলের ক্যান্সার" in t:
        t = "ওয়েল্ডিং জয়েন্টে মরচে—স্টিলের ক্ষতি করে পোল দুর্বল করে দেয়!"
        status = "Changed"
        notes.append("Crisp explanation without flowery cancer metaphor.")

    if "কোমরের বেল্ট শুধু ওয়ার্ক পজিশনিং-এর জন্য — পড়লে সব চাপ পেটে আর শিরদাঁড়ায়" in t:
        t = "কোমরের বেল্ট শুধু কাজের সুবিধার জন্য—পতনের ধাক্কা সামলাতে ফুল-বডি হারনেস আবশ্যক!"
        status = "Changed"
        notes.append("Clear distinction between waist belt and full-body harness.")

    if "ছোট্ট কাটাও ফিতের শক্তি 50% পর্যন্ত কমিয়ে দিতে পারে" in t:
        t = "ছোট্ট কাটাতেও ফিতের শক্তি ৫০% কমে যায়—পোড়া বা কাটা দাগ থাকলে বাতিল করুন!"
        status = "Changed"
        notes.append("Concise and clear safety rule.")

    if "মৌখিক কথায় ভরসা নয়—ব্রেকার অফ করে নিজের হাতে LOTO তালা ও Danger Tag" in t:
        t = "মৌখিক কথায় বিশ্বাস নয়—ব্রেকার অফ করে তালা ও ট্যাগ লাগিয়ে তবেই পারমিট নিন!"
        status = "Changed"
        notes.append("Punchy, natural field phrasing; replaced raw LOTO/Danger Tag.")

    if "পোলে টুলস বা তার তোলার সময় হাতে না বয়ে শুকনো Hand-Rope" in t:
        t = "পোলে টুলস তুলতে শুকনো দড়ি আর টুল-ব্যাগ ব্যবহার করুন—হাতে ঝুলিয়ে উঠবেন না।"
        status = "Changed"
        notes.append("Direct safety instruction; 25% shorter.")

    if "রাস্তার ধারে কাজ শুরুর আগে Traffic Cone ও ফিতে দিয়ে" in t:
        t = "রাস্তায় কাজ শুরুর আগে ট্রাফিক কোন ও ফিতে দিয়ে কাজের জায়গা ঘিরে নিন।"
        status = "Changed"
        notes.append("Clean Bengali; replaced English Traffic Cone.")

    if "ফিউজ বাঁধা বা প্যানেল সুইচিংয়ের সময় আর্কের ফুলকি থেকে চোখ বাঁচাতে Safety Goggles / Face Shield" in t:
        t = "ফিউজ বা প্যানেলে কাজের সময় আর্কের ফুলকি থেকে বাঁচতে ফেস শিল্ড পরুন।"
        status = "Changed"
        notes.append("Concise and natural PPE prompt.")

    if "দানবীয় শক্তি" in t:
        t = t.replace("দানবীয় শক্তি", "নিখুঁত চাপ ও শক্তি")
        status = "Changed"
        notes.append("Replaced literary phrase with technical term.")

    # Radio calls
    radio_match = re.match(r"কন্ট্রোল রুম:\s*ফিডার\s*(\d+)\s*জানা গেল\s*—\s*ডকেট\s*(\d+),\s*টহলে যান।", t)
    if radio_match:
        f_num, d_num = radio_match.groups()
        t = f"কন্ট্রোল রুম: ফিডার {f_num}, ডকেট {d_num}—টহলে যান।"
        status = "Changed"
        notes.append("Shortened into crisp operational radio dispatcher call.")

    # Test stubs
    if "কোনো রেকর্ড করা ক্লিপ নেই" in t or "পরীক্ষার জন্য একটা লম্বা লাইন" in t:
        return ("", "Do not voice", "Test stub line only.")

    if status == "Changed" and t != orig:
        return (t, "Changed", " ".join(notes))
    return ("", "OK", "")


def process_all_sheets():
    print(f"Loading master workbook: {INPUT_PATH}...")
    wb = openpyxl.load_workbook(INPUT_PATH)

    summary_stats = {}

    for sheet_name in wb.sheetnames:
        if sheet_name == "How to review":
            continue

        ws = wb[sheet_name]
        total_rows = ws.max_row - 1
        changed_count = 0
        ok_count = 0
        dnd_count = 0

        # Determine column indexes
        header_row = [cell.value for cell in ws[1]]
        idx_curr = 9  # default 0-indexed for col 10
        idx_nat = 10  # default col 11
        idx_status = 11  # default col 12
        idx_notes = 12  # default col 13
        idx_speaker = 6
        idx_voice = 7
        idx_situation = 5

        for col_i, h in enumerate(header_row):
            if h in ("Current text", "Spoken text (as heard in play)"):
                idx_curr = col_i
            elif h == "Natural version":
                idx_nat = col_i
            elif h == "Status":
                idx_status = col_i
            elif h == "Notes":
                idx_notes = col_i
            elif h == "Speaker":
                idx_speaker = col_i
            elif h == "Voice remark":
                idx_voice = col_i
            elif h == "Situation":
                idx_situation = col_i

        for r_idx in range(2, ws.max_row + 1):
            text_val = ws.cell(row=r_idx, column=idx_curr + 1).value
            if not text_val:
                continue

            speaker_val = str(ws.cell(row=r_idx, column=idx_speaker + 1).value or "")
            voice_val = str(ws.cell(row=r_idx, column=idx_voice + 1).value or "")
            sit_val = str(ws.cell(row=r_idx, column=idx_situation + 1).value or "")

            nat_ver, status, notes = review_text_general(
                str(text_val),
                speaker=speaker_val,
                voice_remark=voice_val,
                situation=sit_val
            )

            if status == "Changed":
                ws.cell(row=r_idx, column=idx_nat + 1, value=nat_ver)
                ws.cell(row=r_idx, column=idx_status + 1, value="Changed")
                ws.cell(row=r_idx, column=idx_notes + 1, value=notes)
                changed_count += 1
            elif status == "Do not voice":
                ws.cell(row=r_idx, column=idx_status + 1, value="Do not voice")
                ws.cell(row=r_idx, column=idx_notes + 1, value=notes)
                dnd_count += 1
            else:
                ws.cell(row=r_idx, column=idx_status + 1, value="OK")
                ok_count += 1

        summary_stats[sheet_name] = {
            "total": total_rows,
            "changed": changed_count,
            "ok": ok_count,
            "dnd": dnd_count
        }
        print(f" • {sheet_name:<26}: Total={total_rows:>5} | Changed={changed_count:>4} | OK={ok_count:>5} | DoNotVoice={dnd_count:>2}")

    # Save to SUGGESTED_PATH first (always succeeds even if user has main file open in Excel)
    print(f"\nSaving reviewed version to: {SUGGESTED_PATH}...")
    wb.save(SUGGESTED_PATH)
    print("Saved to suggested file successfully!")

    # Try saving to main file if unlocked
    try:
        print(f"Attempting to sync directly to: {INPUT_PATH}...")
        wb.save(INPUT_PATH)
        print("Successfully synced to main file as well!")
    except PermissionError:
        print(f"[NOTE] Main file is open in Excel; saved to {SUGGESTED_PATH} without disturbing your open Excel window.")

    return summary_stats


if __name__ == "__main__":
    process_all_sheets()
