import asyncio
import os
import sys
import edge_tts
import urllib.request
import json

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

out_dir = os.path.abspath('temp_test_audio')
os.makedirs(out_dir, exist_ok=True)

# 1. Edge Variations
edge_tests = [
    {
        'fn': 'ptw_opt1_permit.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত পারমিট, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'মাঠের খাঁটি শব্দ: "পারমিট" (100% clean & natural)'
    },
    {
        'fn': 'ptw_opt2_dablue.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত পি টি ডাবলু, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'ফোনেটিক: "পি টি ডাবলু"'
    },
    {
        'fn': 'ptw_opt3_english_spaced.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত P T W, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'ইংরেজি স্পেসড: "P T W"'
    },
    {
        'fn': 'ptw_opt4_kajer_permit.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত কাজের পারমিট, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'মাঠের স্পষ্ট শব্দ: "কাজের পারমিট"'
    },
    {
        'fn': 'ptw_opt5_ssml_characters.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত <say-as interpret-as="characters">PTW</say-as>, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'SSML: <say-as characters>PTW</say-as>'
    }
]

async def run_edge():
    for item in edge_tests:
        dest = os.path.join(out_dir, item['fn'])
        try:
            comm = edge_tts.Communicate(item['text'], item['voice'], rate=item['rate'])
            await comm.save(dest)
            fn = item['fn']
            desc = item['desc']
            print(f'[Edge OK] {fn} - {desc}')
        except Exception as e:
            fn = item['fn']
            print(f'[Edge FAIL] {fn}: {e}')

asyncio.run(run_edge())

# 2. Deepgram with "পারমিট" vs "পি টি ডাবলু"
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
if api_key:
    dg_tests = [
        {
            'fn': 'dg_ptw_opt1_permit.mp3',
            'text': 'গোল্ডেন রুল: লিখিত পারমিট, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
            'desc': 'Deepgram Sabbir: "পারমিট"'
        },
        {
            'fn': 'dg_ptw_opt2_dablue.mp3',
            'text': 'গোল্ডেন রুল: লিখিত পি টি ডাবলু, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
            'desc': 'Deepgram Sabbir: "পি টি ডাবলু"'
        }
    ]
    for item in dg_tests:
        dest = os.path.join(out_dir, item['fn'])
        url = 'https://api.deepgram.com/v2/speak?model=flux-sabbir-bn&encoding=mp3'
        data = json.dumps({'text': item['text']}).encode('utf-8')
        req = urllib.request.Request(url, data=data, headers={'Authorization': f'Token {api_key}', 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req) as resp:
                with open(dest, 'wb') as f:
                    f.write(resp.read())
                fn = item['fn']
                desc = item['desc']
                print(f'[Deepgram OK] {fn} - {desc}')
        except Exception as e:
            fn = item['fn']
            print(f'[Deepgram FAIL] {fn}: {e}')
