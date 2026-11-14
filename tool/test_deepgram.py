import urllib.request
import json
import os

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
model = env.get('DEEPGRAM_TTS_MODEL', 'flux-sabbir-bn')

print(f'Testing Deepgram TTS model: {model}')
url = f'https://api.deepgram.com/v2/speak?model={model}&encoding=mp3'
payload = {'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!'}
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
        os.makedirs('temp_test_audio', exist_ok=True)
        out_path = 'temp_test_audio/test_sabbir.mp3'
        with open(out_path, 'wb') as f:
            f.write(audio)
        print(f'SUCCESS! Generated {len(audio)} bytes -> {out_path}')
except urllib.error.HTTPError as e:
    err_body = e.read().decode('utf-8', errors='ignore')
    print(f'HTTP Error {e.code}: {err_body}')
except Exception as e:
    print(f'Error: {e}')
