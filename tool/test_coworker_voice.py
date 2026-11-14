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

# Coworker lines to test
coworker_lines = [
    {
        'fn': 'coworker_opt1_edge_pradeep.mp3',
        'voice': 'bn-BD-PradeepNeural',
        'rate': '+18%',
        'pitch': '-2Hz',
        'text': 'আরে ভাই, লাইন তো ট্রিপ করেই আছে! কাগজ লাগবে কেন? জলদি ওঠো!',
        'desc': 'Edge Pradeep (Gruff, impatient, rough field voice)'
    },
    {
        'fn': 'coworker_opt2_edge_bashkar_taunt.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'rate': '+20%',
        'pitch': '+3Hz',
        'text': 'ধুর! ২০ বছর ধরে কাজ করছি, কিছু হয়নি! এত দেখার সময় নেই, জলদি কাজ সারো!',
        'desc': 'Edge Bashkar (Faster, impatient West Bengal taunt)'
    },
    {
        'fn': 'coworker_opt3_edge_pradeep_storm.mp3',
        'voice': 'bn-BD-PradeepNeural',
        'rate': '+16%',
        'pitch': '-1Hz',
        'text': 'একটু একটু বৃষ্টি পড়ছে তো কী হয়েছে? এইটুকুতে পোল থেকে নামার কোনো মানে হয় না!',
        'desc': 'Edge Pradeep (Stubborn, dismissive peer pressure)'
    }
]

async def run_edge():
    for item in coworker_lines:
        dest = os.path.join(out_dir, item['fn'])
        comm = edge_tts.Communicate(item['text'], item['voice'], rate=item['rate'], pitch=item['pitch'])
        await comm.save(dest)
        fn = item['fn']
        desc = item['desc']
        print(f'[Edge Coworker OK] {fn} - {desc}')

asyncio.run(run_edge())

# Deepgram Shuvo for comparison
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
    url = 'https://api.deepgram.com/v2/speak?model=flux-shuvo-bn&encoding=mp3'
    payload = {'text': 'ধুর! ২০ বছর ধরে কাজ করছি, কিছু হয়নি! এত দেখার সময় নেই, জলদি কাজ সারো!'}
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Authorization': f'Token {api_key}', 'Content-Type': 'application/json'})
    dest = os.path.join(out_dir, 'coworker_opt4_deepgram_shuvo.mp3')
    try:
        with urllib.request.urlopen(req) as resp:
            with open(dest, 'wb') as f:
                f.write(resp.read())
            print('[Deepgram Coworker OK] coworker_opt4_deepgram_shuvo.mp3 - Deepgram Shuvo (Male)')
    except Exception as e:
        print('[Deepgram Coworker FAIL]:', e)

