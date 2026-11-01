import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("tool/all_training_chapters_bn.json", "r", encoding="utf-8") as f:
    rows = json.load(f)

for mod in [1, 2]:
    mod_rows = [r for r in rows if r['module_number'] == mod]
    for r in mod_rows:
        ch = r['chapter_number']
        title = r['title']
        content = r.get('content', {})
        print(f"\n=======================================================")
        print(f"LESSON {mod}.{ch}: {title}")
        print(f"=======================================================")
        for k, v in content.items():
            if k == 'mission_briefing':
                print(f"BRIEFING: {v.strip()[:150]}...")
            elif k == 'sections':
                print("SECTIONS:")
                for s in v:
                    print(f" - {s.get('item_name') or s.get('title')}: {str(s.get('teaching_points') or s.get('points') or s.get('content'))[:100]}")
            elif k == 'pro_tip':
                print("PRO TIPS:", v.get('content', [])[:2])
            elif k == 'myth_buster':
                print("MYTHS:", [m.get('myth') for m in v.get('items', [])[:2]])
