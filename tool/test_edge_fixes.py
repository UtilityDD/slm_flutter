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

variations = [
    {
        'fn': 'edge_ptw_v1_hyphen.mp3',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত পি-টি-ডব্লিউ, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'Phonetic পি-টি-ডব্লিউ at +12% speed'
    },
    {
        'fn': 'edge_ptw_v2_fast.mp3',
        'rate': '+18%',
        'text': 'গোল্ডেন রুল: লিখিত পি-টি-ডব্লিউ, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'Phonetic পি-টি-ডব্লিউ at +18% speed'
    },
    {
        'fn': 'edge_ptw_v3_permit_full.mp3',
        'rate': '+12%',
        'text': 'গোল্ডেন রুল: লিখিত পারমিট বা পি-টি-ডব্লিউ, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুপাশে আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
        'desc': 'পারমিট বা পি-টি-ডব্লিউ at +12% speed'
    },
    {
        'fn': 'edge_ptw_v4_permit_advice.mp3',
        'rate': '+15%',
        'text': 'লিখিত পি-টি-ডব্লিউ ছাড়া কাজে নামবেন না—সই করা পারমিটই আপনার আসল সুরক্ষা!',
        'desc': 'Permit advice with পি-টি-ডব্লিউ at +15% speed'
    },
    {
        'fn': 'edge_01_bashkar_welcome_fast.mp3',
        'rate': '+12%',
        'text': 'হ্যালো! আমি ওস্তাদ। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!',
        'desc': 'Welcome at +12% speed'
    },
    {
        'fn': 'edge_02_bashkar_warning_fast.mp3',
        'rate': '+14%',
        'text': 'লাইনে হাত দেওয়ার আগে গ্লাভস ফুঁ দিয়ে দেখুন—লিক থাকলে বাতিল!',
        'desc': 'Warning at +14% speed'
    }
]

async def main():
    print(f'Testing {len(variations)} improved audio clips...')
    for v in variations:
        fn = v['fn']
        desc = v['desc']
        rate = v['rate']
        dest = os.path.join(out_dir, fn)
        comm = edge_tts.Communicate(v['text'], 'bn-IN-BashkarNeural', rate=rate)
        await comm.save(dest)
        size = os.path.getsize(dest)
        print(f'  [OK] {fn} ({size} bytes, {rate}) - {desc}')

if __name__ == '__main__':
    asyncio.run(main())

