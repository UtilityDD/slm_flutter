import asyncio
import os
import subprocess
import shutil
import base64
import edge_tts
import imageio_ffmpeg

FFMPEG_EXE = imageio_ffmpeg.get_ffmpeg_exe()
EDGE_EXE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

VOICE = "bn-IN-BashkarNeural"
RATE = "-2%"
PITCH = "+0Hz"

WIDTH = 1280
HEIGHT = 720
FPS = 25

OUT_DIR_AUDIO = os.path.abspath("assets/sounds/voice")
OUT_DIR_VIDEO = os.path.abspath("assets/video")
TEMP_DIR = os.path.abspath("temp_media_pro")
ARTIFACT_DIR = r"C:\Users\rouma\.gemini\antigravity-ide\brain\4668dc13-9193-433c-804a-fb85feeaef65"

os.makedirs(OUT_DIR_AUDIO, exist_ok=True)
os.makedirs(OUT_DIR_VIDEO, exist_ok=True)
os.makedirs(TEMP_DIR, exist_ok=True)

def to_base64_data_uri(filepath):
    if not os.path.exists(filepath):
        return ""
    ext = os.path.splitext(filepath)[1].lower().replace(".", "")
    if ext == "jpg":
        ext = "jpeg"
    with open(filepath, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("utf-8")
    return f"data:image/{ext};base64,{encoded}"

SCENES = [
    {
        "id": "scene_1",
        "title": "লাইনে কাজের প্রথম প্রতিরোধ",
        "subtitle": "ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) ও সতর্কতা",
        "badge": "⚠️ ফিল্ড রিয়েলিটি ও সতর্কতা",
        "text": "লাইনে কাজ করার সময় বিদ্যুৎ কোনো দ্বিতীয় সুযোগ দেয় না। সাইটে নেমে যন্ত্রপাতি ছোঁয়ার আগেই—আপনার শরীরের পোশাকই তৈরি করে জীবন আর মৃত্যুর প্রথম ফারাক।",
        "bg_img": "assets/zero_loss/scene/bg_market_wire_down.webp"
    },
    {
        "id": "scene_2",
        "title": "সঠিক কাজের পোশাক নির্বাচন",
        "subtitle": "পোশাকের বিজ্ঞান — কী পরবেন ও কী বর্জন করবেন",
        "badge": "👕 কাজের পোশাকের নিয়মাবলী",
        "text": "কখনোই পলিয়েস্টার বা সিন্থেটিক জামাকাপড় পরবেন না। আর্ক ফ্ল্যাশের উত্তাপে পলিয়েস্টার সরাসরি গলে ত্বকে আটকে যায়। সবসময় ১০০% সুতির ফুল হাতা পোশাক পরুন। ঢিলেঢালা ফতুয়া বা পাজামা বাতাসে উড়ে লাইনের তারে জড়িয়ে যেতে পারে—তাই পোশাক হবে সম্পূর্ণ আঁটোসাঁটো।",
        "img_vest": "assets/safety/library/ppe/Arc_Fire_Resistant_Full_Body_Vest.webp"
    },
    {
        "id": "scene_3",
        "title": "ক্লাস-ই সেফটি হেলমেট ও সেফটি বুট",
        "subtitle": "মাথা ও পায়ের বৈদ্যুতিক ইনসুলেশন",
        "badge": "🛡️ প্রধান সুরক্ষা সরঞ্জাম",
        "text": "মাথার সুরক্ষায় ক্লাস-ই ইলেকট্রিক্যাল হেলমেট পরা বাধ্যতামূলক। এতে কোনো ভেন্টিলেশন ফুটো থাকা চলবে না, যাতে লাইনের স্পার্ক ঢুকতে না পারে। থুতনির ফিতে সবসময় শক্ত করে লক রাখুন। আর পায়ে থাকবে ডাই-ইলেকট্রিক সেফটি বুট—যার সোল কোনো পেরেক বা তার ছাড়া অক্ষত থাকতে হবে।",
        "img_helmet": "assets/safety/library/ppe/Safety_Helmet.webp",
        "img_boot": "assets/safety/library/ppe/Lineman_Boot_2.webp"
    },
    {
        "id": "scene_4",
        "title": "ভুল ধারণা বনাম আসল সত্য (Myth Buster)",
        "subtitle": "মাঠপর্যায়ের বিপজ্জনক ভুল বর্জন করুন",
        "badge": "🚫 মারাত্মক ভুল ও সমাধান",
        "text": "মনে রাখবেন: মাথায় গামছা বেঁধে হেলমেট পরলে হেলমেট নড়বড়ে থাকে এবং সামান্য ঝাঁকুনিতেই খুলে পড়ে। আর 'চটি পরে কেবল একটু তার জোড়া দেব'—এই অবহেলাতেই সবচেয়ে বেশি মানুষ পা পিছলে নিচে পড়ে যান।",
        "img_cracked": "assets/quizzes/mistake_cracked_helmet.webp",
        "img_slippers": "assets/quizzes/mistake_slippers.webp"
    },
    {
        "id": "scene_5",
        "title": "গোল্ডেন ফিল্ড রুল ও রিভিশন কুইজ",
        "subtitle": "লেভেল ১.১ সম্পন্ন • ট্রেইনি ব্যাজ আনলক",
        "badge": "🏆 লেসন ১.১ কমপ্লিশন",
        "text": "কাজে নামার আগে শরীরকে সম্পূর্ণ সুরক্ষিত রাখুন। এই পাঠের মূল পয়েন্টগুলো মনে রেখেছেন তো? এখনই নিচের কুইজে অংশ নিন, আপনার জ্ঞান যাচাই করুন এবং প্লাস ২০ পয়েন্ট জিতে ট্রেইনি ব্যাজ আনলক করুন!"
    }
]

CSS_TEMPLATE = """
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;500;600;700;800;900&display=swap');
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  width: 1280px; height: 720px; overflow: hidden;
  background: radial-gradient(circle at 80% 20%, #172554 0%, #0b132b 55%, #050b14 100%);
  color: #f8fafc; font-family: 'Noto Sans Bengali', sans-serif;
  position: relative; display: flex; flex-direction: column;
}

/* Header */
.header {
  height: 105px; padding: 14px 45px 10px;
  background: rgba(15, 23, 42, 0.85);
  border-bottom: 2.5px solid #f59e0b;
  display: flex; justify-content: space-between; align-items: center;
  position: relative; z-index: 10;
}
.header-left { display: flex; flex-direction: column; }
.header-tag { font-size: 16px; font-weight: 700; color: #f59e0b; letter-spacing: 0.5px; }
.header-title { font-size: 29px; font-weight: 800; color: #ffffff; line-height: 1.25; margin-top: 2px; }
.header-sub { font-size: 17px; font-weight: 500; color: #94a3b8; }
.badge {
  padding: 8px 18px; border-radius: 20px; font-size: 15px; font-weight: 700;
  background: rgba(245, 158, 11, 0.15); border: 1.5px solid #f59e0b; color: #fef08a;
}

/* Footer */
.footer {
  height: 48px; padding: 0 45px;
  background: rgba(15, 23, 42, 0.9); border-top: 1.5px solid #1e293b;
  display: flex; justify-content: space-between; align-items: center;
  font-size: 15px; font-weight: 500; color: #94a3b8;
  position: absolute; bottom: 0; left: 0; right: 0; z-index: 10;
}
.footer .brand { color: #f59e0b; font-weight: 700; }

/* Content Box */
.content {
  flex: 1; padding: 25px 45px; margin-bottom: 48px;
  display: flex; gap: 28px; position: relative; z-index: 5;
}

/* Common Card Styles */
.card {
  border-radius: 18px; background: rgba(15, 23, 42, 0.8);
  border: 1.8px solid #334155; padding: 22px 26px; flex: 1;
  display: flex; flex-direction: column; position: relative;
  backdrop-filter: blur(10px);
}
.card.danger { border-color: rgba(239, 68, 68, 0.8); background: rgba(30, 10, 15, 0.75); }
.card.success { border-color: rgba(34, 197, 94, 0.8); background: rgba(10, 30, 20, 0.75); }
.card.amber { border-color: rgba(245, 158, 11, 0.8); background: rgba(25, 20, 10, 0.75); }

.card-title {
  font-size: 21px; font-weight: 800; margin-bottom: 14px;
  display: flex; align-items: center; gap: 10px;
}
.card.danger .card-title { color: #fca5a5; }
.card.success .card-title { color: #86efac; }
.card.amber .card-title { color: #fef08a; }

.point-list { list-style: none; display: flex; flex-direction: column; gap: 10px; font-size: 17px; line-height: 1.42; }
.point-list li { display: flex; align-items: flex-start; gap: 8px; color: #e2e8f0; }
.point-list li strong { color: #fff; }

.img-wrap {
  width: 175px; height: 175px; align-self: center; margin-top: auto;
  display: flex; justify-content: center; align-items: center;
}
.img-wrap img { max-width: 100%; max-height: 100%; object-fit: contain; filter: drop-shadow(0 8px 16px rgba(0,0,0,0.6)); }
"""

def generate_scene_html(sc):
    sid = sc["id"]
    if sid == "scene_1":
        bg_uri = to_base64_data_uri(sc["bg_img"])
        body = f"""
        <div class="content" style="align-items: center;">
          <div class="card amber" style="flex: 1.3; padding: 32px 36px;">
            <div style="display: inline-block; padding: 6px 14px; border-radius: 8px; background: rgba(239, 68, 68, 0.2); border: 1px solid #ef4444; color: #fca5a5; font-size: 16px; font-weight: 700; margin-bottom: 16px;">
              ⚠️ গুরুত্বপূর্ণ ফিল্ড ওয়ার্নিং
            </div>
            <div style="font-size: 30px; font-weight: 900; color: #ffffff; line-height: 1.3; margin-bottom: 16px;">
              “লাইনে কাজ করার সময় বিদ্যুৎ কোনো দ্বিতীয় সুযোগ দেয় না।”
            </div>
            <div style="font-size: 19px; line-height: 1.5; color: #cbd5e1; margin-bottom: 24px;">
              সাইটে নেমে যন্ত্রপাতি ছোঁয়ার আগেই—আপনার শরীরের পোশাক ও প্রাথমিক সুরক্ষা সরঞ্জামই তৈরি করে জীবন আর মৃত্যুর প্রথম ফারাক।
            </div>
            <div style="display: flex; flex-direction: column; gap: 10px; font-size: 18px; color: #fef08a; font-weight: 600;">
              <div>✓ কোনো তাড়াহুড়ো নয় — আগে জীবন, তারপর কাজ!</div>
              <div>✓ ১০০% সুতি পোশাক ও ক্লাস-ই হেলমেটই লাইনম্যানের রক্ষাকবচ।</div>
            </div>
          </div>
          <div style="flex: 0.9; height: 450px; border-radius: 18px; overflow: hidden; border: 2px solid #f59e0b; position: relative;">
            <img src="{bg_uri}" style="width: 100%; height: 100%; object-fit: cover;">
            <div style="position: absolute; inset: 0; background: linear-gradient(to top, rgba(15,23,42,0.95) 0%, rgba(15,23,42,0.2) 60%); display: flex; align-items: flex-end; padding: 24px;">
              <div style="font-size: 17px; font-weight: 700; color: #fef08a;">
                ফিডার সাইট • দুর্ঘটনা এড়াতে চেকলিস্ট মানুন
              </div>
            </div>
          </div>
        </div>
        """

    elif sid == "scene_2":
        vest_uri = to_base64_data_uri(sc["img_vest"])
        body = f"""
        <div class="content">
          <div class="card danger">
            <div class="card-title">❌ বর্জনীয়: পলিয়েস্টার ও ঢিলে পোশাক</div>
            <ul class="point-list">
              <li><strong>• পলিয়েস্টার বা সিন্থেটিক কাপড়:</strong> আর্ক ফ্ল্যাশের তাপে গলে সরাসরি চামড়ায় আটকে যায় ও মারাত্মক পোড়া ক্ষত তৈরি করে।</li>
              <li><strong>• ঢিলে ফতুয়া বা পাজামা:</strong> বাতাসে উড়ে লাইনের কন্ডাক্টরে বা যন্ত্রাংশে জড়িয়ে গিয়ে ভারসাম্য নষ্ট করে।</li>
              <li><strong>• হাফ টি-শার্ট ও হাফ প্যান্ট:</strong> হাত-পা খোলা থাকলে যেকোনো সামান্য স্পার্ক বা ঘষায় সরাসরি চামড়া পুড়ে যায়।</li>
            </ul>
          </div>
          <div class="card success">
            <div class="card-title">✅ আবশ্যক: ১০০% খাঁটি সুতি (FR) ফুল হাতা</div>
            <ul class="point-list">
              <li><strong>• ১০০% সুতি (ফায়ার রেজিস্ট্যান্ট):</strong> উচ্চ তাপেও গলে না, শরীরকে সুরক্ষিত রাখে।</li>
              <li><strong>• সম্পূর্ণ ফুল হাতা পোশাক:</strong> হাতের শেষ প্রান্ত পর্যন্ত সম্পূর্ণ ঢেকে রাখে।</li>
              <li><strong>• আঁটোসাঁটো উপযুক্ত মাপ (Snug Fit):</strong> কোনো আলগা অংশ তারে জড়াবে না।</li>
              <li><strong>• পরিচ্ছন্ন রাখুন:</strong> তেল, গ্রিজ বা রাসায়নিক কালি লাগা পোশাক পরা নিষেধ।</li>
            </ul>
            <div class="img-wrap"><img src="{vest_uri}"></div>
          </div>
        </div>
        """

    elif sid == "scene_3":
        hl_uri = to_base64_data_uri(sc["img_helmet"])
        bt_uri = to_base64_data_uri(sc["img_boot"])
        body = f"""
        <div class="content">
          <div class="card amber">
            <div class="card-title">🪖 ক্লাস-ই সেফটি হেলমেট</div>
            <ul class="point-list">
              <li><strong>• নিশ্ছিদ্র শেল (ভেন্ট ফুটো ছাড়া):</strong> কোনো ফুটো থাকা চলবে না, যাতে লাইনের স্পার্ক ও জল ভেতরে ঢুকতে না পারে।</li>
              <li><strong>• থুতনির ফিতে (Chin Strap) লক:</strong> ফিতে সবসময় শক্ত করে লক রাখুন, যাতে কাজের সময় হেলমেট খুলে না পড়ে।</li>
              <li><strong>• সাসপেনশন জালি (Cradle):</strong> মাথার সাথে উপযুক্ত ফাঁক বজায় রাখে ও যেকোনো পতনশীল বস্তুর শক শুষে নেয়।</li>
            </ul>
            <div class="img-wrap"><img src="{hl_uri}"></div>
          </div>
          <div class="card amber">
            <div class="card-title">🥾 ডাই-ইলেকট্রিক সেফটি বুট</div>
            <ul class="point-list">
              <li><strong>• ইলেকট্রিক্যাল ইনসুলেটেড সোল:</strong> মাটির দিক থেকে ভোল্টেজ বা কারেন্ট শরীরে উঠে আসা আটকায়।</li>
              <li><strong>• সোল চেকলিস্ট:</strong> জুতোর সোলে কোনো পেরেক, লোহার টুকরো বা বাঁধার তার বিঁধে নেই তো? প্রতিদিন চেক করুন।</li>
              <li><strong>• শুকনো বুট বাধ্যতামূলক:</strong> ভিজে বুটে বৈদ্যুতিক ইনসুলেশন নষ্ট হয়; ভেজা অবস্থায় কাজ সম্পূর্ণ নিষেধ।</li>
            </ul>
            <div class="img-wrap"><img src="{bt_uri}"></div>
          </div>
        </div>
        """

    elif sid == "scene_4":
        cr_uri = to_base64_data_uri(sc["img_cracked"])
        sl_uri = to_base64_data_uri(sc["img_slippers"])
        body = f"""
        <div class="content" style="flex-direction: column; gap: 16px;">
          <div class="card" style="border-color: #ef4444; background: rgba(30, 15, 20, 0.85); flex-direction: row; align-items: center; gap: 24px; padding: 18px 24px;">
            <div style="width: 100px; height: 100px; flex-shrink: 0;"><img src="{cr_uri}" style="width: 100%; height: 100%; object-fit: contain;"></div>
            <div style="flex: 1;">
              <div style="font-size: 19px; font-weight: 800; color: #fca5a5; margin-bottom: 4px;">❌ ভুল ধারণা ১: মাথায় গামছা পেঁচিয়ে হেলমেট পরা</div>
              <div style="font-size: 17px; color: #e2e8f0; line-height: 1.4;"><strong>আসল সত্য:</strong> মাথায় গামছা থাকলে হেলমেট সঠিকভাবে বসে না; সামান্য ঝাঁকুনিতেই হেলমেট খুলে নিচে পড়ে যায়।</div>
              <div style="font-size: 16px; color: #fef08a; font-weight: 700; margin-top: 4px;">👉 সমাধান: সর্বদা খালি মাথায় সঠিক সাইজের হেলমেট পরুন এবং চিন-স্ট্র্যাপ শক্ত করে বাঁধুন।</div>
            </div>
          </div>
          <div class="card" style="border-color: #ef4444; background: rgba(30, 15, 20, 0.85); flex-direction: row; align-items: center; gap: 24px; padding: 18px 24px;">
            <div style="width: 100px; height: 100px; flex-shrink: 0;"><img src="{sl_uri}" style="width: 100%; height: 100%; object-fit: contain;"></div>
            <div style="flex: 1;">
              <div style="font-size: 19px; font-weight: 800; color: #fca5a5; margin-bottom: 4px;">❌ ভুল ধারণা ২: চটি বা সাধারণ কেডস জুতো পরে লাইনে ওঠা</div>
              <div style="font-size: 17px; color: #e2e8f0; line-height: 1.4;"><strong>আসল সত্য:</strong> চটিতে কোনো গ্রিপ নেই; ফিল্ডে স্লিপ করে পতন দুর্ঘটনার অন্যতম প্রধান কারণ চটি।</div>
              <div style="font-size: 16px; color: #fef08a; font-weight: 700; margin-top: 4px;">👉 সমাধান: পোলে ওঠার আগে পেরেক-মুক্ত গ্রিপযুক্ত ডাই-ইলেকট্রিক বুট পরা বাধ্যতামূলক।</div>
            </div>
          </div>
        </div>
        """

    elif sid == "scene_5":
        body = f"""
        <div class="content" style="justify-content: center; align-items: center;">
          <div class="card amber" style="width: 820px; flex: unset; padding: 36px 48px; text-align: center; align-items: center;">
            <div style="font-size: 34px; font-weight: 900; color: #f59e0b; margin-bottom: 12px;">
              ⭐ গোল্ডেন ফিল্ড রুল ⭐
            </div>
            <div style="font-size: 38px; font-weight: 900; color: #ffffff; margin-bottom: 20px;">
              « আগে জীবন, তারপর কাজ! »
            </div>
            <div style="font-size: 19px; color: #cbd5e1; line-height: 1.6; margin-bottom: 28px; text-align: left; background: rgba(0,0,0,0.3); padding: 18px 24px; border-radius: 12px; border: 1px solid rgba(245,158,11,0.3);">
              <div>• ১০০% খাঁটি সুতি ফুল হাতা পোশাক ও নিশ্ছিদ্র শেল হেলমেট।</div>
              <div>• চিন স্ট্র্যাপ ও ডাই-ইলেকট্রিক বুটের ইনসুলেশন নিশ্চিত করুন।</div>
              <div>• গামছা পেঁচিয়ে হেলমেট বা চটি পরে কাজে যাওয়া সম্পূর্ণ নিষিদ্ধ।</div>
            </div>
            <div style="padding: 16px 36px; border-radius: 50px; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: #0f172a; font-size: 24px; font-weight: 900; box-shadow: 0 10px 25px rgba(245,158,11,0.4);">
              📱 অ্যাপে কুইজ দিন ও +20 পয়েন্ট অর্জন করুন!
            </div>
          </div>
        </div>
        """

    html = f"""<!DOCTYPE html>
    <html lang="bn">
    <head>
      <meta charset="utf-8">
      <style>{CSS_TEMPLATE}</style>
    </head>
    <body>
      <div class="header">
        <div class="header-left">
          <div class="header-tag">স্মার্ট লাইনম্যান (SLM) • মডিউল ১.১ (ট্রেইনি)</div>
          <div class="header-title">{sc["title"]}</div>
          <div class="header-sub">{sc["subtitle"]}</div>
        </div>
        <div class="badge">{sc["badge"]}</div>
      </div>
      {body}
      <div class="footer">
        <div>⚡ WBSEDCL & CEA সেফটি স্ট্যান্ডার্ডস • জীবনের আগে কোনো আপস নয়</div>
        <div class="brand">SmartLineman.in</div>
      </div>
    </body>
    </html>"""
    return html

async def build_pro_media():
    print("Step 1: Generating audio narration clips with edge-tts...")
    audio_files = []
    for sc in SCENES:
        out_mp3 = os.path.join(TEMP_DIR, f"{sc['id']}.mp3")
        out_wav = os.path.join(TEMP_DIR, f"{sc['id']}.wav")
        communicate = edge_tts.Communicate(sc['text'], VOICE, rate=RATE, pitch=PITCH)
        await communicate.save(out_mp3)

        cmd = [FFMPEG_EXE, "-y", "-i", out_mp3, "-ar", "44100", "-ac", "2", out_wav]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        res = subprocess.run([FFMPEG_EXE, "-i", out_wav], stderr=subprocess.PIPE, text=True)
        dur = 5.0
        for line in res.stderr.splitlines():
            if "Duration:" in line:
                part = line.split("Duration:")[1].split(",")[0].strip()
                h, m, s = part.split(":")
                dur = float(h)*3600 + float(m)*60 + float(s)
                break
        sc["duration"] = dur + 0.6
        sc["audio_wav"] = out_wav
        print(f"  Scene {sc['id']}: audio duration = {dur:.2f}s (+0.6s pause = {sc['duration']:.2f}s)")
        audio_files.append((out_wav, sc["duration"]))

    # Master audio track
    concat_list = os.path.join(TEMP_DIR, "concat.txt")
    silence_wav = os.path.join(TEMP_DIR, "silence.wav")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-t", "0.6", silence_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    with open(concat_list, "w", encoding="utf-8") as f:
        for idx, (w, _) in enumerate(audio_files):
            f.write(f"file '{w.replace(chr(92), '/')}'\n")
            if idx < len(audio_files) - 1:
                f.write(f"file '{silence_wav.replace(chr(92), '/')}'\n")

    master_wav = os.path.join(TEMP_DIR, "master_audio.wav")
    master_mp3 = os.path.join(OUT_DIR_AUDIO, "lesson_1_1_explainer.mp3")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-c:a", "pcm_s16le", master_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    subprocess.run([
        FFMPEG_EXE, "-y", "-i", master_wav, "-b:a", "192k", master_mp3
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    print(f"Master audio saved to: {master_mp3}")

    print("Step 2: Rendering high-definition slides via Microsoft Edge HarfBuzz engine...")
    slide_images = []
    for sc in SCENES:
        html_file = os.path.join(TEMP_DIR, f"{sc['id']}.html")
        png_file = os.path.join(TEMP_DIR, f"{sc['id']}.png")
        with open(html_file, "w", encoding="utf-8") as f:
            f.write(generate_scene_html(sc))

        cmd = [
            EDGE_EXE,
            "--headless=new",
            f"--screenshot={png_file}",
            f"--window-size={WIDTH},{HEIGHT}",
            "--hide-scrollbars",
            f"file:///{html_file.replace(chr(92), '/')}"
        ]
        subprocess.run(cmd, check=True)
        print(f"  Rendered slide {sc['id']}.png (Size: {os.path.getsize(png_file)} bytes)")
        slide_images.append((png_file, sc["duration"]))

    print("Step 3: Compiling video clips with precise durations and smooth crossfades...")
    video_segments = []
    for idx, (img_path, dur) in enumerate(slide_images):
        seg_mp4 = os.path.join(TEMP_DIR, f"seg_{idx}.mp4")
        cmd = [
            FFMPEG_EXE, "-y",
            "-loop", "1",
            "-i", img_path,
            "-t", f"{dur:.2f}",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-r", str(FPS),
            "-preset", "medium",
            "-crf", "18",
            seg_mp4
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        video_segments.append(seg_mp4)

    # Concat video segments
    v_concat = os.path.join(TEMP_DIR, "v_concat.txt")
    with open(v_concat, "w", encoding="utf-8") as f:
        for seg in video_segments:
            f.write(f"file '{seg.replace(chr(92), '/')}'\n")

    raw_video = os.path.join(TEMP_DIR, "video_merged.mp4")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", v_concat,
        "-c", "copy", raw_video
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print("Step 4: Muxing raw video and master audio...")
    final_video = os.path.join(OUT_DIR_VIDEO, "lesson_1_1_explainer.mp4")
    mux_cmd = [
        FFMPEG_EXE, "-y",
        "-i", raw_video,
        "-i", master_wav,
        "-c:v", "copy",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        final_video
    ]
    subprocess.run(mux_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    print(f"Final Explainer Video generated: {final_video}")

    # Copy to Artifact directory
    shutil.copy2(final_video, os.path.join(ARTIFACT_DIR, "lesson_1_1_explainer.mp4"))
    shutil.copy2(master_mp3, os.path.join(ARTIFACT_DIR, "lesson_1_1_explainer.mp3"))
    print("Copied files to Artifacts directory!")

if __name__ == "__main__":
    asyncio.run(build_pro_media())
