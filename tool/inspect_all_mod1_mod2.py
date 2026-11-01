import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("tool/all_training_chapters_bn.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

for mod in [1, 2]:
    print(f"\n=======================================================")
    print(f"               MODULE {mod} SUMMARY")
    print(f"=======================================================")
    mod_rows = [r for r in rows if r['module_number'] == mod]
    for r in mod_rows:
        ch = r['chapter_number']
        title = r['title']
        content = r.get('content', {})
        briefing = content.get('mission_briefing') or ''
        sections = content.get('sections', [])
        tips = content.get('pro_tip', {}).get('content', [])
        myths = content.get('myth_buster', {}).get('items', [])
        
        print(f"\n--- Lesson {mod}.{ch}: {title} ---")
        if briefing:
            print(f"Briefing: {briefing.strip()[:100]}...")
        sec_names = [s.get('item_name') or s.get('title') or '' for s in sections]
        print(f"Sections ({len(sections)}): {', '.join(sec_names[:5])}")
