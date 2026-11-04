import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("--- SUPPLEMENTARY MODULES ---")
if os.path.exists('tool/media_src/data/supplementary_modules.json'):
    data = json.load(open('tool/media_src/data/supplementary_modules.json', encoding='utf-8'))
    for item in data:
        code = item.get('lesson_code') or item.get('number')
        print(f"[{code}] {item.get('title_bn')} | {item.get('title_en')}")

print("\n--- SAFETY LIBRARY ---")
if os.path.exists('assets/data/safety_library.json'):
    data = json.load(open('assets/data/safety_library.json', encoding='utf-8'))
    if isinstance(data, list):
        for item in data[:10]:
            print(item.get('title_bn') or item.get('title') or item.get('name'))
    elif isinstance(data, dict):
        print("Keys:", list(data.keys()))

print("\n--- LIFE SKILL LESSONS ---")
if os.path.exists('assets/data/life_skill'):
    files = os.listdir('assets/data/life_skill')
    print("Files in life_skill:", files[:10])
