# -*- coding: utf-8 -*-
"""
Copies new gear icons into assets/zero_loss/scene/ and builds the complete
zero_loss_storm_feeder.json with 12 real-world field jobs, authentic scenes,
tactile layers, spots, and safety protocols.
"""
import json
import os
import shutil

root = r'c:\Dipankar\slm_flutter'
data_path = os.path.join(root, 'assets', 'data', 'zero_loss_storm_feeder.json')
scene_dir = os.path.join(root, 'assets', 'zero_loss', 'scene')

# 1. Copy gear assets into assets/zero_loss/scene/gear_<id>.webp
gear_source_mapping = {
    'discharge_rod': os.path.join(root, 'assets/safety/library/ppe/discharge_rod.webp'),
    'cable_spiking_gun': os.path.join(root, 'assets/safety/library/tools/High_Voltage_Detector.webp'),
    'ipc_clamp': os.path.join(root, 'assets/safety/library/tools/AB_Cable_Stripper.webp'),
    'torque_wrench': os.path.join(root, 'assets/safety/library/tools/Torque_Wrench.webp'),
    'tree_saw': os.path.join(root, 'assets/safety/library/tools/Hacksaw.webp'),
    'high_vis_vest': os.path.join(root, 'assets/safety/library/ppe/High_Visibility_Vest_3.webp'),
    'high_lumen_torch': os.path.join(root, 'assets/safety/library/ppe/Helmet_Mounted_Torch_2.webp'),
    'fuse_wire': os.path.join(root, 'assets/quizzes/mat_acsr.webp'),
    'oil_gauge': os.path.join(root, 'assets/quizzes/ptr_part_oil_gauge.webp'),
    'plain_wire': os.path.join(root, 'assets/quizzes/mat_acsr.webp'),
    'iron_sickle': os.path.join(root, 'assets/safety/library/tools/Hacksaw.webp'),
    'wet_cloth': os.path.join(root, 'assets/safety/library/tools/Measuring_Tape.webp'),
}

for gid, src in gear_source_mapping.items():
    dst = os.path.join(scene_dir, f'gear_{gid}.webp')
    if os.path.exists(src) and not os.path.exists(dst):
        shutil.copy2(src, dst)
        print(f"Copied {src} -> {dst}")

with open(data_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Update truck capacity
data['truck_capacity'] = 8
data['voice']['zero_loss_bn'] = "সাবাস ভাই! দুটো ফল্টই ঠিক হলো, ফিডারে আলো ফিরল, আর আমাদের দলের সবাই অক্ষত দেহে বাড়ি ফিরছে। এই হলো আসল স্মার্ট লাইনম্যান।" 

# Add new accident causes
new_accident_causes = {
    "arc_flash": {
        "title_bn": "মারাত্মক আর্ক ফ্ল্যাশ",
        "line_bn": "ফেস শিল্ড ছিল না। ১০,০০০ ডিগ্রি তীব্র আগুনের শিখায় চোখ ও শরীর ঝলসে গেল।",
        "image": "assets/zero_loss/scene/acc_arc_flash.webp"
    },
    "cable_blast": {
        "title_bn": "আন্ডারগ্রাউন্ড কেবল বিস্ফোরণ",
        "line_bn": "স্পাইকিং টেস্ট না করে লাইভ কেবল কাটায় প্রচণ্ড বিস্ফোরণ ও অগ্নিকাণ্ড।",
        "image": "assets/zero_loss/scene/acc_cable_blast.webp"
    },
    "tree_flashover": {
        "title_bn": "ডালে ১১ কেভি ফ্ল্যাশওভার",
        "line_bn": "পারমিট ছাড়া কাটার সময় ভেজা ডাল তারে ঠেকে প্রচণ্ড বিদ্যুৎ বিস্ফোরণ।",
        "image": "assets/zero_loss/scene/acc_tree_flashover.webp"
    },
    "induction_shock": {
        "title_bn": "পাশের লাইনের ইন্ডাকশন শক",
        "line_bn": "দুই দিকে আর্থিং ছিল না। সমান্তরাল দ্বিতীয় সার্কিটের আবেশে প্রাণঘাতী শক।",
        "image": "assets/zero_loss/scene/acc_induction.webp"
    },
    "pole_collapse": {
        "title_bn": "পোল হুড়মুড়িয়ে ভেঙে পড়ল",
        "line_bn": "গোড়া ভাঙা পোল শক্ত না বেঁধে কাজ করায় পোল ভেঙে কর্মীদের ওপর ধস।",
        "image": "assets/zero_loss/scene/acc_pole_collapse.webp"
    }
}
for k, v in new_accident_causes.items():
    data['accident_causes'][k] = v

# Update gear items: all MUST point to assets/zero_loss/scene/gear_*.webp
updated_gear = []
seen_gear = set()
for g in data['gear']:
    gid = g['id']
    if gid in seen_gear:
        continue
    seen_gear.add(gid)
    # Ensure correct image path
    g['image'] = f"assets/zero_loss/scene/gear_{gid}.webp"
    updated_gear.append(g)

data['gear'] = updated_gear

# 12 real field jobs definition
jobs_catalog = [
    # 1. Fault 1 (Original)
    {
        "fault_id": "pole_insulator",
        "slot": "A",
        "short_title_bn": "ফাটা পিন ইনসুলেটর",
        "title_bn": "১১ কেভি পিন ইনসুলেটর বাস্ট — ফিডার ট্রিপ",
        "detail_bn": "{placeA}-এ ১১ কেভি লাইনের একটা পিন ইনসুলেটর ফেটে গেছে। গোটা ফিডার বন্ধ, প্রায় তিনশো বাড়ি অন্ধকার।",
        "severity": "high",
        "work": "climb",
        "urgency_minutes": 75,
        "required_crew_count": 3,
        "travel_minutes": 18,
        "repair_minutes": 20,
        "required_gear": ["tester", "earth_rods", "ptw", "lock_board"],
        "job_gear": ["spare_insulator", "frp_ladder"],
        "events": [
            {
                "id": "p_stop",
                "mantra": "stop",
                "image": "assets/quizzes/proc_no_brief.webp",
                "speaker": "junior",
                "alert_bn": "আকাশে ঘন মেঘ, ঝড়-বৃষ্টি শুরু",
                "line_bn": "দাদা, ঝড় বাড়ছে! চট করে উঠে ইনসুলেটরটা বদলে নামি?",
                "situation_bn": "{placeA}-এ ১১ কেভি লাইনে কাজ শুরু করার মুখে আকাশ ভেঙে বৃষ্টি নামছে, ঘনঘন বাজ পড়ছে। {junior} তাড়া দিচ্ছে উপরে ওঠার।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.62, 0.48],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_phone", "role": "lead", "x": 0.26, "y": 0.985, "h": 0.36, "when": ["before", "wrong"]},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.985, "h": 0.36, "when": "best"},
                        {"sprite": "man_point", "role": "junior", "x": 0.84, "y": 0.99, "h": 0.37, "when": ["before", "best"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.6, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.25, "y": 0.25, "r": 0.11, "label_bn": "বাজ পড়ছে", "icon": "bolt"},
                        {"x": 0.75, "y": 0.18, "r": 0.07, "label_bn": "ফাটা ইনসুলেটর", "icon": "broken"},
                        {"x": 0.65, "y": 0.88, "r": 0.08, "label_bn": "পিচ্ছিল কাদা", "icon": "slip"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "wait", "short_bn": "বাজ থামুক, দাঁড়াও", "text_bn": "থামো! ঝড়-বৃষ্টিতে পোলে ওঠা নিষেধ। মাটিতে অপেক্ষা করো।", "best": True, "safety": 10, "satisfaction": -2, "minutes": 10, "risk": 0.0, "feedback_bn": "সঠিক সিদ্ধান্ত। ঝড়ের মধ্যে পোলে ওঠা মানে মৃত্যুর ঝুঁকি। জীবন আগে, লাইন পরে।"},
                    {"id": "b", "icon": "rush", "cause": "lightning", "short_bn": "তাড়াতাড়ি উঠে সেরে নাও", "text_bn": "বৃষ্টির মধ্যেই তাড়াতাড়ি উঠে শেষ করো, দেরি হলে বকা খাব।", "best": False, "safety": -25, "satisfaction": 3, "minutes": 0, "risk": 0.35, "feedback_bn": "ঝড়ের মধ্যে পোলে ওঠার সিদ্ধান্ত ছিল ভয়াবহ। বাজ পড়ে কর্মী গুরুতর আহত হতে পারত।"},
                    {"id": "c", "icon": "alone", "cause": "fall", "short_bn": "তুমি একা উঠে দেখে নাও", "text_bn": "{junior} একাই উঠে দেখে নিক, আমরা গাড়িতে বসছি।", "best": False, "safety": -15, "satisfaction": 0, "minutes": 0, "risk": 0.2, "feedback_bn": "একা কাউকে পোলে পাঠানো নিয়মবিরুদ্ধ। পিচ্ছিল পোলে পা পিছলে দুর্ঘটনা ঘটতে পারত।"}
                ]
            },
            {
                "id": "p_earth",
                "mantra": "earth",
                "image": "assets/quizzes/proc_earth_one_phase.webp",
                "speaker": "junior",
                "alert_bn": "পাশের মিলবাড়িতে জেনারেটর চলছে",
                "line_bn": "দাদা, পাশের মিলবাড়িতে জেনারেটর চলছে! টেস্টার দিয়ে পরখ করুন, লাইনে উল্টো কারেন্ট আসতে পারে। দুই দিকেই আর্থিং রড না ঝুলিয়ে পোলে উঠবেন না।",
                "situation_bn": "দাদা, পাশের মিলবাড়িতে জেনারেটর চলছে! টেস্টার দিয়ে পরখ করুন, লাইনে উল্টো কারেন্ট আসতে পারে। দুই দিকেই আর্থিং রড না ঝুলিয়ে পোলে উঠবেন না।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.65, 0.45],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "earth_set", "x": 0.58, "y": 0.55, "h": 0.2, "when": "best"},
                        {"sprite": "man_tester", "role": "lead", "x": 0.32, "y": 0.985, "h": 0.36, "when": ["before", "best"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.25, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.82, "y": 0.99, "h": 0.37, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.58, "y": 0.42, "r": 0.08, "label_bn": "১১ কেভি তার", "icon": "bolt"},
                        {"x": 0.32, "y": 0.85, "r": 0.08, "label_bn": "টেস্টার দিয়ে পরীক্ষা", "icon": "tester"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "টেস্ট + দুই দিকে আর্থিং", "text_bn": "এইচভি টেস্টার দিয়ে চেক করো, তারপর কাজের জায়গার দুই দিকে আর্থিং রড লাগাও।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 5, "risk": 0.0, "feedback_bn": "একেবারে সঠিক। টেস্টার দিয়ে নিশ্চিত হয়ে দুই দিকে আর্থিং না করলে ব্যাকফিডের বিপদ থাকে।"},
                    {"id": "b", "icon": "one_side", "cause": "backfeed", "short_bn": "একদিকে আর্থ করলেই হবে", "text_bn": "একদিকে আর্থিং করলেই যথেষ্ট, সাবস্টেশন তো অফ করাই আছে।", "best": False, "safety": -20, "satisfaction": 2, "minutes": 0, "risk": 0.3, "feedback_bn": "একদিকের আর্থিং যথেষ্ট নয়। অন্যদিক থেকে জেনারেটরের ব্যাকফিডে মারাত্মক শক লাগতে পারত।"},
                    {"id": "c", "icon": "no_test", "cause": "charged", "short_bn": "টেস্ট লাগবে না, সরাসরি ওঠো", "text_bn": "পারমিট আছে যখন, টেস্টার লাগবে না। সরাসরি পোলে ওঠো।", "best": False, "safety": -30, "satisfaction": 3, "minutes": 0, "risk": 0.4, "feedback_bn": "টেস্টার ছাড়া লাইনে হাত দেওয়া সবচেয়ে বড় ভুল। সাবস্টেশনে ভুল ফিডার কাটা হতে পারত।"}
                ]
            },
            {
                "id": "p_mend",
                "mantra": "mend",
                "image": "assets/quizzes/proc_cut_safety_belt.webp",
                "speaker": "lead",
                "alert_bn": "পোলে ওঠার সময়",
                "line_bn": "ইনসুলেটর বদলাতে পোলে উঠতে হবে। কীভাবে উঠবে?",
                "situation_bn": "পোলে ওঠার প্রস্তুতি নিচ্ছেন {junior}। কী নির্দেশ দেবেন?",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.4],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.985, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.25, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.985, "h": 0.37, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.6, "y": 0.4, "r": 0.08, "label_bn": "পোল অ্যাঙ্করিং", "icon": "harness"},
                        {"x": 0.22, "y": 0.85, "r": 0.08, "label_bn": "সহকর্মীর নজর", "icon": "eye"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "harness", "short_bn": "ফুল বডি হারনেস লক করো", "text_bn": "ফুল বডি হারনেস পোলে শক্ত করে লক করো। দুই হাত খালি রেখে ওপরে ওঠো।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "ঠিক তাই। ফুল বডি হারনেস ছাড়া পোলে ওঠা আইনত অপরাধ এবং জীবনঘাতী।"},
                    {"id": "b", "icon": "belt", "cause": "fall", "short_bn": "কোমর-রশা পেঁচিয়ে ওঠো", "text_bn": "কোমরে দড়িটা এক পাক পেঁচিয়ে উঠে পড়ো, বেশিক্ষণ তো লাগবে না।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "কোমর-দড়ি কোনো নিরাপত্তা দেয় না। হাত ফসকালে নিচে পড়ে শিরদাঁড়া ভাঙার ঝুঁকি।"},
                    {"id": "c", "icon": "hurry", "cause": "fall", "short_bn": "কোনো কিছু ছাড়াই চট করে ওঠো", "text_bn": "হারনেস পরতে দেরি হবে, সাবধানে এমনিই উঠে সেরে এসো।", "best": False, "safety": -35, "satisfaction": 2, "minutes": 0, "risk": 0.45, "feedback_bn": "বিনা সুরক্ষায় পোলে ওঠা আত্মহত্যার সামিল। একটু অসাবধানে নিচে পড়ে মৃত্যু হতে পারত।"}
                ]
            }
        ]
    },
    # 2. Fault 2 (Original)
    {
        "fault_id": "wire_on_ground",
        "slot": "B",
        "short_title_bn": "ছিঁড়ে মাটিতে লাইভ তার",
        "title_bn": "১১ কেভি তার ছিঁড়ে রাস্তায় — ভিড় জমেছে",
        "detail_bn": "{placeB}-এ ১১ কেভি তার ছিঁড়ে রাস্তার ওপর পড়ে আছে। গ্রামের লোকজন গোল হয়ে দেখছে, গরু-বাছুর ঘুরছে।",
        "severity": "critical",
        "work": "ground",
        "urgency_minutes": 60,
        "required_crew_count": 2,
        "travel_minutes": 14,
        "repair_minutes": 25,
        "required_gear": ["tester", "earth_rods", "ptw", "tape_cones"],
        "job_gear": ["wire_grip"],
        "events": [
            {
                "id": "w_fence",
                "mantra": "fence",
                "image": "assets/quizzes/mistake_public_near_line.webp",
                "speaker": "lead",
                "alert_bn": "বাঁশ দিয়ে জ্যান্ত তার ছোঁয়ার চেষ্টা!",
                "line_bn": "এই দাদা, সরুন! ভেজা বাঁশ দিয়ে তারে ছোঁবেন না! সবাই দশ হাত দূরে যান, লাল ফিতে দিয়ে ঘেরা হচ্ছে!",
                "situation_bn": "এই দাদা, সরুন! ভেজা বাঁশ দিয়ে তারে ছোঁবেন না! সবাই দশ হাত দূরে যান, লাল ফিতে দিয়ে ঘেরা হচ্ছে!",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.6, 0.72],
                    "layers": [
                        {"sprite": "cones_tape", "x": 0.42, "y": 0.9, "h": 0.14, "when": "best"},
                        {"sprite": "villagers", "x": 0.78, "y": 0.95, "h": 0.38, "when": ["before", "wrong"]},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_phone", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36, "when": ["before", "wrong"]}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.78, "r": 0.09, "label_bn": "মাটিতে ১১ কেভি তার", "icon": "bolt"},
                        {"x": 0.78, "y": 0.8, "r": 0.08, "label_bn": "উৎসুক সাধারণ মানুষ", "icon": "crowd"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "tape", "short_bn": "ফিতে দিয়ে ঘেরো, লোক সরাও", "text_bn": "লাল ফিতে আর কোন দিয়ে অন্তত ১০ মিটার জায়গা ঘেরো। চিৎকার করে সবাইকে দূরে পাঠাও।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 4, "risk": 0.0, "feedback_bn": "চমৎকার। স্টেপ পটেনশিয়ালের বিপদ এড়াতে সাধারণ মানুষকে অন্তত ৮-১০ মিটার দূরে রাখতেই হবে।"},
                    {"id": "b", "icon": "bamboo", "cause": "public", "short_bn": "শুকনো বাঁশ দিয়ে তার সরিয়ে দাও", "text_bn": "শুকনো বাঁশ দিয়ে তারটা রাস্তার একপাশে সরিয়ে দাও, যাতে গাড়ি যেতে পারে।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "১১ কেভি তার বাঁশ দিয়ে সরানো যায় না! বাঁশের সামান্য আর্দ্রতাতেও বিদ্যুৎ চলে আসে।"},
                    {"id": "c", "icon": "ignore", "cause": "public", "short_bn": "আগে সাবস্টেশন কল করো", "text_bn": "লোকজন তো দেখছেই, আগে শান্তিতে সাবস্টেশনে ফোন করে পাওয়ার কাটি।", "best": False, "safety": -20, "satisfaction": -1, "minutes": 2, "risk": 0.3, "feedback_bn": "ফোন করার সময়টুকুতেই কেউ তার ছুঁয়ে ফেলতে পারে। প্রথম কাজ জায়গা ঘেরা ও মানুষ হটানো।"}
                ]
            },
            {
                "id": "w_cut",
                "mantra": "cut",
                "image": "assets/quizzes/proc_verbal_ptw.webp",
                "speaker": "substation",
                "alert_bn": "সাবস্টেশন থেকে ফোনে কথা",
                "line_bn": "ফিডার অফ করে দিয়েছি। কাজ শুরু করতে পারো।",
                "situation_bn": "সাবস্টেশন অপারেটর ফোনে বলল পাওয়ার অফ। আপনি কী করবেন?",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.4, 0.7],
                    "layers": [
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36},
                        {"sprite": "lock_board", "x": 0.2, "y": 0.88, "h": 0.12, "when": "best"},
                        {"sprite": "man_tester", "role": "junior", "x": 0.65, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.28, "y": 0.85, "r": 0.08, "label_bn": "লিখিত পিটিডব্লিউ বই", "icon": "permit"},
                        {"x": 0.52, "y": 0.78, "r": 0.08, "label_bn": "তারের ভোল্টেজ পরীক্ষা", "icon": "tester"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "ptw", "short_bn": "লিখিত পারমিট + লক বোর্ড চাই", "text_bn": "মুখে বলায় হবে না। পিটিডব্লিউ বইতে লিখে দিন, ব্রেকারে তালা মারুন, ডেঞ্জার বোর্ড ঝোলান।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 6, "risk": 0.0, "feedback_bn": "পেশাদার লাইনম্যানের মতো কাজ। মৌখিক কথায় কাজ শুরু করলে কেউ ভুল করে চার্জ দিতে পারে।"},
                    {"id": "b", "icon": "trust", "cause": "charged", "short_bn": "অপারেটর বলেছে, শুরু করি", "text_bn": "অপারেটর যখন বলল, তখন অফ হয়ে গেছে। তার জোড়া লাগানো শুরু করো।", "best": False, "safety": -30, "satisfaction": 3, "minutes": 0, "risk": 0.4, "feedback_bn": "মৌখিক আশ্বাসে কাজ শুরু করে প্রতি বছর দুর্ঘটনা ঘটে। লিখিত পারমিট ও তালা বাধ্যতামূলক।"},
                    {"id": "c", "icon": "touch_test", "cause": "shock", "short_bn": "প্লায়ার্স দিয়ে ছুঁয়ে দেখো", "text_bn": "ইনসুলেটেড প্লায়ার্স দিয়ে হালকা ছুঁয়ে দেখে নিই সত্যিই কারেন্ট আছে কিনা।", "best": False, "safety": -35, "satisfaction": 0, "minutes": 0, "risk": 0.45, "feedback_bn": "প্লায়ার্স দিয়ে ১১ কেভি তার ছোঁয়া মারাত্মক বোকামি। ফ্ল্যাশওভারে হাত পুড়ে যেত।"}
                ]
            },
            {
                "id": "w_count",
                "mantra": "count",
                "image": "assets/quizzes/proc_remove_earth_first.webp",
                "speaker": "lead",
                "alert_bn": "কাজ শেষ হয়েছে",
                "line_bn": "তার জোড়া লাগানো শেষ। এবার লাইন চার্জের জন্য কী করব?",
                "situation_bn": "কাজ শেষ। লাইন আবার চালু করার আগে সঠিক ক্রম কী?",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.55, 0.7],
                    "layers": [
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36},
                        {"sprite": "man_stop", "role": "junior", "x": 0.75, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.75, "r": 0.08, "label_bn": "নতুন জোড়া লাগানো তার", "icon": "wire"},
                        {"x": 0.28, "y": 0.85, "r": 0.08, "label_bn": "টুলবক্স গোনা ও রিপোর্ট", "icon": "count"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "count", "short_bn": "হাতিয়ার গোনো, আর্থ খোলো, রিপোর্ট", "text_bn": "আগে হাতিয়ার ও লোক গোনো, আর্থিং রড সবার শেষে খোলো, পারমিট ফেরত দিয়ে চার্জ দিতে বলো।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 5, "risk": 0.0, "feedback_bn": "নিখুঁত প্রক্রিয়া। আর্থিং রড সবার শেষে খুলতে হয় এবং সব হাতিয়ার না গুনে লাইন চালু করা যায় না।"},
                    {"id": "b", "icon": "early_charge", "cause": "arc_flash", "short_bn": "আগে চার্জ দিন, জিনিস তুলছি", "text_bn": "সাবস্টেশনকে বলুন চার্জ দিতে, আমরা ততক্ষণে ফিতে আর হাতিয়ার গুটিয়ে নিচ্ছি।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "আর্থিং লাগানো অবস্থায় চার্জ দিলে বিরাট শর্ট-সার্কিট ও বিস্ফোরণ হতো।"},
                    {"id": "c", "icon": "hurry_leave", "cause": "public", "short_bn": "তাড়াতাড়ি গাড়িতে ওঠো", "text_bn": "সব ঠিক আছে, গাড়িতে উঠে পড়ো। অপারেটরকে বলো লাইন অন করতে।", "best": False, "safety": -15, "satisfaction": 1, "minutes": 0, "risk": 0.2, "feedback_bn": "মাটিতে হাতিয়ার বা তারের টুকরো ফেলে গেলে পরে তা বিপজ্জনক হতে পারে। গোনা আবশ্যক।"}
                ]
            }
        ]
    },
    # 3. DTR HG Fuse
    {
        "fault_id": "dtr_hg_fuse",
        "slot": "A",
        "short_title_bn": "ডিটিআর ফিউজ উড়েছে",
        "title_bn": "ট্রান্সফরমারের এইচ জি ফিউজ বদল ও বুশিং চেক",
        "detail_bn": "{placeA}-এ ১০০ কেভিএ ট্রান্সফরমারের এইচ জি ফিউজ বাস্ট করে গোটা গ্রাম অন্ধকার। গরমে গ্রামবাসীরা সাবস্টেশন ঘেরাওয়ের হুমকি দিচ্ছে।",
        "severity": "high",
        "work": "climb",
        "urgency_minutes": 60,
        "required_crew_count": 3,
        "travel_minutes": 15,
        "repair_minutes": 20,
        "required_gear": ["tester", "discharge_rod", "ptw", "lock_board"],
        "job_gear": ["fuse_wire", "frp_ladder"],
        "events": [
            {
                "id": "df_stop",
                "mantra": "cut",
                "image": "assets/quizzes/mistake_dofuse_under.webp",
                "speaker": "junior",
                "alert_bn": "জিও সুইচ এখনো অন",
                "line_bn": "দাদা, গ্রাহকরা চ্যাঁচামেচি করছে! জিও সুইচ না কেটে চট করে ফিউজটা তার দিয়ে পেঁচিয়ে দিই?",
                "situation_bn": "{placeA}-এ ১০০ কেভিএ ট্রান্সফরমারের এইচ জি ফিউজ উড়ে গোটা গ্রাম অন্ধকার। {junior} তাড়া দিচ্ছে জিও সুইচ না কেটে কাজ করতে।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.62, 0.48],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_phone", "role": "lead", "x": 0.26, "y": 0.985, "h": 0.36, "when": ["before", "wrong"]},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.985, "h": 0.36, "when": "best"},
                        {"sprite": "man_point", "role": "junior", "x": 0.84, "y": 0.99, "h": 0.37, "when": ["before", "best"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.6, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.65, "y": 0.35, "r": 0.08, "label_bn": "ডিটিআর এইচটি বুশিং", "icon": "bolt"},
                        {"x": 0.3, "y": 0.78, "r": 0.08, "label_bn": "জিও সুইচ হ্যান্ডেল", "icon": "warning"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "switch", "short_bn": "আগে জিও অফ + তালা", "text_bn": "থামো! আগে জিও সুইচ কাটো, হ্যান্ডেলে তালা মারো, ডেঞ্জার বোর্ড ঝোলাও।", "best": True, "safety": 8, "satisfaction": -2, "minutes": 6, "risk": 0.0, "feedback_bn": "ঠিক করেছেন। জিও সুইচ অফ আর তালা ছাড়া ট্রান্সফরমার প্ল্যাটফর্মে ওঠা সাক্ষাৎ মৃত্যু।"},
                    {"id": "b", "icon": "rush", "cause": "charged", "short_bn": "চট করে জড়িয়ে দাও", "text_bn": "হ্যাঁ, তার দিয়ে চট করে পেঁচিয়ে দাও, গ্রাহক খুব রেগে আছে।", "best": False, "safety": -30, "satisfaction": 3, "minutes": 0, "risk": 0.35, "feedback_bn": "১১ কেভি এইচটি বুশিংয়ে হাত দিতেই প্রচণ্ড ফ্ল্যাশওভারে ঝলসে গেল।"},
                    {"id": "c", "icon": "alone", "cause": "fall", "short_bn": "একাই উঠে হ্যান্ডেল টানো", "text_bn": "{junior} একাই উপরে উঠে ফিউজ হ্যান্ডেলটা টেনে দিক।", "best": False, "safety": -20, "satisfaction": 0, "minutes": 0, "risk": 0.25, "feedback_bn": "একা তেলচিটে স্লিপারি প্লিন্থে কাজ করতে গিয়ে নিচে পড়ে গেল।"}
                ]
            },
            {
                "id": "df_earth",
                "mantra": "earth",
                "image": "assets/quizzes/proc_test_before_climb.webp",
                "speaker": "lead",
                "alert_bn": "এইচটি বুশিংয়ে স্ট্যাটিক চার্জ",
                "line_bn": "সুইচ কাটা হয়েছে। কিন্তু ট্রান্সফরমার কয়েলে সঞ্চিত বিদ্যুৎ থাকতে পারে।",
                "situation_bn": "জিও সুইচ কাটার পর বুশিংয়ে হাত দেওয়ার আগে কী করবেন?",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.4],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_tester", "role": "lead", "x": 0.45, "y": 0.98, "h": 0.36, "when": ["before", "best"]},
                        {"sprite": "earth_set", "x": 0.58, "y": 0.65, "h": 0.18, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.6, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.62, "y": 0.38, "r": 0.08, "label_bn": "স্ট্যাটিক চার্জ সম্ভাবনা", "icon": "bolt"},
                        {"x": 0.45, "y": 0.88, "r": 0.08, "label_bn": "ডিসচার্জ রড পয়েন্ট", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "টেস্ট + ডিসচার্জ রড", "text_bn": "আগে এইচভি টেস্টার দিয়ে দেখো, তারপর ডিসচার্জ রড দিয়ে তিনটে ফেজের বুশিং গ্রাউন্ড করো।", "best": True, "safety": 8, "satisfaction": -1, "minutes": 5, "risk": 0.0, "feedback_bn": "সঠিক নিয়ম। ট্রান্সফরমারের ওয়াইন্ডিংয়ে জমা স্ট্যাটিক কারেন্ট ডিসচার্জ রড মাটিতে পাঠিয়ে দেয়।"},
                    {"id": "b", "icon": "no_earth", "cause": "shock", "short_bn": "সুইচ অফ, ডিসচার্জ লাগবে না", "text_bn": "সুইচ যখন অফ, আর ডিসচার্জ লাগবে না, খালি হাতেই ফিউজ খোলো।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.3, "feedback_bn": "ক্যাপাসিটিভ স্ট্যাটিক চার্জে বিদ্যুৎস্পৃষ্ট হয়ে হাত পুড়ে গেল।"},
                    {"id": "c", "icon": "bamboo", "cause": "shock", "short_bn": "বাঁশের কঞ্চি দিয়ে ছোঁয়াও", "text_bn": "ডিসচার্জ রড ট্রাকে নেই, বাঁশের কঞ্চি দিয়ে বুশিং ঠেকিয়ে দেখো।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 1, "risk": 0.25, "feedback_bn": "ভেজা বাঁশ দিয়ে কারেন্ট শরীরে চলে এল।"}
                ]
            },
            {
                "id": "df_count",
                "mantra": "count",
                "image": "assets/quizzes/proc_work_after_close.webp",
                "speaker": "substation",
                "alert_bn": "পোলে এখনো কাজ চলছে",
                "line_bn": "ফিউজ লাগানো হলো? সাবস্টেশন থেকে লাইন চালু করে দেব?",
                "situation_bn": "নতুন ফিউজ তার লাগানো শেষ। সাবস্টেশন লাইন চার্জ দিতে চাইছে।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.62, 0.45],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.985, "h": 0.36},
                        {"sprite": "man_stop", "role": "junior", "x": 0.75, "y": 0.985, "h": 0.36, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.6, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.6, "y": 0.5, "r": 0.08, "label_bn": "ট্রান্সফরমার প্ল্যাটফর্ম", "icon": "hazard"},
                        {"x": 0.25, "y": 0.85, "r": 0.08, "label_bn": "টুলবক্স গোনা", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "count", "short_bn": "সবাই নামুক, তবে জিও অন", "text_bn": "দাঁড়ান! সবাই নামুক, ডিসচার্জ রড খুলি, হাতিয়ার গুনি, পারমিট ক্লোজ করে তবে জিও সুইচ তুলব।", "best": True, "safety": 8, "satisfaction": -1, "minutes": 5, "risk": 0.0, "feedback_bn": "সবাই নিচে নামার পর জিও সুইচ তোলাই আসল পেশাদারি লাইনম্যানের ধর্ম।"},
                    {"id": "b", "icon": "power_on", "cause": "arc_flash", "short_bn": "পোলে থেকেই জিও তোলো", "text_bn": "হ্যাঁ চার্জ দিয়ে দিন, আমরা পোলে দাঁড়িয়েই দেখে নিচ্ছি ফিউজ ঠিক আছে কিনা।", "best": False, "safety": -35, "satisfaction": 3, "minutes": 0, "risk": 0.4, "feedback_bn": "চার্জ হতেই চোখের সামনে প্রচণ্ড আর্ক বিস্ফোরণ! পোলে থাকা কর্মীর চোখ ক্ষতিগ্রস্ত হলো।"}
                ]
            }
        ]
    },
    # 4. Service Connection
    {
        "fault_id": "service_connection",
        "slot": "B",
        "short_title_bn": "বাজারে নতুন সার্ভিস সংযোগ",
        "title_bn": "জনবহুল হাটে নতুন দোকানঘরে সার্ভিস তার টানা",
        "detail_bn": "{placeB}-এ হাটের ব্যস্ত গলিতে তিনতলা দোকানের নতুন মিটার সার্ভিস লাইন টানতে হবে। নিচে প্রচুর লোক ও রিকশার যাতায়াত।",
        "severity": "medium",
        "work": "climb",
        "urgency_minutes": 50,
        "required_crew_count": 2,
        "travel_minutes": 12,
        "repair_minutes": 18,
        "required_gear": ["tester", "gloves", "tape_cones", "frp_ladder"],
        "job_gear": ["wire_grip"],
        "events": [
            {
                "id": "sc_fence",
                "mantra": "fence",
                "image": "assets/zero_loss/scene/bg_market_wire_down.webp",
                "speaker": "lead",
                "alert_bn": "হাটের ভিড়ে সার্ভিস তারের জটলা",
                "line_bn": "তার টানার সময় নিচে ক্রেতা ও রিকশার ভিড়। কীভাবে ব্যারিকেড করব?",
                "situation_bn": "ব্যস্ত বাজারের ওপর দিয়ে সার্ভিস তার টানার সময় নিচে মানুষের ভিড়।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.5, 0.6],
                    "layers": [
                        {"sprite": "cones_tape", "x": 0.42, "y": 0.88, "h": 0.14, "when": "best"},
                        {"sprite": "villagers", "x": 0.8, "y": 0.95, "h": 0.38},
                        {"sprite": "man_stop", "role": "lead", "x": 0.25, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.78, "y": 0.75, "r": 0.09, "label_bn": "হাটের উৎসুক পথচারী", "icon": "crowd"},
                        {"x": 0.42, "y": 0.88, "r": 0.08, "label_bn": "ব্যারিকেড এলাকা", "icon": "fence"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "tape", "short_bn": "কোন ও ফিতে দিয়ে ঘিরে নাও", "text_bn": "ফিতে আর কোন বসিয়ে রাস্তা সুরক্ষিত করো। সহকারী ট্রাফিক আর পথচারীদের সতর্ক রাখুক।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "খুব ভালো। সার্ভিস তার টানার সময় তার ফসকে পথচারীর গায়ে পড়া আটকাতে ব্যারিকেড জরুরি।"},
                    {"id": "b", "icon": "hurry", "cause": "public", "short_bn": "মুখের কথায় লোক সরিয়ে টানো", "text_bn": "ফিতে বাঁধার সময় নেই, চিৎকার করে পথচারীদের সরে যেতে বলে তার ছুড়ে দাও।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "ছুড়ে দেওয়া সার্ভিস তার গিয়ে সাইকেল আরোহীর গলায় আটকে রক্তারক্তি কাণ্ড।"}
                ]
            },
            {
                "id": "sc_cut",
                "mantra": "cut",
                "image": "assets/quizzes/proc_cut_safety_belt.webp",
                "speaker": "junior",
                "alert_bn": "এলটি কাটআউট এখনো লাইভ",
                "line_bn": "দাদা, সার্ভিস পাইপের কাটআউট ফিউজটা কি খুলে রাখব নাকি লাইভ অবস্থাতেই কানেকশন করব?",
                "situation_bn": "গ্রাহকের মিটারের সার্ভিস কাটআউটে তার সংযোগ দেওয়ার সঠিক নিরাপত্তা কোনটি?",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.55, 0.4],
                    "layers": [
                        {"sprite": "man_tester", "role": "lead", "x": 0.3, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.62, "y": 0.65, "h": 0.25, "when": "wrong"},
                        {"sprite": "lock_board", "x": 0.2, "y": 0.85, "h": 0.12, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.65, "y": 0.42, "r": 0.08, "label_bn": "এলটি কাটআউট বক্স", "icon": "switch"},
                        {"x": 0.48, "y": 0.58, "r": 0.08, "label_bn": "সার্ভিস তারের সংযোগ", "icon": "bolt"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "cut", "short_bn": "কাটআউট ফিউজ ক্যারিয়ার খোলো", "text_bn": "আগে কাটআউট ফিউজ ক্যারিয়ার খুলে পকেটে রাখো। টেস্টার দিয়ে চেক করে শূন্য লোডে সংযোগ দাও।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "সঠিক সিদ্ধান্ত। লোড অন থাকলে কানেকশন দেওয়ার সময় প্রচণ্ড স্পার্কিং হয়।"},
                    {"id": "b", "icon": "rush", "cause": "arc_flash", "short_bn": "লাইভ কাটআউটে সরাসরি জুড়ুন", "text_bn": "দোকানের মেইন সুইচ তো খোলাই আছে, কাটআউটে সরাসরি তারটা জুড়ে স্ক্রু এঁটে দাও।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "ভেতরের শর্ট-সার্কিটে কাটআউট ব্লাস্ট করে প্লাস্টিক গলিয়ে হাতে ছিটকে এল।"}
                ]
            },
            {
                "id": "sc_mend",
                "mantra": "armour",
                "image": "assets/quizzes/proc_insulation_peel.webp",
                "speaker": "lead",
                "alert_bn": "অ্যালুমিনিয়াম কোরে হাত",
                "line_bn": "সার্ভিস তারের ইনসুলেশন ছিলতে হবে। খালি হাতেই করা যাবে?",
                "situation_bn": "সার্ভিস তারের মুখ ছিলার সময় পিপিই মানা।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.6, 0.5],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36},
                        {"sprite": "man_point", "role": "junior", "x": 0.75, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.6, "y": 0.48, "r": 0.08, "label_bn": "আইপিসি ক্ল্যাম্প পয়েন্ট", "icon": "tool"},
                        {"x": 0.75, "y": 0.85, "r": 0.08, "label_bn": "সেফটি গ্লাভস পরা লাইনম্যান", "icon": "ppe"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "gloves", "short_bn": "লেদার গ্লাভস + ওয়্যার স্ট্রিপার", "text_bn": "লেদার গ্লাভস পরো এবং কেবল স্ট্রিপার দিয়ে সাবধানে খোলো যাতে আঙুল না কাটে।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "পদ্ধতি নিখুঁত। ধাতব ধারালো তারের ছোঁয়াচ বা কাটা থেকে হাত সুরক্ষিত রইল।"},
                    {"id": "b", "icon": "teeth", "cause": "shock", "short_bn": "দাঁত বা পুরনো ছুরি দিয়ে ছোলো", "text_bn": "গ্লাভস খুলে ফেলে পুরনো ভোঁতা ছুরি দিয়ে টান মেরে ছিলুন।", "best": False, "safety": -15, "satisfaction": 1, "minutes": 0, "risk": 0.2, "feedback_bn": "ছুরি পিছলে হাত কেটে গভীর ক্ষত ও রক্তপাত।" }
                ]
            }
        ]
    },
    # 5. Tree Trimming
    {
        "fault_id": "tree_trimming",
        "slot": "A",
        "short_title_bn": "ডালে ১১ কেভি ঠেকেছে",
        "title_bn": "বর্ষায় লাইনের ওপর ঝুঁকে পড়া কদম ডাল ছাঁটাই",
        "detail_bn": "{placeA}-এ কদম গাছের মোটা ডাল ১১ কেভি কন্ডাক্টরে ঠেকে ঘন ঘন আগুন ছিটকাচ্ছে। রাস্তায় ধোঁয়া ও আতঙ্ক।",
        "severity": "high",
        "work": "climb",
        "urgency_minutes": 65,
        "required_crew_count": 3,
        "travel_minutes": 16,
        "repair_minutes": 25,
        "required_gear": ["tester", "earth_rods", "ptw", "rope"],
        "job_gear": ["tree_saw", "frp_ladder"],
        "events": [
            {
                "id": "tt_permit",
                "mantra": "permit",
                "image": "assets/quizzes/mistake_tree_on_line.webp",
                "speaker": "junior",
                "alert_bn": "পারমিট আসার আগেই ডাল কাটার তাড়া",
                "line_bn": "দাদা, ডাল তো কাঠের, শুকনো মনে হচ্ছে। সাবস্টেশন ফোন ধরে নি, তার আগেই গাছে উঠে করাত চালাই?",
                "situation_bn": "১১ কেভি তারে ঠেকে থাকা গাছের ডাল কাটার আগে পারমিটের সিদ্ধান্ত।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.55, 0.35],
                    "layers": [
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": ["before", "wrong"]},
                        {"sprite": "man_stop", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.55, "y": 0.55, "h": 0.26, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.82, "y": 0.98, "h": 0.36, "when": ["before", "best"]}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.28, "r": 0.09, "label_bn": "১১ কেভি তারে ঠেকে থাকা ডাল", "icon": "hazard"},
                        {"x": 0.25, "y": 0.85, "r": 0.08, "label_bn": "সাবস্টেশন পিটিডব্লিউ কনফার্মেশন", "icon": "permit"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "ptw", "short_bn": "পারমিট ছাড়া গাছে হাত নয়", "text_bn": "কখনই না! জীবন্ত গাছের রস বিদ্যুৎ পরিবহন করে। লিখিত পারমিট না আসা অবধি গাছে কেউ উঠবে না।", "best": True, "safety": 10, "satisfaction": -2, "minutes": 8, "risk": 0.0, "feedback_bn": "জীবন্ত গাছের ডাল সবসময় কন্ডাক্টর। পারমিট ছাড়া কাটার চেষ্টা বহু তাজা প্রাণ কেড়ে নিয়েছে।"},
                    {"id": "b", "icon": "saw", "cause": "tree_flashover", "short_bn": "শুকনো অংশ ধরে কেটে ফেলো", "text_bn": "হ্যাঁ, করাত দিয়ে ওপর থেকে আস্তে আস্তে কেটে দাও, তার যেন না ছোঁয়।", "best": False, "safety": -35, "satisfaction": 3, "minutes": 0, "risk": 0.45, "feedback_bn": "ডাল নড়তেই ১১ কেভি কন্ডাক্টরের সাথে হেভি ফ্ল্যাশওভার! গাছে থাকা কর্মী ঝলসে নিচে পড়ল।"}
                ]
            },
            {
                "id": "tt_earth",
                "mantra": "earth",
                "image": "assets/quizzes/proc_earth_both_sides.webp",
                "speaker": "lead",
                "alert_bn": "ডাল কাটার জায়গায় আর্থিং",
                "line_bn": "পারমিট পেয়েছি। ডাল কাটার স্প্যানে আর্থিং কীভাবে হবে?",
                "situation_bn": "গাছের ডাল কাটার সময় লাইনের দুই প্রান্তে আর্থিং নিশ্চিত করা।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.45, 0.4],
                    "layers": [
                        {"sprite": "earth_set", "x": 0.22, "y": 0.48, "h": 0.18, "when": "best"},
                        {"sprite": "man_earth", "role": "junior", "x": 0.78, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_stop", "role": "lead", "x": 0.32, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.28, "y": 0.32, "r": 0.08, "label_bn": "বাম পাশের আর্থিং পয়েন্ট", "icon": "earth"},
                        {"x": 0.72, "y": 0.32, "r": 0.08, "label_bn": "ডান পাশের আর্থিং পয়েন্ট", "icon": "earth"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "দুই পাশের পোলে ডবল আর্থিং", "text_bn": "ডাল যে স্প্যানে আছে, তার আগের ও পরের পোলে টেস্টার ছুঁইয়ে দুই দিকেই গ্রাউন্ড রড লাগাও।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 6, "risk": 0.0, "feedback_bn": "আদর্শ নিয়ম। ডাল কাটলে তার লাফাতে পারে, দুই দিকে আর্থ থাকলে কোনো দুর্ঘটনা ঘটবে না।"},
                    {"id": "b", "icon": "skip", "cause": "backfeed", "short_bn": "শুধু ডাল ছাঁটাই, আর্থ লাগবে না", "text_bn": "ডাল তো তার থেকে আলাদা, শুধু ডাল কাটছি তার ছুঁচ্ছি না, আর্থিং করার দরকার নেই।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.3, "feedback_bn": "ডাল কাটার ধাক্কায় তার ছিঁড়ে গেল এবং পাশের ফিডারের ইন্ডাকশন ভোল্টেজে কর্মী আহত হলো।"}
                ]
            },
            {
                "id": "tt_fence",
                "mantra": "fence",
                "image": "assets/quizzes/mistake_cut_stay.webp",
                "speaker": "lead",
                "alert_bn": "ভারী ডাল কাটার নিচে পথচারী",
                "line_bn": "কাটা ডালটা নিচে পড়বে। নিচে কীভাবে নিয়ন্ত্রণ করব?",
                "situation_bn": "গাছের ভারী ডাল কাটার সময় নিচ দিয়ে পথচারী যাচ্ছে।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.6, 0.75],
                    "layers": [
                        {"sprite": "cones_tape", "x": 0.5, "y": 0.9, "h": 0.12, "when": "best"},
                        {"sprite": "villagers", "x": 0.82, "y": 0.95, "h": 0.36},
                        {"sprite": "man_stop", "role": "lead", "x": 0.25, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.55, "y": 0.45, "r": 0.09, "label_bn": "কাটা ডাল পড়ার জোন", "icon": "hazard"},
                        {"x": 0.82, "y": 0.85, "r": 0.08, "label_bn": "ভিলেজার জটলা", "icon": "crowd"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "rope", "short_bn": "দড়ি বেঁধে গাই করো + এলাকা ঘেরো", "text_bn": "ডালে শক্ত দড়ি বেঁধে নিয়ন্ত্রিতভাবে নামাও। নিচে ফিতে দিয়ে পথচারী সম্পূর্ণ আটকাও।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 5, "risk": 0.0, "feedback_bn": "নিখুঁত কাজ। ভারী ডাল দড়ি দিয়ে গাই না করলে তারের ওপর বা পথচারীর মাথায় ভেঙে পড়ে।"},
                    {"id": "b", "icon": "drop", "cause": "head", "short_bn": "সরাসরি নিচে ফেলে দাও", "text_bn": "ডাল কেটে সোজাসুজি নিচে ফেলে দাও, মাটিতে কেউ নেই দেখে নিলেই হবে।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "ডাল পড়ার সময় আচমকা এক সাইকেল আরোহী এসে পড়ায় ডাল মাথায় পড়ে মারাত্মক চোট পেল।"}
                ]
            }
        ]
    },
    # 6. Double Pole Insulator
    {
        "fault_id": "insulator_double_pole",
        "slot": "A",
        "short_title_bn": "ডবল পোলে ডিস্ক বাস্ট",
        "title_bn": "১১ কেভি ডবল-পোলে ডিস্ক ইনসুলেটর প্রতিস্থাপন",
        "detail_bn": "{placeA}-এ নদীর ধারের ডবল পোলে হেভি টেনশন ডিস্ক ইনসুলেটর ভেঙে লাইন ঝুলে গেছে। পোলের ক্রসম-আর্ম ভারী ও পিচ্ছিল।",
        "severity": "critical",
        "work": "climb",
        "urgency_minutes": 80,
        "required_crew_count": 3,
        "travel_minutes": 20,
        "repair_minutes": 30,
        "required_gear": ["tester", "earth_rods", "ptw", "rope", "harness"],
        "job_gear": ["spare_insulator", "frp_ladder", "wire_grip"],
        "events": [
            {
                "id": "dp_armour",
                "mantra": "armour",
                "image": "assets/quizzes/proc_cut_safety_belt.webp",
                "speaker": "junior",
                "alert_bn": "ডবল পোলের ভারী অ্যাঙ্গেল",
                "line_bn": "দাদা, ডবল পোলে ক্রসম-আর্মে হেঁটে যেতে হবে। হারনেসের ল্যানইয়ার্ড দুটোই কি আটকাতে হবে?",
                "situation_bn": "ডবল পোলের লোহার অ্যাঙ্গেলে চলার সময় ১০০% টাই-অফ নিয়ম।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.55, 0.45],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.26, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.82, "y": 0.98, "h": 0.36, "when": ["before", "best"]}
                    ],
                    "spots": [
                        {"x": 0.55, "y": 0.28, "r": 0.09, "label_bn": "ভারী ক্রসম-আর্ম চ্যানেল", "icon": "hazard"},
                        {"x": 0.75, "y": 0.22, "r": 0.08, "label_bn": "ভাঙা ডিস্ক ইনসুলেটর", "icon": "broken"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "harness", "short_bn": "ডবল ল্যানইয়ার্ড ১০০% টাই-অফ", "text_bn": "অবশ্যই! একটা হুক খোলার আগে অন্য হুক পোলে আটকাতে হবে। এক সেকেন্ডের জন্যও আন-লক থাকবে না।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "১০০% টাই-অফ নীতি ডবল পোলে জীবন বাঁচায়। কোনো অবস্থাতেই দুই হুক একসাথে খোলা চলবে না।"},
                    {"id": "b", "icon": "rush", "cause": "fall", "short_bn": "একটা হুক আটকে ছুটে যাও", "text_bn": "একটা হুক কোমরে ঝুলিয়ে রেখে শুধু একটা লাগাও, এতে দ্রুত কাজ হবে।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "হুক বদলানোর মুহূর্তে পা পিছলে কর্মী শূন্যে ঝুলে পড়ে গুরুতর জখম হলো।"}
                ]
            },
            {
                "id": "dp_earth",
                "mantra": "earth",
                "image": "assets/quizzes/mistake_earth_one_phase.webp",
                "speaker": "lead",
                "alert_bn": "সমান্তরাল লাইনের আবেশ",
                "line_bn": "এই ডবল পোলের পাশ দিয়েই আরেকটা ৩৩ কেভি লাইন গেছে। আবেশ কারেন্ট থাকতে পারে।",
                "situation_bn": "সমান্তরাল লাইনের ইন্ডাকশন কারেন্ট ড্রেনের জন্য সঠিক পদক্ষেপ।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.38],
                    "layers": [
                        {"sprite": "earth_set", "x": 0.62, "y": 0.42, "h": 0.18, "when": "best"},
                        {"sprite": "man_tester", "role": "lead", "x": 0.3, "y": 0.98, "h": 0.36, "when": ["before", "best"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.26, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.78, "y": 0.25, "r": 0.08, "label_bn": "পাশের চালু লাইনের ইনস্পেকশন", "icon": "warning"},
                        {"x": 0.55, "y": 0.38, "r": 0.08, "label_bn": "ডবল সাইড আর্থিং", "icon": "earth"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "কাজের স্প্যানের উভয় দিকে হেভি আর্থ", "text_bn": "কাজের ঠিক দুই দিকে সলিড গ্রাউন্ড রড লাগাও যাতে আবেশ ভোল্টেজ শূন্য হয়।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 5, "risk": 0.0, "feedback_bn": "সমান্তরাল ৩৩ কেভি লাইনের ইন্ডাকশন মারাত্মক। দুই দিকে আর্থ না থাকলে স্পর্শ করলেই শক।"},
                    {"id": "b", "icon": "skip", "cause": "induction_shock", "short_bn": "১১ কেভি অফ তো, চিন্তা নেই", "text_bn": "আমাদের লাইন তো বন্ধই আছে, ৩৩ কেভির আবেশে কিছু হবে না। কাজ করো।", "best": False, "safety": -30, "satisfaction": 2, "minutes": 0, "risk": 0.4, "feedback_bn": "৩৩ কেভি লাইনের ইলেক্ট্রোম্যাগনেটিক ইন্ডাকশনে তারে প্রায় ১০০০ ভোল্ট তৈরি হয়ে শক লাগল।"}
                ]
            },
            {
                "id": "dp_mend",
                "mantra": "mend",
                "image": "assets/quizzes/proc_insulation_peel.webp",
                "speaker": "lead",
                "alert_bn": "ভারী কন্ডাক্টরের টেনশন রিলিজ",
                "line_bn": "ডিস্ক বদলাতে তারের প্রবল টান কমাতে হবে। পুলিং রোপ ও গ্রিপার লাগবে।",
                "situation_bn": "ডবল পোলে হেভি টেনশন তার আটকে ডিস্ক ইনসুলেটর বদলানো।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.58, 0.48],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.58, "y": 0.5, "h": 0.26, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.58, "y": 0.35, "r": 0.08, "label_bn": "ল্যানইয়ার্ড অ্যাঙ্করিং পয়েন্ট", "icon": "harness"},
                        {"x": 0.26, "y": 0.85, "r": 0.08, "label_bn": "গ্রাউন্ড হেল্পার মনিটরিং", "icon": "eye"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "tool", "short_bn": "কাম-এলং ক্ল্যাম্প + কপিকল", "text_bn": "কাম-এলং ক্ল্যাম্প লাগিয়ে কপিকল দিয়ে তারের টান কমাও, তারপর ডিস্ক পিন খোলো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 6, "risk": 0.0, "feedback_bn": "সঠিক মেকানিক্যাল সুরক্ষাবিধি। তারের প্রচণ্ড টান মেকানিক্যাল টুলস দিয়েই সামলাতে হয়।"},
                    {"id": "b", "icon": "hand", "cause": "fall", "short_bn": "হাত দিয়ে টেনে পিন খুলে নাও", "text_bn": "দুজন মিলে তারটা হাত দিয়ে টেনে আলগা করো আর পিনটা ঠুকে বের করে দাও।", "best": False, "safety": -25, "satisfaction": 1, "minutes": 0, "risk": 0.3, "feedback_bn": "তারের টান হাত ফসকে ছিটকে গিয়ে ইনসুলেটর ভেঙে কর্মীর মুখ থেঁতলে দিল।"}
                ]
            }
        ]
    },
    # 7. UG Cable Joint
    {
        "fault_id": "ug_cable_joint",
        "slot": "B",
        "short_title_bn": "মাটির নিচের কেব্‌ল বাস্ট",
        "title_bn": "১১ কেভি আন্ডারগ্রাউন্ড কেব্‌ল ফল্ট লোকেশন ও জয়েন্টিং",
        "detail_bn": "{placeB}-এ সাবস্টেশনের আউটগোয়িং ১১ কেভি কেবল বাস্ট করেছে। ড্রেনের পাশে গভীর ট্রেঞ্চে জল জমেছে।",
        "severity": "critical",
        "work": "ground",
        "urgency_minutes": 90,
        "required_crew_count": 3,
        "travel_minutes": 15,
        "repair_minutes": 35,
        "required_gear": ["tester", "cable_spiking_gun", "ptw", "lock_board", "tape_cones"],
        "job_gear": ["torque_wrench"],
        "events": [
            {
                "id": "ug_permit",
                "mantra": "permit",
                "image": "assets/quizzes/mistake_approach_close.webp",
                "speaker": "lead",
                "alert_bn": "গর্তে একাধিক কেবল",
                "line_bn": "ট্রেঞ্চে চারটে কেবল পাশাপাশি গেছে। কোনটা ফল্টি কেবল তা চিহ্নিত করতে হবে।",
                "situation_bn": "আন্ডারগ্রাউন্ড কেব্‌ল কাটার আগে নিশ্চিত হওয়ার পদ্ধতি।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.55, 0.75],
                    "layers": [
                        {"sprite": "truck", "x": 0.18, "y": 0.82, "h": 0.08},
                        {"sprite": "man_tester", "role": "lead", "x": 0.32, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_point", "role": "junior", "x": 0.78, "y": 0.98, "h": 0.36},
                        {"sprite": "cones_tape", "x": 0.55, "y": 0.88, "h": 0.12, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.55, "y": 0.78, "r": 0.09, "label_bn": "ট্রেঞ্চের ৪টি কেবল বান্ডিল", "icon": "bolt"},
                        {"x": 0.32, "y": 0.88, "r": 0.08, "label_bn": "স্পাইকিং টেস্ট গান", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "spike", "short_bn": "কেবল স্পাইকিং গান দিয়ে টেস্ট", "text_bn": "দূর থেকে কেবল স্পাইকিং গান চালিয়ে নিশ্চিত করো যে লাইভ কেবল নয়, তারপর কাটো।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 8, "risk": 0.0, "feedback_bn": "আন্ডারগ্রাউন্ড কেবলের গোল্ডেন রুল স্পাইকিং টেস্ট। চোখের দেখায় কেবল কাটলে বিস্ফোরণ ঘটে।"},
                    {"id": "b", "icon": "guess", "cause": "cable_blast", "short_bn": "কালচে দাগ দেখে কেটে ফেলো", "text_bn": "যে কেব্‌লটার গায়ে পোড়া গন্ধ আর দাগ আছে, হ্যাকস দিয়ে কেটে দাও।", "best": False, "safety": -40, "satisfaction": 3, "minutes": 0, "risk": 0.5, "feedback_bn": "ভুল লাইভ কেবলে করাত চালাতেই ১০,০০০ অ্যাম্পিয়ার বিস্ফোরণ! কেব্‌ল ফেটে চরম অগ্নিকাণ্ড।"}
                ]
            },
            {
                "id": "ug_cut",
                "mantra": "cut",
                "image": "assets/quizzes/proc_verbal_ptw.webp",
                "speaker": "lead",
                "alert_bn": "দুই প্রান্তের ব্রেকার",
                "line_bn": "আন্ডারগ্রাউন্ড কেবল রিং-মেইনে থাকে। একদিকের ব্রেকার বন্ধ করলেই কি হবে?",
                "situation_bn": "ইউজি কেবলের উভয় প্রান্ত আইসোলেশন ও লক করা।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.5, 0.7],
                    "layers": [
                        {"sprite": "lock_board", "x": 0.25, "y": 0.88, "h": 0.12, "when": "best"},
                        {"sprite": "man_phone", "role": "lead", "x": 0.38, "y": 0.98, "h": 0.36},
                        {"sprite": "man_stop", "role": "junior", "x": 0.75, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.25, "y": 0.88, "r": 0.08, "label_bn": "সাবস্টেশন ও রিং মেইন ইউনিট লক", "icon": "switch"},
                        {"x": 0.65, "y": 0.78, "r": 0.08, "label_bn": "কাট প্রান্তের টেস্ট পয়েন্ট", "icon": "warning"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "lock", "short_bn": "সাবস্টেশন ও আরএমইউ দুই প্রান্তেই লক", "text_bn": "রিং মেইন ইউনিটের দুই প্রান্তের ব্রেকার অফ করে তালা মারো ও গ্রাউন্ড সুইচ অন করো।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 6, "risk": 0.0, "feedback_bn": "ইউজি কেবলে রিং ফিড ব্যাকফিড সবচেয়ে বিপজ্জনক। দুই মাথা ডিসকানেক্ট ও লক মাস্ট।"},
                    {"id": "b", "icon": "skip", "cause": "charged", "short_bn": "শুধু সাবস্টেশনের ব্রেকার অফ রাখো", "text_bn": "সাবস্টেশন থেকে কেবল কাটা আছে, অপর প্রান্তের কিয়স্ক দেখার দরকার নেই।", "best": False, "safety": -30, "satisfaction": 2, "minutes": 0, "risk": 0.4, "feedback_bn": "অন্য প্রান্তের রিং মেইন থেকে কারেন্ট ব্যাক এসে তার কাটার সাথে সাথে শক লাগল।"}
                ]
            },
            {
                "id": "ug_earth",
                "mantra": "earth",
                "image": "assets/quizzes/proc_earth_both_sides.webp",
                "speaker": "junior",
                "alert_bn": "কেবল আর্মার ও কোর ডিসচার্জ",
                "line_bn": "কেবলের আর্মার আর কপার স্ক্রিন কি বডিতে গ্রাউন্ড করতে হবে?",
                "situation_bn": "জয়েন্ট কিট লাগানোর সময় কেবলের আর্মার আর্দিং।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.52, 0.75],
                    "layers": [
                        {"sprite": "man_tester", "role": "lead", "x": 0.45, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36},
                        {"sprite": "cones_tape", "x": 0.52, "y": 0.88, "h": 0.12}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.8, "r": 0.08, "label_bn": "কেবল কোর ও আর্মার আর্থিং", "icon": "earth"},
                        {"x": 0.8, "y": 0.88, "r": 0.08, "label_bn": "হিট শ্রিঙ্ক জয়েন্ট কিট", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "আর্মার ও কপার স্ক্রিন বন্ড + আর্থ", "text_bn": "হ্যাঁ, আর্মার ও স্ক্রিন ওয়্যার সলিডভাবে আর্থ করো যাতে স্ট্যাটিক এবং লিকেজ চার্জ বের হয়ে যায়।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "সঠিক। কেবলের আর্মার আর্থ না করলে পরবর্তীকালে পুরো মাটিতে বিপজ্জনক ভোল্টেজ ছড়ায়।"},
                    {"id": "b", "icon": "tape", "cause": "shock", "short_bn": "শুধু টেপ দিয়ে মুড়ে দাও", "text_bn": "আর্মার কাটার পর টেপ দিয়ে পেঁচিয়ে দাও, আর্থ বাঁধতে গেলে সময় নষ্ট হবে।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "চার্জিং কারেন্টের স্পার্কে জয়েন্ট কিট পাংচার হয়ে নষ্ট হলো।"}
                ]
            }
        ]
    },
    # 8. AB Cable Piercing
    {
        "fault_id": "ab_cable_piercing",
        "slot": "B",
        "short_title_bn": "এবি কেব্‌লে স্পার্কিং",
        "title_bn": "এলটি এবি কেব্‌লে আইপিসি ক্ল্যাম্প ও পথবাতি সংযোগ",
        "detail_bn": "{placeB}-এ পঞ্চায়েতের পথবাতির কানেকশনে এরিয়াল বাঞ্চড (AB) কেবলের ইনসুলেশন লুজ হয়ে আগুন বেরোচ্ছে।",
        "severity": "medium",
        "work": "climb",
        "urgency_minutes": 55,
        "required_crew_count": 2,
        "travel_minutes": 12,
        "repair_minutes": 20,
        "required_gear": ["tester", "gloves", "frp_ladder", "harness"],
        "job_gear": ["ipc_clamp", "torque_wrench"],
        "events": [
            {
                "id": "ab_stop",
                "mantra": "stop",
                "image": "assets/quizzes/proc_insulation_peel.webp",
                "speaker": "junior",
                "alert_bn": "তার ইনসুলেটেড, তাই অসাবধানতা?",
                "line_bn": "দাদা, এবি কেবল তো পুরো প্লাস্টিকে মোড়া, এতে কি শক লাগার কোনো ভয় আছে?",
                "situation_bn": "ইনসুলেটেড এবি কেবলে কাজ করার সময় সুরক্ষা মানসিকতা।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.5, 0.4],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": ["before", "wrong"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.52, "y": 0.6, "h": 0.25, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36, "when": ["before", "best"]}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.35, "r": 0.08, "label_bn": "এলটি এবি কেবল বান্ডিল", "icon": "bolt"},
                        {"x": 0.35, "y": 0.85, "r": 0.08, "label_bn": "রাস্তার ট্রাফিক লাইন", "icon": "warning"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "stop", "short_bn": "ইনসুলেশন থাকলেও গ্লাভস ও হারনেস মাস্ট", "text_bn": "কখনও তা ভাববে না! পুরনো ইনসুলেশনে মাইক্রো-ক্র্যাক থাকে। গ্লাভস আর বুট পরে কাজ করো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "অভিজ্ঞতার শিক্ষা। এবি কেবলের কালো জ্যাকেটে ফাটল থাকলে ভেজা আবহাওয়ায় ৪১৫ ভোল্ট শক লাগে।"},
                    {"id": "b", "icon": "bare", "cause": "shock", "short_bn": "প্লাস্টিক মোড়া, খালি হাতেই করো", "text_bn": "হ্যাঁ, এতে শক লাগে না, খালি হাতেই ক্ল্যাম্পটা চেপে ধরে থাকো।", "best": False, "safety": -25, "satisfaction": 1, "minutes": 0, "risk": 0.3, "feedback_bn": "ভাঙা ইনসুলেশন থেকে ফেজ তারে আঙুল লাগায় ৪১৫ ভোল্টের প্রচণ্ড ধাক্কা।"}
                ]
            },
            {
                "id": "ab_mend",
                "mantra": "mend",
                "image": "assets/quizzes/proc_insulation_peel.webp",
                "speaker": "lead",
                "alert_bn": "আইপিসি ক্ল্যাম্প টাইট",
                "line_bn": "আইপিসি ক্ল্যাম্প টাইট দেওয়ার নিয়ম কী? সাধারণ স্প্যানার দিয়ে করলেই হবে?",
                "situation_bn": "আইপিসি ক্ল্যাম্প (Insulation Piercing Connector) ব্যবহারের সঠিক প্রযুক্তি।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.55, 0.42],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.3, "y": 0.98, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.52, "y": 0.55, "h": 0.25, "when": ["before", "best"]}
                    ],
                    "spots": [
                        {"x": 0.55, "y": 0.38, "r": 0.08, "label_bn": "শেয়ার নাট আইপিসি ক্ল্যাম্প", "icon": "tool"},
                        {"x": 0.52, "y": 0.68, "r": 0.08, "label_bn": "এফআরপি মই সাপোর্ট", "icon": "ladder"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "wrench", "short_bn": "শেয়ার-হেড নাট ভাঙা পর্যন্ত টর্ক দাও", "text_bn": "আইপিসির শেয়ার-হেড নাট ভাঙা পর্যন্ত টাইট দাও, যাতে তার না কেটে সঠিক সংযোগ হয়।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "নিখুঁত ইঞ্জিনিয়ারিং। শেয়ার হেড নাট ভাঙলে সঠিক প্রেসার ও সিলিং নিশ্চিত হয়।"},
                    {"id": "b", "icon": "overtight", "cause": "fall", "short_bn": "প্লায়ার্স দিয়ে দাঁতগুলো তারে ঢুকিয়ে দাও", "text_bn": "প্লায়ার্স দিয়ে চেপে দাঁতগুলো তারের গভীরে ঢুকিয়ে দাও যাতে আর নড়তে না পারে।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "ভেতরের অ্যালুমিনিয়াম কোর কেটে গিয়ে স্প্যানে তার ছিঁড়ে নিচে পড়ল।"}
                ]
            },
            {
                "id": "ab_fence",
                "mantra": "fence",
                "image": "assets/zero_loss/scene/bg_span_two_poles.webp",
                "speaker": "lead",
                "alert_bn": "ফুটপাথের পথচারী ও দোকান",
                "line_bn": "মই লাগানোর নিচে ফুটপাতে দোকানদারদের ভিড়। কীভাবে কাজ করব?",
                "situation_bn": "মইয়ের কাজের নিচে ট্রাফিক ও দোকান।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.6, 0.8],
                    "layers": [
                        {"sprite": "cones_tape", "x": 0.55, "y": 0.88, "h": 0.12, "when": "best"},
                        {"sprite": "villagers", "x": 0.82, "y": 0.95, "h": 0.36},
                        {"sprite": "man_stop", "role": "lead", "x": 0.25, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.82, "y": 0.82, "r": 0.08, "label_bn": "পথচারী সাধারণ মানুষ", "icon": "crowd"},
                        {"x": 0.55, "y": 0.88, "r": 0.08, "label_bn": "সেফটি কোন ও ফিতে", "icon": "fence"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "fence", "short_bn": "নিচে সহযোগী মই ধরুক ও এলাকা ঘেরো", "text_bn": "সহকারী নিচে হেলমেট পরে মই শক্ত করে ধরুক এবং কোন দিয়ে পথচারীদের দূরে রাখুক।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "খুব ভালো। হেল্পার ছাড়া মইয়ে কাজ করা সম্পূর্ণ নিষিদ্ধ।"},
                    {"id": "b", "icon": "alone", "cause": "fall", "short_bn": "পোলে মই ঠেকিয়ে একাই উঠে পড়ো", "text_bn": "মইটা কেবল বান্ডিলে ঠেসিয়ে একাই তাড়াতাড়ি উঠে কাজটা সেরে এসো।", "best": False, "safety": -25, "satisfaction": 1, "minutes": 0, "risk": 0.3, "feedback_bn": "নিচে পথচারীর ধাক্কায় মই পিছলে কর্মী ফুটপাতে আছড়ে পড়ল।"}
                ]
            }
        ]
    },
    # 9. Jumper Cutting
    {
        "fault_id": "jumper_cutting",
        "slot": "A",
        "short_title_bn": "১১ কেভি পোড়া জাম্পার",
        "title_bn": "সেকশন পোলে পুড়ে যাওয়া জাম্পার কাটা ও নতুন জাম্পার স্থাপন",
        "detail_bn": "{placeA}-এ সেকশন পোলে লুজ কানেকশনের কারণে জাম্পার পুড়ে ঝুলছে। পাশের সমান্তরাল লাইভ সার্কিটে বিদ্যুৎ চালু আছে।",
        "severity": "high",
        "work": "climb",
        "urgency_minutes": 70,
        "required_crew_count": 3,
        "travel_minutes": 15,
        "repair_minutes": 22,
        "required_gear": ["tester", "earth_rods", "ptw", "gloves", "harness"],
        "job_gear": ["wire_grip"],
        "events": [
            {
                "id": "jc_earth",
                "mantra": "earth",
                "image": "assets/quizzes/mistake_earth_one_phase.webp",
                "speaker": "lead",
                "alert_bn": "সমান্তরাল চালু ১১ কেভি লাইনের ইন্ডাকশন",
                "line_bn": "আমাদের লাইন বন্ধ, কিন্তু ঠিক পাশের পোল দিয়ে অন্য ফিডার ফুল লোডে চলছে!",
                "situation_bn": "সমান্তরাল লাইভ লাইনের পাশে জাম্পার মেরামতে আর্থিং।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.4],
                    "layers": [
                        {"sprite": "earth_set", "x": 0.62, "y": 0.42, "h": 0.18, "when": "best"},
                        {"sprite": "man_tester", "role": "lead", "x": 0.32, "y": 0.98, "h": 0.36, "when": ["before", "best"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.78, "y": 0.25, "r": 0.08, "label_bn": "পাশের সচল সার্কিট", "icon": "warning"},
                        {"x": 0.58, "y": 0.38, "r": 0.08, "label_bn": "ডবল সাইড গ্রাউন্ড সেট", "icon": "earth"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "কাজের পোলেই দুই পাশে টেস্ট ও ডবল আর্থ", "text_bn": "কাজের ঠিক দুই দিকে টেস্টার ছুঁইয়ে দুই প্রান্তেই আর্থিং রড লাগাও।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 6, "risk": 0.0, "feedback_bn": "সঠিক। সমান্তরাল চালু লাইনের আবেশ বিদ্যুৎ মৃত্যুর কারণ হতে পারে। ডবল আর্থ জীবন রক্ষাকারী।"},
                    {"id": "b", "icon": "skip", "cause": "induction_shock", "short_bn": "দূর থেকে আর্থ করা আছে, এখানে লাগবে না", "text_bn": "সাবস্টেশনে আর্থ সুইচ দেওয়া আছে, পোলে আলাদা আর্থিং লাগবে না।", "best": False, "safety": -30, "satisfaction": 2, "minutes": 0, "risk": 0.4, "feedback_bn": "সমান্তরাল লাইনের আবেশে পোড়ার জাম্পারে হাত দিতেই মারাত্মক শক।"}
                ]
            },
            {
                "id": "jc_cut",
                "mantra": "cut",
                "image": "assets/quizzes/mistake_under_load.webp",
                "speaker": "junior",
                "alert_bn": "জাম্পার খোলার সাথে সাথে আর্কিং",
                "line_bn": "জাম্পার কাটার সময় কি কোনো স্পার্ক হতে পারে? প্লাস দিয়ে সোজাসুজি কেটে দেব?",
                "situation_bn": "জাম্পার কাটার সময় সম্ভাব্য ক্যাপাসিটিভ চার্জ।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.62, 0.35],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.55, "h": 0.25, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.82, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.62, "y": 0.32, "r": 0.08, "label_bn": "পোড়া জাম্পার ক্ল্যাম্প", "icon": "bolt"},
                        {"x": 0.26, "y": 0.85, "r": 0.08, "label_bn": "সেকশন আইসোলেটর স্ট্যাটাস", "icon": "switch"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "cut", "short_bn": "ডিসচার্জ রড ঠেকিয়ে তবে কাটো", "text_bn": "আগে ডিসচার্জ রড দিয়ে জাম্পারের উভয় প্রান্ত ডিসচার্জ করো, তারপর ইনসুলেটেড কাটার চালাও।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "সঠিক প্র্যাকটিস। দীর্ঘ লাইনের সঞ্চিত ক্যাপাসিট্যান্স আর্ক তৈরি করতে পারে।"},
                    {"id": "b", "icon": "bare", "cause": "arc_flash", "short_bn": "সাধারণ প্লাস দিয়ে সরাসরি কাটো", "text_bn": "সাধারণ প্লাস দিয়ে ঝটপট তারটা মোচড় দিয়ে কেটে ফেলো।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "স্পার্কিংয়ে চোখ ধাঁধিয়ে হাত ফসকে নিচে পড়ে গেল।"}
                ]
            },
            {
                "id": "jc_armour",
                "mantra": "armour",
                "image": "assets/quizzes/proc_cut_safety_belt.webp",
                "speaker": "lead",
                "alert_bn": "পোলে স্প্যান পরিবর্তনের সময় সেফটি",
                "line_bn": "জাম্পারের ক্ল্যাম্প বদলাতে পোলের দুই প্রান্তে ঘুরতে হবে।",
                "situation_bn": "পোলের শীর্ষে অবস্থান পরিবর্তনের সময় সেফটি হারনেস অবস্থান।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.58, 0.48],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.26, "y": 0.98, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.58, "y": 0.5, "h": 0.26, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.58, "y": 0.35, "r": 0.08, "label_bn": "১০০% টাই-অফ হারনেস পয়েন্ট", "icon": "harness"},
                        {"x": 0.75, "y": 0.2, "r": 0.08, "label_bn": "নতুন পিজি ক্ল্যাম্প", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "harness", "short_bn": "ফুল বডি হারনেস ডবল ল্যানইয়ার্ড লক", "text_bn": "সবসময় একটা ল্যানইয়ার্ড পোলে বাঁধা রেখে তবে দ্বিতীয়টা সরাও।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "১০০% টাই-অফ মানায় পোলের ওপর কর্মী সম্পূর্ণ সুরক্ষিত।"},
                    {"id": "b", "icon": "slip", "cause": "fall", "short_bn": "ল্যানইয়ার্ড খুলে হাত দিয়ে ধরে ঘোরো", "text_bn": "তাড়াতাড়ি ঘোরার জন্য বেল্ট খুলে হাত দিয়ে পোল জড়িয়ে ধরে ঘুরে যাও।", "best": False, "safety": -30, "satisfaction": 1, "minutes": 0, "risk": 0.4, "feedback_bn": "হাত পিছলে ১০ মিটার ওপর থেকে মাটিতে পড়ে মারাত্মক ট্রমা।"}
                ]
            }
        ]
    },
    # 10. DTR Maintenance
    {
        "fault_id": "dtr_maintenance",
        "slot": "A",
        "short_title_bn": "ডিটিআর শিডিউল মেনটেন্যান্স",
        "title_bn": "১০০ কেভিএ ট্রান্সফরমার ওভারহলিং, তেল টপিং ও আর্থ রেজিস্ট্যান্স টেস্ট",
        "detail_bn": "{placeA}-এ ১০০ কেভিএ ট্রান্সফরমারের বার্ষিক রক্ষণাবেক্ষণ। তেলের লেভেল নেমে গেছে ও আর্দিং ইলেকট্রোড শুকিয়ে গেছে।",
        "severity": "medium",
        "work": "climb",
        "urgency_minutes": 90,
        "required_crew_count": 3,
        "travel_minutes": 14,
        "repair_minutes": 30,
        "required_gear": ["tester", "ptw", "lock_board", "gloves", "earth_rods"],
        "job_gear": ["oil_gauge"],
        "events": [
            {
                "id": "dm_cut",
                "mantra": "cut",
                "image": "assets/quizzes/proc_verbal_ptw.webp",
                "speaker": "lead",
                "alert_bn": "জিও সুইচ হ্যান্ডেল কাটা ও লক",
                "line_bn": "রক্ষণাবেক্ষণের কাজ শুরু করার আগে জিও সুইচ কীভাবে হ্যান্ডল করব?",
                "situation_bn": "ট্রান্সফরমার রক্ষণাবেক্ষণে জিও সুইচ ও এলটি সার্কিট ব্রেকার আইসোলেশন।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.32, 0.72],
                    "layers": [
                        {"sprite": "lock_board", "x": 0.28, "y": 0.82, "h": 0.12, "when": "best"},
                        {"sprite": "man_stop", "role": "lead", "x": 0.35, "y": 0.98, "h": 0.36},
                        {"sprite": "man_climb", "role": "junior", "x": 0.6, "y": 0.58, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.28, "y": 0.78, "r": 0.08, "label_bn": "জিও সুইচ প্যাডলক ও বোর্ড", "icon": "switch"},
                        {"x": 0.65, "y": 0.4, "r": 0.08, "label_bn": "১০০ কেভিএ ট্রান্সফরমার", "icon": "hazard"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "lock", "short_bn": "জিও সুইচ ওপেন + প্যাডলক + এলটি সুইচ অফ", "text_bn": "জিও সুইচ কেটে হ্যান্ডেলে প্যাডলক লাগাও, ডেঞ্জার বোর্ড ঝোলাও এবং এলটি কাটআউট খুলে রাখো।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 5, "risk": 0.0, "feedback_bn": "দুদিক অফ এবং ফিজিক্যাল লক—এটাই রক্ষণাবেক্ষণের প্রাথমিক শর্ত।"},
                    {"id": "b", "icon": "loose", "cause": "charged", "short_bn": "শুধু জিও টেনে দাও, লক লাগবে না", "text_bn": "জিও সুইচ টেনে হ্যান্ডেলটা নামিয়ে রাখো, দিনের বেলা কেউ হাত দেবে না।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "গ্রামের কোনো ব্যক্তি ভুল করে হ্যান্ডেল তুলে দেওয়ায় বুশিংয়ে ফ্ল্যাশওভার।"}
                ]
            },
            {
                "id": "dm_earth",
                "mantra": "earth",
                "image": "assets/quizzes/proc_earth_both_sides.webp",
                "speaker": "lead",
                "alert_bn": "ট্যাঙ্ক ও বুশিং আর্থিং",
                "line_bn": "এইচটি এবং এলটি উভয় বুশিং কি ডিসচার্জ রড দিয়ে গ্রাউন্ড করতে হবে?",
                "situation_bn": "ট্রান্সফরমারের সব টার্মিনাল আর্থিং করা।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.42],
                    "layers": [
                        {"sprite": "earth_set", "x": 0.58, "y": 0.62, "h": 0.18, "when": "best"},
                        {"sprite": "man_tester", "role": "lead", "x": 0.42, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.62, "y": 0.38, "r": 0.08, "label_bn": "এইচটি ও এলটি বুশিং গ্রাউন্ডিং", "icon": "earth"},
                        {"x": 0.58, "y": 0.65, "r": 0.08, "label_bn": "ট্রান্সফরমার নিউট্রাল আর্থ বডি", "icon": "warning"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "earth", "short_bn": "এইচটি ও এলটি সব কটি বুশিং আর্থ করো", "text_bn": "এইচভি টেস্টার দিয়ে নিশ্চিত হয়ে সব বুশিং ডিসচার্জ রড দিয়ে ট্রান্সফরমার বডির সাথে গ্রাউন্ড করো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "সঠিক। এলটি সাইড থেকেও জেনারেটরের ব্যাকফিড আসতে পারে। সম্পূর্ণ গ্রাউন্ডিং দরকার।"},
                    {"id": "b", "icon": "ht_only", "cause": "backfeed", "short_bn": "শুধু এইচটি আর্থ করলেই হবে", "text_bn": "শুধু এইচটি সাইড গ্রাউন্ড করো, এলটি তো ২৪০ ভোল্ট, ওতে কিছু হবে না।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "গ্রামের কোনো জেনারেটর চালু হওয়ায় এলটি বুশিং দিয়ে ৪১৫ ভোল্ট ব্যাকফিড এসে শক।"}
                ]
            },
            {
                "id": "dm_mend",
                "mantra": "armour",
                "image": "assets/quizzes/proc_test_before_climb.webp",
                "speaker": "junior",
                "alert_bn": "গরম ট্রান্সফরমার অয়েল ও স্যাম্পলিং",
                "line_bn": "তেলের গেজ চেক করতে ও ড্রেন ভালভ খুলতে যাচ্ছি। তেল বেশ গরম।",
                "situation_bn": "ট্রান্সফরমার অয়েল স্যাম্পলিং ও টপিং করার সময় সুরক্ষা।",
                "scene": {
                    "bg": "pole_storm",
                    "fail_at": [0.6, 0.48],
                    "layers": [
                        {"sprite": "truck", "x": 0.22, "y": 0.79, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.3, "y": 0.98, "h": 0.36},
                        {"sprite": "man_point", "role": "junior", "x": 0.78, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.6, "y": 0.45, "r": 0.08, "label_bn": "অয়েল গেজ ও ড্রেন ভালভ", "icon": "tool"},
                        {"x": 0.78, "y": 0.85, "r": 0.08, "label_bn": "সেফটি গগলস ও গ্লাভস", "icon": "ppe"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "goggles", "short_bn": "সেফটি গগলস ও হিট-রেজিস্ট্যান্ট গ্লাভস", "text_bn": "চোখে সেফটি গগলস ও হাতে মোটা হিট-রেজিস্ট্যান্ট গ্লাভস পরে তবে স্যাম্পল ভালভ খোলো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "চমৎকার। গরম তেলের ছিটকে চোখে পড়লে অন্ধত্বের ঝুঁকি থাকে। গগলস পরা অপরিহার্য।"},
                    {"id": "b", "icon": "bare", "cause": "head", "short_bn": "খালি চোখে প্লাস্টিক বোতলে ধরো", "text_bn": "গগলস ট্রাকে আছে, খালি চোখেই সাবধানে ড্রেন করলেই হবে।", "best": False, "safety": -20, "satisfaction": 1, "minutes": 0, "risk": 0.25, "feedback_bn": "ভালভের প্রেশারে গরম তেল চোখে ছিটকে কর্নিয়া ক্ষতিগ্রস্ত।"}
                ]
            }
        ]
    },
    # 11. Three Phase Meter
    {
        "fault_id": "three_phase_meter",
        "slot": "B",
        "short_title_bn": "রাইস মিল ৩-ফেজ মিটার",
        "title_bn": "ইন্ডাস্ট্রিয়াল প্যানেলে ৩-ফেজ সিটি-পিটি মিটার প্রতিস্থাপন",
        "detail_bn": "{placeB}-এ রাইস মিলের ৩-ফেজ প্যানেলে মিটার পুড়ে ধোঁয়া বেরোচ্ছে। ৪০০ অ্যাম্পিয়ারের লাইভ বাসবার পাশেই অবস্থিত।",
        "severity": "high",
        "work": "ground",
        "urgency_minutes": 65,
        "required_crew_count": 2,
        "travel_minutes": 12,
        "repair_minutes": 25,
        "required_gear": ["tester", "gloves", "ptw", "lock_board"],
        "job_gear": ["torque_wrench"],
        "events": [
            {
                "id": "tm_cut",
                "mantra": "cut",
                "image": "assets/quizzes/proc_verbal_ptw.webp",
                "speaker": "lead",
                "alert_bn": "রাইস মিল ব্যাকফিড ঝুঁকি",
                "line_bn": "মিলের জেনারেটর ব্যাকফিড হতে পারে। কীভাবে নিশ্চিত করব পাওয়ার অফ?",
                "situation_bn": "ইন্ডাস্ট্রিয়াল রাইস মিল প্যানেলে ব্যাকফিড আইসোলেশন।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.55, 0.5],
                    "layers": [
                        {"sprite": "lock_board", "x": 0.22, "y": 0.85, "h": 0.12, "when": "best"},
                        {"sprite": "man_tester", "role": "lead", "x": 0.35, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_stop", "role": "junior", "x": 0.75, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.55, "y": 0.48, "r": 0.08, "label_bn": "ইন্ডাস্ট্রিয়াল প্যানেল মেইন কাটআউট", "icon": "switch"},
                        {"x": 0.72, "y": 0.55, "r": 0.08, "label_bn": "ডিজেল জেনারেটর ব্যাকফিড লাইন", "icon": "warning"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "lock", "short_bn": "মেইন চেঞ্জওভার সুইচ অফ + লক", "text_bn": "মেইন আইসোলেটর ও জেনারেটরের চেঞ্জওভার সুইচ অফ করে প্যাডলক করো এবং টেস্টার দিয়ে ৩ ফেজেই ভোল্টেজ মাপো।", "best": True, "safety": 10, "satisfaction": 0, "minutes": 5, "risk": 0.0, "feedback_bn": "ইন্ডাস্ট্রিয়াল কাজে ব্যাকফিড আইসোলেশন ও টেস্টার টেস্টই জীবন বাঁচায়।"},
                    {"id": "b", "icon": "trust", "cause": "arc_flash", "short_bn": "মালিক সুইচ বন্ধ করেছে, তাই শুরু করো", "text_bn": "মিলের ম্যানেজার তো মেইন সুইচ বন্ধ করেই ডেকেছে, আর কী চেক করব।", "best": False, "safety": -35, "satisfaction": 2, "minutes": 0, "risk": 0.45, "feedback_bn": "জেনারেটর অটোমেটিক স্টার্ট হওয়ায় ৪০০ অ্যাম্পিয়ারের প্রচণ্ড আর্ক ব্লাস্টে প্যানেল পুড়ে গেল।"}
                ]
            },
            {
                "id": "tm_armour",
                "mantra": "armour",
                "image": "assets/quizzes/proc_insulation_peel.webp",
                "speaker": "junior",
                "alert_bn": "প্যানেল শর্ট সার্কিট ও আর্ক ফ্ল্যাশ",
                "line_bn": "প্যানেলের মধ্যে স্ক্রু ড্রাইভার দিয়ে সিটি টার্মিনাল খুলছি। ফেস শিল্ড কি লাগবে?",
                "situation_bn": "ইন্ডাস্ট্রিয়াল প্যানেলে আর্ক ফ্ল্যাশ প্রতিরোধ।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.52, 0.52],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.3, "y": 0.98, "h": 0.36},
                        {"sprite": "man_point", "role": "junior", "x": 0.78, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.48, "r": 0.08, "label_bn": "৪১৫ ভোল্ট বাসবার বাস-পয়েন্ট", "icon": "bolt"},
                        {"x": 0.3, "y": 0.85, "r": 0.08, "label_bn": "ফেস শিল্ড ও ইনসুলেটেড টুলস", "icon": "ppe"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "shield", "short_bn": "আর্ক-রেটেড ফেস শিল্ড ও ইনসুলেটেড টুলস", "text_bn": "অবশ্যই! ফেস শিল্ড নামাও এবং ১০০০ ভোল্ট ইনসুলেটেড স্ক্রু ড্রাইভার ব্যবহার করো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 3, "risk": 0.0, "feedback_bn": "সঠিক। প্যানেলের সামান্য স্পার্কও ফেস শিল্ড ছাড়া মুখে লাগলে চিরতরে দৃষ্টিশক্তি হারাতে পারে।"},
                    {"id": "b", "icon": "bare", "cause": "arc_flash", "short_bn": "খালি মুখেই সাবধানে করো", "text_bn": "ফেস শিল্ডে দেখতে অসুবিধা হয়, খালি চোখেই সাবধানে হাত চালাও।", "best": False, "safety": -30, "satisfaction": 1, "minutes": 0, "risk": 0.4, "feedback_bn": "স্ক্রু ড্রাইভার স্লিপ করে বাসবারে ঠেকতেই প্রচণ্ড আর্ক ফ্ল্যাশে মুখের চামড়া ঝলসে গেল।"}
                ]
            },
            {
                "id": "tm_count",
                "mantra": "count",
                "image": "assets/quizzes/proc_work_after_close.webp",
                "speaker": "lead",
                "alert_bn": "টেস্ট রান ও সীলিং",
                "line_bn": "নতুন মিটারের টার্মিনাল কভার লাগানো শেষ। লাইন অন করার আগে কী নিয়ম?",
                "situation_bn": "মিটার প্রতিস্থাপন পরবর্তী কাউন্ট ও ক্লোজিং।",
                "scene": {
                    "bg": "market_wire_down",
                    "fail_at": [0.5, 0.55],
                    "layers": [
                        {"sprite": "man_phone", "role": "lead", "x": 0.32, "y": 0.98, "h": 0.36},
                        {"sprite": "man_stop", "role": "junior", "x": 0.75, "y": 0.98, "h": 0.36, "when": "best"}
                    ],
                    "spots": [
                        {"x": 0.52, "y": 0.5, "r": 0.08, "label_bn": "নতুন ৩-ফেজ ইলেকট্রনিক মিটার", "icon": "tool"},
                        {"x": 0.75, "y": 0.85, "r": 0.08, "label_bn": "রাইস মিল মালিক", "icon": "crowd"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "count", "short_bn": "হাতিয়ার কাউন্ট + কভার ক্লোজ + নো-লোড অন", "text_bn": "সব স্ক্রু ও টুলস মিলিয়ে নাও, প্যানেল বন্ধ করে শূন্য লোডে আইসোলেটর অন করো।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 4, "risk": 0.0, "feedback_bn": "খুব ভালো। প্যানেলের ভেতর কোনো ধাতব স্ক্রু পড়ে থাকলে চার্জ দেওয়ার মুহূর্তে বিস্ফোরণ হতো।"},
                    {"id": "b", "icon": "rush_on", "cause": "arc_flash", "short_bn": "প্যানেল খোলা রেখেই সুইচ দিন", "text_bn": "প্যানেল খোলা থাক, মিলের মোটর ফুল লোডে চালিয়ে মিটার ঘুরছে কিনা দেখি।", "best": False, "safety": -20, "satisfaction": 2, "minutes": 0, "risk": 0.25, "feedback_bn": "হেভি লোডের কারেন্ট টানতেই সিটি টার্মিনাল স্পার্ক করে প্যানেলে আগুন লাগল।"}
                ]
            }
        ]
    },
    # 12. Leaning Pole Repair
    {
        "fault_id": "leaning_pole_repair",
        "slot": "A",
        "short_title_bn": "হেলে পড়া ভাঙা পোল",
        "title_bn": "গাড়ির ধাক্কায় ভাঙা গোড়ার হেলে পড়া পোল প্রতিস্থাপন",
        "detail_bn": "{placeA}-এ হাইওয়ের ধারে লরির ধাক্কায় পিএসসি পোল গোড়া থেকে ফেটে বিপজ্জনকভাবে হেলে গেছে। তারের টানে যেকোনো মুহূর্তে ভেঙে পড়তে পারে।",
        "severity": "critical",
        "work": "climb",
        "urgency_minutes": 60,
        "required_crew_count": 3,
        "travel_minutes": 18,
        "repair_minutes": 35,
        "required_gear": ["tester", "earth_rods", "ptw", "rope", "tape_cones"],
        "job_gear": ["pulling_rope", "wire_grip"],
        "events": [
            {
                "id": "lp_stop",
                "mantra": "stop",
                "image": "assets/quizzes/mistake_cut_stay.webp",
                "speaker": "junior",
                "alert_bn": "হেলে পড়া পোলে ওঠার চরম ঝুঁকি",
                "line_bn": "দাদা, তারগুলো তো উপরে বাঁধা, মই লাগিয়ে পোলে উঠে তারগুলো আলগা করে দিই?",
                "situation_bn": "গোড়া ভাঙা হেলে পড়া পোলে ওঠার নিরাপত্তা সিদ্ধান্ত।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.48, 0.5],
                    "layers": [
                        {"sprite": "truck", "x": 0.18, "y": 0.82, "h": 0.08},
                        {"sprite": "man_stop", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_phone", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36, "when": ["before", "wrong"]},
                        {"sprite": "man_climb", "role": "junior", "x": 0.48, "y": 0.55, "h": 0.26, "when": "wrong"},
                        {"sprite": "man_point", "role": "junior", "x": 0.8, "y": 0.98, "h": 0.36, "when": ["before", "best"]}
                    ],
                    "spots": [
                        {"x": 0.48, "y": 0.7, "r": 0.09, "label_bn": "গোড়া ভাঙা হেলে পড়া পিসি পোল", "icon": "hazard"},
                        {"x": 0.25, "y": 0.88, "r": 0.08, "label_bn": "হাইড্রোলিক সাপোর্ট ক্রেন / গাড়ি", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "stop", "short_bn": "কখনও নয়! পোল সাপোর্টিং রোপ ও ক্রেন দিয়ে বাঁধো", "text_bn": "খবরদার! গোড়া ভাঙা পোলে কখনো মানুষ ওঠে না। আগে চারপাশ থেকে দড়ি ও উইঞ্চ দিয়ে পোল বাঁধো।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 8, "risk": 0.0, "feedback_bn": "জীবন বাঁচানো সিদ্ধান্ত। গোড়া ভাঙা পোলে উঠলে শরীরের ভারে পোল হুড়মুড়িয়ে ভেঙে পড়ে।"},
                    {"id": "b", "icon": "climb", "cause": "pole_collapse", "short_bn": "তাড়াতাড়ি উঠে তার কেটে দাও", "text_bn": "হ্যাঁ, সাবধানে উঠে ওপরের তারগুলো ঝটপট কেটে নেমে এসো।", "best": False, "safety": -40, "satisfaction": 2, "minutes": 0, "risk": 0.5, "feedback_bn": "কর্মী পোলে অর্ধেক উঠতেই গোড়া মচকে পুরো পোল রাস্তায় আছড়ে পড়ল! চরম ক্যাজুয়ালটি।"}
                ]
            },
            {
                "id": "lp_fence",
                "mantra": "fence",
                "image": "assets/quizzes/mistake_public_near_line.webp",
                "speaker": "lead",
                "alert_bn": "রাস্তার চলমান গাড়ি ও ট্রাফিক",
                "line_bn": "পোলটা রাস্তার দিকে কাত হয়ে আছে। বাস-লরি চলাচল করছে।",
                "situation_bn": "ভাঙা পোলের আশেপাশে ট্রাফিক ব্যারিকেড ও নিরাপত্তা।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.6, 0.82],
                    "layers": [
                        {"sprite": "cones_tape", "x": 0.5, "y": 0.9, "h": 0.14, "when": "best"},
                        {"sprite": "villagers", "x": 0.82, "y": 0.95, "h": 0.36},
                        {"sprite": "man_stop", "role": "lead", "x": 0.25, "y": 0.98, "h": 0.36}
                    ],
                    "spots": [
                        {"x": 0.5, "y": 0.9, "r": 0.08, "label_bn": "ট্রাফিক ব্যারিকেড ও রিফ্লেক্টর কোন", "icon": "fence"},
                        {"x": 0.82, "y": 0.8, "r": 0.08, "label_bn": "বাস ও লরি চলাচল", "icon": "crowd"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "fence", "short_bn": "রিফ্লেক্টর কোন ও ফিতে দিয়ে উভয় দিকের ট্রাফিক আটকাও", "text_bn": "অন্তত ৫০ মিটার আগে সতর্কীকরণ বোর্ড ও কোন লাগাও এবং পুলিশ/গ্রামবাসীদের দিয়ে গাড়ি থামাও।", "best": True, "safety": 10, "satisfaction": -1, "minutes": 5, "risk": 0.0, "feedback_bn": "সঠিক। পোল ভেঙে পড়ার সময় নিচে কোনো চলমান গাড়ি থাকলে প্রাণহানি ঘটে।"},
                    {"id": "b", "icon": "hurry", "cause": "vehicle", "short_bn": "গাড়ি তো পাশ দিয়েই চলে যাবে", "text_bn": "রাস্তার একপাশ ফাঁকা আছে, গাড়ি ধীরে ধীরে যেতে পারে, আমাদের কাজের দিকে খেয়াল রাখো।", "best": False, "safety": -25, "satisfaction": 2, "minutes": 0, "risk": 0.35, "feedback_bn": "ঝুলে থাকা তারে বাসের ছাদ আটকে পোল সজোরে ভেঙে বাসের ওপর ধসে পড়ল।"}
                ]
            },
            {
                "id": "lp_mend",
                "mantra": "mend",
                "image": "assets/quizzes/proc_cut_safety_belt.webp",
                "speaker": "lead",
                "alert_bn": "তারের টান নামানোর সিকোয়েন্স",
                "line_bn": "পোল বাঁধা হয়েছে। কন্ডাক্টরের টান কীভাবে খালাস করবে?",
                "situation_bn": "ভাঙা পোলের তার আলগা করার মেকানিক্যাল সিকোয়েন্স।",
                "scene": {
                    "bg": "span_two_poles",
                    "fail_at": [0.5, 0.35],
                    "layers": [
                        {"sprite": "man_stop", "role": "lead", "x": 0.28, "y": 0.98, "h": 0.36},
                        {"sprite": "man_point", "role": "junior", "x": 0.78, "y": 0.98, "h": 0.36, "when": "best"},
                        {"sprite": "man_climb", "role": "junior", "x": 0.5, "y": 0.5, "h": 0.25, "when": "wrong"}
                    ],
                    "spots": [
                        {"x": 0.5, "y": 0.32, "r": 0.08, "label_bn": "লাইন কন্ডাক্টর টেনশন", "icon": "bolt"},
                        {"x": 0.78, "y": 0.88, "r": 0.08, "label_bn": "কাম-এলং ক্ল্যাম্প ও পুলিং রোপ", "icon": "tool"}
                    ]
                },
                "options": [
                    {"id": "a", "icon": "rope", "short_bn": "ট্রেঞ্চের অপর পোলে টান ধরে তবে আলগা করো", "text_bn": "পাশের সুস্থ পোলে ব্যাক-স্টে বেঁধে টান রাখো, তারপর পুলিং রোপ দিয়ে আস্তে আস্তে কন্ডাক্টর নামাও।", "best": True, "safety": 8, "satisfaction": 0, "minutes": 6, "risk": 0.0, "feedback_bn": "নিখুঁত মেকানিক্যাল ব্যালান্স। ভারসাম্য বজায় রেখে তার নামালে পোল ঝাঁকুনি খায় না।"},
                    {"id": "b", "icon": "cut", "cause": "pole_collapse", "short_bn": "তার এক ঝটকায় কেটে ফেলো", "text_bn": "টান আলগা করার সময় নেই, হ্যাকস দিয়ে তার সোজাসুজি কেটে দাও।", "best": False, "safety": -35, "satisfaction": 1, "minutes": 0, "risk": 0.45, "feedback_bn": "একদিকের তার কাটতেই বিপরীত টানের ভারসাম্য হারিয়ে পোল উল্টোদিকে ছিটকে পড়ল।"}
                ]
            }
        ]
    }
]

# Write all 12 faults to data['faults']
data['faults'] = jobs_catalog

with open(data_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Successfully updated {data_path} with {len(data['faults'])} jobs and {len(data['gear'])} gear items!")
