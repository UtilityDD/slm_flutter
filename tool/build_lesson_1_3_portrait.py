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
TEMP_DIR = os.path.abspath("temp_portrait_1_3")
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
        "title": "উঁচুতে কাজের একমাত্র সুরক্ষা",
        "sub": "পতন রোধে ফুল বডি হারনেসই জীবন বাঁচায়",
        "points": [
            "পোলে ওঠার সময় অসাবধানতায় পতন প্রাণঘাতী",
            "প্রত্যেক লাইনে ফুল বডি হারনেস পরা বাধ্যতামূলক"
        ],
        "img": "tool/media_src/brand/lineman_harness_fit.jpg",
        "text": "উচ্চতায় কাজের সময় পতন রোধে ফুল বডি সেফটি হারনেসই একমাত্র জীবন বাঁচায়। পোলে ওঠার আগে প্রতিটি বাকল ও ল্যানিয়ার্ড সঠিক নিয়মে লক করাই জীবনরক্ষার প্রথম শর্ত।"
    },
    {
        "id": "slide_2",
        "tag": "❌ মারাত্মক ভুল",
        "tag_color": "danger",
        "title": "সাধারণ কোমর বেল্ট নিষিদ্ধ",
        "sub": "পতনের ধাক্কায় মেরুদণ্ড ভেঙে পঙ্গুত্ব নিশ্চিত",
        "points": [
            "কোমর রশা কেবল হেলান দেওয়ার জন্য, পতন রক্ষার জন্য নয়",
            "পতনের আকস্মিক ধাক্কায় পেট ও শিরদাঁড়া চূর্ণ হয়"
        ],
        "img": "tool/media_src/brand/waist_belt_hazard.jpg",
        "text": "সাবধান! সাধারণ কোমরের বেল্ট বা কোমর রশা কোনো পতন সুরক্ষা সরঞ্জাম নয়। ওপর থেকে পিছলে পড়লে সমস্ত ঝাঁকুনি কোমরে এসে মেরুদণ্ড ভেঙে দিতে পারে। উচ্চতায় কাজের জন্য ফুল বডি হারনেস আবশ্যক।"
    },
    {
        "id": "slide_3",
        "tag": "✅ সঠিক সরঞ্জাম",
        "tag_color": "success",
        "title": "ফুল বডি সেফটি হারনেস",
        "sub": "আইএস ৩৫২১ অনুমোদিত সম্পূর্ণ শরীরের বন্ধন",
        "points": [
            "কাঁধ, বুক, কোমর ও উরুতে পতনের শক্তি ছড়িয়ে দেয়",
            "পিঠের মাঝে মজবুত ডরসাল ডি-রিং (D-Ring)"
        ],
        "img": "assets/safety/library/ppe/Full_Body_Harness.webp",
        "text": "সর্বদা ভারতীয় স্ট্যান্ডার্ড বা আইএস ৩৫২১ অনুমোদিত ফুল বডি হারনেস ব্যবহার করুন। পতনের সময় এটি কোনো একটি অঙ্গে চাপ না দিয়ে কাঁধ, বুক ও উরুতে আঘাতের শক্তি সমানভাবে ছড়িয়ে দেয়।"
    },
    {
        "id": "slide_4",
        "tag": "🔍 গোল্ডেন নিয়ম",
        "tag_color": "amber",
        "title": "স্ট্র্যাপে ২ আঙুল নিয়ম",
        "sub": "খুব ঢিলা নয়, আবার অতিরিক্ত আঁটোসাঁটোও নয়",
        "points": [
            "স্ট্র্যাপ ও শরীরের মাঝে মাত্র দুই আঙুল ঢুকবে",
            "ঢিলা হারনেসে পতনের সময় শরীর পিছলে বেরিয়ে যায়"
        ],
        "img": "assets/safety/library/ppe/Full_Body_Harness_2.webp",
        "text": "হারনেস পরার পর মনে রাখবেন বিখ্যাত দুই আঙুল নিয়ম। ফিতে এবং আপনার শরীরের মাঝে ঠিক দুটি আঙুল ঢুকবে এমন টান রাখুন। অতিরিক্ত ঢিলা হারনেস থাকলে পড়ে যাওয়ার সময় শরীর পিছলে বেরিয়ে প্রাণহানি ঘটতে পারে।"
    },
    {
        "id": "slide_5",
        "tag": "🔗 লাইফলাইন সরঞ্জাম",
        "tag_color": "success",
        "title": "ডাবল ল্যানিয়ার্ড ও শক অ্যাবসর্বার",
        "sub": "উচ্চ ক্ষমতার জোড়া রিবার স্ন্যাপ হুক",
        "points": [
            "পতনের তীব্র ঝাঁকুনি কমাতে এনার্জি অ্যাবসর্বার যুক্ত",
            "সহজে পোলের ক্রস-আর্ম বা পাইপে লকিং স্ক্যাফোল্ড হুক"
        ],
        "img": "assets/safety/library/ppe/Full_Body_Harness_Lanyard_Hook.webp",
        "text": "হারনেসের পিঠের ডি-রিংয়ে সবসময় শক-অ্যাবজরবার যুক্ত ডাবল ল্যানিয়ার্ড লাগান। এর দুটি বড় স্ক্যাফোল্ড হুক পোলের ক্রস-আর্মে বা অ্যাঙ্কর পয়েন্টে যেকোনো অবস্থায় সহজে লক করা যায়।"
    },
    {
        "id": "slide_6",
        "tag": "⭐ কার্ডিনাল রুল",
        "tag_color": "amber",
        "title": "১০০% টাই-অফ নীতি মানুন",
        "sub": "পোলে এক মুহূর্তের জন্যও আনলক থাকা চলবে না",
        "points": [
            "একটি হুক পোলে লক রেখে তবে অন্যটি স্থানান্তর",
            "পোলের এক পাশ থেকে অন্য পাশে যাওয়ার সময় সুরক্ষা"
        ],
        "img": "assets/safety/library/ppe/Lanyard_Hook_3.webp",
        "text": "পোলে অবস্থান পরিবর্তনের সময় ১০০% টাই-অফ নীতি বাধ্যতামূলক। সবসময় একটি ল্যানিয়ার্ড শক্তভাবে পোলে আটকানো রেখে তবেই দ্বিতীয় ল্যানিয়ার্ডটি খুলুন এবং নতুন পয়েন্টে লক করুন। পোলে কখনোই এক মুহূর্তের জন্য সম্পূর্ণ বন্ধনমুক্ত হবেন না।"
    },
    {
        "id": "slide_7",
        "tag": "🔍 ৩ মিনিটের রুল",
        "tag_color": "amber",
        "title": "ব্যবহারের আগে ৩ মিনিট চেকলিস্ট",
        "sub": "সামান্য কাটা দাগ বা ফাটল থাকলে হারনেস বাতিল",
        "points": [
            "ফিতের ধার কাটা, পোড়া বা সেলাই খোলা পরীক্ষা",
            "ডি-রিং ও বাকলে জং বা মেয়াদের তারিখ যাচাই"
        ],
        "img": "assets/safety/library/ppe/Full_Body_Harness_3.webp",
        "text": "পোলে ওঠার আগে ৩ মিনিটের গোল্ডেন রুল মেনে হারনেসটি সম্পূর্ণ পরীক্ষা করুন। ফিতায় কোনো কাটা বা পোড়া দাগ, সেলাই আলগা হওয়া কিংবা ডি-রিং ও বাকলসে কোনো জং রয়েছে কি না দেখুন। ত্রুটি থাকলে তা সঙ্গে সঙ্গে বদলে ফেলুন।"
    },
    {
        "id": "slide_8",
        "tag": "⭐ গোল্ডেন রুল",
        "tag_color": "amber",
        "title": "আগে জীবন, তারপর কাজ!",
        "sub": "লেভেল ১.৩ সম্পন্ন • ট্রেইনি ব্যাজ",
        "points": [
            "ফুল বডি হারনেস ও ১০০% টাই-অফ নিশ্চিত করুন",
            "অ্যাপে কুইজ সম্পূর্ণ করে +20 পয়েন্ট পান"
        ],
        "is_final": True,
        "text": "উঁচুতে কাজের একমাত্র সুরক্ষা—১০০% টাই-অফ এবং সঠিক হারনেস। মনে রাখবেন: আগে জীবন, তারপর কাজ! এখনই নিচের কুইজে অংশ নিন, নিজের সুরক্ষা জ্ঞান যাচাই করুন এবং প্লাস ২০ পয়েন্ট অর্জন করুন।"
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
        <div class="badge-step">লেভেল ১.৩ • ট্রেইনি</div>
      </div>
      {middle}
      {bottom}
    </body>
    </html>"""
    return html

async def build_1_3():
    print("Step 1: Generating Lesson 1.3 audio clips with Edge Neural bn-IN-BashkarNeural...")
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
    master_mp3 = os.path.join(OUT_DIR_AUDIO, "lesson_1_3_portrait.mp3")
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
    final_video = os.path.join(OUT_DIR_VIDEO, "lesson_1_3_portrait.mp4")
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
    shutil.copy2(final_video, os.path.join(ARTIFACT_DIR, "lesson_1_3_portrait.mp4"))
    shutil.copy2(master_mp3, os.path.join(ARTIFACT_DIR, "lesson_1_3_portrait.mp3"))
    print("Copied files to Artifacts directory!")

if __name__ == "__main__":
    asyncio.run(build_1_3())
