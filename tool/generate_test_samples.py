import urllib.request
import json
import os
import sys

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def get_env():
    env = {}
    if os.path.exists('.env'):
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env[k.strip()] = v.strip()
    return env

env = get_env()
api_key = env.get('DEEPGRAM_API_KEY')
out_dir = os.path.abspath('temp_test_audio')
os.makedirs(out_dir, exist_ok=True)

test_clips = [
    {
        'filename': '01_sabbir_welcome.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'স্বাগতম (Welcome / Mascot Intro)',
        'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!'
    },
    {
        'filename': '02_sabbir_warning.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'সাবধানবার্তা (Field Warning / Danger)',
        'text': 'লাইনে হাত দেওয়ার আগে গ্লাভস ফুঁ দিয়ে দেখুন—লিক থাকলে বাতিল!'
    },
    {
        'filename': '03_sabbir_praise.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'প্রশংসা (Reward / Success Praise)',
        'text': 'সাবাশ ওস্তাদ! একদম সঠিক উত্তর—বোনাস পয়েন্ট জমা হলো!'
    },
    {
        'filename': '04_sabbir_coaching.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'ভুলের পরামর্শ (Supportive Coaching on Mistake)',
        'text': 'আরে, একটু ভুল হলো! শান্ত হয়ে আরেকবার ভেবে দেখুন।'
    },
    {
        'filename': '05_sabbir_golden_rule.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'গোল্ডেন রুল (Authoritative Technical Standard)',
        'text': 'গোল্ডেন রুল: লিখিত PTW, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!'
    },
    {
        'filename': '06_sabbir_permit.mp3',
        'model': 'flux-sabbir-bn',
        'title': 'পারমিট পরামর্শ (Field Procedure Advice)',
        'text': 'লিখিত PTW ছাড়া কাজে নামবেন না—সই করা পারমিটই আপনার আসল সুরক্ষা!'
    },
    {
        'filename': '07_shuvo_sample.mp3',
        'model': 'flux-shuvo-bn',
        'title': 'বিকল্প পুরুষ কণ্ঠ (Alternative Male Voice: Shuvo)',
        'text': 'গোল্ডেন রুল: লিখিত PTW, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!'
    },
    {
        'filename': '08_sumaiya_sample.mp3',
        'model': 'flux-sumaiya-bn',
        'title': 'বিকল্প মহিলা কণ্ঠ (Alternative Female Voice: Sumaiya)',
        'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!'
    }
]

print(f'Generating {len(test_clips)} test audio clips using Deepgram Flux TTS...')
for item in test_clips:
    dest = os.path.join(out_dir, item['filename'])
    m_name = item['model']
    url = f'https://api.deepgram.com/v2/speak?model={m_name}&encoding=mp3'
    payload = {'text': item['text']}
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            'Authorization': f'Token {api_key}',
            'Content-Type': 'application/json'
        }
    )
    try:
        with urllib.request.urlopen(req) as resp:
            audio = resp.read()
            with open(dest, 'wb') as f:
                f.write(audio)
            fn = item['filename']
            title = item['title']
            print(f'  [OK] {fn} ({len(audio)} bytes) - {title}')
    except urllib.error.HTTPError as e:
        fn = item['filename']
        err_msg = e.read().decode('utf-8', errors='ignore')
        print(f'  [FAIL] {fn}: HTTP {e.code} - {err_msg}')
    except Exception as e:
        fn = item['filename']
        print(f'  [FAIL] {fn}: {e}')

print('All done!')
