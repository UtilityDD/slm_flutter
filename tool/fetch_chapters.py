import sys
import json
import urllib.request

sys.stdout.reconfigure(encoding='utf-8')

url = "https://wkunyvomogeazjwtenck.supabase.co/rest/v1/training_chapters?select=*&language=eq.bn&order=module_number,chapter_number"
anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdW55dm9tb2dlYXpqd3RlbmNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MDIwMDgsImV4cCI6MjA4MTA3ODAwOH0.iY8BjqhUn8rvOwul9a0625LQ_TGmauth5Ltml5mTcR0"

headers = {
    "apikey": anon_key,
    "Authorization": f"Bearer {anon_key}"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        rows = json.loads(response.read().decode('utf-8'))
        print(f"Total Bengali chapters fetched: {len(rows)}")
        with open("tool/all_training_chapters_bn.json", "w", encoding="utf-8") as f:
            json.dump(rows, f, ensure_ascii=False, indent=2)
        
        for r in rows:
            mod = r.get("module_number")
            ch = r.get("chapter_number")
            title = r.get("title")
            if mod in [1, 2]:
                print(f"Chapter {mod}.{ch}: {title}")
except Exception as e:
    print(f"Error fetching chapters: {e}")
