import asyncio
import os
import sys
import edge_tts

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

out_dir = os.path.abspath('temp_test_audio')
os.makedirs(out_dir, exist_ok=True)

test_clips = [
    {
        'filename': 'edge_01_bashkar_welcome.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'স্বাগতম (Welcome / Mascot Intro)',
        'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!'
    },
    {
        'filename': 'edge_02_bashkar_warning.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'সাবধানবার্তা (Field Warning / Danger)',
        'text': 'লাইনে হাত দেওয়ার আগে গ্লাভস ফুঁ দিয়ে দেখুন—লিক থাকলে বাতিল!'
    },
    {
        'filename': 'edge_03_bashkar_praise.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'প্রশংসা (Reward / Success Praise)',
        'text': 'সাবাশ ওস্তাদ! একদম সঠিক উত্তর—বোনাস পয়েন্ট জমা হলো!'
    },
    {
        'filename': 'edge_04_bashkar_coaching.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'ভুলের পরামর্শ (Supportive Coaching on Mistake)',
        'text': 'আরে, একটু ভুল হলো! শান্ত হয়ে আরেকবার ভেবে দেখুন।'
    },
    {
        'filename': 'edge_05_bashkar_golden_rule.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'গোল্ডেন রুল (Authoritative Technical Standard)',
        'text': 'গোল্ডেন রুল: লিখিত PTW, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!'
    },
    {
        'filename': 'edge_06_bashkar_permit.mp3',
        'voice': 'bn-IN-BashkarNeural',
        'title': 'পারমিট পরামর্শ (Field Procedure Advice)',
        'text': 'লিখিত PTW ছাড়া কাজে নামবেন না—সই করা পারমিটই আপনার আসল সুরক্ষা!'
    },
    {
        'filename': 'edge_07_pradeep_golden_rule.mp3',
        'voice': 'bn-BD-PradeepNeural',
        'title': 'বিকল্প পুরুষ কণ্ঠ (BD Male: Pradeep)',
        'text': 'গোল্ডেন রুল: লিখিত PTW, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!'
    },
    {
        'filename': 'edge_08_tanishaa_welcome.mp3',
        'voice': 'bn-IN-TanishaaNeural',
        'title': 'বিকল্প মহিলা কণ্ঠ (IN Female: Tanishaa)',
        'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!'
    }
]

async def main():
    print(f'Generating {len(test_clips)} audio clips using Microsoft Edge Neural TTS...')
    for item in test_clips:
        fn = item['filename']
        title = item['title']
        dest = os.path.join(out_dir, fn)
        voice = item['voice']
        text = item['text']
        try:
            communicate = edge_tts.Communicate(text, voice, rate='+2%', pitch='+0Hz')
            await communicate.save(dest)
            size = os.path.getsize(dest)
            print(f'  [OK] {fn} ({size} bytes) [{voice}] - {title}')
        except Exception as e:
            print(f'  [FAIL] {fn}: {e}')

    print('All Edge TTS test clips generated successfully!')

if __name__ == '__main__':
    asyncio.run(main())

