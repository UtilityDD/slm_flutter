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
RATE = "-1%"
PITCH = "+0Hz"

WIDTH = 720
HEIGHT = 1280
FPS = 25

OUT_DIR_AUDIO = os.path.abspath("assets/sounds/voice")
OUT_DIR_VIDEO = os.path.abspath("assets/video")
TEMP_DIR = os.path.abspath("temp_portrait_1_4")
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

SLIDES = [
    {
        "id": "slide_1",
        "tag": "⚠️ ফিল্ড রিয়েলিটি",
        "tag_color": "danger",
        "title": "বাইরে দেখে পোলে ভরসা নয়",
        "sub": "ওঠার আগে পোলের স্বাস্থ্য পরীক্ষা বাধ্যতামূলক",
        "points": [
            "বাইরে থেকে সোজা দেখালেও পোল ভেতরে দুর্বল হতে পারে",
            "লাইনম্যানের ভারে পোল ভেঙে পড়া সবচেয়ে বড় দুর্ঘটনা"
        ],
        "img": "assets/zero_loss/scene/acc_pole_collapse.webp",
        "text": "পোল বাইরে থেকে সোজা ও অক্ষত দেখালেই অন্ধের মতো মই লাগিয়ে উঠবেন না। বহু পোল গোড়ায় উই বা ভেতরে কংক্রিট ক্ষয়ে ফাঁপা হয়ে থাকে, যা লাইনম্যানের সামান্য ভারেই ভেঙে পড়তে পারে।"
    },
    {
        "id": "slide_2",
        "tag": "🔍 গোড়ার পরীক্ষা",
        "tag_color": "amber",
        "title": "গোড়ার ঘাস ও মাফিং পরীক্ষা",
        "sub": "মাটি সরিয়ে ফাউন্ডেশনের সংযোগস্থল দেখুন",
        "points": [
            "গোড়ার আগাছা সরিয়ে কংক্রিটের মাফিং যাচাই",
            "মাটির ঠিক ওপরে সূক্ষ্ম হেয়ারলাইন ফাটল আছে কি না দেখা"
        ],
        "img": "assets/zero_loss/scene/pole11_front_clear.jpg",
        "text": "পোলে ওঠার প্রথম কাজ—গোড়ার ঘাস ও জঞ্জাল পরিষ্কার করা। মাটির সংযোগস্থলে কংক্রিটের মাফিং শক্ত আছে কি না এবং কোনো সূক্ষ্ম ফাটল ধরেছে কি না তা ভালোভাবে দেখে নিন।"
    },
    {
        "id": "slide_3",
        "tag": "🔨 সাউন্ড টেস্ট",
        "tag_color": "success",
        "title": "হাতুড়ি ঠুকে পোলের শব্দ শুনুন",
        "sub": "নিরেট ও ফাঁপা শব্দের পার্থক্যই জীবনের পার্থক্য",
        "points": [
            "নিরেট ঠক্ ঠক্ শব্দ মানে পোল সম্পূর্ণ মজবুত",
            "ফাঁপা দপ্ দপ্ শব্দ পেলে পোল তৎক্ষণাৎ বাতিল"
        ],
        "img": "tool/media_src/brand/pole_hammer_test.jpg",
        "text": "ইনস্পেকশন হাতুড়ি দিয়ে পোলের বিভিন্ন অংশে আলতো করে ঠুকুন। পরিষ্কার নিরেট ঠক্ ঠক্ শব্দ নিশ্চিত করে পোল মজবুত। কিন্তু ভেতরে ফাঁপা বা ভোঁতা দপ্ দপ্ আওয়াজ মিললে সেই পোলে ওঠা সরাসরি মৃত্যুর সামিল।"
    },
    {
        "id": "slide_4",
        "tag": "❌ মারাত্মক ত্রুটি",
        "tag_color": "danger",
        "title": "পোলের পেছনের দিক ঘুরে দেখুন",
        "sub": "সামনে ভালো থাকলেও পেছনে রড বেরিয়ে থাকতে পারে",
        "points": [
            "পোলের ৩৬০ ডিগ্রি ঘুরে পেছনের আর্থিং তার ও রড দেখা",
            "কংক্রিট খসে রড উন্মুক্ত থাকলে মই লাগানো নিষিদ্ধ"
        ],
        "img": "tool/media_src/brand/pole_decay_hazard.jpg",
        "text": "সামনের দিক ভালো লাগলেও পুরো ৩৬০ ডিগ্রি ঘুরে পোলের পেছন ও আর্থিং তার পরীক্ষা করুন। পেছনের কংক্রিট খসে যদি ভেতরের রড বের হয়ে থাকে, তবে সেই পোল সামান্য বাতাসেও ভেঙে পড়ার ঝুঁকিতে থাকে।"
    },
    {
        "id": "slide_5",
        "tag": "📐 ভারসাম্য পরীক্ষা",
        "tag_color": "amber",
        "title": "স্টে-তার ও এগ ইনসুলেটর চেক",
        "sub": "টানটান সাপোর্ট ও লিকেজ কারেন্ট সুরক্ষা",
        "points": [
            "স্টে-তার ঢিলা বা মরিচাধরা হলে পোল হেলে পড়বে",
            "ইনসুলেটর অক্ষত থাকলে স্টে-তারে বিদ্যুৎ সঞ্চালিত হয় না"
        ],
        "img": "assets/zero_loss/scene/pole11_back.jpg",
        "text": "পোলের ভারসাম্য ধরে রাখে স্টে-তার। স্টে-তার টানটান আছে কি না এবং তার ওপরের এগ ইনসুলেটর অক্ষত কি না হাত দিয়ে স্পর্শ করে নিশ্চিত হোন। স্টে আলগা থাকলে পোল যে কোনো মুহূর্তে হেলে পড়তে পারে।"
    },
    {
        "id": "slide_6",
        "tag": "⚡ স্টিল পোল চেক",
        "tag_color": "amber",
        "title": "স্টিল পোলে মরিচা ও টপ স্ক্যান",
        "sub": "মাটিতে টন-টন শব্দ ও ওপরে ক্রস-আর্ম পর্যবেক্ষণ",
        "points": [
            "মাটির ঠিক সংযোগস্থলে স্টিল পোলে মরিচা বা ক্যান্সার পরীক্ষা",
            "নিচ থেকে ওপর পর্যন্ত ইনসুলেটর ও মৌচাকের জন্য চোখ বোলানো"
        ],
        "img": "assets/zero_loss/scene/pole13_top.jpg",
        "text": "স্টিল পোলের ক্ষেত্রে হাতুড়ি ঠুকলে পরিষ্কার টন টন প্রতিধ্বনি মিলবে। মাটির সংযোগস্থলে কোনো মরচে বা ক্ষয় থাকলে তৎক্ষণাৎ চিহ্নিত করুন। ওঠার আগে নিচ থেকে মাথা পর্যন্ত ক্রস-আর্ম, ইনসুলেটর বা কোনো বোলতা-মৌমাছির বাসা আছে কি না চোখ বুলিয়ে নিন।"
    },
    {
        "id": "slide_7",
        "tag": "🚫 জরুরি প্রটোকল",
        "tag_color": "danger",
        "title": "ত্রুটি দেখলে মই নয়, ডেঞ্জার ট্যাগ",
        "sub": "হিরো হতে গিয়ে জীবন হারাবেন না",
        "points": [
            "ফাঁপা শব্দ বা ফাটল দেখলে কখনোই মই লাগাবেন না",
            "পোলে লাল ডেঞ্জার ট্যাগ লাগান এবং সুপারভাইজারকে জানান"
        ],
        "img": "assets/zero_loss/scene/pole12_tag.jpg",
        "text": "যদি হাতুড়ির পরীক্ষায় ফাঁপা শব্দ পান বা গোড়ায় বড় ফাটল দেখেন—কখনোই আরোহণের ঝুঁকি নেবেন না। হিরো না হয়ে পোলে লাল ডেঞ্জার ট্যাগ ঝুলিয়ে দিন এবং কন্ট্রোল রুম ও সুপারভাইজারকে লিখিত রিপোর্ট করুন।"
    },
    {
        "id": "slide_8",
        "tag": "⭐ গোল্ডেন রুল",
        "tag_color": "amber",
        "title": "আগে জীবন, তারপর কাজ!",
        "sub": "লেভেল ১.৪ সম্পন্ন • ট্রেইনি ব্যাজ",
        "points": [
            "চারপাশ, গোড়া, স্টে-তার ও শব্দ দেখে তবেই মই",
            "অ্যাপে কুইজ সম্পূর্ণ করে +20 পয়েন্ট পান"
        ],
        "is_final": True,
        "text": "এই তো আসল লাইনম্যানের অভ্যাস! চারপাশ, গোড়া, স্টে-তার আর শব্দ যাচাই করে তবেই মই লাগাবেন। মনে রাখবেন: আগে জীবন, তারপর কাজ! এখনই নিচের কুইজে অংশ নিন এবং প্লাস ২০ পয়েন্ট অর্জন করুন।"
    }
]

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800;900&display=swap');
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  width: 720px; height: 1280px; overflow: hidden;
  background: radial-gradient(circle at 50% 20%, #1e293b 0%, #0b132b 50%, #030712 100%);
  color: #f8fafc; font-family: 'Noto Sans Bengali', sans-serif;
  display: flex; flex-direction: column; justify-content: space-between;
  padding: 50px 42px 45px; position: relative;
}

body::before {
  content: ''; position: absolute; top: 25%; left: 15%; width: 500px; height: 500px;
  background: radial-gradient(circle, rgba(245, 158, 11, 0.12) 0%, transparent 70%);
  filter: blur(50px); pointer-events: none; z-index: 1;
}

.top-bar {
  display: flex; justify-content: space-between; align-items: center; width: 100%;
  position: relative; z-index: 10;
}
.brand {
  font-size: 21px; font-weight: 800; color: #f59e0b; display: flex; align-items: center; gap: 8px;
  letter-spacing: 0.5px;
}
.badge-step {
  padding: 8px 18px; border-radius: 20px; font-size: 16px; font-weight: 700;
  background: rgba(255,255,255,0.08); border: 1.2px solid rgba(255,255,255,0.18); color: #e2e8f0;
}

.visual-card {
  flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
  margin: 25px 0 20px; position: relative; z-index: 5;
}
.hero-image-box {
  width: 480px; height: 480px; border-radius: 36px;
  background: radial-gradient(circle at 50% 50%, rgba(30, 41, 59, 0.8) 0%, rgba(15, 23, 42, 0.95) 100%);
  border: 2px solid rgba(245, 158, 11, 0.35);
  box-shadow: 0 25px 50px rgba(0,0,0,0.7), 0 0 30px rgba(245,158,11,0.15);
  display: flex; justify-content: center; align-items: center; padding: 20px; position: relative;
  overflow: hidden;
}
.hero-image-box img {
  width: 100%; height: 100%; object-fit: cover; border-radius: 24px;
}
.hero-image-box.contain img {
  object-fit: contain;
}

.text-card {
  background: rgba(15, 23, 42, 0.88); border-radius: 28px; padding: 34px 32px 32px;
  border: 2px solid #334155; backdrop-filter: blur(20px);
  display: flex; flex-direction: column; gap: 14px; position: relative; z-index: 10;
  box-shadow: 0 15px 35px rgba(0,0,0,0.5);
}
.text-card.danger { border-color: rgba(239, 68, 68, 0.85); background: rgba(30, 10, 16, 0.9); }
.text-card.success { border-color: rgba(34, 197, 94, 0.85); background: rgba(10, 30, 20, 0.9); }
.text-card.amber { border-color: rgba(245, 158, 11, 0.85); background: rgba(30, 22, 10, 0.9); }

.tag-pill {
  align-self: flex-start; padding: 7px 18px; border-radius: 10px;
  font-size: 17px; font-weight: 800; letter-spacing: 0.5px;
}
.tag-danger { background: rgba(239, 68, 68, 0.22); color: #fca5a5; border: 1.2px solid #ef4444; }
.tag-success { background: rgba(34, 197, 94, 0.22); color: #86efac; border: 1.2px solid #22c55e; }
.tag-amber { background: rgba(245, 158, 11, 0.22); color: #fef08a; border: 1.2px solid #f59e0b; }

.title {
  font-size: 42px; font-weight: 900; line-height: 1.2; color: #ffffff;
  text-shadow: 0 3px 12px rgba(0,0,0,0.8);
}
.sub {
  font-size: 21px; font-weight: 600; color: #94a3b8; margin-top: -6px;
}

.bullets {
  list-style: none; display: flex; flex-direction: column; gap: 10px; margin-top: 6px;
}
.bullets li {
  font-size: 21px; line-height: 1.35; color: #f1f5f9; font-weight: 600;
  display: flex; align-items: center; gap: 12px;
}
.bullets li::before {
  content: '•'; color: #f59e0b; font-size: 28px; line-height: 0;
}

.trophy-wrap {
  width: 480px; height: 480px; border-radius: 36px;
  background: radial-gradient(circle at 50% 50%, rgba(245, 158, 11, 0.2) 0%, rgba(15, 23, 42, 0.95) 100%);
  border: 2.5px solid #f59e0b; box-shadow: 0 0 60px rgba(245, 158, 11, 0.35);
  display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center;
  padding: 30px;
}
.trophy-emoji { font-size: 110px; margin-bottom: 16px; filter: drop-shadow(0 10px 20px rgba(245,158,11,0.5)); }
.trophy-text { font-size: 44px; font-weight: 900; color: #fef08a; line-height: 1.2; }

.cta-btn {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #0f172a; padding: 20px 26px; border-radius: 18px;
  font-size: 25px; font-weight: 900; text-align: center; margin-top: 10px;
  box-shadow: 0 10px 25px rgba(245,158,11,0.45);
}
"""

def generate_portrait_html(s):
    tag_cls = f"tag-{s['tag_color']}"
    card_cls = s['tag_color']

    if s.get("is_final"):
        middle = """
        <div class="visual-card">
          <div class="trophy-wrap">
            <div class="trophy-emoji">🏆</div>
            <div class="trophy-text">আগে জীবন,<br>তারপর কাজ!</div>
          </div>
        </div>
        """
        bottom = f"""
        <div class="text-card amber">
          <div class="tag-pill tag-amber">{s['tag']}</div>
          <div class="title">{s['title']}</div>
          <div class="sub">{s['sub']}</div>
          <div class="cta-btn">📱 অ্যাপে কুইজ দিন ও +20 পয়েন্ট পান</div>
        </div>
        """
    else:
        img_uri = to_base64_data_uri(s['img'])
        is_contain = "assets/safety" in s['img']
        box_cls = "hero-image-box contain" if is_contain else "hero-image-box"
        middle = f"""
        <div class="visual-card">
          <div class="{box_cls}">
            <img src="{img_uri}">
          </div>
        </div>
        """
        bullets_html = "".join([f"<li>{p}</li>" for p in s['points']])
        bottom = f"""
        <div class="text-card {card_cls}">
          <div class="tag-pill {tag_cls}">{s['tag']}</div>
          <div class="title">{s['title']}</div>
          <div class="sub">{s['sub']}</div>
          <ul class="bullets">{bullets_html}</ul>
        </div>
        """

    html = f"""<!DOCTYPE html>
    <html lang="bn">
    <head>
      <meta charset="utf-8">
      <style>{CSS}</style>
    </head>
    <body>
      <div class="top-bar">
        <div class="brand">⚡ স্মার্ট লাইনম্যান</div>
        <div class="badge-step">লেভেল ১.৪ • ট্রেইনি</div>
      </div>
      {middle}
      {bottom}
    </body>
    </html>"""
    return html

async def build_1_4():
    print("Step 1: Generating Lesson 1.4 audio clips with Edge Neural bn-IN-BashkarNeural...")
    audio_files = []
    for s in SLIDES:
        out_mp3 = os.path.join(TEMP_DIR, f"{s['id']}.mp3")
        out_wav = os.path.join(TEMP_DIR, f"{s['id']}.wav")
        communicate = edge_tts.Communicate(s['text'], VOICE, rate=RATE, pitch=PITCH)
        await communicate.save(out_mp3)

        cmd = [FFMPEG_EXE, "-y", "-i", out_mp3, "-ar", "44100", "-ac", "2", out_wav]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

        res = subprocess.run([FFMPEG_EXE, "-i", out_wav], stderr=subprocess.PIPE, text=True)
        dur = 5.0
        for line in res.stderr.splitlines():
            if "Duration:" in line:
                part = line.split("Duration:")[1].split(",")[0].strip()
                h, m, s_sec = part.split(":")
                dur = float(h)*3600 + float(m)*60 + float(s_sec)
                break
        s["duration"] = dur + 0.35
        s["audio_wav"] = out_wav
        print(f"  {s['id']}: duration = {dur:.2f}s (+0.35s = {s['duration']:.2f}s)")
        audio_files.append((out_wav, s["duration"]))

    # Master audio track
    concat_list = os.path.join(TEMP_DIR, "concat.txt")
    silence_wav = os.path.join(TEMP_DIR, "silence.wav")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-t", "0.35", silence_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    with open(concat_list, "w", encoding="utf-8") as f:
        for idx, (w, _) in enumerate(audio_files):
            f.write(f"file '{w.replace(chr(92), '/')}'\n")
            if idx < len(audio_files) - 1:
                f.write(f"file '{silence_wav.replace(chr(92), '/')}'\n")

    master_wav = os.path.join(TEMP_DIR, "master_audio.wav")
    master_mp3 = os.path.join(OUT_DIR_AUDIO, "lesson_1_4_portrait.mp3")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-c:a", "pcm_s16le", master_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    subprocess.run([
        FFMPEG_EXE, "-y", "-i", master_wav, "-b:a", "192k", master_mp3
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    print(f"Master portrait audio saved: {master_mp3}")

    print("Step 2: Rendering 720x1280 mobile portrait plates with Edge HarfBuzz...")
    slide_images = []
    for s in SLIDES:
        html_file = os.path.join(TEMP_DIR, f"{s['id']}.html")
        png_file = os.path.join(TEMP_DIR, f"{s['id']}.png")
        with open(html_file, "w", encoding="utf-8") as f:
            f.write(generate_portrait_html(s))

        cmd = [
            EDGE_EXE,
            "--headless=new",
            f"--screenshot={png_file}",
            f"--window-size={WIDTH},{HEIGHT}",
            "--hide-scrollbars",
            f"file:///{html_file.replace(chr(92), '/')}"
        ]
        subprocess.run(cmd, check=True)
        print(f"  Rendered slide plate: {s['id']}.png ({os.path.getsize(png_file)} bytes)")
        slide_images.append((png_file, s["duration"]))

    print("Step 3: Compiling motion graphics video segments with Ken-Burns kinetic camera...")
    video_segments = []
    for idx, (img_path, dur) in enumerate(slide_images):
        seg_mp4 = os.path.join(TEMP_DIR, f"seg_{idx}.mp4")
        frames_count = int(dur * FPS)
        vf_filter = f"zoompan=z='min(zoom+0.0006,1.05)':d={frames_count}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={WIDTH}x{HEIGHT}:fps={FPS}"
        cmd = [
            FFMPEG_EXE, "-y",
            "-loop", "1",
            "-i", img_path,
            "-t", f"{dur:.2f}",
            "-vf", vf_filter,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-r", str(FPS),
            "-preset", "medium",
            "-crf", "18",
            seg_mp4
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        video_segments.append(seg_mp4)

    v_concat = os.path.join(TEMP_DIR, "v_concat.txt")
    with open(v_concat, "w", encoding="utf-8") as f:
        for seg in video_segments:
            f.write(f"file '{seg.replace(chr(92), '/')}'\n")

    raw_video = os.path.join(TEMP_DIR, "video_merged.mp4")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", v_concat,
        "-c", "copy", raw_video
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print("Step 4: Muxing kinetic portrait video with master audio...")
    final_video = os.path.join(OUT_DIR_VIDEO, "lesson_1_4_portrait.mp4")
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
    print(f"Final Kinetic Mobile Portrait Video: {final_video}")

    # Copy to Artifact directory
    shutil.copy2(final_video, os.path.join(ARTIFACT_DIR, "lesson_1_4_portrait.mp4"))
    shutil.copy2(master_mp3, os.path.join(ARTIFACT_DIR, "lesson_1_4_portrait.mp3"))
    print("Copied files to Artifacts directory!")

if __name__ == "__main__":
    asyncio.run(build_1_4())
