"""
SLM Bangla Full Review V2 Processor.

Applies natural, shorter, and meaningful field Bengali revisions across
all sheets in C:\\Dipankar\\slm_flutter\\docs\\review\\bangla_full_review_v2.xlsx.
"""

import os
import re
import sys
import openpyxl

sys.stdout.reconfigure(encoding="utf-8")

WORKBOOK_PATH = r"C:\Dipankar\slm_flutter\docs\review\bangla_full_review_v2.xlsx"


def review_spoken_runtime_text(text: str) -> tuple[str, str, str]:
    """Reviews Spoken, built at runtime lines. Returns (natural_version, status, notes)."""
    t = text.strip()
    status = "OK"
    notes = ""
    orig = t

    # Test dummy lines
    if "কোনো রেকর্ড করা ক্লিপ নেই" in t or "পরীক্ষার জন্য একটা লম্বা লাইন" in t:
        return ("", "Do not voice", "Test stub line only.")

    # 1. Transform 'আবার বলি —' to natural spoken 'আবার বলছি —'
    if t.startswith("আবার বলি —"):
        t = "আবার বলছি — " + t[len("আবার বলি —"):].strip()
        notes = "Natural spoken 'আবার বলছি' prompt."
        status = "Changed"

    # 2. Awkward terms
    replacements = [
        ("তেল পড়ছে", "তেল লিক করছে", "Replaced awkward পড়ছে with field term লিক করছে."),
        ("দোষটা খুঁজে", "সমস্যা খুঁজে", "Replaced awkward দোষটা with সমস্যা/ফল্ট."),
        ("রায় দিন", "সিদ্ধান্ত নিন", "Replaced judicial term রায় দিন with field decision."),
        ("ছুঁয়ে চিহ্ন দিন", "ট্যাপ করে চিহ্নিত করুন", "Clear modern interactive UI term."),
        ("ছুঁয়ে দাগ দিন", "ট্যাপ করে চিহ্নিত করুন", "Clear modern interactive UI term."),
        ("পুরো শেলটা", "পুরো বডি", "Natural PPE body term."),
        ("PTW", "পারমিট", "Replaced raw English PTW with natural spoken পারমিট."),
        ("লক্ষ্মণ রেখা কতদূর?", "নিরাপদ দূরত্ব কত?", "Direct safety distance terminology."),
        ("ঝলক দেখেছেন", "স্পার্ক দেখেছেন", "Field electrical term স্পার্ক."),
        ("কেবিলটা ছিলতে", "কেব্‌ল ছিলতে", "Spelling normalization."),
        ("কেবিলটা লাগের মাপে ছিলুন", "কেব্‌ল লাগের মাপে ছিলুন", "Natural spelling."),
        ("দুটো সূত্র দেখুন", "দুটো ক্লু দেখুন", "Field game context clue."),
        ("সূত্রের ছবি তুলুন", "প্রমাণের ছবি তুলুন", "Natural evidence term."),
    ]

    for old, new, note in replacements:
        if old in t:
            t = t.replace(old, new)
            status = "Changed"
            notes = (notes + " " + note).strip()

    # 3. Radio prompts shortening: "কন্ট্রোল রুম: ফিডার 1 জানা গেল — ডকেট 322, টহলে যান।"
    radio_match = re.match(r"কন্ট্রোল রুম:\s*ফিডার\s*(\d+)\s*জানা গেল\s*—\s*ডকেট\s*(\d+),\s*টহলে যান।", t)
    if radio_match:
        f_num, d_num = radio_match.groups()
        t = f"কন্ট্রোল রুম: ফিডার {f_num}, ডকেট {d_num}—টহলে যান।"
        status = "Changed"
        notes = "Shortened into crisp operational radio dispatcher call."

    # 4. Repetitive long lines: RUN-0166
    if "হাতলের ইনসুলেশন কাটা — ইনসুলেশন ঠিক না থাকলে ব্যবহার নয়" in t:
        t = "হাতলের ইনসুলেশন কাটা থাকলে ব্যবহার করবেন না। ফাটল বা পোড়া দাগ আছে কি না দেখুন।"
        status = "Changed"
        notes = "Removed redundant repetition; 35% shorter."

    if status == "Changed" and t != orig:
        return (t, "Changed", notes)
    return ("", "OK", "")


def review_guide_library_text(text: str) -> tuple[str, str, str]:
    """Reviews Guide library lines. Returns (natural_version, status, notes)."""
    t = text.strip()
    status = "OK"
    notes = ""
    orig = t

    # 1. Guide persona: Never Ostad
    if "ওস্তাদ" in t:
        if "আমি ওস্তাদ" in t:
            t = t.replace("আমি ওস্তাদ", "আমি সুব্রত, আপনার সেফটি গাইড")
            notes = "User directive: Guide name is Subrata, never Ostad."
        else:
            t = t.replace("ওস্তাদ!", "দাদা!").replace("ওস্তাদ", "দাদা")
            notes = "Replaced Ostad with natural respectful address দাদা."
        status = "Changed"

    # 2. Raw acronyms in Guide tips
    if "PTW" in t or "ptw" in t:
        t = re.sub(r"\bPTW\b|\bptw\b", "পারমিট", t)
        status = "Changed"
        notes = (notes + " Replaced raw PTW with natural পারমিট.").strip()

    # 3. Old literary terms
    archaic_map = {
        "হস্তাবরণী": ("গ্লাভস", "Replaced archaic textbook word with universal field term."),
        "শিরস্ত্রাণ": ("হেলমেট", "Replaced archaic textbook word with universal field term."),
        "পাদুকা": ("সেফটি বুট", "Replaced archaic textbook word with universal field term."),
        "নিরাপত্তা বেল্ট": ("ফুল-বডি হারনেস", "Accurate modern safety PPE term."),
        "বিচ্ছিন্নকরণ": ("আইসোলেশন ও শাটডাউন", "Standard utility operational term."),
        "ভূ-সংযোগ": ("আর্থিং", "Universal field electrical term."),
    }
    for old, (new, note) in archaic_map.items():
        if t == old:
            return (new, "Changed", note)
        elif old in t:
            t = t.replace(old, new)
            status = "Changed"
            notes = (notes + " " + note).strip()

    # 4. Long / stiff guide tips
    if "মৌখিক কথায় ভরসা নয়" in t:
        t = "মৌখিক কথায় বিশ্বাস নয়—ব্রেকার অফ করে তালা ও ট্যাগ লাগিয়ে তবেই পারমিট নিন!"
        status = "Changed"
        notes = "Punchier, natural lineman phrasing; replaced raw LOTO/Danger Tag."

    if "পোলে টুলস বা তার তোলার সময়" in t:
        t = "পোলে টুলস তুলতে শুকনো দড়ি আর টুল-ব্যাগ ব্যবহার করুন—হাতে ঝুলিয়ে উঠবেন না।"
        status = "Changed"
        notes = "Direct, natural safety instruction; 25% shorter."

    if "রাস্তার ধারে কাজ শুরুর আগে Traffic Cone" in t:
        t = "রাস্তায় কাজ শুরুর আগে ট্রাফিক কোন ও ফিতে দিয়ে কাজের জায়গা ঘিরে নিন।"
        status = "Changed"
        notes = "Short, clean Bengali; replaced English Traffic Cone and Lakshman Rekha."

    if "ফিউজ বাঁধা বা প্যানেল সুইচিংয়ের সময়" in t:
        t = "ফিউজ বা প্যানেলে কাজের সময় আর্কের ফুলকি থেকে বাঁচতে ফেস শিল্ড পরুন।"
        status = "Changed"
        notes = "Concise and natural PPE prompt."

    if status == "Changed" and t != orig:
        return (t, "Changed", notes)
    return ("", "OK", "")


def process_workbook():
    print(f"Loading workbook: {WORKBOOK_PATH}...")
    wb = openpyxl.load_workbook(WORKBOOK_PATH)

    # 1. Process 'Spoken, built at runtime'
    if "Spoken, built at runtime" in wb.sheetnames:
        ws = wb["Spoken, built at runtime"]
        changed = 0
        ok = 0
        for row_idx in range(2, ws.max_row + 1):
            text = ws.cell(row=row_idx, column=2).value
            if not text:
                continue
            nat_ver, status, notes = review_spoken_runtime_text(str(text))
            if status == "Changed":
                ws.cell(row=row_idx, column=5, value=nat_ver)
                ws.cell(row=row_idx, column=6, value="Changed")
                ws.cell(row=row_idx, column=7, value=notes)
                changed += 1
            elif status == "Do not voice":
                ws.cell(row=row_idx, column=6, value="Do not voice")
                ws.cell(row=row_idx, column=7, value=notes)
            else:
                ws.cell(row=row_idx, column=6, value="OK")
                ok += 1
        print(f" • 'Spoken, built at runtime': {changed} Changed, {ok} OK (Total {ws.max_row - 1})")

    # 2. Process 'Guide library'
    if "Guide library" in wb.sheetnames:
        ws = wb["Guide library"]
        changed = 0
        ok = 0
        for row_idx in range(2, ws.max_row + 1):
            text = ws.cell(row=row_idx, column=10).value
            if not text:
                continue
            nat_ver, status, notes = review_guide_library_text(str(text))
            if status == "Changed":
                ws.cell(row=row_idx, column=11, value=nat_ver)
                ws.cell(row=row_idx, column=12, value="Changed")
                ws.cell(row=row_idx, column=13, value=notes)
                changed += 1
            else:
                ws.cell(row=row_idx, column=12, value="OK")
                ok += 1
        print(f" • 'Guide library': {changed} Changed, {ok} OK (Total {ws.max_row - 1})")

    print(f"Saving workbook to {WORKBOOK_PATH}...")
    wb.save(WORKBOOK_PATH)
    print("Done!")


if __name__ == "__main__":
    process_workbook()
