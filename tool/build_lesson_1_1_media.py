import asyncio
import os
import subprocess
import json
import math
import shutil
import edge_tts
import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFont

FFMPEG_EXE = imageio_ffmpeg.get_ffmpeg_exe()
VOICE = "bn-IN-BashkarNeural"
RATE = "-2%"
PITCH = "+0Hz"

WIDTH = 1280
HEIGHT = 720
FPS = 25

FONT_DIR = os.path.abspath("assets/fonts")
FONT_BOLD_PATH = os.path.join(FONT_DIR, "NotoSansBengali-Bold.ttf")
FONT_MED_PATH = os.path.join(FONT_DIR, "NotoSansBengali-Medium.ttf")
FONT_REG_PATH = os.path.join(FONT_DIR, "NotoSansBengali-Regular.ttf")

TEMP_DIR = os.path.abspath("temp_media_build")
os.makedirs(TEMP_DIR, exist_ok=True)

OUT_DIR_AUDIO = os.path.abspath("assets/sounds/voice")
OUT_DIR_VIDEO = os.path.abspath("assets/video")
os.makedirs(OUT_DIR_AUDIO, exist_ok=True)
os.makedirs(OUT_DIR_VIDEO, exist_ok=True)

ARTIFACT_DIR = r"C:\Users\rouma\.gemini\antigravity-ide\brain\4668dc13-9193-433c-804a-fb85feeaef65"

SCENES = [
    {
        "id": "scene_1",
        "title": "লাইনে কাজের প্রথম প্রতিরোধ",
        "subtitle": "ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) ও সতর্কতা",
        "text": "লাইনে কাজ করার সময় বিদ্যুৎ কোনো দ্বিতীয় সুযোগ দেয় না। সাইটে নেমে যন্ত্রপাতি ছোঁয়ার আগেই—আপনার শরীরের পোশাকই তৈরি করে জীবন আর মৃত্যুর প্রথম ফারাক।",
        "bg_img": "assets/zero_loss/scene/bg_market_wire_down.webp",
        "badge": "⚠️ ফিল্ড রিয়েলিটি ও সতর্কতা",
        "points": [
            "লাইনে কাজ শুরুর আগে নিজের সুরক্ষা সবচেয়ে আগে",
            "পোশাক ও হেলমেট হলো লাইনম্যানের প্রথম সুরক্ষাকবচ",
            "কোনো তাড়াহুড়ো নয় — আগে জীবন, তারপর কাজ"
        ],
        "type": "hero"
    },
    {
        "id": "scene_2",
        "title": "সঠিক কাজের পোশাক নির্বাচন",
        "subtitle": "পোশাকের বিজ্ঞান — কী পরবেন ও কী বর্জন করবেন",
        "text": "কখনোই পলিয়েস্টার বা সিন্থেটিক জামাকাপড় পরবেন না। আর্ক ফ্ল্যাশের উত্তাপে পলিয়েস্টার সরাসরি গলে ত্বকে আটকে যায়। সবসময় ১০০% সুতির ফুল হাতা পোশাক পরুন। ঢিলেঢালা ফতুয়া বা পাজামা বাতাসে উড়ে লাইনের তারে জড়িয়ে যেতে পারে—তাই পোশাক হবে সম্পূর্ণ আঁটোসাঁটো।",
        "img_wrong": "assets/quizzes/mistake_working_alone.webp",
        "img_right": "assets/safety/library/ppe/Arc_Fire_Resistant_Full_Body_Vest.webp",
        "type": "comparison",
        "badge": "👕 কাজের পোশাকের নিয়মাবলী",
        "wrong_points": ["পলিয়েস্টার বা সিন্থেটিক কাপড় নিষিদ্ধ", "ঢিলে ফতুয়া বা পাজামা বিপজ্জনক"],
        "right_points": ["১০০% খাঁটি সুতি (FR) ফুল হাতা পোশাক", "শরীরে আঁটোসাঁটো মাপ (Snug Fit)"]
    },
    {
        "id": "scene_3",
        "title": "ক্লাস-ই সেফটি হেলমেট ও সেফটি বুট",
        "subtitle": "মাথা ও পায়ের বৈদ্যুতিক ইনসুলেশন",
        "text": "মাথার সুরক্ষায় ক্লাস-ই ইলেকট্রিক্যাল হেলমেট পরা বাধ্যতামূলক। এতে কোনো ভেন্টিলেশন ফুটো থাকা চলবে না, যাতে লাইনের স্পার্ক ঢুকতে না পারে। থুতনির ফিতে সবসময় শক্ত করে লক রাখুন। আর পায়ে থাকবে ডাই-ইলেকট্রিক সেফটি বুট—যার সোল কোনো পেরেক বা তার ছাড়া অক্ষত থাকতে হবে।",
        "img_left": "assets/safety/library/ppe/Safety_Helmet.webp",
        "img_right": "assets/safety/library/ppe/Lineman_Boot_2.webp",
        "type": "equipment",
        "badge": "🛡️ প্রধান সুরক্ষা সরঞ্জাম",
        "left_info": ("ক্লাস-ই সেফটি হেলমেট", ["নিশ্ছিদ্র শেল (ভেন্ট ফুটো ছাড়া)", "থুতনির ফিতে (Chin Strap) লক", "সাসপেনশন জালি টাইট রাখুন"]),
        "right_info": ("ডাই-ইলেকট্রিক বুট", ["নন-কন্ডাক্টিভ ইনসুলেটেড সোল", "সোলে পেরেক বা তার নেই তো?", "ভেজা বুট পরা সম্পূর্ণ নিষেধ"])
    },
    {
        "id": "scene_4",
        "title": "ভুল ধারণা বনাম আসল সত্য (Myth Buster)",
        "subtitle": "মাঠপর্যায়ের বিপজ্জনক ভুল বর্জন করুন",
        "text": "মনে রাখবেন: মাথায় গামছা বেঁধে হেলমেট পরলে হেলমেট নড়বড়ে থাকে এবং সামান্য ঝাঁকুনিতেই খুলে পড়ে। আর 'চটি পরে কেবল একটু তার জোড়া দেব'—এই অবহেলাতেই সবচেয়ে বেশি মানুষ পা পিছলে নিচে পড়ে যান।",
        "img_left": "assets/quizzes/mistake_cracked_helmet.webp",
        "img_right": "assets/quizzes/mistake_slippers.webp",
        "type": "myths",
        "badge": "🚫 মারাত্মক ভুল ও সমাধান",
        "myths": [
            ("ভুল ধারণা: মাথায় গামছা থাকলে হেলমেট আরাম লাগে", "আসল সত্য: গামছায় হেলমেট নড়বড়ে হয় ও একটুতেই খুলে পড়ে।"),
            ("ভুল ধারণা: সামান্য কাজের জন্য চটি পরেই ওঠা যায়", "আসল সত্য: চটিতে কোনো গ্রিপ নেই; পা হড়কে পতন ঘটে।")
        ]
    },
    {
        "id": "scene_5",
        "title": "গোল্ডেন রুল ও রিভিশন কুইজ",
        "subtitle": "লেভেল ১.১ সম্পন্ন ও ব্যাজ আনলক",
        "text": "কাজে নামার আগে শরীরকে সম্পূর্ণ সুরক্ষিত রাখুন। এই পাঠের মূল পয়েন্টগুলো মনে রেখেছেন তো? এখনই নিচের কুইজে অংশ নিন, আপনার জ্ঞান যাচাই করুন এবং প্লাস ২০ পয়েন্ট জিতে ট্রেইনি ব্যাজ আনলক করুন!",
        "type": "cta",
        "badge": "🏆 লেসন ১.১ কমপ্লিশন",
        "points": [
            "আগে জীবন — তারপর কাজ!",
            "কুইজ সফল হলে +20 পয়েন্ট প্রোফাইলে যোগ হবে",
            "ট্রেইনি ব্যাজের পরবর্তী পাঠ আনলক হবে"
        ]
    }
]

def get_font(size, bold=False, medium=False):
    path = FONT_BOLD_PATH if bold else (FONT_MED_PATH if medium else FONT_REG_PATH)
    return ImageFont.truetype(path, size)

async def generate_speech_clips():
    print("Generating speech audio clips with edge-tts...")
    audio_files = []
    for sc in SCENES:
        out_mp3 = os.path.join(TEMP_DIR, f"{sc['id']}.mp3")
        out_wav = os.path.join(TEMP_DIR, f"{sc['id']}.wav")
        communicate = edge_tts.Communicate(sc['text'], VOICE, rate=RATE, pitch=PITCH)
        await communicate.save(out_mp3)
        # Convert to wav for precision and inspect duration
        cmd = [FFMPEG_EXE, "-y", "-i", out_mp3, "-ar", "44100", "-ac", "2", out_wav]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        
        # Get duration
        probe_cmd = [
            FFMPEG_EXE, "-i", out_wav,
            "-f", "null", "-"
        ]
        res = subprocess.run([FFMPEG_EXE, "-i", out_wav], stderr=subprocess.PIPE, text=True)
        # extract duration from stderr
        dur = 5.0
        for line in res.stderr.splitlines():
            if "Duration:" in line:
                part = line.split("Duration:")[1].split(",")[0].strip()
                h, m, s = part.split(":")
                dur = float(h)*3600 + float(m)*60 + float(s)
                break
        sc["duration"] = dur + 0.6  # include small natural pause
        sc["audio_wav"] = out_wav
        print(f"Scene {sc['id']}: duration = {dur:.2f}s (+0.6s pause = {sc['duration']:.2f}s)")
        audio_files.append((out_wav, sc["duration"]))
    
    # Concatenate all wavs into one master audio track with 0.6s silence between them
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

    print(f"Master audio created: {master_mp3}")
    return master_wav

def draw_header(draw, title, subtitle, badge_text, progress):
    # Top banner background
    draw.rectangle([0, 0, WIDTH, 110], fill=(15, 23, 42, 240))
    # Border line
    draw.line([0, 110, WIDTH, 110], fill=(245, 158, 11, 200), width=3)
    
    # Progress line at very top
    draw.line([0, 2, WIDTH, 2], fill=(51, 65, 85), width=4)
    prog_w = int(WIDTH * progress)
    if prog_w > 0:
        draw.line([0, 2, prog_w, 2], fill=(245, 158, 11), width=4)

    # Top Brand tag
    font_brand = get_font(18, bold=True)
    draw.text((40, 14), "স্মার্ট লাইনম্যান (SLM) • লেভেল ১.১", font=font_brand, fill=(245, 158, 11))
    
    # Badge
    font_badge = get_font(16, bold=True)
    badge_w = draw.textlength(badge_text, font=font_badge)
    bx = WIDTH - 40 - badge_w - 24
    draw.rounded_rectangle([bx, 14, bx + badge_w + 24, 40], radius=8, fill=(30, 41, 59), outline=(245, 158, 11), width=1)
    draw.text((bx + 12, 16), badge_text, font=font_badge, fill=(254, 243, 199))

    # Title & Subtitle
    font_title = get_font(30, bold=True)
    draw.text((40, 40), title, font=font_title, fill=(255, 255, 255))
    font_sub = get_font(19, medium=True)
    draw.text((40, 78), subtitle, font=font_sub, fill=(148, 163, 184))

def draw_footer(draw):
    draw.rectangle([0, HEIGHT - 50, WIDTH, HEIGHT], fill=(15, 23, 42, 240))
    draw.line([0, HEIGHT - 50, WIDTH, HEIGHT - 50], fill=(30, 41, 59), width=2)
    font_foot = get_font(18, medium=True)
    draw.text((40, HEIGHT - 38), "⚡ WBSEDCL & Utility Safety Standards • জীবনের আগে কোনো কাজ নয়", font=font_foot, fill=(203, 213, 225))
    draw.text((WIDTH - 250, HEIGHT - 38), "SmartLineman.in", font=font_foot, fill=(245, 158, 11))

def render_frame(sc, t_in_scene, progress):
    img = Image.new("RGBA", (WIDTH, HEIGHT), (11, 19, 43, 255))
    draw = ImageDraw.Draw(img)

    # Subtle radial or angled background glow
    # Draw header & footer
    draw_header(draw, sc["title"], sc["subtitle"], sc["badge"], progress)
    draw_footer(draw)

    # Content Area: y from 130 to 650
    content_y = 130

    if sc["type"] == "hero":
        # Draw background site image softly in right half
        if os.path.exists(sc["bg_img"]):
            try:
                bg = Image.open(sc["bg_img"]).convert("RGBA")
                bg = bg.resize((620, 480))
                # Soft fade
                mask = Image.new("L", bg.size, 160)
                img.paste(bg, (600, 135), mask)
            except Exception as e:
                pass
        
        # Left card
        card_rect = [50, 140, 580, 620]
        draw.rounded_rectangle(card_rect, radius=18, fill=(17, 24, 39, 230), outline=(245, 158, 11), width=2)
        
        # Big warning tag inside
        draw.rounded_rectangle([75, 165, 555, 220], radius=10, fill=(180, 83, 9, 80), outline=(245, 158, 11), width=1)
        font_warn = get_font(22, bold=True)
        draw.text((95, 178), "⚠️ কাজের আগে জীবন সুরক্ষা", font=font_warn, fill=(254, 240, 138))

        font_body = get_font(21, medium=True)
        lines = [
            "পোলে ওঠার আগে শরীরের পোশাকই হলো",
            "আর্ক ফ্ল্যাশ ও বৈদ্যুতিক শকের প্রথম প্রতিরোধ।",
            "",
            "✓ ঢিলে পোশাক নয় — আঁটোসাঁটো সুতি পোশাক",
            "✓ কোনো ফুটো ছাড়া ক্লাস-ই সেফটি হেলমেট",
            "✓ খাঁটি ডাই-ইলেকট্রিক ইনসুলেটেড বুট",
            "",
            "মনে রাখবেন: অসতর্কতায় দ্বিতীয় সুযোগ নেই।"
        ]
        curr_y = 250
        for l in lines:
            color = (253, 224, 71) if l.startswith("✓") else ((248, 113, 113) if "দ্বিতীয় সুযোগ নেই" in l else (241, 245, 249))
            draw.text((85, curr_y), l, font=font_body, fill=color)
            curr_y += 38

    elif sc["type"] == "comparison":
        # Two cards: Left = Wrong (Red), Right = Right (Green)
        # Left card
        left_box = [50, 135, 620, 630]
        draw.rounded_rectangle(left_box, radius=16, fill=(24, 24, 27, 240), outline=(239, 68, 68), width=2)
        draw.rounded_rectangle([65, 150, 605, 200], radius=8, fill=(153, 27, 27, 100), outline=(239, 68, 68), width=1)
        font_tag = get_font(22, bold=True)
        draw.text((85, 162), "❌ বর্জনীয়: পলিয়েস্টার ও ঢিলে পোশাক", font=font_tag, fill=(254, 202, 202))

        # Right card
        right_box = [660, 135, 1230, 630]
        draw.rounded_rectangle(right_box, radius=16, fill=(24, 24, 27, 240), outline=(34, 197, 94), width=2)
        draw.rounded_rectangle([675, 150, 1215, 200], radius=8, fill=(22, 101, 52, 100), outline=(34, 197, 94), width=1)
        draw.text((695, 162), "✅ আবশ্যক: ১০০% খাঁটি সুতি (FR) ফুল হাতা", font=font_tag, fill=(187, 247, 208))

        # Put image on right
        if os.path.exists(sc["img_right"]):
            try:
                fr_img = Image.open(sc["img_right"]).convert("RGBA").resize((220, 220))
                img.paste(fr_img, (960, 220), fr_img)
            except Exception:
                pass

        # Text on left
        font_p = get_font(20, medium=True)
        w_lines = [
            "• পলিয়েস্টার/সিন্থেটিক কাপড়:",
            "  আর্ক ফ্ল্যাশের তাপে গলে চামড়ায়",
            "  আটকে মারাত্মক জখম তৈরি করে।",
            "",
            "• ঢিলে ফতুয়া বা পাজামা:",
            "  বাতাসে উড়ে তারে বা যন্ত্রাংশে",
            "  জড়িয়ে গিয়ে ভারসাম্য নষ্ট করে।",
            "",
            "• হাফ টি-শার্ট / খালি হাত:",
            "  স্পার্কে সরাসরি হাত পুড়ে যায়।"
        ]
        y = 220
        for l in w_lines:
            draw.text((75, y), l, font=font_p, fill=(254, 226, 226))
            y += 33

        # Text on right
        r_lines = [
            "• ১০০% সুতি বা ফায়ার রেজিস্ট্যান্ট:",
            "  উচ্চ তাপেও গলে না, চামড়া রক্ষা করে।",
            "",
            "• সম্পূর্ণ ফুল হাতা পোশাক:",
            "  হাতের শেষ প্রান্ত পর্যন্ত ঢেকে রাখে।",
            "",
            "• আঁটোসাঁটো উপযুক্ত মাপ (Snug):",
            "  কোনো আলগা অংশ তারে জড়াবে না।",
            "",
            "• পরিচ্ছন্ন ও তেল-কালি মুক্ত রাখুন।"
        ]
        y = 220
        for l in r_lines:
            draw.text((685, y), l, font=font_p, fill=(220, 252, 231))
            y += 33

    elif sc["type"] == "equipment":
        # Two equipment cards
        left_box = [50, 135, 620, 630]
        draw.rounded_rectangle(left_box, radius=16, fill=(24, 24, 27, 240), outline=(245, 158, 11), width=2)
        right_box = [660, 135, 1230, 630]
        draw.rounded_rectangle(right_box, radius=16, fill=(24, 24, 27, 240), outline=(245, 158, 11), width=2)

        # Left: Helmet
        draw.rounded_rectangle([65, 150, 605, 200], radius=8, fill=(30, 41, 59), outline=(245, 158, 11), width=1)
        font_eq = get_font(23, bold=True)
        draw.text((85, 162), "🪖 ক্লাস-ই সেফটি হেলমেট", font=font_eq, fill=(254, 243, 199))
        if os.path.exists(sc["img_left"]):
            try:
                hl_img = Image.open(sc["img_left"]).convert("RGBA").resize((200, 200))
                img.paste(hl_img, (400, 220), hl_img)
            except Exception:
                pass
        
        font_p = get_font(20, medium=True)
        hl_lines = [
            "১. নিশ্ছিদ্র শেল (ভেন্ট ফুটো ছাড়া):",
            "   ফুটো থাকলে স্পার্ক ও জল ঢুকবে।",
            "",
            "২. থুতনির ফিতে (Chin Strap):",
            "   শক্ত করে লক করা বাধ্যতামূলক।",
            "",
            "৩. সাসপেনশন জালি (Cradle):",
            "   মাথার সাথে ২ সেমি ফাঁক রাখে,",
            "   যা পতনশীল বস্তুর শক শুষে নেয়।"
        ]
        y = 220
        for l in hl_lines:
            draw.text((75, y), l, font=font_p, fill=(241, 245, 249))
            y += 34

        # Right: Boots
        draw.rounded_rectangle([675, 150, 1215, 200], radius=8, fill=(30, 41, 59), outline=(245, 158, 11), width=1)
        draw.text((695, 162), "🥾 ডাই-ইলেকট্রিক সেফটি বুট", font=font_eq, fill=(254, 243, 199))
        if os.path.exists(sc["img_right"]):
            try:
                bt_img = Image.open(sc["img_right"]).convert("RGBA").resize((200, 200))
                img.paste(bt_img, (1000, 220), bt_img)
            except Exception:
                pass
        
        bt_lines = [
            "১. ইলেকট্রিক্যাল ইনসুলেটেড সোল:",
            "   মাটি থেকে ভোল্টেজ ওঠা আটকায়।",
            "",
            "২. সোল চেকলিস্ট:",
            "   কোনো পেরেক, লোহার টুকরো বা",
            "   বাঁধার তার বিঁধে নেই তো?",
            "",
            "৩. শুকনো বুট ব্যবহার করুন:",
            "   ভিজে বুটে কাজ সম্পূর্ণ নিষেধ।"
        ]
        y = 220
        for l in bt_lines:
            draw.text((685, y), l, font=font_p, fill=(241, 245, 249))
            y += 34

    elif sc["type"] == "myths":
        # Myth Buster layout
        top_box = [50, 135, 1230, 360]
        draw.rounded_rectangle(top_box, radius=16, fill=(24, 24, 27, 240), outline=(239, 68, 68), width=2)
        bottom_box = [50, 390, 1230, 630]
        draw.rounded_rectangle(bottom_box, radius=16, fill=(24, 24, 27, 240), outline=(239, 68, 68), width=2)

        font_mh = get_font(22, bold=True)
        font_rt = get_font(21, medium=True)

        # Myth 1: Gamcha + Helmet
        draw.rounded_rectangle([65, 150, 350, 195], radius=8, fill=(153, 27, 27, 100), outline=(239, 68, 68), width=1)
        draw.text((85, 160), "❌ ভুল ধারণা ১", font=font_mh, fill=(254, 202, 202))
        draw.text((370, 160), "মাথায় গামছা পেঁচিয়ে হেলমেট পরলে আরাম পাওয়া যায়।", font=font_rt, fill=(254, 226, 226))

        draw.rounded_rectangle([65, 215, 350, 260], radius=8, fill=(22, 101, 52, 100), outline=(34, 197, 94), width=1)
        draw.text((85, 225), "✅ আসল সত্য", font=font_mh, fill=(187, 247, 208))
        draw.text((370, 225), "গামছায় হেলমেটের গ্রিপ নষ্ট হয়; সামান্য ঝাঁকুনিতেই হেলমেট খুলে পড়ে।", font=font_rt, fill=(220, 252, 231))
        draw.text((370, 265), "👉 সর্বদা খালি মাথায় সঠিক সাইজের হেলমেট ও চিন স্ট্র্যাপ লক করুন।", font=font_rt, fill=(253, 224, 71))

        if os.path.exists(sc["img_left"]):
            try:
                cr_img = Image.open(sc["img_left"]).convert("RGBA").resize((170, 170))
                img.paste(cr_img, (1030, 160), cr_img)
            except Exception:
                pass

        # Myth 2: Slippers / চটি
        draw.rounded_rectangle([65, 410, 350, 455], radius=8, fill=(153, 27, 27, 100), outline=(239, 68, 68), width=1)
        draw.text((85, 420), "❌ ভুল ধারণা ২", font=font_mh, fill=(254, 202, 202))
        draw.text((370, 420), "সামান্য কাজ, চটি পরে বা খালি পায়ে চটপট পোলে ওঠা যায়।", font=font_rt, fill=(254, 226, 226))

        draw.rounded_rectangle([65, 475, 350, 520], radius=8, fill=(22, 101, 52, 100), outline=(34, 197, 94), width=1)
        draw.text((85, 485), "✅ আসল সত্য", font=font_mh, fill=(187, 247, 208))
        draw.text((370, 485), "চটিতে কোনো গ্রিপ নেই; ফিল্ডে স্লিপ করে পতন দুর্ঘটনার প্রধান কারণ চটি।", font=font_rt, fill=(220, 252, 231))
        draw.text((370, 525), "👉 পোলে বা মইতে ওঠার আগে ডাই-ইলেকট্রিক বুটের ফিতে শক্ত করে বাঁধুন।", font=font_rt, fill=(253, 224, 71))

        if os.path.exists(sc["img_right"]):
            try:
                sl_img = Image.open(sc["img_right"]).convert("RGBA").resize((170, 170))
                img.paste(sl_img, (1030, 420), sl_img)
            except Exception:
                pass

    elif sc["type"] == "cta":
        # Final CTA card
        box = [150, 145, 1130, 620]
        draw.rounded_rectangle(box, radius=24, fill=(17, 24, 39, 245), outline=(245, 158, 11), width=3)
        
        # Golden Badge
        font_c1 = get_font(34, bold=True)
        draw.text((340, 175), "⭐ গোল্ডেন ফিল্ড রুল ⭐", font=font_c1, fill=(251, 191, 36))

        font_rule = get_font(28, bold=True)
        draw.text((320, 240), "« আগে জীবন, তারপর কাজ! »", font=font_rule, fill=(255, 255, 255))

        font_pts = get_font(23, medium=True)
        draw.text((260, 320), "• সম্পূর্ণ সুতি ফুল হাতা পোশাক ও নিশ্ছিদ্র হেলমেট", font=font_pts, fill=(226, 232, 240))
        draw.text((260, 365), "• ডাই-ইলেকট্রিক বুটে পেরেক চেক নিশ্চিত করুন", font=font_pts, fill=(226, 232, 240))
        draw.text((260, 410), "• গামছা ও চটি পরে সাইটে প্রবেশ নিষিদ্ধ", font=font_pts, fill=(248, 113, 113))

        # Big CTA button
        btn_rect = [320, 490, 960, 570]
        draw.rounded_rectangle(btn_rect, radius=16, fill=(245, 158, 11), outline=(254, 243, 199), width=2)
        font_btn = get_font(28, bold=True)
        draw.text((360, 510), "📱 অ্যাপে কুইজ দিন ও +20 পয়েন্ট পান!", font=font_btn, fill=(15, 23, 42))

    return img.convert("RGB")

async def build_video():
    master_wav = await generate_speech_clips()

    # Calculate total duration and frames
    total_duration = sum(sc["duration"] for sc in SCENES)
    total_frames = int(total_duration * FPS)
    print(f"Total video duration: {total_duration:.2f}s ({total_frames} frames)")

    raw_video = os.path.join(TEMP_DIR, "raw_video.mp4")
    final_video = os.path.join(OUT_DIR_VIDEO, "lesson_1_1_explainer.mp4")

    # Start ffmpeg process to pipe raw frames
    ffmpeg_cmd = [
        FFMPEG_EXE, "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "fast",
        "-crf", "22",
        raw_video
    ]
    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)

    frame_count = 0
    curr_scene_idx = 0
    scene_start_frame = 0

    print("Rendering video frames...")
    for f in range(total_frames):
        t_global = f / FPS
        # Find which scene we are in
        acc = 0.0
        sc = SCENES[-1]
        for idx, s in enumerate(SCENES):
            if t_global < acc + s["duration"]:
                sc = s
                curr_scene_idx = idx
                break
            acc += s["duration"]

        t_in_scene = t_global - acc
        progress = f / total_frames

        frame_img = render_frame(sc, t_in_scene, progress)
        proc.stdin.write(frame_img.tobytes())
        frame_count += 1
        if frame_count % (FPS * 5) == 0:
            print(f"Rendered {frame_count}/{total_frames} frames ({frame_count/total_frames*100:.1f}%)")

    proc.stdin.close()
    proc.wait()
    print("Raw video rendering complete.")

    # Mux raw video + master audio into final video
    print("Muxing audio and video...")
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
    print(f"Final explainer video generated: {final_video}")

    # Copy files to Artifact directory so user can directly inspect and download them
    shutil.copy2(final_video, os.path.join(ARTIFACT_DIR, "lesson_1_1_explainer.mp4"))
    shutil.copy2(os.path.join(OUT_DIR_AUDIO, "lesson_1_1_explainer.mp3"), os.path.join(ARTIFACT_DIR, "lesson_1_1_explainer.mp3"))
    print(f"Artifacts copied to: {ARTIFACT_DIR}")

if __name__ == "__main__":
    asyncio.run(build_video())
