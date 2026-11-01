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
TEMP_DIR = os.path.abspath("temp_portrait_build")
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
        "title": "শরীরের সুরক্ষাই প্রথম প্রতিরোধ",
        "sub": "কাজে নামার আগে নিজেকে বাঁচান",
        "points": [
            "লাইনে বিদ্যুৎ দ্বিতীয় সুযোগ দেয় না",
            "যন্ত্রপাতি ছোঁয়ার আগেই নিন সুরক্ষাকবচ"
        ],
        "img": "assets/zero_loss/scene/acc_charged.webp",
        "text": "লাইনে কাজ করার সময় বিদ্যুৎ কোনো দ্বিতীয় সুযোগ দেয় না। সাইটে নেমে যন্ত্রপাতি ছোঁয়ার আগেই—আপনার শরীরের পোশাকই তৈরি করে জীবন আর মৃত্যুর প্রথম ফারাক।"
    },
    {
        "id": "slide_2",
        "tag": "❌ মারাত্মক ভুল",
        "tag_color": "danger",
        "title": "পলিয়েস্টার ও ঢিলে পোশাক নিষিদ্ধ",
        "sub": "আর্ক ফ্ল্যাশে ভয়াবহ বিপদ",
        "points": [
            "আর্ক ফ্ল্যাশের তাপে গলে চামড়ায় আটকে যায়",
            "ঢিলে ফতুয়া বা পাজামা তারে জড়িয়ে পড়ে"
        ],
        "img": "assets/quizzes/mistake_working_alone.webp",
        "text": "কখনোই পলিয়েস্টার বা সিন্থেটিক জামাকাপড় পরবেন না। আর্ক ফ্ল্যাশের উত্তাপে পলিয়েস্টার সরাসরি গলে ত্বকে আটকে যায়। ঢিলেঢালা পোশাক বাতাসে উড়ে লাইনের তারে জড়িয়ে যেতে পারে।"
    },
    {
        "id": "slide_3",
        "tag": "✅ সঠিক পোশাক",
        "tag_color": "success",
        "title": "১০০% খাঁটি সুতি (FR) ফুল হাতা",
        "sub": "শারীরিক নিরাপত্তার বর্ম",
        "points": [
            "উচ্চ তাপেও গলে না — ত্বক সুরক্ষিত রাখে",
            "শরীরের সাথে আঁটোসাঁটো মাপ (Snug Fit)"
        ],
        "img": "assets/safety/library/ppe/Arc_Fire_Resistant_Full_Body_Vest.webp",
        "text": "সবসময় ১০০% খাঁটি সুতি বা ফায়ার রেজিস্ট্যান্ট ফুল হাতা পোশাক পরুন। শরীরের সাথে মাপ যেন সম্পূর্ণ আঁটোসাঁটো থাকে।"
    },
    {
        "id": "slide_4",
        "tag": "🪖 মাথার সুরক্ষা",
        "tag_color": "amber",
        "title": "ক্লাস-ই সেফটি হেলমেট",
        "sub": "পতনশীল বস্তু ও স্পার্ক থেকে বাঁচায়",
        "points": [
            "নিশ্ছিদ্র শেল — কোনো ভেন্ট বা ফুটো ছাড়া",
            "থুতনির ফিতে (Chin Strap) শক্ত করে লক"
        ],
        "img": "assets/safety/library/ppe/Safety_Helmet.webp",
        "text": "মাথার সুরক্ষায় ক্লাস-ই ইলেকট্রিক্যাল হেলমেট বাধ্যতামূলক। এতে কোনো ভেন্টিলেশন ফুটো থাকা চলবে না, আর থুতনির ফিতে সবসময় শক্ত করে লক রাখুন।"
    },
    {
        "id": "slide_5",
        "tag": "🥾 পায়ের সুরক্ষা",
        "tag_color": "amber",
        "title": "ডাই-ইলেকট্রিক সেফটি বুট",
        "sub": "মাটি থেকে বিদ্যুৎ ওঠা আটকায়",
        "points": [
            "নন-কন্ডাক্টিভ ইনসুলেটেড গ্রিপ সোল",
            "সোলে পেরেক বা তার নেই তো? চেক করুন"
        ],
        "img": "assets/safety/library/ppe/Lineman_Boot_2.webp",
        "text": "পায়ে থাকবে ডাই-ইলেকট্রিক সেফটি বুট। প্রতিদিন দেখে নিন—সোলে কোনো পেরেক, তার বা লোহার টুকরো বিঁধে নেই তো? ভেজা বুটে কাজ সম্পূর্ণ নিষিদ্ধ।"
    },
    {
        "id": "slide_6",
        "tag": "🚫 মাঠের ভুল ধারণা",
        "tag_color": "danger",
        "title": "গামছা ও চটি সম্পূর্ণ নিষিদ্ধ",
        "sub": "সবচেয়ে বেশি দুর্ঘটনার ফাঁদ",
        "points": [
            "গামছায় হেলমেট নড়বড়ে হয় ও খুলে পড়ে",
            "চটিতে গ্রিপ থাকে না — পা পিছলে পতন"
        ],
        "img": "assets/quizzes/mistake_slippers.webp",
        "text": "মনে রাখবেন: মাথায় গামছা বেঁধে হেলমেট পরলে তা নড়বড়ে থাকে ও খুলে পড়ে। আর চটি পায়ে পোলে ওঠার অবহেলাতেই সবচেয়ে বেশি মানুষ নিচে পড়ে যান।"
    },
    {
        "id": "slide_7",
        "tag": "⭐ গোল্ডেন রুল",
        "tag_color": "amber",
        "title": "আগে জীবন, তারপর কাজ!",
        "sub": "লেভেল ১.১ সম্পন্ন • ট্রেইনি ব্যাজ",
        "points": [
            "কাজের আগে পিপিই চেকলিস্ট নিশ্চিত করুন",
            "অ্যাপে কুইজ সম্পূর্ণ করে +20 পয়েন্ট নিন"
        ],
        "img": "assets/sounds/quiz_right.wav",
        "is_final": True,
        "text": "কাজে নামার আগে শরীরকে সুরক্ষিত রাখুন। মনে রাখবেন: আগে জীবন, তারপর কাজ! এখনই নিচের কুইজে অংশ নিন এবং প্লাস ২০ পয়েন্ট অর্জন করুন।"
    }
]

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800;900&display=swap');
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  width: 720px; height: 1280px; overflow: hidden;
  background: radial-gradient(circle at 50% 25%, #172554 0%, #0b132b 50%, #030712 100%);
  color: #f8fafc; font-family: 'Noto Sans Bengali', sans-serif;
  display: flex; flex-direction: column; justify-content: space-between;
  padding: 55px 44px 50px; position: relative;
}

/* Top Bar */
.top-bar {
  display: flex; justify-content: space-between; align-items: center; width: 100%;
}
.brand {
  font-size: 19px; font-weight: 800; color: #f59e0b; display: flex; align-items: center; gap: 8px;
}
.badge-step {
  padding: 6px 16px; border-radius: 20px; font-size: 15px; font-weight: 700;
  background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.15); color: #cbd5e1;
}

/* Main Visual Area */
.visual-card {
  flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
  margin: 30px 0; position: relative;
}
.hero-image-box {
  width: 440px; height: 440px; border-radius: 32px;
  background: radial-gradient(circle at 50% 50%, rgba(30, 41, 59, 0.7) 0%, rgba(15, 23, 42, 0.9) 100%);
  border: 2px solid rgba(245, 158, 11, 0.25);
  box-shadow: 0 20px 40px rgba(0,0,0,0.6);
  display: flex; justify-content: center; align-items: center; padding: 36px; position: relative;
}
.hero-image-box img {
  max-width: 100%; max-height: 100%; object-fit: contain;
  filter: drop-shadow(0 14px 20px rgba(0,0,0,0.7));
}

/* Bottom Text Card */
.text-card {
  background: rgba(15, 23, 42, 0.85); border-radius: 26px; padding: 32px 30px 28px;
  border: 1.8px solid #334155; backdrop-filter: blur(16px);
  display: flex; flex-direction: column; gap: 14px;
}
.text-card.danger { border-color: rgba(239, 68, 68, 0.8); background: rgba(30, 10, 15, 0.85); }
.text-card.success { border-color: rgba(34, 197, 94, 0.8); background: rgba(10, 30, 20, 0.85); }
.text-card.amber { border-color: rgba(245, 158, 11, 0.8); background: rgba(30, 22, 10, 0.85); }

.tag-pill {
  align-self: flex-start; padding: 6px 16px; border-radius: 8px;
  font-size: 16px; font-weight: 800; letter-spacing: 0.5px;
}
.tag-danger { background: rgba(239, 68, 68, 0.2); color: #fca5a5; border: 1px solid #ef4444; }
.tag-success { background: rgba(34, 197, 94, 0.2); color: #86efac; border: 1px solid #22c55e; }
.tag-amber { background: rgba(245, 158, 11, 0.2); color: #fef08a; border: 1px solid #f59e0b; }

.title {
  font-size: 32px; font-weight: 900; line-height: 1.25; color: #ffffff;
}
.sub {
  font-size: 19px; font-weight: 600; color: #94a3b8; margin-top: -6px;
}

.bullets {
  list-style: none; display: flex; flex-direction: column; gap: 8px; margin-top: 4px;
}
.bullets li {
  font-size: 19px; line-height: 1.35; color: #e2e8f0; font-weight: 500;
  display: flex; align-items: center; gap: 10px;
}
.bullets li::before {
  content: '•'; color: #f59e0b; font-size: 24px; line-height: 0;
}

/* Final Trophy Layout */
.trophy-wrap {
  width: 440px; height: 440px; border-radius: 32px;
  background: radial-gradient(circle at 50% 50%, rgba(245, 158, 11, 0.15) 0%, rgba(15, 23, 42, 0.9) 100%);
  border: 2.5px solid #f59e0b; box-shadow: 0 0 50px rgba(245, 158, 11, 0.3);
  display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center;
  padding: 30px;
}
.trophy-emoji { font-size: 100px; margin-bottom: 12px; }
.trophy-text { font-size: 38px; font-weight: 900; color: #fef08a; line-height: 1.2; }

.cta-btn {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #0f172a; padding: 18px 24px; border-radius: 16px;
  font-size: 22px; font-weight: 900; text-align: center; margin-top: 8px;
  box-shadow: 0 8px 20px rgba(245,158,11,0.35);
}

.footer-bar {
  text-align: center; font-size: 15px; color: #64748b; font-weight: 600; margin-top: 15px;
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
        middle = f"""
        <div class="visual-card">
          <div class="hero-image-box">
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
        <div class="badge-step">লেভেল ১.১ • ট্রেইনি</div>
      </div>
      {middle}
      {bottom}
      <div class="footer-bar">WBSEDCL ও CEA সেফটি গাইডলাইন • SmartLineman.in</div>
    </body>
    </html>"""
    return html

async def build_portrait_media():
    print("Step 1: Generating mobile portrait voice clips...")
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
        s["duration"] = dur + 0.4
        s["audio_wav"] = out_wav
        print(f"  {s['id']}: audio duration = {dur:.2f}s (+0.4s pause = {s['duration']:.2f}s)")
        audio_files.append((out_wav, s["duration"]))

    # Master audio track
    concat_list = os.path.join(TEMP_DIR, "concat.txt")
    silence_wav = os.path.join(TEMP_DIR, "silence.wav")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-t", "0.4", silence_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    with open(concat_list, "w", encoding="utf-8") as f:
        for idx, (w, _) in enumerate(audio_files):
            f.write(f"file '{w.replace(chr(92), '/')}'\n")
            if idx < len(audio_files) - 1:
                f.write(f"file '{silence_wav.replace(chr(92), '/')}'\n")

    master_wav = os.path.join(TEMP_DIR, "master_audio.wav")
    master_mp3 = os.path.join(OUT_DIR_AUDIO, "lesson_1_1_portrait.mp3")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-c:a", "pcm_s16le", master_wav
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    subprocess.run([
        FFMPEG_EXE, "-y", "-i", master_wav, "-b:a", "192k", master_mp3
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    print(f"Master portrait audio saved: {master_mp3}")

    print("Step 2: Rendering 720x1280 mobile portrait slides with Edge HarfBuzz...")
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
        print(f"  Rendered portrait slide: {s['id']}.png ({os.path.getsize(png_file)} bytes)")
        slide_images.append((png_file, s["duration"]))

    print("Step 3: Compiling 9:16 mobile video segments...")
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

    v_concat = os.path.join(TEMP_DIR, "v_concat.txt")
    with open(v_concat, "w", encoding="utf-8") as f:
        for seg in video_segments:
            f.write(f"file '{seg.replace(chr(92), '/')}'\n")

    raw_video = os.path.join(TEMP_DIR, "video_merged.mp4")
    subprocess.run([
        FFMPEG_EXE, "-y", "-f", "concat", "-safe", "0", "-i", v_concat,
        "-c", "copy", raw_video
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    print("Step 4: Muxing 9:16 mobile portrait video with audio...")
    final_video = os.path.join(OUT_DIR_VIDEO, "lesson_1_1_portrait.mp4")
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
    print(f"Final Mobile Portrait Video generated: {final_video}")

    # Copy to Artifact directory
    shutil.copy2(final_video, os.path.join(ARTIFACT_DIR, "lesson_1_1_portrait.mp4"))
    shutil.copy2(master_mp3, os.path.join(ARTIFACT_DIR, "lesson_1_1_portrait.mp3"))
    print("Copied portrait video & audio to Artifacts directory!")

if __name__ == "__main__":
    asyncio.run(build_portrait_media())
