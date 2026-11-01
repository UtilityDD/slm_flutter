import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("tool/all_training_chapters_bn.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

for r in rows:
    mod = r.get("module_number")
    ch = r.get("chapter_number")
    if mod in [1, 2]:
        title = r.get("title")
        subtitle = r.get("subtitle") or ""
        briefing = r.get("mission_briefing") or r.get("description") or ""
        print(f"\n==========================================")
        print(f"MODULE {mod}.{ch}: {title}")
        print(f"Subtitle: {subtitle}")
        print(f"Briefing: {briefing[:120]}...")
        print(f"Keys present: {list(r.keys())}")
        if "sections" in r and r["sections"]:
            print(f"Sections count: {len(r['sections'])}")
            for idx, s in enumerate(r['sections'][:3]):
                print(f"  Sec {idx+1}: {s.get('item_name') or s.get('title')}")
        if "pro_tips" in r and r["pro_tips"]:
            print(f"Pro Tips: {r['pro_tips'][:2]}")
