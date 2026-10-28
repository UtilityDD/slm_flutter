import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'duty_slip_engine.dart';

class _Piece {
  const _Piece({required this.id, required this.asset, required this.zone, required this.good, required this.why});
  final String id;
  final String asset;
  final String zone;
  final bool good;
  final String why;
}

const _pieces = <_Piece>[
  _Piece(id: 'fatua', asset: 'assets/duty_slip/dress/tray_fatua.webp', zone: 'torso', good: false, why: 'না, সাবধান! ঢিলে পোশাক বাতাসে উড়ে লাইনের তারে জড়িয়ে যেতে পারে। শরীর আঁটোসাঁটো রাখা জরুরি।'),
  _Piece(id: 'halftee', asset: 'assets/duty_slip/dress/tray_halftee.webp', zone: 'torso', good: false, why: 'থামুন! হাত খোলা থাকলে সামান্য স্পার্কেই সরাসরি চামড়া পুড়ে যাবে। হাত সম্পূর্ণ ঢাকা দরকার।'),
  _Piece(id: 'poly', asset: 'assets/duty_slip/dress/tray_poly.webp', zone: 'torso', good: false, why: 'মারাত্মক ভুল! আর্ক ফ্ল্যাশের তাপে পলিয়েস্টার গলে চামড়ায় আটকে যাবে। এমন কাপড় বিপজ্জনক।'),
  _Piece(id: 'shirt', asset: 'assets/duty_slip/dress/tray_shirt.webp', zone: 'torso', good: true, why: ''),
  _Piece(id: 'halfpant', asset: 'assets/duty_slip/dress/tray_halfpant.webp', zone: 'legs', good: false, why: 'সাবধান! পা উন্মুক্ত রেখে কাজ করা অনিরাপদ, ধারালো তারের ঘষা লাগতে পারে।'),
  _Piece(id: 'pajama', asset: 'assets/duty_slip/dress/tray_pajama.webp', zone: 'legs', good: false, why: 'না, এটা বিপজ্জনক! ঢিলে পাজামা যন্ত্রাংশে আটকে ভারসাম্য নষ্ট করতে পারে।'),
  _Piece(id: 'pant', asset: 'assets/duty_slip/dress/tray_pant.webp', zone: 'legs', good: true, why: ''),
  _Piece(id: 'slip', asset: 'assets/duty_slip/dress/tray_slipper.webp', zone: 'feet', good: false, why: 'বিপদ! চপ্পলে কোনো গ্রিপ নেই—মই বা পোলে পা হড়কালেই পতন ঘটবে।'),
  _Piece(id: 'normal', asset: 'assets/duty_slip/dress/tray_normalshoe.webp', zone: 'feet', good: false, why: 'না, সতর্ক হোন! সাধারণ জুতোর সোলে বৈদ্যুতিক ইনসুলেশন থাকে না।'),
  _Piece(id: 'boot', asset: 'assets/duty_slip/dress/tray_boot.webp', zone: 'feet', good: true, why: ''),
];

const _roomStart = 'কন্ট্রোল রুমের ভিতরে কাজের আদেশ এসেছে। দ্রুত তৈরি হতে হবে।';
const _roomDone = 'সাজ সম্পূর্ণ। ভোল্টেজ ডিটেক্টর, ডিসচার্জ রড আর পোর্টেবল আর্থিং কিট ভ্যানে উঠেছে। এবার বের হওয়া যাবে।';
const _vanInsist = 'লাইনম্যান তৈরি। ভোল্টেজ ডিটেক্টর, ডিসচার্জ রড আর পোর্টেবল আর্থিং কিট সবসময় সঙ্গে রাখতে হবে।';
const _vanNoTester = 'ভোল্টেজ ডিটেক্টর ছাড়া ভ্যানে উঠবেন না। লাইন জীবিত না মৃত, আগে সেটাই দেখতে হয়।';
const _vanNoDischarge = 'ডিসচার্জ রড বাদ পড়েছে। আটকে থাকা বিদ্যুৎ না নামালে ছুঁলেই শক।';
const _vanNoEarth = 'পোর্টেবল আর্থিং কিট না নিলে কাজ শুরু করা যাবে না। ভোল্টেজ ফিরলে মাটিতে যাবে না।';
const _roomFatua = 'না, সাবধান! ঢিলে পোশাক প্যানেলের হাতলে জড়িয়ে যেতে পারে। শরীর আঁটোসাঁটো রাখা জরুরি।';
const _roomBareLeg = 'সাবধান! পা উন্মুক্ত রেখে কাজ করা অনিরাপদ, আর্কের আগুন সরাসরি চামড়ায় লাগবে।';
const _roomSlip = 'বিপদ! চপ্পলে কোনো ইনসুলেশন নেই। স্পার্ক লাগলে পা বাঁচবে না।';
const _roomHarness = 'সাবধান! কন্ট্রোল রুমে হারনেস লাগে না। প্যানেলের দরজায় আটকে গেলে বিপদ। এই ঘরে হারনেস খুলে রাখুন।';
const _roomBelt = 'না, এটা বিপজ্জনক! কোমরের বেল্ট প্যানেলের হাতলে আটকে যেতে পারে। এই ঘরে বেল্ট নয়।';
const _roomNoShirt = 'থামুন! শরীর খোলা থাকলে সামান্য স্পার্কেই সরাসরি চামড়া পুড়ে যাবে। শরীর সম্পূর্ণ ঢাকা দরকার।';
const _roomNoHelmet = 'মাথার সুরক্ষায় কোনো ছাড় নেই। নিশ্ছিদ্র ইলেকট্রিক্যাল হেলমেট পরুন।';
const _roomNoShield = 'থামুন! মুখ খোলা থাকলে আর্ক ফ্ল্যাশের আগুন সরাসরি চোখে লাগবে। ফেস শিল্ড দরকার।';
const _roomNoGlove = 'থামুন! হাত খালি থাকলে সামান্য স্পার্কেই সরাসরি চামড়া পুড়ে যাবে। ইনসুলেটেড গ্লাভস দরকার।';
const _roomNoBoot = 'না, সতর্ক হোন! খালি পায়ে বৈদ্যুতিক ইনসুলেশন থাকে না। সেফটি বুট পরুন।';
const _roomMiss = 'আরও কিছু জিনিস বাদ পড়েছে।';
const _roomDress = {'shirt', 'pant', 'boot', 'helmet', 'shield', 'rubber'};
const _vanMust = {'tester', 'discharge', 'earth'};
const _roomKeep = {..._roomDress, ..._vanMust};

const _poleStart = 'গলিতে তার ছিঁড়ে মাটিতে পড়ে আছে। খুঁটিতে ওঠার আগে যা যা লাগবে, বেঞ্চে রাখুন। ঠিক মনে হলে তৈরি টিপুন।';
const _poleDone = 'ঠিক আছে। এই সাজে খুঁটিতে ওঠা যাবে।';
const _poleBamboo = 'আরে, বাঁশের মই নিয়ে উঠবেন না। ভিজলে পা হড়কায়, হঠাৎ ভেঙেও যায়।';
const _poleBelt = 'কোমরের বেল্টে ঝুললে শরীর উল্টে যায়। খুঁটিতে ফুল-বডি হারনেস লাগবে।';
const _poleSlip = 'চপ্পল পরে মইয়ে উঠবেন না। পা হড়কালেই পড়ে যাবেন।';
const _poleShoe = 'সাধারণ জুতোয় বিদ্যুৎ আটকায় না, মইয়ে পাও হড়কায়। সেফটি বুট রাখুন।';
const _poleRoad = 'এটা রাস্তার হেলমেট। খুঁটির কাজে এতে মাথা বাঁচবে না।';
const _poleVent = 'ফুটো হেলমেট নিয়ে খুঁটিতে উঠবেন না। ফুলকি বা জল ঢুকে যাবে।';
const _poleCotton = 'সুতির গ্লাভসে বিদ্যুৎ আটকায় না। রাবারের গ্লাভস রাখুন।';
const _poleWet = 'গ্লাভস ভেজা। ভেজা গ্লাভস দিয়ে বিদ্যুৎ হাতে চলে আসে।';
const _poleHole = 'এই গ্লাভসে ফুটো। ফুটো দিয়েই শক লাগে।';
const _poleBike = 'বাইকের গ্লাভসে বিদ্যুৎ আটকায় না।';
const _poleFatua = 'ফতুয়া হাওয়ায় উড়ে তারে জড়িয়ে যাবে। সুতির শার্ট রাখুন।';
const _poleHalf = 'হাতা ছোট। তারের ছ্যাঁকা সোজা গায়ে লাগবে।';
const _polePoly = 'পলিয়েস্টার গলে গায়ে লেগে যায়। সুতির শার্ট রাখুন।';
const _polePajama = 'ঢিলে পাজামায় পা জড়িয়ে মই থেকে পড়ে যাবেন।';
const _poleHalfPant = 'হাফ প্যান্টে পা খোলা। তারের ঘষা সোজা গায়ে লাগবে।';
const _poleGamcha = 'গামছা মাথায় জড়ালে হেলমেট বসবে না। এতে বিদ্যুৎও আটকায় না।';
const _poleKeep = {'shirt', 'pant', 'boot', 'helmet', 'rubber', 'harness', 'frp'};

const _dtrStart = 'শাটডাউন হয়েছে। বুশিং খোলার আগে যা যা লাগবে, বেঞ্চে রাখুন। ঠিক মনে হলে তৈরি টিপুন।';
const _dtrDone = 'ঠিক আছে। এবার বুশিং খোলা যাবে।';
const _dtrWire = 'তার জড়িয়ে শর্ট করবেন না। ডিসচার্জ রড দিয়ে মাটিতে নামান।';
const _dtrCloth = 'ভেজা ন্যাকড়া দিয়ে বুশিং মুছবেন না। জল দিয়ে বিদ্যুৎ হাতে চলে আসবে।';
const _dtrRoad = 'এটা রাস্তার হেলমেট। বুশিংয়ের কাজে এতে মাথা বাঁচবে না।';
const _dtrVent = 'ফুটো হেলমেট নিয়ে বুশিং খুলবেন না। ফুলকি ঢুকে যাবে।';
const _dtrGamcha = 'গামছা মাথায় জড়ালে হেলমেট বসবে না। বুশিংয়ের আগুনও আটকায় না।';
const _dtrFatua = 'ফতুয়া হাওয়ায় উড়ে বুশিংয়ে জড়িয়ে যাবে। সুতির শার্ট রাখুন।';
const _dtrHalf = 'হাতা ছোট। আর্কের ছ্যাঁকা সোজা গায়ে লাগবে।';
const _dtrPoly = 'পলিয়েস্টার গলে গায়ে লেগে যায়। সুতির শার্ট রাখুন।';
const _dtrPajama = 'ঢিলে পাজামা যন্ত্রাংশে জড়িয়ে যাবে।';
const _dtrHalfPant = 'হাফ প্যান্টে পা খোলা। আর্কের আগুন সোজা গায়ে লাগবে।';
const _dtrCotton = 'সুতির গ্লাভসে বিদ্যুৎ আটকায় না। রাবারের গ্লাভস রাখুন।';
const _dtrWet = 'গ্লাভস ভেজা। ভেজা গ্লাভস দিয়ে বিদ্যুৎ হাতে চলে আসে।';
const _dtrHole = 'এই গ্লাভসে ফুটো। ফুটো দিয়েই শক লাগে।';
const _dtrBike = 'বাইকের গ্লাভসে বিদ্যুৎ আটকায় না।';
const _dtrSlip = 'চপ্পল পরে বুশিংয়ের কাছে যাবেন না। পা হড়কাবে, বিদ্যুৎও আটকাবে না।';
const _dtrShoe = 'সাধারণ জুতোয় বিদ্যুৎ আটকায় না। সেফটি বুট রাখুন।';
const _dtrKeep = {'shirt', 'pant', 'boot', 'helmet', 'shield', 'rubber', 'tester', 'discharge', 'earth'};

const _nightStart = 'রাত দুপুরে এলটি ফল্ট। যা যা লাগবে, বেঞ্চে রাখুন। ঠিক মনে হলে তৈরি টিপুন।';
const _nightDone = 'ঠিক আছে। এই সাজে রাতের লাইনে নামা যাবে।';
const _nightBamboo = 'আরে, বাঁশের মই নিয়ে রাতে উঠবেন না। ভিজলে পা হড়কায়, অন্ধকারে দেখাও যায় না।';
const _nightWet = 'গ্লাভস ভেজা। ভেজা গ্লাভস দিয়ে বিদ্যুৎ হাতে চলে আসে।';
const _nightSlip = 'চপ্পল পরে রাতের রাস্তায় উঠবেন না। পা হড়কালেই পড়ে যাবেন।';
const _nightRoad = 'এটা রাস্তার হেলমেট। রাতের লাইনে এতে মাথা বাঁচবে না।';
const _nightVent = 'ফুটো হেলমেট নিয়ে বৃষ্টিতে উঠবেন না। জল ঢুকে যাবে।';
const _nightGamcha = 'গামছা মাথায় জড়ালে হেলমেট বসবে না। রাতে গাড়িও আপনাকে দেখবে না।';
const _nightFatua = 'ফতুয়া হাওয়ায় উড়ে তারে জড়িয়ে যাবে। সুতির শার্ট রাখুন।';
const _nightHalf = 'হাতা ছোট। তারের ছ্যাঁকা সোজা গায়ে লাগবে।';
const _nightPoly = 'পলিয়েস্টার গলে গায়ে লেগে যায়। সুতির শার্ট রাখুন।';
const _nightPajama = 'ঢিলে পাজামায় পা জড়িয়ে মই থেকে পড়ে যাবেন।';
const _nightHalfPant = 'হাফ প্যান্টে পা খোলা। তারের ঘষা সোজা গায়ে লাগবে।';
const _nightCotton = 'সুতির গ্লাভসে বিদ্যুৎ আটকায় না। রাবারের গ্লাভস রাখুন।';
const _nightHole = 'এই গ্লাভসে ফুটো। ফুটো দিয়েই শক লাগে।';
const _nightBike = 'বাইকের গ্লাভসে বিদ্যুৎ আটকায় না।';
const _nightShoe = 'সাধারণ জুতোয় বিদ্যুৎ আটকায় না, ভেজা রাস্তায় পাও হড়কায়। সেফটি বুট রাখুন।';
const _nightKeep = {'shirt', 'pant', 'boot', 'helmet', 'rubber', 'vest', 'torch', 'frp'};

const _treeStart = 'ডাল লাইনের উপর। নামানোর আগে যা যা লাগবে, বেঞ্চে রাখুন। ঠিক মনে হলে তৈরি টিপুন।';
const _treeDone = 'ঠিক আছে। এবার ডাল নামানো যাবে।';
const _treeSickle = 'লাইন মৃত না করে কাস্তে দিয়ে ডাল কাটবেন না।';
const _treeSaw = 'লাইন মৃত না করে করাত দিয়ে ডাল কাটবেন না।';
const _treeRoad = 'এটা রাস্তার হেলমেট। ডালের কাজে এতে মাথা বাঁচবে না।';
const _treeVent = 'ফুটো হেলমেট নিয়ে ডালের কাছে যাবেন না। ফুলকি ঢুকে যাবে।';
const _treeGamcha = 'গামছা মাথায় জড়ালে হেলমেট বসবে না। এতে বিদ্যুৎও আটকায় না।';
const _treeFatua = 'ফতুয়া হাওয়ায় উড়ে ডালে জড়িয়ে যাবে। সুতির শার্ট রাখুন।';
const _treeHalf = 'হাতা ছোট। ডালের ঘষা সোজা গায়ে লাগবে।';
const _treePoly = 'পলিয়েস্টার গলে গায়ে লেগে যায়। সুতির শার্ট রাখুন।';
const _treePajama = 'ঢিলে পাজামা ডালে জড়িয়ে যাবে।';
const _treeHalfPant = 'হাফ প্যান্টে পা খোলা। ডালের ঘষা সোজা গায়ে লাগবে।';
const _treeCotton = 'সুতির গ্লাভসে বিদ্যুৎ আটকায় না। রাবারের গ্লাভস রাখুন।';
const _treeWet = 'গ্লাভস ভেজা। ভেজা গ্লাভস দিয়ে বিদ্যুৎ হাতে চলে আসে।';
const _treeHole = 'এই গ্লাভসে ফুটো। ফুটো দিয়েই শক লাগে।';
const _treeBike = 'বাইকের গ্লাভসে বিদ্যুৎ আটকায় না।';
const _treeSlip = 'চপ্পল পরে ভেজা মাটিতে ডাল নামানো যাবে না। পা হড়কালেই পড়ে যাবেন।';
const _treeShoe = 'সাধারণ জুতোয় বিদ্যুৎ আটকায় না। সেফটি বুট রাখুন।';
const _treeKeep = {'shirt', 'pant', 'boot', 'helmet', 'rubber', 'tester', 'discharge', 'rope'};

const _testerPiece = _Piece(id: 'tester', asset: 'assets/zero_loss/scene/gear_tester.webp', zone: 'tool', good: true, why: '');
const _dischargePiece = _Piece(id: 'discharge', asset: 'assets/safety/library/ppe/discharge_rod_1.webp', zone: 'tool', good: true, why: '');
const _earthPiece = _Piece(id: 'earth', asset: 'assets/zero_loss/scene/gear_earth_rods.webp', zone: 'tool', good: true, why: '');
const _wirePiece = _Piece(id: 'wire', asset: 'assets/duty_slip/dress/tray_wire.webp', zone: 'tool', good: false, why: _dtrWire);
const _clothPiece = _Piece(id: 'cloth', asset: 'assets/zero_loss/scene/gear_wet_cloth.webp', zone: 'tool', good: false, why: _dtrCloth);
const _vestPiece = _Piece(id: 'vest', asset: 'assets/zero_loss/scene/gear_high_vis_vest.webp', zone: 'tool', good: true, why: '');
const _torchPiece = _Piece(id: 'torch', asset: 'assets/zero_loss/scene/gear_high_lumen_torch.webp', zone: 'tool', good: true, why: '');
const _ropePiece = _Piece(id: 'rope', asset: 'assets/zero_loss/scene/gear_rope.webp', zone: 'tool', good: true, why: '');
const _sicklePiece = _Piece(id: 'sickle', asset: 'assets/zero_loss/scene/gear_iron_sickle.webp', zone: 'tool', good: false, why: _treeSickle);
const _sawPiece = _Piece(id: 'saw', asset: 'assets/zero_loss/scene/gear_tree_saw.webp', zone: 'tool', good: false, why: _treeSaw);

const _vanTraps = <_Piece>[
  _Piece(id: 'neon', asset: 'assets/safety/library/tools/Non_Contact_Voltage_Tester_2.webp', zone: 'tool', good: false, why: 'এই কলম টেস্টার 11 কেভিতে কাজ করে না। হাই ভোল্টেজ ডিটেক্টর নিন।'),
  _Piece(id: 'meter', asset: 'assets/safety/library/tools/Multimeter_Digital.webp', zone: 'tool', good: false, why: 'মাল্টিমিটার দিয়ে হাই ভোল্টেজ লাইন ছোঁবেন না। ভোল্টেজ ডিটেক্টর লাগবে।'),
  _Piece(id: 'megger', asset: 'assets/safety/library/tools/Analog_Insulation_Tester_Hand_Crank.webp', zone: 'tool', good: false, why: 'মেগার ইনসুলেশন মাপে। লাইন জীবিত কি না, ভোল্টেজ ডিটেক্টর বলে।'),
  _Piece(id: 'clamp', asset: 'assets/safety/library/tools/Digital_Clamp_On_Meter.webp', zone: 'tool', good: false, why: 'ক্ল্যাম্প মিটার কারেন্ট মাপে। লাইন মৃত প্রমাণ করে না।'),
  _Piece(id: 'pliers', asset: 'assets/zero_loss/scene/gear_plain_pliers.webp', zone: 'tool', good: false, why: 'সাধারণ প্লায়ার বিদ্যুৎ আটকায় না। এটা ভ্যানে তুলবেন না।'),
  _Piece(id: 'cloth', asset: 'assets/zero_loss/scene/gear_wet_cloth.webp', zone: 'tool', good: false, why: 'ভেজা ন্যাকড়া বিদ্যুৎ সরায় না। হাতে নিয়ে ছুঁলে শক লাগবে।'),
  _Piece(id: 'wire', asset: 'assets/zero_loss/scene/gear_plain_wire.webp', zone: 'tool', good: false, why: 'খোলা তার দিয়ে শর্ট করবেন না। পোর্টেবল আর্থিং কিট লাগবে।'),
  _Piece(id: 'fuse', asset: 'assets/zero_loss/scene/gear_fuse_wire.webp', zone: 'tool', good: false, why: 'ফিউজ তার আর্থিং নয়। পোর্টেবল আর্থিং কিট নিন।'),
  _Piece(id: 'hacksaw', asset: 'assets/safety/library/tools/Hacksaw.webp', zone: 'tool', good: false, why: 'করাত দিয়ে চার্জড লাইন কাটা যায় না।'),
  _Piece(id: 'torque', asset: 'assets/zero_loss/scene/gear_torque_wrench.webp', zone: 'tool', good: false, why: 'টর্ক রেঞ্চ এখন দরকার নেই। আগে ডিটেক্টর, ডিসচার্জ রড আর আর্থিং।'),
  _Piece(id: 'sickle', asset: 'assets/zero_loss/scene/gear_iron_sickle.webp', zone: 'tool', good: false, why: 'কাস্তে কন্ট্রোল রুমের সাজ নয়।'),
  _Piece(id: 'driver', asset: 'assets/safety/library/tools/Insulated_Screwdriver.webp', zone: 'tool', good: false, why: 'স্ক্রু ড্রাইভার ভোল্টেজ ডিটেক্টরের বদলি নয়।'),
  _Piece(id: 'earthmeter', asset: 'assets/safety/library/tools/Digital_Earth_Tester.webp', zone: 'tool', good: false, why: 'আর্থ টেস্টার মাটির রোধ মাপে। এটা পোর্টেবল আর্থিং কিট নয়।'),
  _Piece(id: 'spanner', asset: 'assets/safety/library/tools/Combination_Spanner.webp', zone: 'tool', good: false, why: 'স্প্যানার দিয়ে লাইন মৃত হয় না।'),
];

const _vanToolPieces = <_Piece>[_testerPiece, _dischargePiece, _earthPiece, ..._vanTraps];

const _vanToolIds = {
  'tester', 'discharge', 'earth',
  'neon', 'meter', 'megger', 'clamp', 'pliers', 'cloth', 'wire',
  'fuse', 'hacksaw', 'torque', 'sickle', 'driver', 'earthmeter', 'spanner',
};

const _frpPiece = _Piece(
  id: 'frp',
  asset: 'assets/zero_loss/scene/gear_frp_ladder.webp',
  zone: 'ladder',
  good: true,
  why: '',
);
const _bambooPiece = _Piece(
  id: 'bamboo',
  asset: 'assets/zero_loss/scene/gear_bamboo_ladder.webp',
  zone: 'ladder',
  good: false,
  why: _poleBamboo,
);

const _benchOrder = [
  'fatua', 'halftee', 'poly', 'shirt',
  'halfpant', 'pajama', 'pant',
  'slip', 'normal', 'boot',
  'road', 'vent', 'helmet',
  'cotton', 'wet', 'hole', 'bike', 'rubber',
  'gamcha', 'shield', 'belt', 'harness',
  'frp', 'bamboo',
  'tester', 'discharge', 'earth', 'wire', 'cloth',
  'neon', 'meter', 'megger', 'clamp', 'pliers', 'fuse', 'hacksaw', 'torque', 'driver', 'earthmeter', 'spanner',
  'vest', 'torch', 'rope', 'sickle', 'saw',
];

const _shoeBlock = 'আরে আরে, ভুল হচ্ছে! জুতো পরা অবস্থায় প্যান্ট ঠিকমতো পরা সম্ভব নয়। আগে প্যান্টের কাজ শেষ করুন।';

const _headPieces = <_Piece>[
  _Piece(id: 'gamcha', asset: 'assets/duty_slip/dress/tray_gamcha.webp', zone: 'head', good: true, why: ''),
  _Piece(id: 'road', asset: 'assets/duty_slip/dress/tray_road_helmet.webp', zone: 'head', good: false, why: 'না, একদম নয়! এটি ট্রাফিকের হেলমেট, হাই-ভোল্টেজ শক আটকানোর ক্ষমতা নেই।'),
  _Piece(id: 'vent', asset: 'assets/duty_slip/dress/tray_vent_helmet.webp', zone: 'head', good: false, why: 'বিপজ্জনক! বাতাসের ফুটো দিয়ে লাইনের স্পার্ক বা জল ঢুকলে মাথায় বিদ্যুৎ নামবে। নিশ্ছিদ্র শেল প্রয়োজন।'),
  _Piece(id: 'helmet', asset: 'assets/duty_slip/dress/tray_elec_helmet.webp', zone: 'head', good: true, why: ''),
];

const _gamchaBlock = 'একটু দাঁড়ান! মাথায় কাপড় থাকলে হেলমেট বসবে না, একটু ঝাঁকুনিতেই পড়ে যাবে।';
const _gamchaNoSave = 'না দাদা! গামছা কোনো নিরাপত্তা সরঞ্জাম নয়, এটি বিদ্যুৎস্পর্শ আটকাতে পারে না।';

const _handPieces = <_Piece>[
  _Piece(id: 'cotton', asset: 'assets/duty_slip/dress/tray_cotton_gloves.webp', zone: 'hands', good: false, why: 'সাবধান! সুতির কাপড়ে কোনো ইনসুলেশন থাকে না, বিদ্যুৎ স্পর্শ লাগলেই মারাত্মক শক লাগবে।'),
  _Piece(id: 'wet', asset: 'assets/duty_slip/dress/tray_wet_gloves.webp', zone: 'hands', good: false, why: 'থামুন! গ্লাভসে সামান্য আর্দ্রতা বা জল থাকলে তা দিয়ে বিদ্যুৎ শরীরে নেমে আসবে। সম্পূর্ণ শুকনো গ্লাভস আবশ্যক।'),
  _Piece(id: 'hole', asset: 'assets/duty_slip/dress/tray_hole_gloves.webp', zone: 'hands', good: false, why: 'বিপজ্জনক! সামান্য সূক্ষ্ম ছিদ্র বা পিনহোল থাকলেও হাই-ভোল্টেজ বিদ্যুৎ সেখান দিয়েই আঘাত করবে। কাজ শুরুর আগে হাওয়া ভরে পরীক্ষা জরুরি।'),
  _Piece(id: 'bike', asset: 'assets/duty_slip/dress/tray_bike_gloves.webp', zone: 'hands', good: false, why: 'না, মারাত্মক ঝুঁকি! সাধারণ বাইকের গ্লাভসে বিদ্যুৎ অপরিবাহী স্তর থাকে না, এতে বিদ্যুৎ আটকাবে না।'),
  _Piece(id: 'rubber', asset: 'assets/duty_slip/dress/tray_rubber_gloves.webp', zone: 'hands', good: true, why: ''),
];

const _gloveBlock = 'থামুন! মোটা গ্লাভস পরে হারনেসের বাকল বা ডি-রিং ঠিকমতো ধরা ও লক করা যায় না। আগে গ্লাভস খুলে নিন।';
const _sleeveBlock = 'গ্লাভস পরা থাকলে হাতা পরবেন কীভাবে? আগে গ্লাভস খুলুন।';
const _laceBlock = 'গ্লাভস পরা থাকলে জুতোর ফিতে বাঁধবেন কীভাবে? আগে গ্লাভস খুলুন।';
const _harnessClothes = 'শার্ট আর প্যান্ট না পরলে হারনেস বসে না।';
const _harnessBoot = 'আগে সেফটি সু পরুন। তারপর হারনেস।';
const _helmetHarness = 'আগে হারনেস পরুন। তারপর হেলমেট।';
const _shieldBlock = 'হেলমেট না থাকলে ফেস শিল্ড আটকায় না। আগে বিদ্যুতের হেলমেট পরুন।';

const _shieldPiece = _Piece(
  id: 'shield',
  asset: 'assets/duty_slip/dress/tray_faceshield.webp',
  zone: 'head',
  good: true,
  why: '',
);

const _fullOrder = [
  'fatua',
  'road',
  'cotton',
  'belt',
  'pant',
  'vent',
  'wet',
  'slip',
  'halftee',
  'bike',
  'harness',
  'boot',
  'gamcha',
  'hole',
  'poly',
  'shield',
  'halfpant',
  'rubber',
  'pajama',
  'normal',
  'shirt',
  'helmet',
];

const _looseFingers = 'চার আঙুল ঢুকছে। ফিতা ঢিলা।';
const _tightFingers = 'এক আঙুলও ঢোকে না। একটু ঢিলা করুন।';
const _twoFingers = 'দুই আঙুল ঢোকে, তার বেশি নয়।';
const _legsFirst = 'পায়ের বাকল খোলা থাকলে হারনেস খুলে যায়। আগে দুই পা বাঁধুন।';
const _tugEarly = 'খোলা বাকল টানলে ফিতা বেরিয়ে আসে। আগে সব বাকল বন্ধ করুন।';
const _tugHeld = 'টানলাম। ফিতা সরেনি। দুই আঙুল ঢোকে, তার বেশি নয়।';
const _wrongLeg = 'এই ফিতা ওই পায়ে বসে না।';
const _legOnRing = 'পায়ের ফিতা রিংয়ে বসে না।';
const _chestOnBuckle = 'বুকের ফিতা এই বাকলে বসে না।';
const _waistOnThigh = 'কোমরের ফিতা উরুর বাকলে বসে না।';
const _thighOnWaist = 'উরুর ফিতা কোমরের বাকলে বসে না।';
const _waistOnRing = 'কোমরের ফিতা রিংয়ে বসে না।';
const _wrongWaist = 'এই ফিতা ওই কোমরে বসে না।';
const _buckleFirst = 'আগে বাকল বন্ধ করুন। তারপর আঙুল দেখুন।';
const _fingersFirst = 'আগে দুই আঙুল মিলিয়ে নিন।';

const _strapAsset = 'assets/duty_slip/dress/tray_harness.webp';

const _fingersPiece = _Piece(
  id: 'fingers',
  asset: 'assets/duty_slip/dress/tray_two_fingers.webp',
  zone: 'gap',
  good: true,
  why: '',
);
const _endL = _Piece(id: 'endL', asset: _strapAsset, zone: 'endL', good: true, why: '');
const _endR = _Piece(id: 'endR', asset: _strapAsset, zone: 'endR', good: true, why: '');
const _endWaistL = _Piece(id: 'endWaistL', asset: _strapAsset, zone: 'endWaistL', good: true, why: '');
const _endWaistR = _Piece(id: 'endWaistR', asset: _strapAsset, zone: 'endWaistR', good: true, why: '');
const _endChest = _Piece(id: 'endChest', asset: _strapAsset, zone: 'endChest', good: true, why: '');

enum _Gap { open, loose, snug, tight }

enum _HStep { gloves, lift, shoulderL, shoulderR, chest, chestFit, legL, legR, waistL, waistR, tuckL, tuckR, nape, fitL, fitR, done }

const _holdRing = 'পিঠের রিং ধরে তুলুন।';
const _shouldersOn = 'কাঁধে ফিতা দিন। রিং পিঠে, দুই কাঁধের মাঝে।';
const _leftShoulder = 'আগে বাঁ কাঁধে তুলুন।';
const _otherShoulder = 'এই ফিতা ওই কাঁধে বসে না।';
const _legBuckle = 'পায়ের ফিতা উল্টো দিকের বাকলে আটকান।';
const _tuckTail = 'খোলা ফিতা ঝুললে বিপদ।';
const _napeReach = 'পিঠের রিং হাত পৌঁছায়।';
const _doneMove = 'হারনেস ঠিক আছে। নড়াচড়া করা যায়।';

const _pullRing = _Piece(id: 'pullRing', asset: _strapAsset, zone: 'pullRing', good: true, why: '');
const _pullStrap = _Piece(id: 'pullStrap', asset: _strapAsset, zone: 'pullStrap', good: true, why: '');
const _pullShoulder = _Piece(id: 'pullShoulder', asset: _strapAsset, zone: 'handReach', good: true, why: '');
const _pullChest = _Piece(id: 'pullChest', asset: _strapAsset, zone: 'endChest', good: true, why: '');
const _pullLeg = _Piece(id: 'pullLeg', asset: _strapAsset, zone: 'endL', good: true, why: '');
const _pullWaist = _Piece(id: 'pullWaist', asset: _strapAsset, zone: 'endWaistL', good: true, why: '');
const _pullTuck = _Piece(id: 'pullTuck', asset: _strapAsset, zone: 'tuckFromL', good: true, why: '');
const _pullHand = _Piece(id: 'pullHand', asset: _strapAsset, zone: 'handReach', good: true, why: '');
const _pullFit = _Piece(id: 'pullFit', asset: _strapAsset, zone: 'fitPull', good: true, why: '');

const _harnessPieces = <_Piece>[
  _Piece(id: 'rubber', asset: 'assets/duty_slip/dress/tray_rubber_gloves.webp', zone: 'hands', good: true, why: ''),
  _Piece(id: 'belt', asset: 'assets/duty_slip/dress/tray_waist_belt.webp', zone: 'torso', good: false, why: 'সাবধান! কোমরের সাধারণ বেল্ট পতনজনিত অবস্থায় মেরুদণ্ড ভেঙে দিতে পারে। ওপরের কাজের জন্য ফুল বডি হারনেস আবশ্যক।'),
  _Piece(id: 'harness', asset: 'assets/duty_slip/dress/tray_harness.webp', zone: 'torso', good: true, why: ''),
];

class _Mark {
  const _Mark(this.zone, this.why, this.asset);
  final String zone;
  final String why;
  final String asset;
}

enum _MarkShape { dots, openC, clasp, ring, ticks, pull }

class _Spot {
  const _Spot(this.zone, this.l, this.t, this.w, this.h, {this.mark = true, this.shape = _MarkShape.dots, this.reachScale = 1.5});
  final String zone;
  final double l;
  final double t;
  final double w;
  final double h;
  final bool mark;
  final _MarkShape shape;
  final double reachScale;

  Rect of(Rect image) => Rect.fromLTWH(image.left + image.width * l, image.top + image.height * t, image.width * w, image.height * h);

  /// Drop reach around the mark. The painted mark stays on [of].
  Rect reach(Rect image) {
    final mark = of(image);
    return Rect.fromCenter(center: mark.center, width: mark.width * reachScale, height: mark.height * reachScale);
  }
}

const _spotHead = _Spot('head', 0.39, 0.03, 0.22, 0.16);
const _spotNeck = _Spot('neck', 0.43, 0.16, 0.14, 0.08);
const _spotChest = _Spot('torso', 0.40, 0.22, 0.20, 0.14);
const _spotTorso = _Spot('torso', 0.40, 0.22, 0.20, 0.28);
const _spotBuckle = _Spot('harness', 0.42, 0.36, 0.16, 0.14);
const _spotHandL = _Spot('hands', 0.28, 0.45, 0.11, 0.17);
const _spotHandR = _Spot('hands', 0.61, 0.45, 0.11, 0.17, mark: false);
const _jointReach = 1.3;
const _spotEndL = _Spot('endL', 0.34, 0.68, 0.09, 0.08, shape: _MarkShape.openC, reachScale: _jointReach);
const _spotBuckleL = _Spot('buckleL', 0.35, 0.555, 0.10, 0.065, shape: _MarkShape.clasp, reachScale: _jointReach);
const _spotTightL = _Spot('tightL', 0.44, 0.60, 0.07, 0.06, mark: false, reachScale: _jointReach);
const _spotGapL = _Spot('gapL', 0.36, 0.58, 0.08, 0.14, shape: _MarkShape.ticks, reachScale: _jointReach);
const _spotEndR = _Spot('endR', 0.58, 0.66, 0.09, 0.10, shape: _MarkShape.openC, reachScale: _jointReach);
const _spotBuckleR = _Spot('buckleR', 0.555, 0.555, 0.10, 0.065, shape: _MarkShape.clasp, reachScale: _jointReach);
const _spotTightR = _Spot('tightR', 0.49, 0.60, 0.07, 0.06, mark: false, reachScale: _jointReach);
const _spotGapR = _Spot('gapR', 0.56, 0.58, 0.08, 0.14, shape: _MarkShape.ticks, reachScale: _jointReach);
const _spotEndWaistL = _Spot('endWaistL', 0.36, 0.49, 0.08, 0.07, shape: _MarkShape.openC, reachScale: _jointReach);
const _spotWaistBuckleL = _Spot('buckleWaistL', 0.355, 0.44, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: _jointReach);
const _spotEndWaistR = _Spot('endWaistR', 0.57, 0.49, 0.08, 0.07, shape: _MarkShape.openC, reachScale: _jointReach);
const _spotWaistBuckleR = _Spot('buckleWaistR', 0.56, 0.44, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: _jointReach);
const _spotEndChest = _Spot('endChest', 0.36, 0.27, 0.10, 0.08, shape: _MarkShape.openC, reachScale: _jointReach);
const _spotRing = _Spot('ring', 0.45, 0.27, 0.10, 0.07, shape: _MarkShape.ring, reachScale: _jointReach);
const _spotRingHandle = _Spot('ring', 0.455, 0.295, 0.09, 0.07, mark: false, reachScale: _jointReach);
const _spotTug = _Spot('tug', 0.46, 0.385, 0.08, 0.06, shape: _MarkShape.pull, reachScale: _jointReach);
const _spotHold = _Spot('hold', 0.22, 0.44, 0.16, 0.14, shape: _MarkShape.clasp, reachScale: 1.35);
const _spotShoulderL = _Spot('shoulderL', 0.34, 0.18, 0.11, 0.07, shape: _MarkShape.clasp, reachScale: 1.4);
const _spotShoulderR = _Spot('shoulderR', 0.55, 0.18, 0.11, 0.07, shape: _MarkShape.clasp, reachScale: 1.4);
const _spotHandReach = _Spot('handReach', 0.14, 0.42, 0.16, 0.10, shape: _MarkShape.openC, reachScale: 1.3);
const _spotLiftRing = _Spot('liftRing', 0.62, 0.32, 0.16, 0.09, shape: _MarkShape.openC, reachScale: 1.25);
const _spotLiftStrap = _Spot('liftStrap', 0.54, 0.48, 0.16, 0.09, shape: _MarkShape.openC, reachScale: 1.15);
const _spotLiftLeg = _Spot('liftLeg', 0.70, 0.62, 0.14, 0.10, shape: _MarkShape.openC, reachScale: 1.15);
const _spotNape = _Spot('nape', 0.45, 0.11, 0.10, 0.06, shape: _MarkShape.ring, reachScale: 1.4);
const _spotTuckFromL = _Spot('tuckFromL', 0.35, 0.64, 0.10, 0.08, shape: _MarkShape.openC, reachScale: 1.3);
const _spotTuckToL = _Spot('tuckToL', 0.355, 0.53, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: 1.3);
const _spotTuckFromR = _Spot('tuckFromR', 0.56, 0.64, 0.10, 0.08, shape: _MarkShape.openC, reachScale: 1.3);
const _spotTuckToR = _Spot('tuckToR', 0.56, 0.53, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: 1.3);
const _spotChestPull = _Spot('chestPull', 0.45, 0.35, 0.10, 0.06, shape: _MarkShape.openC, reachScale: 1.3);
const _spotChestGoal = _Spot('chestGoal', 0.45, 0.27, 0.10, 0.06, shape: _MarkShape.ring, reachScale: 1.3);
const _spotChestHigh = _Spot('chestHigh', 0.44, 0.24, 0.09, 0.05, mark: false, reachScale: 1.2);
const _spotChestHighShow = _Spot('chestPull', 0.44, 0.24, 0.10, 0.06, shape: _MarkShape.openC, reachScale: 1.3);
const _spotFitPullL = _Spot('fitPullL', 0.36, 0.72, 0.09, 0.08, shape: _MarkShape.openC, reachScale: 1.3);
const _spotFitGoalL = _Spot('fitGoalL', 0.36, 0.60, 0.09, 0.06, shape: _MarkShape.ring, reachScale: 1.3);
const _spotFitHighL = _Spot('fitHighL', 0.38, 0.52, 0.08, 0.05, mark: false, reachScale: 1.2);
const _spotFitHighShowL = _Spot('fitPullL', 0.38, 0.52, 0.09, 0.06, shape: _MarkShape.openC, reachScale: 1.3);
const _spotFitDoneL = _Spot('fitGoalL', 0.36, 0.60, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: 1.3);
const _spotFitPullR = _Spot('fitPullR', 0.56, 0.72, 0.09, 0.08, shape: _MarkShape.openC, reachScale: 1.3);
const _spotFitGoalR = _Spot('fitGoalR', 0.56, 0.60, 0.09, 0.06, shape: _MarkShape.ring, reachScale: 1.3);
const _spotFitHighR = _Spot('fitHighR', 0.54, 0.52, 0.08, 0.05, mark: false, reachScale: 1.2);
const _spotFitHighShowR = _Spot('fitPullR', 0.54, 0.52, 0.09, 0.06, shape: _MarkShape.openC, reachScale: 1.3);
const _spotFitDoneR = _Spot('fitGoalR', 0.56, 0.60, 0.09, 0.06, shape: _MarkShape.clasp, reachScale: 1.3);
const _gPalm = _Spot('gPalm', 0.22, 0.42, 0.18, 0.16, shape: _MarkShape.ring, reachScale: 1.55);
const _gShoulder = _Spot('gShoulder', 0.34, 0.15, 0.32, 0.11, shape: _MarkShape.ring, reachScale: 1.35);
const _gChest = _Spot('gChest', 0.38, 0.26, 0.24, 0.11, shape: _MarkShape.ring, reachScale: 1.4);
const _gThigh = _Spot('gThigh', 0.32, 0.56, 0.36, 0.14, shape: _MarkShape.ring, reachScale: 1.3);
const _gWaist = _Spot('gWaist', 0.34, 0.40, 0.32, 0.11, shape: _MarkShape.ring, reachScale: 1.4);
const _gTuck = _Spot('gTuck', 0.32, 0.60, 0.36, 0.14, shape: _MarkShape.ring, reachScale: 1.3);
const _gNape = _Spot('gNape', 0.38, 0.08, 0.24, 0.09, shape: _MarkShape.ring, reachScale: 1.45);
const _gFingers = _Spot('gFingers', 0.32, 0.56, 0.36, 0.14, shape: _MarkShape.ring, reachScale: 1.3);

class _GuideRow {
  const _GuideRow(this.title, this.figure, this.zone, this.pieceId, this.miss);
  final String title;
  final String figure;
  final String zone;
  final String pieceId;
  final String miss;
}

const _earlyStep = 'সাবধান! হারনেসের সুরক্ষায় ধারাবাহিকতা রক্ষা জরুরি। আগের ধাপটি আগে সম্পন্ন করুন।';
const _tapStep = 'তালিকার সঠিক ধাপটি নির্বাচন করে এগিয়ে চলুন।';

const _guideRows = <_GuideRow>[
  _GuideRow('রিং ধরুন', 'head_helmet', 'gPalm', 'harness', 'পিঠের রিং ধরে হাতের কাছে তুলুন।'),
  _GuideRow('কাঁধে দিন', 'pose_hold', 'gShoulder', 'harness', 'ফিতা দুই কাঁধে দিন।'),
  _GuideRow('বুক আটকান', 'pose_shoulder', 'gChest', 'harness', 'বুকের ফিতা বুকের বাকলে দিন।'),
  _GuideRow('পা বাঁধুন', 'pose_chest', 'gThigh', 'harness', 'পায়ের ফিতা উরুর বাকলে দিন।'),
  _GuideRow('কোমর আটকান', 'pose_leg', 'gWaist', 'harness', 'কোমরের ফিতা কোমরের বাকলে দিন।'),
  _GuideRow('ফিতা গুঁজুন', 'pose_waist', 'gTuck', 'harness', 'খোলা ফিতা লুপে গুঁজে দিন।'),
  _GuideRow('রিং চেক', 'pose_tuck', 'gNape', 'harness', 'পিঠে ডি রিংয়ের পজিশন চেক করুন।'),
  _GuideRow('দুই আঙুল', 'pose_nape', 'gFingers', 'fingers', 'দুই আঙুল উরুর ফিতায় দিন।'),
];

_Spot _guideSpot(String zone) {
  return switch (zone) {
    'gPalm' => _gPalm,
    'gShoulder' => _gShoulder,
    'gChest' => _gChest,
    'gThigh' => _gThigh,
    'gWaist' => _gWaist,
    'gTuck' => _gTuck,
    'gNape' => _gNape,
    _ => _gFingers,
  };
}
const _spotBelt = _Spot('belt', 0.36, 0.46, 0.28, 0.08);
const _spotLegs = _Spot('legs', 0.38, 0.63, 0.24, 0.22);
const _spotFeet = _Spot('feet', 0.33, 0.86, 0.34, 0.12);

class _OvalClip extends CustomClipper<Path> {
  const _OvalClip();

  @override
  Path getClip(Size size) => Path()..addOval(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SoftRingPainter extends CustomPainter {
  const _SoftRingPainter(this.pulse);

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = (Offset.zero & size).deflate(7);
    if (oval.width < 8 || oval.height < 8) return;
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0x55C9A227)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = Color.lerp(const Color(0xFFC9A227), const Color(0xFFFFF6D4), 0.25 + 0.35 * pulse)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftRingPainter oldDelegate) => oldDelegate.pulse != pulse;
}

class _DotRingPainter extends CustomPainter {
  const _DotRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width * 0.36;
    final ry = size.height * 0.36;
    if (rx <= 2 || ry <= 2) return;
    final c = Offset(size.width / 2, size.height / 2);
    final n = math.max(8, ((size.width + size.height) / 14).round());
    final gold = Paint()..color = const Color(0xFFC9A227);
    final cream = Paint()..color = const Color(0xFFFFF8EE);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / n;
      final p = Offset(c.dx + rx * math.cos(a), c.dy + ry * math.sin(a));
      canvas.drawCircle(p, 3.6, gold);
      canvas.drawCircle(p, 1.6, cream);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinkPainter extends CustomPainter {
  const _LinkPainter(this.from, this.to, this.t, this.bad);
  final Offset from;
  final Offset to;
  final double t;
  final bool bad;

  @override
  void paint(Canvas canvas, Size size) {
    final end = Offset.lerp(from, to, t.clamp(0, 1))!;
    final color = bad ? const Color(0xFFC62828) : const Color(0xFFC9A227);
    final shaft = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, end, shaft);
    canvas.drawCircle(from, 6, Paint()..color = color);
    canvas.drawCircle(end, 6, Paint()..color = color);
    canvas.drawCircle(from, 2.4, Paint()..color = const Color(0xFFFFF8EE));
    canvas.drawCircle(end, 2.4, Paint()..color = const Color(0xFFFFF8EE));
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => oldDelegate.from != from || oldDelegate.to != to || oldDelegate.t != t || oldDelegate.bad != bad;
}

class _JointPainter extends CustomPainter {
  const _JointPainter(this.shape, {this.hot = false, this.picked = false, this.spread = 1});
  final _MarkShape shape;
  final bool hot;
  final bool picked;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = const Color(0xFFC9A227);
    final cream = Paint()..color = const Color(0xFFFFF8EE);
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(picked ? 11.0 : 8.0, size.shortestSide * 0.28);
    if (r <= 1) return;
    void filled(Offset p, double radius) {
      canvas.drawCircle(p, radius, gold);
      canvas.drawCircle(p, radius * 0.38, cream);
    }

    void hollow(Offset p, double radius) {
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..color = const Color(0xFFC9A227)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }

    switch (shape) {
      case _MarkShape.openC:
        canvas.drawCircle(c, r, gold);
        if (!picked) canvas.drawCircle(c, r * 0.38, cream);
      case _MarkShape.clasp:
        filled(c, r * 0.92);
      case _MarkShape.ring:
        hollow(c, r);
        if (picked) canvas.drawCircle(c, r * 0.42, gold);
      case _MarkShape.pull:
        filled(c, r * 0.9);
      case _MarkShape.ticks:
        final loose = spread > 1.2;
        final tight = spread < 0.6;
        final goal = Offset(c.dx, size.height * 0.28);
        final strap = Offset(c.dx, size.height * (loose ? 0.74 : tight ? 0.16 : 0.28));
        if (loose || tight) hollow(goal, r * 0.85);
        canvas.drawCircle(strap, r, gold);
        canvas.drawCircle(strap, r * 0.38, cream);
      case _MarkShape.dots:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _JointPainter oldDelegate) => oldDelegate.shape != shape || oldDelegate.hot != hot || oldDelegate.picked != picked || oldDelegate.spread != spread;
}

/// Getting-ready lessons. Clothes, head, hands, harness, then the whole kit.
class _Cam {
  const _Cam(this.scale, this.align);
  final double scale;
  final Alignment align;

  static _Cam lerp(_Cam a, _Cam b, double t) {
    return _Cam(a.scale + (b.scale - a.scale) * t, Alignment.lerp(a.align, b.align, t)!);
  }

  @override
  bool operator ==(Object other) => other is _Cam && other.scale == scale && other.align == align;

  @override
  int get hashCode => Object.hash(scale, align);
}

class _CamTween extends Tween<_Cam> {
  _CamTween(_Cam end) : super(begin: const _Cam(1, Alignment.center), end: end);

  @override
  _Cam lerp(double t) => _Cam.lerp(begin ?? const _Cam(1, Alignment.center), end ?? const _Cam(1, Alignment.center), t);
}

enum _VanBeat { coach, yard }

enum _VanGate { dress, portrait, guide, tools }

enum _VanOutro { idle, list, pair, aboard, away, guide }

const _vanChecklist = <({String id, String label})>[
  (id: 'shirt', label: 'সুতির শার্ট'),
  (id: 'pant', label: 'সুতির প্যান্ট'),
  (id: 'boot', label: 'ডাইইলেকট্রিক বুট'),
  (id: 'helmet', label: 'ইলেকট্রিক্যাল হেলমেট'),
  (id: 'shield', label: 'ফেস শিল্ড'),
  (id: 'rubber', label: 'রাবার গ্লাভস'),
  (id: 'tester', label: 'ভোল্টেজ ডিটেক্টর'),
  (id: 'discharge', label: 'ডিসচার্জ রড'),
  (id: 'earth', label: 'পোর্টেবল আর্থিং কিট'),
];

class DsDressUp extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onDone;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, Offset global) onDelta;
  final VoidCallback? onBack;

  const DsDressUp({
    super.key,
    required this.engine,
    required this.onDone,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
    this.onBack,
  });

  @override
  State<DsDressUp> createState() => _DsDressUpState();
}

class _DsDressUpState extends State<DsDressUp> with TickerProviderStateMixin {
  late final AnimationController _sway;
  late final AnimationController _shake;
  final _on = <String>{};
  Timer? _markTimer;
  var _dragZone = '';
  var _finishing = false;
  var _glow = false;
  var _hero = false;
  _Mark? _mark;
  var _ask = false;
  var _left = _Gap.open;
  var _right = _Gap.open;
  var _fingerL = false;
  var _fingerR = false;
  var _chest = false;
  var _waistL = false;
  var _waistR = false;
  var _tugged = false;
  var _paidL = false;
  var _paidR = false;
  final _boardKey = GlobalKey();
  late final AnimationController _link;
  var _step = _HStep.gloves;
  var _fitReady = false;
  var _fitTight = false;
  var _pullLanded = false;
  var _parked = false;
  var _zoom = 1.0;
  var _zoomAt = Alignment.center;
  var _coachFace = DsCoachMood.talk;
  var _coachSay = '';
  Timer? _coachTimer;
  var _speakToken = 0;
  var _guide = 0;
  var _rowOk = false;
  var _rowBad = false;
  var _badRow = -1;
  late final AnimationController _rowFx;
  Offset? _linkFrom;
  Offset? _linkTo;
  var _linkBad = false;
  var _linking = false;
  var _chosen = '';
  final _shelfOrder = <String>[];
  var _checking = false;
  var _vanBoarded = false;
  var _vanBeat = _VanBeat.yard;
  var _vanGate = _VanGate.dress;
  var _guideShown = false;
  var _gateToken = 0;
  var _outro = _VanOutro.idle;
  var _checkShown = 0;
  var _coachOn = true;
  var _blameZone = '';
  var _roomToken = 0;
  var _landId = '';
  var _landToken = 0;
  var _frontId = '';
  var _frontWhy = '';
  var _tossAsset = '';
  var _tossFrom = Offset.zero;
  var _tossTo = Offset.zero;
  final _heldBack = <String>{};
  _Cam _cam = const _Cam(1, Alignment.center);
  final _roomKey = GlobalKey();
  final _benchPaneKey = GlobalKey();
  final _dressKey = GlobalKey();
  final _shelfKey = GlobalKey();
  final _pieceKeys = <String, GlobalKey>{};
  late final AnimationController _toss;
  late final AnimationController _ring;
  late final AnimationController _vanRide;
  late final AnimationController _vanDepart;

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
    _link = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _rowFx = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _toss = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _vanRide = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _vanDepart = AnimationController(vsync: this, duration: const Duration(milliseconds: 1560));
    if (_vanLesson) {
      _vanBeat = _VanBeat.coach;
      _coachOn = true;
    }
    if (_headLesson) _on.add('gamcha');
    if (_harnessLesson) _on.add('rubber');
    _mixShelf(sound: false);
    widget.engine.beginDress();
    ZlFx.holdClock();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    final hello = switch (widget.engine.level.number) {
      2 => 'লাইনম্যানের সবচেয়ে বড় সুরক্ষা তার হেলমেট। সঠিক সুরক্ষাকবচটি বেছে নিন।',
      3 => 'হাতে গ্লাভস পরার আগে ত্রুটি ও ইনসুলেশন যাচাই করে সঠিক সুরক্ষাকবচ বেছে নিন।',
      4 => 'উচ্চতায় ওঠায় হারনেসই শেষ ভরসা। গ্লাভস সরিয়ে হারনেস ধরুন এবং ধাপে ধাপে বাঁধুন।',
      5 => 'সব জিনিস টেনে ঠিক জায়গায় ছোঁয়ান।',
      6 => _roomStart,
      7 => _poleStart,
      8 => _dtrStart,
      9 => _nightStart,
      10 => _treeStart,
      _ => 'কাজে নামার আগে ঠিকঠাক পোশাক বেছে নিন—ঝুঁকি এড়িয়ে সঠিকটা পরান।',
    };
    _speakCoach(
      hello,
      mood: DsCoachMood.talk,
      buffer: const Duration(milliseconds: 1400),
      then: _vanLesson ? _leaveCoach : null,
    );
  }

  void _leaveCoach() {
    Future<void>.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted || _finishing) return;
      setState(() => _coachOn = false);
      await Future<void>.delayed(const Duration(milliseconds: 460));
      if (!mounted || _finishing) return;
      setState(() => _vanBeat = _VanBeat.yard);
      await Future<void>.delayed(const Duration(milliseconds: 620));
      if (mounted && !_finishing) _rollVan();
    });
  }

  @override
  void dispose() {
    _roomToken++;
    _gateToken++;
    _markTimer?.cancel();
    _sway.dispose();
    _shake.dispose();
    _link.dispose();
    _rowFx.dispose();
    _toss.dispose();
    _ring.dispose();
    _vanRide.dispose();
    _vanDepart.dispose();
    _coachTimer?.cancel();
    ZlFx.releaseClock();
    super.dispose();
  }

  bool get _headLesson => widget.engine.level.number == 2;

  bool get _handsLesson => widget.engine.level.number == 3;

  bool get _harnessLesson => widget.engine.level.number == 4;

  bool get _roomLesson => widget.engine.level.number >= 6 && widget.engine.level.number <= 10;

  bool get _vanLesson => widget.engine.level.number == 6;

  bool get _vanParked => _vanRide.status == AnimationStatus.completed;

  bool get _vanPortrait => _vanLesson && (_vanGate == _VanGate.portrait || _vanGate == _VanGate.guide);

  String get _vanLook {
    final shirt = _on.contains('shirt');
    final pant = _on.contains('pant');
    final boot = _on.contains('boot');
    final helmet = _on.contains('helmet');
    final gloves = _on.contains('rubber');
    if (shirt && pant && boot && helmet) return 'head_helmet';
    if (gloves && shirt && pant && boot) return 'gloves_all';
    if (gloves && shirt && pant) return 'gloves_shirt_pant';
    if (gloves && shirt && boot) return 'gloves_shirt_boot';
    if (gloves && pant && boot) return 'gloves_pant_boot';
    if (gloves && shirt) return 'gloves_shirt';
    if (gloves && pant) return 'gloves_pant';
    if (gloves && boot) return 'gloves_boot';
    if (shirt && pant && boot) return 'all';
    if (shirt && pant) return 'shirt_pant';
    if (pant && boot) return 'pant_boot';
    if (shirt && boot) return 'shirt_boot';
    if (gloves) return 'gloves_body';
    if (shirt) return 'shirt';
    if (pant) return 'pant';
    if (boot) return 'boot';
    return 'body';
  }

  bool get _poleLesson => widget.engine.level.number == 7;

  bool get _dtrLesson => widget.engine.level.number == 8;

  bool get _nightLesson => widget.engine.level.number == 9;

  bool get _treeLesson => widget.engine.level.number == 10;

  String get _benchScene => switch (widget.engine.level.number) {
        7 => 'assets/zero_loss/scene/bg_market_wire_down.webp',
        8 => 'assets/zero_loss/scene/bg_dtr_structure.webp',
        9 => 'assets/zero_loss/scene/bg_pole_storm.webp',
        10 => 'assets/zero_loss/scene/bg_tree_on_line.webp',
        _ => 'assets/zero_loss/scene/bg_control_room.webp',
      };

  String get _benchDone => switch (widget.engine.level.number) {
        7 => _poleDone,
        8 => _dtrDone,
        9 => _nightDone,
        10 => _treeDone,
        _ => _roomDone,
      };

  bool _tallPiece(String id) => id == 'frp' || id == 'bamboo' || id == 'discharge' || id == 'tester' || id == 'torch' || id == 'sickle' || id == 'saw';

  bool get _showFingers => _harnessLesson && (_step == _HStep.fitL || _step == _HStep.fitR);

  bool get _beside => _parked && (_step == _HStep.gloves || _step == _HStep.lift);

  List<_Piece> get _harnessKit {
    final kit = <_Piece>[_harnessPieces[0], _harnessPieces[1]];
    if (_guide == 0) kit.add(_harnessPieces[2]);
    return kit;
  }

  bool get _legsBuckled => _left != _Gap.open && _right != _Gap.open;

  bool get _canTug => _chest && _waistL && _waistR && _fingerL && _fingerR && _legsBuckled && !_tugged;

  bool get _fullLesson => widget.engine.level.number == 5;

  List<_Piece> get _kit => switch (widget.engine.level.number) {
        2 => _headPieces,
        3 => _handPieces,
        4 => _harnessKit,
        5 => _fullKit,
        6 => [..._fullKit, ..._vanToolPieces],
        7 => _poleKit,
        8 => _dtrKit,
        9 => _nightKit,
        10 => _treeKit,
        _ => _pieces,
      };

  List<_Piece> get _fullKit {
    final byId = <String, _Piece>{};
    for (final p in [..._pieces, ..._headPieces, ..._handPieces, ..._harnessPieces]) {
      byId[p.id] = p;
    }
    return [
      for (final id in _fullOrder)
        if (id == 'shield')
          _shieldPiece
        else if (id == 'harness')
          _Piece(id: 'harness', asset: byId['harness']!.asset, zone: 'harness', good: true, why: '')
        else
          byId[id]!,
    ];
  }

  List<_Piece> get _poleKit => [..._fullKit, _frpPiece, _bambooPiece];

  List<_Piece> get _dtrKit => [..._fullKit, _testerPiece, _dischargePiece, _earthPiece, _wirePiece, _clothPiece];

  List<_Piece> get _nightKit => [..._fullKit, _vestPiece, _torchPiece, _frpPiece, _bambooPiece];

  List<_Piece> get _treeKit => [..._fullKit, _testerPiece, _dischargePiece, _ropePiece, _sicklePiece, _sawPiece];

  bool get _ready => switch (widget.engine.level.number) {
        2 => _on.contains('helmet') && !_on.contains('gamcha'),
        3 => _on.contains('rubber'),
        4 => _tugged && _on.contains('harness') && !_on.contains('rubber'),
        5 => _on.contains('shirt') &&
            _on.contains('pant') &&
            _on.contains('boot') &&
            _on.contains('harness') &&
            _on.contains('helmet') &&
            _on.contains('shield') &&
            _on.contains('rubber') &&
            !_on.contains('gamcha'),
        6 => _roomKeep.every(_on.contains) && _on.length == _roomKeep.length,
        7 => _poleKeep.every(_on.contains),
        8 => _dtrKeep.every(_on.contains),
        9 => _nightKeep.every(_on.contains),
        10 => _treeKeep.every(_on.contains),
        _ => _on.contains('shirt') && _on.contains('pant') && _on.contains('boot'),
      };

  _Piece? _byId(String id) {
    for (final p in _kit) {
      if (p.id == id) return p;
    }
    return null;
  }

  _Piece? _worn(String zone) {
    _Piece? found;
    for (final id in _on) {
      final p = _byId(id);
      if (p != null && p.zone == zone) found = p;
    }
    return found;
  }

  String get _harnessFigure {
    if (_guide >= _guideRows.length) return 'pose_fingers';
    if (_guide == 0 && _on.contains('rubber')) return 'hands_gloves';
    return _guideRows[_guide].figure;
  }

  String get _figure {
    if (_roomLesson) return 'body';
    if (_fullLesson) return _fullFigure;
    if (_harnessLesson) return _harnessFigure;
    if (_handsLesson) return _on.contains('rubber') ? 'hands_gloves' : 'head_helmet';
    if (_headLesson) {
      if (_on.contains('helmet')) return 'head_helmet';
      if (_on.contains('gamcha')) return 'head_gamcha';
      return 'all';
    }
    final shirt = _on.contains('shirt');
    final pant = _on.contains('pant');
    final boot = _on.contains('boot');
    if (shirt && pant && boot) return 'all';
    if (shirt && pant) return 'shirt_pant';
    if (pant && boot) return 'pant_boot';
    if (shirt && boot) return 'shirt_boot';
    if (shirt) return 'shirt';
    if (pant) return 'pant';
    if (boot) return 'boot';
    return 'body';
  }

  String get _fullFigure {
    final shirt = _on.contains('shirt');
    final pant = _on.contains('pant');
    final boot = _on.contains('boot');
    final harness = _on.contains('harness');
    final helmet = _on.contains('helmet');
    final shield = _on.contains('shield');
    final gloves = _on.contains('rubber');
    final gamcha = _on.contains('gamcha');
    if (shield && helmet && harness && shirt && pant && boot) return gloves ? 'kit_ready' : 'kit_shield';
    if (helmet && harness && shirt && pant && boot) return gloves ? 'kit_helmet_gloves' : 'body_harness';
    if (harness && shirt && pant && boot) return gloves ? 'kit_harness_gloves' : 'kit_harness';
    if (gloves && helmet && shirt && pant && boot) return 'hands_gloves';
    if (gloves) {
      if (shirt && pant && boot && gamcha) return 'gloves_gamcha';
      if (shirt && pant && boot) return 'gloves_all';
      if (shirt && pant) return 'gloves_shirt_pant';
      if (pant && boot) return 'gloves_pant_boot';
      if (shirt && boot) return 'gloves_shirt_boot';
      if (shirt) return 'gloves_shirt';
      if (pant) return 'gloves_pant';
      if (boot) return 'gloves_boot';
      return 'gloves_body';
    }
    if (shirt && pant && boot && helmet) return 'head_helmet';
    if (shirt && pant && boot && gamcha) return 'head_gamcha';
    if (shirt && pant && boot) return 'all';
    if (shirt && pant) return 'shirt_pant';
    if (pant && boot) return 'pant_boot';
    if (shirt && boot) return 'shirt_boot';
    if (shirt) return 'shirt';
    if (pant) return 'pant';
    if (boot) return 'boot';
    return 'body';
  }

  void _clearMark() {
    _markTimer?.cancel();
    _coachTimer?.cancel();
    _mark = null;
    _ask = false;
    if (!_finishing) _coachFace = DsCoachMood.ready;
  }

  void _holdCoach(Duration hold) {
    _coachTimer?.cancel();
    _coachTimer = Timer(hold, () {
      if (!mounted || _finishing || _checking || _mark != null) return;
      setState(() => _coachFace = DsCoachMood.ready);
    });
  }

  void _speakCoach(
    String line, {
    DsCoachMood mood = DsCoachMood.talk,
    Duration buffer = const Duration(milliseconds: 1000),
    VoidCallback? then,
  }) {
    _coachTimer?.cancel();
    _markTimer?.cancel();
    _mark = null;
    _ask = false;
    _coachFace = mood;
    _coachSay = line;
    final token = ++_speakToken;
    setState(() {});
    widget.onSpeak(line).whenComplete(() {
      if (!mounted || token != _speakToken || _finishing) return;
      then?.call();
      _holdCoach(buffer);
    });
  }

  void _rollVan() {
    if (!mounted || _vanRide.isAnimating || _vanRide.isCompleted) return;
    unawaited(ZlFx.cue('sounds/van_arrive.wav', volume: 0.62, muted: widget.muted));
    _vanRide.forward().whenComplete(() {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {});
    });
  }

  void _showCoach(DsCoachMood mood, String line, Duration hold) {
    _coachTimer?.cancel();
    setState(() {
      _coachFace = mood;
      _coachSay = line;
    });
    if (mood != DsCoachMood.ready && !_finishing) _holdCoach(hold);
  }

  bool get _vanDressed {
    if (!_roomDress.every(_on.contains)) return false;
    for (final id in _on) {
      if (_roomDress.contains(id) || _vanToolIds.contains(id)) continue;
      return false;
    }
    return true;
  }

  bool _shelfShows(String id) {
    if (!_vanLesson) return true;
    final tool = _vanToolIds.contains(id);
    return _vanGate == _VanGate.tools ? tool : !tool;
  }

  Future<void> _revealTools() async {
    if (!_vanLesson || _finishing || _vanGate != _VanGate.dress || !_vanDressed) return;
    final token = ++_gateToken;
    _speakToken++;
    _coachTimer?.cancel();
    _markTimer?.cancel();
    setState(() {
      _vanGate = _VanGate.portrait;
      _checking = true;
      _guideShown = false;
      _mark = null;
      _ask = false;
      _frontId = '';
      _frontWhy = '';
      _coachFace = DsCoachMood.ready;
      _coachSay = '';
    });
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.32, muted: widget.muted));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || token != _gateToken || _finishing) return;
    await Future<void>.delayed(const Duration(milliseconds: 680));
    if (!mounted || token != _gateToken || _finishing) return;
    setState(() {
      _vanGate = _VanGate.guide;
      _guideShown = true;
      _coachFace = DsCoachMood.talk;
      _coachSay = _vanInsist;
    });
    HapticFeedback.selectionClick();
    final voice = widget.onSpeak(_vanInsist);
    final hold = Future<void>.delayed(const Duration(milliseconds: 2400));
    try {
      await Future.wait([voice, hold]);
    } catch (_) {}
    if (!mounted || token != _gateToken || _finishing) return;
    setState(() {
      _guideShown = false;
      _coachFace = DsCoachMood.ready;
      _coachSay = '';
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || token != _gateToken || _finishing) return;
    setState(() {
      _vanGate = _VanGate.tools;
      _checking = false;
      _mixShelf(sound: true);
    });
  }

  String _vanToolGap() {
    final missingTester = !_on.contains('tester');
    final missingDischarge = !_on.contains('discharge');
    final missingEarth = !_on.contains('earth');
    final count = (missingTester ? 1 : 0) + (missingDischarge ? 1 : 0) + (missingEarth ? 1 : 0);
    if (count == 3) return _vanInsist;
    if (count == 1) {
      if (missingTester) return _vanNoTester;
      if (missingDischarge) return _vanNoDischarge;
      return _vanNoEarth;
    }
    if (count == 0) return _roomMiss;
    final bits = <String>[
      if (missingTester) 'ভোল্টেজ ডিটেক্টর',
      if (missingDischarge) 'ডিসচার্জ রড',
      if (missingEarth) 'পোর্টেবল আর্থিং কিট',
    ];
    return 'এখনও বাকি: ${bits.join(', ')}। এগুলো ছাড়া ভ্যানে উঠবেন না।';
  }

  void _mixShelf({required bool sound}) {
    final ids = [for (final piece in _kit) if (!_on.contains(piece.id) && _shelfShows(piece.id)) piece.id];
    if (ids.isEmpty) return;
    final before = ids.join('|');
    ids.shuffle(math.Random());
    if (ids.length > 1 && ids.join('|') == before) {
      ids.add(ids.removeAt(0));
    }
    _shelfOrder
      ..clear()
      ..addAll(ids);
    if (sound) unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', volume: 0.4, muted: widget.muted));
  }

  void _fail(String zone, String why, _Piece piece, Offset global) {
    widget.engine.dressWrong();
    widget.onDelta(-5, global);
    _shake.forward(from: 0);
    _mixShelf(sound: true);
    unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: widget.muted));
    HapticFeedback.heavyImpact();

    _coachTimer?.cancel();
    _markTimer?.cancel();
    _mark = _Mark(zone, why, piece.asset);
    _ask = false;
    _coachFace = DsCoachMood.oops;
    _coachSay = why;
    final token = ++_speakToken;
    setState(() {});

    widget.onSpeak(why).whenComplete(() {
      if (!mounted || token != _speakToken || _ask) return;
      _markTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted || token != _speakToken || _ask) return;
        setState(_clearMark);
      });
    });
  }

  bool _wearOrder(_Piece piece, Offset global) {
    if (piece.id == 'shirt' && _on.contains('rubber')) {
      _fail('torso', _sleeveBlock, piece, global);
      return false;
    }
    if (piece.id == 'boot' && _on.contains('rubber')) {
      _fail('feet', _laceBlock, piece, global);
      return false;
    }
    if (piece.id == 'harness') {
      if (!_on.contains('shirt') || !_on.contains('pant')) {
        _fail('harness', _harnessClothes, piece, global);
        return false;
      }
      if (!_on.contains('boot')) {
        _fail('harness', _harnessBoot, piece, global);
        return false;
      }
    }
    if (piece.id == 'helmet' && !_on.contains('harness')) {
      _fail('head', _helmetHarness, piece, global);
      return false;
    }
    if (piece.id == 'shield' && !_on.contains('helmet')) {
      _fail('head', _shieldBlock, piece, global);
      return false;
    }
    return true;
  }

  void _point(Offset global) {
    widget.engine.dressRight();
    widget.onDelta(5, global);
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: widget.muted));
    final okSay = switch (widget.engine.level.number) {
      1 || 2 || 3 || 4 => switch (math.Random().nextInt(4)) {
          0 => 'বাহবা! একদম ঠিক।',
          1 => 'বাঃ, একদম মানানসই!',
          2 => 'সঠিক নির্বাচন, এগিয়ে চলুন।',
          _ => 'চমৎকার! এটা ঠিক বসেছে।',
        },
      _ => 'ঠিক আছে।',
    };
    if (!_finishing) {
      _speakCoach(okSay, mood: DsCoachMood.glad, buffer: const Duration(milliseconds: 800));
    }
  }

  Future<void> _doneLesson(String line) async {
    if (_finishing) return;
    _coachTimer?.cancel();
    _markTimer?.cancel();
    setState(() {
      _finishing = true;
      _glow = true;
      _hero = false;
      _mark = null;
      _ask = false;
      _coachFace = DsCoachMood.ready;
      _coachSay = line;
    });
    unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _glow = false;
      _hero = true;
      _coachFace = DsCoachMood.thanks;
    });
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.62, muted: widget.muted));
    HapticFeedback.lightImpact();
    final voice = widget.onSpeak(line);
    final hold = Future<void>.delayed(const Duration(milliseconds: 2400));
    await Future.wait([voice, hold]);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) widget.onDone();
  }

  Future<void> _doneVan() async {
    if (_finishing) return;
    _coachTimer?.cancel();
    _markTimer?.cancel();
    setState(() {
      _finishing = true;
      _glow = false;
      _hero = false;
      _vanBoarded = false;
      _mark = null;
      _ask = false;
      _coachFace = DsCoachMood.ready;
      _coachSay = '';
      _outro = _VanOutro.list;
      _checkShown = 0;
    });
    unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.45, muted: widget.muted));
    HapticFeedback.mediumImpact();
    for (var i = 0; i < _vanChecklist.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() => _checkShown = i + 1);
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.38, muted: widget.muted));
      HapticFeedback.selectionClick();
    }
    await Future<void>.delayed(const Duration(milliseconds: 820));
    if (!mounted) return;
    setState(() => _outro = _VanOutro.pair);
    await Future<void>.delayed(const Duration(milliseconds: 980));
    if (!mounted) return;
    setState(() {
      _outro = _VanOutro.aboard;
      _vanBoarded = true;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: widget.muted));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    setState(() => _outro = _VanOutro.away);
    unawaited(ZlFx.cue('sounds/van_arrive.wav', volume: 0.4, muted: widget.muted));
    await _vanDepart.forward(from: 0);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _outro = _VanOutro.guide;
      _hero = true;
      _coachFace = DsCoachMood.thanks;
      _coachSay = _roomDone;
    });
    unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: widget.muted));
    HapticFeedback.lightImpact();
    final voice = widget.onSpeak(_roomDone);
    final hold = Future<void>.delayed(const Duration(milliseconds: 2600));
    await Future.wait([voice, hold]);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) widget.onDone();
  }

  void _advance(Offset global) {
    final next = _HStep.values[_step.index + 1];
    setState(() {
      _step = next;
      _fitReady = false;
      _fitTight = false;
      _clearMark();
    });
    _point(global);
    final say = switch (next) {
      _HStep.shoulderL => 'রিং ধরে তুলেছেন। এবার কাঁধে দিন।',
      _HStep.chest => _shouldersOn,
      _HStep.legR => _legBuckle,
      _HStep.fitL => _napeReach,
      _HStep.fitR => _twoFingers,
      _ => null,
    };
    if (say != null) unawaited(widget.onSpeak(say));
    if (next == _HStep.done) _doneLesson(_doneMove);
  }

  void _landFit(String zone, _Piece piece, Offset global) {
    final left = _step == _HStep.fitL;
    final goal = left ? 'fitGoalL' : 'fitGoalR';
    final high = left ? 'fitHighL' : 'fitHighR';
    if (zone == high) {
      setState(() {
        _fitTight = true;
        _fitReady = false;
      });
      _fail(goal, _tightFingers, piece, global);
      return;
    }
    if (zone != goal) return;
    setState(() {
      _fitReady = true;
      _fitTight = false;
      _clearMark();
    });
    _point(global);
  }

  void _onPull(_Piece piece, String zone, Offset global) {
    _pullLanded = true;
    if (_beside) {
      if (_on.contains('rubber')) {
        _fail('hands', _gloveBlock, piece, global);
        return;
      }
      if (piece.id != 'pullRing' || zone != 'hold') {
        _fail('liftRing', _holdRing, piece, global);
        return;
      }
      _advance(global);
      return;
    }
    switch (_step) {
      case _HStep.lift:
        if (piece.id == 'pullStrap') {
          _fail('liftRing', _holdRing, piece, global);
          return;
        }
        if (zone == 'hold') _advance(global);
      case _HStep.shoulderL:
        if (zone == 'shoulderR') {
          _fail('shoulderL', _leftShoulder, piece, global);
          return;
        }
        if (zone == 'shoulderL') _advance(global);
      case _HStep.shoulderR:
        if (zone == 'shoulderL') {
          _fail('shoulderR', _otherShoulder, piece, global);
          return;
        }
        if (zone == 'shoulderR') _advance(global);
      case _HStep.chest:
        if (zone == 'ring') _advance(global);
      case _HStep.chestFit:
        if (zone == 'chestHigh') {
          setState(() => _fitTight = true);
          _fail('chestGoal', _tightFingers, piece, global);
          return;
        }
        if (zone == 'chestGoal') _advance(global);
      case _HStep.legL:
        if (zone == 'buckleL') _advance(global);
      case _HStep.legR:
        if (zone == 'buckleR') _advance(global);
      case _HStep.waistL:
        if (zone == 'buckleWaistL') _advance(global);
      case _HStep.waistR:
        if (zone == 'buckleWaistR') _advance(global);
      case _HStep.tuckL:
        if (zone == 'tuckToL') {
          _advance(global);
        } else {
          _fail(zone, _tuckTail, piece, global);
        }
      case _HStep.tuckR:
        if (zone == 'tuckToR') {
          _advance(global);
        } else {
          _fail(zone, _tuckTail, piece, global);
        }
      case _HStep.nape:
        if (zone == 'nape') _advance(global);
      case _HStep.fitL:
      case _HStep.fitR:
        _landFit(zone, piece, global);
      case _HStep.gloves:
      case _HStep.done:
        break;
    }
  }

  void _onFingers(String zone, Offset global) {
    final left = zone == 'fitGoalL';
    if (left && _step != _HStep.fitL) return;
    if (!left && _step != _HStep.fitR) return;
    if (_fitTight) {
      _fail(zone, _tightFingers, _fingersPiece, global);
      return;
    }
    if (!_fitReady) {
      _fail(zone, _looseFingers, _fingersPiece, global);
      return;
    }
    setState(() {
      if (left) {
        _fingerL = true;
      } else {
        _fingerR = true;
      }
    });
    _advance(global);
  }

  void _dropOn(_Spot spot, _Piece piece, Offset global) {
    if (_harnessLesson) {
      _guideDrop(spot, piece, global);
      return;
    }
    if (_harnessLesson && piece.id.startsWith('pull')) {
      _onPull(piece, spot.zone, global);
      return;
    }
    if (_harnessLesson && piece.id == 'fingers') {
      _onFingers(spot.zone, global);
      return;
    }
    if (piece.id.startsWith('end')) {
      _endDrop(piece.id, spot.zone, global);
      return;
    }
    if (piece.id == 'fingers') {
      _fingerTest(spot.zone, global);
      return;
    }
    _wear(piece, global);
  }

  _Piece _endPiece(String id) => switch (id) {
        'endL' => _endL,
        'endR' => _endR,
        'endWaistL' => _endWaistL,
        'endWaistR' => _endWaistR,
        _ => _endChest,
      };

  void _endDrop(String id, String zone, Offset global) {
    if (id == 'endL' || id == 'endR') {
      _legDrop(id == 'endL', zone, _endPiece(id), global);
      return;
    }
    if (id == 'endWaistL' || id == 'endWaistR') {
      _waistDrop(id == 'endWaistL', zone, _endPiece(id), global);
      return;
    }
    _ringDrop(zone, global);
  }

  void _legDrop(bool left, String zone, _Piece piece, Offset global) {
    final open = (left ? _left : _right) == _Gap.open;
    final passed = left ? _fingerL : _fingerR;
    if (zone == 'ring') {
      _fail('ring', _legOnRing, piece, global);
      return;
    }
    if (zone == 'buckleWaistL' || zone == 'buckleWaistR') {
      _fail(zone, _thighOnWaist, piece, global);
      return;
    }
    if (zone == (left ? 'buckleR' : 'buckleL')) {
      _fail(zone, _wrongLeg, piece, global);
      return;
    }
    if (zone == 'buckleL' || zone == 'buckleR') {
      if (!open || zone != (left ? 'buckleL' : 'buckleR')) return;
      setState(() {
        if (left) {
          _left = _Gap.loose;
        } else {
          _right = _Gap.loose;
        }
        _clearMark();
      });
      _point(global);
      return;
    }
    if (open) {
      _fail(left ? 'buckleL' : 'buckleR', _buckleFirst, piece, global);
      return;
    }
    if (passed) return;
    final mine = left ? (zone == 'gapL' || zone == 'tightL') : (zone == 'gapR' || zone == 'tightR');
    if (!mine) {
      _fail(zone, _wrongLeg, piece, global);
      return;
    }
    final tight = zone.startsWith('tight');
    final paid = left ? _paidL : _paidR;
    setState(() {
      if (left) {
        _left = tight ? _Gap.tight : _Gap.snug;
        if (!tight) _paidL = true;
      } else {
        _right = tight ? _Gap.tight : _Gap.snug;
        if (!tight) _paidR = true;
      }
      _clearMark();
    });
    if (!tight && !paid) _point(global);
  }

  void _waistDrop(bool left, String zone, _Piece piece, Offset global) {
    if (left ? _waistL : _waistR) return;
    if (zone == 'ring') {
      _fail('ring', _waistOnRing, piece, global);
      return;
    }
    if (zone == 'buckleL' || zone == 'buckleR') {
      _fail(zone, _waistOnThigh, piece, global);
      return;
    }
    if (zone == (left ? 'buckleWaistR' : 'buckleWaistL')) {
      _fail(zone, _wrongWaist, piece, global);
      return;
    }
    if (zone != (left ? 'buckleWaistL' : 'buckleWaistR')) return;
    setState(() {
      if (left) {
        _waistL = true;
      } else {
        _waistR = true;
      }
      _clearMark();
    });
    _point(global);
  }

  void _ringDrop(String zone, Offset global) {
    if (zone == 'buckleL' || zone == 'buckleR' || zone == 'buckleWaistL' || zone == 'buckleWaistR') {
      _fail(zone, _chestOnBuckle, _endChest, global);
      return;
    }
    if (zone == 'ring') {
      if (!_legsBuckled) {
        _fail('ring', _legsFirst, _endChest, global);
        return;
      }
      if (_chest) return;
      setState(() {
        _chest = true;
        _clearMark();
      });
      _point(global);
      return;
    }
    if (zone != 'tug') return;
    if (!_chest || !_waistL || !_waistR || !_legsBuckled) {
      _fail('ring', _tugEarly, _endChest, global);
      return;
    }
    if (!_fingerL || !_fingerR) {
      _fail('gapL', _fingersFirst, _fingersPiece, global);
      return;
    }
    if (_tugged) return;
    setState(() {
      _tugged = true;
      _clearMark();
    });
    _point(global);
    _doneLesson(_tugHeld);
  }

  void _fingerTest(String zone, Offset global) {
    final left = zone == 'gapL';
    final gap = left ? _left : _right;
    if (gap == _Gap.open) {
      _fail(left ? 'buckleL' : 'buckleR', _buckleFirst, _fingersPiece, global);
      return;
    }
    if ((left && _fingerL) || (!left && _fingerR)) return;
    if (gap == _Gap.loose) {
      _fail(zone, _looseFingers, _fingersPiece, global);
      return;
    }
    if (gap == _Gap.tight) {
      _fail(zone, _tightFingers, _fingersPiece, global);
      return;
    }
    if (gap != _Gap.snug) return;
    setState(() {
      if (left) {
        _fingerL = true;
      } else {
        _fingerR = true;
      }
      _clearMark();
    });
    _point(global);
    unawaited(widget.onSpeak(_twoFingers));
  }

  void _parkHarness(Offset global) {
    if (_parked || _finishing) return;
    final glovesOn = _on.contains('rubber');
    setState(() {
      _parked = true;
      _clearMark();
      if (!glovesOn) _step = _HStep.lift;
    });
    _point(global);
    _speakCoach(glovesOn ? 'হারনেস সামনে আছে। আগে গ্লাভস খুলুন।' : 'পিঠের রিং ধরে হাতের কাছে তুলুন।', mood: DsCoachMood.talk);
  }

  void _guideDrop(_Spot spot, _Piece piece, Offset global) {
    if (_finishing || _rowOk || _guide >= _guideRows.length) return;
    if (piece.id == 'rubber' || (_on.contains('rubber') && piece.id == 'harness')) {
      _failGuide(_guide, 'hands', _gloveBlock, piece, global);
      return;
    }
    if (!piece.good) {
      _failGuide(_guide, spot.zone, piece.why, piece, global);
      return;
    }
    if (_guide == 0 && piece.id == 'harness' && spot.zone == 'gPalm') {
      _passGuide(global);
      return;
    }
    _failGuide(_guide, spot.zone, _guide == 0 ? _guideRows[0].miss : _tapStep, piece, global);
  }

  void _tapGuide(int i, Offset global) {
    if (_finishing || _rowOk || i <= 0 || i < _guide || _guide >= _guideRows.length) return;
    if (i > _guide) {
      _failGuide(i, 'torso', _earlyStep, _harnessPieces[2], global);
      return;
    }
    if (_on.contains('rubber')) {
      _failGuide(i, 'hands', _gloveBlock, _harnessPieces[0], global);
      return;
    }
    _passGuide(global);
  }

  void _passGuide(Offset global) {
    setState(() {
      _rowOk = true;
      _rowBad = false;
      _clearMark();
    });
    _point(global);
    _rowFx.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      final next = _guide + 1;
      setState(() {
        _guide = next;
        _rowOk = false;
      });
      if (next == 6) {
        const ring = 'পিঠের ডি-রিং যেন কাঁধের ব্লেডের ঠিক মাঝখানে থাকে, অবস্থান যাচাই করুন।';
        _speakCoach(ring, mood: DsCoachMood.talk, buffer: const Duration(milliseconds: 1400));
      }
      if (next >= _guideRows.length) _doneLesson('হারনেসের সমস্ত বাকল যথাযথ লক হয়েছে এবং দুই আঙুলের ছাড় ঠিক আছে। উচ্চতায় কাজের সুরক্ষা নিশ্চিত।');
    });
  }

  void _failGuide(int row, String zone, String why, _Piece piece, Offset global) {
    _fail(zone, why, piece, global);
    setState(() {
      _badRow = row;
      _rowBad = true;
      _rowOk = false;
    });
    _rowFx.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _rowBad = false;
          _badRow = -1;
        });
      }
    });
  }

  String _roomFamily(String id) => switch (id) {
        'fatua' || 'halftee' || 'poly' || 'shirt' => 'cloth',
        'halfpant' || 'pajama' || 'pant' => 'legs',
        'slip' || 'normal' || 'boot' => 'feet',
        'road' || 'vent' || 'helmet' => 'helm',
        'cotton' || 'wet' || 'hole' || 'bike' || 'rubber' => 'gloves',
        'frp' || 'bamboo' => 'ladder',
        _ => id,
      };

  List<_Piece> get _benchPieces {
    final out = <_Piece>[];
    for (final id in _benchOrder) {
      if (!_on.contains(id)) continue;
      final piece = _byId(id);
      if (piece != null) out.add(piece);
    }
    return out;
  }

  GlobalKey _pieceKey(String id) => _pieceKeys.putIfAbsent(id, GlobalKey.new);

  RenderBox? _boxOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box;
  }

  RenderBox? _zoneBox(String zone) {
    if (zone != 'bench') {
      final piece = _boxOf(_pieceKey(zone));
      if (piece != null) return piece;
    }
    return _boxOf(_benchPaneKey);
  }

  _Cam _camFor(String zone, {required double scale}) {
    final stage = _boxOf(_roomKey);
    final target = _zoneBox(zone);
    if (stage == null || target == null) return _Cam(scale, Alignment.bottomCenter);
    final p = stage.globalToLocal(target.localToGlobal(target.size.center(Offset.zero)));
    final ax = ((p.dx / stage.size.width) * 2 - 1).clamp(-0.85, 0.85);
    final ay = ((p.dy / stage.size.height) * 2 - 1).clamp(-0.85, 0.85);
    return _Cam(scale, Alignment(ax.toDouble(), ay.toDouble()));
  }

  Offset _flyFrom(String zone) {
    final box = _zoneBox(zone);
    if (box == null) {
      final size = MediaQuery.sizeOf(context);
      return Offset(size.width / 2, size.height * 0.62);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _wearRoom(_Piece piece) {
    final family = _roomFamily(piece.id);
    final token = ++_landToken;
    setState(() {
      _on.removeWhere((id) => _roomFamily(id) == family);
      _on.add(piece.id);
      _landId = piece.id;
    });
    HapticFeedback.lightImpact();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted || token != _landToken) return;
      setState(() => _landId = '');
    });
  }

  List<({String zone, String why})> _roomFaults() {
    if (_poleLesson) return _poleFaults();
    if (_dtrLesson) return _dtrFaults();
    if (_nightLesson) return _nightFaults();
    if (_treeLesson) return _treeFaults();
    final out = <({String zone, String why})>[];
    void add(String zone, String why) => out.add((zone: zone, why: why));
    String whyOf(String id) => _byId(id)?.why ?? '';

    if (_on.contains('gamcha')) add('gamcha', _gamchaNoSave);
    if (_on.contains('road')) {
      add('road', whyOf('road'));
    } else if (_on.contains('vent')) {
      add('vent', whyOf('vent'));
    } else if (!_on.contains('helmet')) {
      add('bench', _roomNoHelmet);
    }
    if (!_on.contains('shield')) add('bench', _roomNoShield);

    if (_on.contains('fatua')) {
      add('fatua', _roomFatua);
    } else if (_on.contains('halftee')) {
      add('halftee', whyOf('halftee'));
    } else if (_on.contains('poly')) {
      add('poly', whyOf('poly'));
    } else if (!_on.contains('shirt')) {
      add('bench', _roomNoShirt);
    }

    if (_on.contains('pajama')) {
      add('pajama', whyOf('pajama'));
    } else if (_on.contains('halfpant')) {
      add('halfpant', _roomBareLeg);
    } else if (!_on.contains('pant')) {
      add('bench', _roomBareLeg);
    }

    if (_on.contains('cotton')) {
      add('cotton', whyOf('cotton'));
    } else if (_on.contains('wet')) {
      add('wet', whyOf('wet'));
    } else if (_on.contains('hole')) {
      add('hole', whyOf('hole'));
    } else if (_on.contains('bike')) {
      add('bike', whyOf('bike'));
    } else if (!_on.contains('rubber')) {
      add('bench', _roomNoGlove);
    }

    if (_on.contains('slip')) {
      add('slip', _roomSlip);
    } else if (_on.contains('normal')) {
      add('normal', whyOf('normal'));
    } else if (!_on.contains('boot')) {
      add('bench', _roomNoBoot);
    }

    if (_on.contains('harness')) add('harness', _roomHarness);
    if (_on.contains('belt')) add('belt', _roomBelt);
    for (final trap in _vanTraps) {
      if (_on.contains(trap.id)) add(trap.id, trap.why);
    }
    return out;
  }

  List<({String zone, String why})> _poleFaults() {
    final out = <({String zone, String why})>[];
    void add(String zone, String why) => out.add((zone: zone, why: why));

    if (_on.contains('gamcha')) add('gamcha', _poleGamcha);
    if (_on.contains('road')) {
      add('road', _poleRoad);
    } else if (_on.contains('vent')) {
      add('vent', _poleVent);
    } else if (!_on.contains('helmet')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('fatua')) {
      add('fatua', _poleFatua);
    } else if (_on.contains('halftee')) {
      add('halftee', _poleHalf);
    } else if (_on.contains('poly')) {
      add('poly', _polePoly);
    } else if (!_on.contains('shirt')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('pajama')) {
      add('pajama', _polePajama);
    } else if (_on.contains('halfpant')) {
      add('halfpant', _poleHalfPant);
    } else if (!_on.contains('pant')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('cotton')) {
      add('cotton', _poleCotton);
    } else if (_on.contains('wet')) {
      add('wet', _poleWet);
    } else if (_on.contains('hole')) {
      add('hole', _poleHole);
    } else if (_on.contains('bike')) {
      add('bike', _poleBike);
    } else if (!_on.contains('rubber')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('slip')) {
      add('slip', _poleSlip);
    } else if (_on.contains('normal')) {
      add('normal', _poleShoe);
    } else if (!_on.contains('boot')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('belt')) add('belt', _poleBelt);
    if (_on.contains('bamboo')) add('bamboo', _poleBamboo);
    if (!_on.contains('harness')) add('bench', _roomMiss);
    if (!_on.contains('frp')) add('bench', _roomMiss);
    return out;
  }

  List<({String zone, String why})> _dtrFaults() {
    final out = <({String zone, String why})>[];
    void add(String zone, String why) => out.add((zone: zone, why: why));

    if (_on.contains('gamcha')) add('gamcha', _dtrGamcha);
    if (_on.contains('road')) {
      add('road', _dtrRoad);
    } else if (_on.contains('vent')) {
      add('vent', _dtrVent);
    } else if (!_on.contains('helmet')) {
      add('bench', _roomMiss);
    }
    if (!_on.contains('shield')) add('bench', _roomMiss);

    if (_on.contains('fatua')) {
      add('fatua', _dtrFatua);
    } else if (_on.contains('halftee')) {
      add('halftee', _dtrHalf);
    } else if (_on.contains('poly')) {
      add('poly', _dtrPoly);
    } else if (!_on.contains('shirt')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('pajama')) {
      add('pajama', _dtrPajama);
    } else if (_on.contains('halfpant')) {
      add('halfpant', _dtrHalfPant);
    } else if (!_on.contains('pant')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('cotton')) {
      add('cotton', _dtrCotton);
    } else if (_on.contains('wet')) {
      add('wet', _dtrWet);
    } else if (_on.contains('hole')) {
      add('hole', _dtrHole);
    } else if (_on.contains('bike')) {
      add('bike', _dtrBike);
    } else if (!_on.contains('rubber')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('slip')) {
      add('slip', _dtrSlip);
    } else if (_on.contains('normal')) {
      add('normal', _dtrShoe);
    } else if (!_on.contains('boot')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('wire')) add('wire', _dtrWire);
    if (_on.contains('cloth')) add('cloth', _dtrCloth);
    if (!_on.contains('tester')) add('bench', _roomMiss);
    if (!_on.contains('discharge')) add('bench', _roomMiss);
    if (!_on.contains('earth')) add('bench', _roomMiss);
    return out;
  }

  List<({String zone, String why})> _nightFaults() {
    final out = <({String zone, String why})>[];
    void add(String zone, String why) => out.add((zone: zone, why: why));

    if (_on.contains('gamcha')) add('gamcha', _nightGamcha);
    if (_on.contains('road')) {
      add('road', _nightRoad);
    } else if (_on.contains('vent')) {
      add('vent', _nightVent);
    } else if (!_on.contains('helmet')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('fatua')) {
      add('fatua', _nightFatua);
    } else if (_on.contains('halftee')) {
      add('halftee', _nightHalf);
    } else if (_on.contains('poly')) {
      add('poly', _nightPoly);
    } else if (!_on.contains('shirt')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('pajama')) {
      add('pajama', _nightPajama);
    } else if (_on.contains('halfpant')) {
      add('halfpant', _nightHalfPant);
    } else if (!_on.contains('pant')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('cotton')) {
      add('cotton', _nightCotton);
    } else if (_on.contains('wet')) {
      add('wet', _nightWet);
    } else if (_on.contains('hole')) {
      add('hole', _nightHole);
    } else if (_on.contains('bike')) {
      add('bike', _nightBike);
    } else if (!_on.contains('rubber')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('slip')) {
      add('slip', _nightSlip);
    } else if (_on.contains('normal')) {
      add('normal', _nightShoe);
    } else if (!_on.contains('boot')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('bamboo')) add('bamboo', _nightBamboo);
    if (!_on.contains('vest')) add('bench', _roomMiss);
    if (!_on.contains('torch')) add('bench', _roomMiss);
    if (!_on.contains('frp')) add('bench', _roomMiss);
    return out;
  }

  List<({String zone, String why})> _treeFaults() {
    final out = <({String zone, String why})>[];
    void add(String zone, String why) => out.add((zone: zone, why: why));

    if (_on.contains('gamcha')) add('gamcha', _treeGamcha);
    if (_on.contains('road')) {
      add('road', _treeRoad);
    } else if (_on.contains('vent')) {
      add('vent', _treeVent);
    } else if (!_on.contains('helmet')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('fatua')) {
      add('fatua', _treeFatua);
    } else if (_on.contains('halftee')) {
      add('halftee', _treeHalf);
    } else if (_on.contains('poly')) {
      add('poly', _treePoly);
    } else if (!_on.contains('shirt')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('pajama')) {
      add('pajama', _treePajama);
    } else if (_on.contains('halfpant')) {
      add('halfpant', _treeHalfPant);
    } else if (!_on.contains('pant')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('cotton')) {
      add('cotton', _treeCotton);
    } else if (_on.contains('wet')) {
      add('wet', _treeWet);
    } else if (_on.contains('hole')) {
      add('hole', _treeHole);
    } else if (_on.contains('bike')) {
      add('bike', _treeBike);
    } else if (!_on.contains('rubber')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('slip')) {
      add('slip', _treeSlip);
    } else if (_on.contains('normal')) {
      add('normal', _treeShoe);
    } else if (!_on.contains('boot')) {
      add('bench', _roomMiss);
    }

    if (_on.contains('sickle')) add('sickle', _treeSickle);
    if (_on.contains('saw')) add('saw', _treeSaw);
    if (!_on.contains('tester')) add('bench', _roomMiss);
    if (!_on.contains('discharge')) add('bench', _roomMiss);
    if (!_on.contains('rope')) add('bench', _roomMiss);
    return out;
  }

  Future<void> _roomCheck() async {
    if (_checking || _finishing || !_roomLesson) return;
    final wrong = [for (final fault in _roomFaults()) if (fault.zone != 'bench') fault];
    if (wrong.isEmpty) {
      if (_ready) {
        widget.engine.dressRight();
        widget.onDelta(5, _flyFrom('bench'));
        if (_vanLesson) {
          await _doneVan();
        } else {
          await _doneLesson(_benchDone);
        }
        return;
      }
      if (_vanLesson && _vanGate == _VanGate.dress && _vanDressed) {
        await _revealTools();
        return;
      }
      await _roomHint();
      return;
    }
    final token = ++_roomToken;
    _speakToken++;
    _coachTimer?.cancel();
    setState(() {
      _checking = true;
      _mark = null;
      _ask = false;
      _coachSay = '';
    });
    for (final fault in wrong) {
      if (!mounted || token != _roomToken) return;
      setState(() {
        _frontId = fault.zone;
        _frontWhy = fault.why;
        _blameZone = fault.zone;
        _coachFace = DsCoachMood.oops;
        _coachSay = '';
      });
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted || token != _roomToken) return;
      widget.engine.dressWrong();
      widget.onDelta(-5, _frontPoint());
      HapticFeedback.heavyImpact();
      unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.7, muted: widget.muted));
      await widget.onSpeak(fault.why);
      if (!mounted || token != _roomToken) return;
      final piece = fault.zone == 'bench' ? null : _byId(fault.zone);
      if (piece != null) {
        await _throwHome(piece);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 320));
        if (!mounted || token != _roomToken) return;
        setState(() {
          _frontId = '';
          _frontWhy = '';
        });
      }
    }
    if (!mounted || token != _roomToken) return;
    setState(() {
      _blameZone = '';
      _frontId = '';
      _frontWhy = '';
      _tossAsset = '';
      _heldBack.clear();
      _coachFace = DsCoachMood.ready;
      _coachSay = '';
      if (widget.engine.level.number == 6) _on.removeWhere((id) => !_roomKeep.contains(id));
      _checking = false;
      _mixShelf(sound: true);
    });
  }

  Future<void> _roomHint() async {
    final token = ++_roomToken;
    _speakToken++;
    _coachTimer?.cancel();
    setState(() {
      _checking = true;
      _frontId = 'hint';
      _frontWhy = _vanLesson && _vanDressed ? _vanToolGap() : _roomMiss;
      _blameZone = '';
      _coachFace = DsCoachMood.talk;
      _coachSay = '';
    });
    await widget.onSpeak(_frontWhy);
    if (!mounted || token != _roomToken) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || token != _roomToken) return;
    setState(() {
      _checking = false;
      _frontId = '';
      _frontWhy = '';
      _coachFace = DsCoachMood.ready;
    });
  }

  Offset _frontPoint() {
    final box = _boxOf(_dressKey);
    if (box == null) {
      final size = MediaQuery.sizeOf(context);
      return Offset(size.width / 2, size.height * 0.4);
    }
    return box.localToGlobal(Offset(box.size.width / 2, box.size.height * 0.36));
  }

  Future<void> _throwHome(_Piece piece) async {
    final stage = _boxOf(_dressKey);
    final shelf = _boxOf(_shelfKey);
    final from = stage == null ? const Offset(180, 240) : Offset(stage.size.width / 2, stage.size.height * 0.36);
    var to = Offset(from.dx, (stage?.size.height ?? 520) - 28);
    if (stage != null && shelf != null) {
      to = stage.globalToLocal(shelf.localToGlobal(Offset(shelf.size.width * 0.62, 30)));
    }
    setState(() {
      _frontId = '';
      _frontWhy = '';
      _on.remove(piece.id);
      _heldBack.add(piece.id);
      _tossAsset = piece.asset;
      _tossFrom = from;
      _tossTo = to;
    });
    try {
      await _toss.forward(from: 0);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      _tossAsset = '';
      _heldBack.remove(piece.id);
    });
    HapticFeedback.lightImpact();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.32, muted: widget.muted));
  }

  void _wear(_Piece piece, Offset global) {
    if (_finishing || _checking || _on.contains(piece.id)) return;
    if (_roomLesson) {
      _wearRoom(piece);
      return;
    }
    if (_harnessLesson && piece.id == 'harness') {
      _parkHarness(global);
      return;
    }
    if (_harnessLesson && piece.id == 'rubber' && _step != _HStep.gloves) {
      _fail('hands', _gloveBlock, piece, global);
      return;
    }
    if (_harnessLesson && piece.id == 'rubber' && _on.contains('harness')) {
      _fail('hands', _gloveBlock, piece, global);
      return;
    }
    if (_fullLesson && piece.id == 'gamcha') {
      _fail('head', _gamchaNoSave, piece, global);
      return;
    }
    if (!piece.good) {
      _fail(piece.zone, piece.why, piece, global);
      return;
    }
    if (piece.id == 'pant' && _on.contains('boot')) {
      _fail('legs', _shoeBlock, piece, global);
      return;
    }
    if (piece.id == 'helmet' && _on.contains('gamcha')) {
      _fail('head', _gamchaBlock, piece, global);
      return;
    }
    if (piece.id == 'harness' && _on.contains('rubber')) {
      _fail(_fullLesson ? 'harness' : 'torso', _gloveBlock, piece, global);
      return;
    }
    if (_fullLesson && !_wearOrder(piece, global)) return;
    final score = !(_harnessLesson && piece.id == 'rubber');
    setState(() {
      _on.add(piece.id);
      _clearMark();
    });
    if (score) _point(global);
    if (!_ready) return;
    _doneLesson(switch (widget.engine.level.number) {
      2 => 'হেলমেট যথাযথভাবে লক করা হয়েছে। মাথার সুরক্ষা নিশ্চিত।',
      3 => 'হাতের গ্লাভস পরা সম্পন্ন হয়েছে। হাত এখন কাজের জন্য প্রস্তুত।',
      5 => 'ঠিক আছে। এভাবেই পুরো কিট পরুন।',
      6 => _roomDone,
      _ => 'পোশাক নির্বাচন সম্পূর্ণ। শরীর এখন কাজের জন্য সুরক্ষিত।',
    });
  }

  bool _blockedTake(_Piece piece) {
    if (piece.id == 'helmet' && _on.contains('shield')) return true;
    if (piece.id == 'harness' && _on.contains('helmet')) return true;
    if ((piece.id == 'shirt' || piece.id == 'pant' || piece.id == 'boot') && _on.contains('harness')) return true;
    return false;
  }

  void _take(_Piece piece) {
    if (_finishing || _checking || !_on.contains(piece.id)) return;
    if (_fullLesson && _blockedTake(piece)) return;
    if (_harnessLesson && piece.id == 'harness' && (_left != _Gap.open || _right != _Gap.open || _waistL || _waistR || _chest)) return;
    setState(() {
      _on.remove(piece.id);
      if (piece.id == 'harness') {
        _left = _Gap.open;
        _right = _Gap.open;
        _fingerL = false;
        _fingerR = false;
        _chest = false;
        _waistL = false;
        _waistR = false;
        _tugged = false;
        _paidL = false;
        _paidR = false;
        _chosen = '';
        _linkFrom = null;
        _linkTo = null;
        _linkBad = false;
      }
      _clearMark();
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.3, muted: widget.muted));
    if (_roomLesson) HapticFeedback.selectionClick();
    if (_headLesson && piece.id == 'gamcha') {
      const line = 'মাথা উন্মুক্ত হয়েছে। এবার উপযুক্ত ইলেকট্রিক্যাল হেলমেটটি পরিয়ে দিন।';
      _speakCoach(line, mood: DsCoachMood.talk, buffer: const Duration(milliseconds: 1200));
    }
  }

  void _openAsk() {
    final why = _mark?.why;
    if (why == null) return;
    _markTimer?.cancel();
    setState(() => _ask = true);
    unawaited(widget.onSpeak(why));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _vanLesson
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8ECAE6), Color(0xFFD7E8C8), Color(0xFFF6E2C4), Color(0xFFE4C48A)],
                stops: [0.0, 0.22, 0.46, 1.0],
              )
            : _roomLesson
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A2430), Color(0xFF243044), Color(0xFF1B140E)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6E2B8), Color(0xFFE7C98A), Color(0xFFC9A36A)],
                stops: [0.0, 0.55, 1.0],
              ),
        image: _roomLesson && !_vanLesson
            ? DecorationImage(
                image: AssetImage(_benchScene),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: 0.78,
              )
            : null,
      ),
      child: Stack(
        key: _dressKey,
        clipBehavior: Clip.none,
        children: [
          if (_vanLesson) const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: DsYardPainter()))),
          Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  fit: _roomLesson ? StackFit.expand : StackFit.loose,
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _hero && !_vanLesson ? 0 : 1,
                      duration: const Duration(milliseconds: 460),
                      curve: Curves.easeInOutCubic,
                        child: IgnorePointer(
                        ignoring: _finishing || _checking || (_vanLesson && _vanBeat == _VanBeat.coach),
                        child: _vanLesson
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 460),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: KeyedSubtree(key: ValueKey(_vanPlayKey), child: _playMan()),
                              )
                            : _glow
                                ? _WinGlow(child: _playMan())
                                : _playMan(),
                      ),
                    ),
                    if (_cornerCoach) _playCoach(),
                    if (_hero && !_vanLesson)
                      _HeroEntrance(
                        child: DsCoach(
                          mood: DsCoachMood.thanks,
                          line: _coachSay,
                          bubbleWidth: 240,
                          sprite: 168,
                          centered: true,
                        ),
                      ),
                  ],
                ),
              ),
              if (_roomLesson && !_finishing && !(_vanLesson && (_vanBeat == _VanBeat.coach || _outro != _VanOutro.idle || _hero)))
                ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.topCenter,
                    heightFactor: _vanPortrait ? 0 : 1,
                    duration: const Duration(milliseconds: 620),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedOpacity(
                      opacity: _vanPortrait ? 0 : 1,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeInCubic,
                      child: IgnorePointer(
                        ignoring: _vanPortrait,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                          child: GestureDetector(
                            onTap: _checking || (_vanLesson && !_vanParked) ? null : _roomCheck,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _checking || (_vanLesson && !_vanParked) ? const Color(0xFF5C4632) : const Color(0xFF3A2A16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC9A227), width: 1.4),
                              ),
                              child: Text('তৈরি', style: zlText(18, weight: FontWeight.w900, color: const Color(0xFFF6E7B0))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!(_vanLesson && (_vanBeat == _VanBeat.coach || _outro != _VanOutro.idle || _hero)))
                ClipRect(
                  child: AnimatedAlign(
                    alignment: Alignment.topCenter,
                    heightFactor: _vanPortrait ? 0 : 1,
                    duration: const Duration(milliseconds: 620),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedSlide(
                      offset: _vanPortrait ? const Offset(0, 0.22) : Offset.zero,
                      duration: const Duration(milliseconds: 620),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedOpacity(
                        opacity: _vanPortrait ? 0 : 1,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInCubic,
                        child: IgnorePointer(ignoring: _finishing || _checking || _vanPortrait, child: _shelf()),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_frontId.isNotEmpty) _reviewFront(),
          if (_vanLesson && _vanBeat == _VanBeat.coach) _vanCoach(),
          if (_vanLesson && _vanGate == _VanGate.guide)
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: IgnorePointer(
                child: AnimatedSlide(
                  offset: _guideShown ? Offset.zero : const Offset(0, 0.32),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInCubic,
                  child: AnimatedOpacity(
                    opacity: _guideShown ? 1 : 0,
                    duration: const Duration(milliseconds: 360),
                    child: _HeroEntrance(
                      child: DsCoach(
                        mood: DsCoachMood.talk,
                        line: _vanInsist,
                        bubbleWidth: 280,
                        sprite: 156,
                        centered: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_vanLesson && _outro == _VanOutro.guide)
            Positioned.fill(
              child: Center(
                child: _HeroEntrance(
                  child: DsCoach(
                    mood: DsCoachMood.thanks,
                    line: _roomDone,
                    bubbleWidth: 280,
                    sprite: 188,
                    centered: true,
                  ),
                ),
              ),
            ),
          if (_vanLesson && _vanBeat == _VanBeat.coach && widget.onBack != null)
            Positioned(
              left: 2,
              top: 0,
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3A2A16)),
              ),
            ),
          if (_tossAsset.isNotEmpty) _tossFlight(),
          if (_ask && _mark != null) _modal(_mark!.why),
        ],
      ),
    );
  }

  List<_Spot> get _harnessSpots {
    final spots = <_Spot>[_spotHead, _spotTorso, _spotLegs, _spotFeet, _spotHandL, _spotHandR];
    if (_guide == 0) spots.add(_gPalm);
    return spots;
  }

  List<_Spot> get _spots {
    final n = widget.engine.level.number;
    if (n == 4) return _harnessSpots;
    return switch (n) {
      2 => const [_spotHead],
      3 => const [_spotHandL, _spotHandR],
      5 => const [_spotHead, _spotChest, _spotBuckle, _spotHandL, _spotHandR, _spotLegs, _spotFeet],
      6 => const [_spotHead, _spotTorso, _spotBelt, _spotBuckle, _spotHandL, _spotHandR, _spotLegs, _spotFeet],
      _ => const [_spotTorso, _spotLegs, _spotFeet],
    };
  }

  Widget _man() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _harnessLesson ? 4 : 28),
      child: Center(
        child: AspectRatio(
          aspectRatio: 864 / 1152,
          child: LayoutBuilder(
            builder: (context, box) {
              final image = Offset.zero & Size(box.maxWidth, box.maxHeight);
              final spots = [for (final spot in _spots) (spot: spot, rect: spot.of(image))];
              final from = _linkFrom;
              final target = _linkTo;
              return ClipRect(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _zoom),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (_, scale, child) => Transform.scale(scale: scale, alignment: _zoomAt, child: child),
                  child: Stack(
                    key: _boardKey,
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/duty_slip/dress/$_figure.webp', fit: BoxFit.fill),
                      if (_blameZone.isNotEmpty)
                        for (final s in spots)
                          if (s.spot.zone == _blameZone)
                            Positioned.fromRect(
                              rect: s.rect.inflate(8),
                              child: const IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0x55E53935),
                                    borderRadius: BorderRadius.all(Radius.circular(18)),
                                    border: Border.fromBorderSide(BorderSide(color: Color(0xFFFF5A4A), width: 2.4)),
                                    boxShadow: [BoxShadow(color: Color(0xAAE53935), blurRadius: 16, spreadRadius: 2)],
                                  ),
                                ),
                              ),
                            ),
                      for (final s in spots) _handle(s.spot, s.rect),
                      for (final s in spots) _reach(s.spot, image),
                      for (final s in spots)
                        if (_showDots(s.spot))
                          Positioned.fromRect(
                            rect: _grown(s.spot, s.rect),
                            child: _jointMark(s.spot, s.rect),
                          ),
                      if (from != null && target != null)
                        Positioned.fill(
                          child: IgnorePointer(child: CustomPaint(painter: _LinkPainter(from, target, _link.value, _linkBad))),
                        ),
                      if (_mark != null) _chip(spots, image.size),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _showDots(_Spot spot) {
    if (_harnessLesson) return spot.shape == _MarkShape.ring && spot.zone == (_guide < _guideRows.length ? _guideRows[_guide].zone : '');
    return _dragZone.isNotEmpty && _dragZone == spot.zone;
  }

  bool _canDrop(_Piece piece, _Spot spot) {
    if (_finishing || _checking) return false;
    if (_harnessLesson) {
      if (_rowOk || _guide >= _guideRows.length) return false;
      if (_on.contains(piece.id)) return false;
      const body = {'head', 'torso', 'legs', 'feet', 'hands'};
      final want = _guideRows[_guide].zone;
      return piece.id == 'harness' || piece.id == 'fingers' || piece.id == 'belt' || piece.id == 'rubber'
          ? spot.zone == want || body.contains(spot.zone)
          : false;
    }
    if (piece.id.startsWith('pull')) {
      if (_beside) return spot.zone == 'hold';
      return switch (_step) {
        _HStep.lift => spot.zone == 'hold',
        _HStep.shoulderL || _HStep.shoulderR => spot.zone == 'shoulderL' || spot.zone == 'shoulderR',
        _HStep.chest => spot.zone == 'ring',
        _HStep.chestFit => spot.zone == 'chestGoal' || spot.zone == 'chestHigh',
        _HStep.legL => spot.zone == 'buckleL',
        _HStep.legR => spot.zone == 'buckleR',
        _HStep.waistL => spot.zone == 'buckleWaistL',
        _HStep.waistR => spot.zone == 'buckleWaistR',
        _HStep.tuckL => spot.zone == 'tuckToL',
        _HStep.tuckR => spot.zone == 'tuckToR',
        _HStep.nape => spot.zone == 'nape',
        _HStep.fitL => spot.zone == 'fitGoalL' || spot.zone == 'fitHighL',
        _HStep.fitR => spot.zone == 'fitGoalR' || spot.zone == 'fitHighR',
        _ => false,
      };
    }
    if (_harnessLesson && piece.id == 'fingers') return spot.zone == 'fitGoalL' || spot.zone == 'fitGoalR';
    if (piece.id.startsWith('end')) {
      return const {'buckleL', 'buckleR', 'buckleWaistL', 'buckleWaistR', 'ring', 'tightL', 'tightR', 'gapL', 'gapR', 'tug'}.contains(spot.zone);
    }
    if (piece.id == 'fingers') return spot.zone == 'gapL' || spot.zone == 'gapR';
    if (_on.contains(piece.id)) return false;
    if (_harnessLesson && piece.id == 'rubber' && _step != _HStep.gloves) return spot.zone == 'hands';
    return piece.zone == spot.zone;
  }

  _Piece? _pullFor(String zone) {
    if (_beside) {
      return switch (zone) {
        'liftRing' => _pullRing,
        'liftStrap' || 'liftLeg' => _pullStrap,
        _ => null,
      };
    }
    return switch (_step) {
      _HStep.lift when zone == 'liftRing' => _pullRing,
      _HStep.lift when zone == 'liftStrap' => _pullStrap,
      _HStep.shoulderL || _HStep.shoulderR when zone == 'handReach' => _pullShoulder,
      _HStep.chest when zone == 'endChest' => _pullChest,
      _HStep.chestFit when zone == 'chestPull' => _pullFit,
      _HStep.legL when zone == 'endL' => _pullLeg,
      _HStep.legR when zone == 'endR' => _pullLeg,
      _HStep.waistL when zone == 'endWaistL' => _pullWaist,
      _HStep.waistR when zone == 'endWaistR' => _pullWaist,
      _HStep.tuckL when zone == 'tuckFromL' => _pullTuck,
      _HStep.tuckR when zone == 'tuckFromR' => _pullTuck,
      _HStep.nape when zone == 'handReach' => _pullHand,
      _HStep.fitL when zone == 'fitPullL' => _pullFit,
      _HStep.fitR when zone == 'fitPullR' => _pullFit,
      _ => null,
    };
  }

  _Piece? _grab(_Spot spot) {
    if (_harnessLesson) {
      final pull = _pullFor(spot.zone);
      if (pull != null) return pull;
    }
    return _worn(spot.zone);
  }

  DsCoachMood get _coachMood {
    if (_hero) return DsCoachMood.thanks;
    if (_mark != null) return DsCoachMood.oops;
    return _coachFace;
  }

  String get _coachLine {
    if (_hero) return _coachSay;
    if (_mark != null) return _mark!.why;
    if (_coachFace == DsCoachMood.ready) return '';
    return _coachSay;
  }

  String get _vanPlayKey => switch (_outro) {
        _VanOutro.idle => 'yard',
        _VanOutro.list => 'list',
        _VanOutro.guide => 'clear',
        _ => 'road',
      };

  Widget _playMan() {
    if (_vanLesson) {
      return switch (_outro) {
        _VanOutro.list => _vanChecklistPage(),
        _VanOutro.guide => const SizedBox.expand(),
        _VanOutro.pair || _VanOutro.aboard || _VanOutro.away => _vanRoad(),
        _ => _vanStage(),
      };
    }
    if (_roomLesson) return _roomStage();
    if (_harnessLesson) {
      return Row(
        children: [
          Expanded(child: _bobbingMan()),
          _guideRail(),
        ],
      );
    }
    return _bobbingMan();
  }

  Widget _vanCoach() {
    final leaving = _vanBeat == _VanBeat.coach && !_coachOn;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: leaving ? const Offset(-0.28, 0.08) : Offset.zero,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: leaving ? 0 : 1,
            duration: const Duration(milliseconds: 360),
            child: Align(
              alignment: _hero ? const Alignment(0, -0.55) : Alignment.center,
              child: DsCoach(
                mood: _hero ? DsCoachMood.thanks : DsCoachMood.talk,
                line: _coachSay,
                bubbleWidth: 280,
                sprite: 188,
                centered: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vanStage() {
    if (_vanBeat == _VanBeat.coach) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: _vanPortrait ? 0 : 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeInOutCubic,
          builder: (_, t, _) {
            final bedH = h * 0.58 * t;
            final holdH = h * 0.36 * (1 - t);
            final actorH = (h - bedH - holdH).clamp(0.0, h);
            return Column(
              children: [
                SizedBox(height: actorH, child: _vanActors()),
                SizedBox(height: holdH),
                SizedBox(
                  height: bedH,
                  child: ClipRect(
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 28 * (1 - t)),
                        child: _vanBed(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _vanRoad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 28),
      child: _vanActors(),
    );
  }

  Widget _vanChecklistPage() {
    final shown = _checkShown.clamp(0, _vanChecklist.length);
    final progress = _vanChecklist.isEmpty ? 0.0 : shown / _vanChecklist.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF012181F),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x44F6E7B0)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 16))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('চেকলিস্ট', style: zlText(13, weight: FontWeight.w800, color: const Color(0xFFC9A227))),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, _) => LinearProgressIndicator(
                    value: t,
                    minHeight: 4,
                    backgroundColor: const Color(0x33F6E7B0),
                    color: const Color(0xFF7DCEA0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < shown; i++)
                      _VanCheckRow(
                        key: ValueKey(_vanChecklist[i].id),
                        asset: _byId(_vanChecklist[i].id)?.asset ?? '',
                        label: _vanChecklist[i].label,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vanMan() {
    final look = _vanLook;
    return AnimatedOpacity(
      opacity: _vanBoarded ? 0 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeIn,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 480),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Image.asset(
          'assets/duty_slip/dress/$look.webp',
          key: ValueKey(look),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _vanActors() {
    return LayoutBuilder(
      builder: (context, box) {
        final road = _outro == _VanOutro.pair || _outro == _VanOutro.aboard || _outro == _VanOutro.away;
        final vanW = road ? math.min(box.maxWidth * 0.9, 520.0) : math.min(box.maxWidth * 0.52, 280.0);
        return AnimatedBuilder(
          animation: Listenable.merge([_shake, _vanRide, _vanDepart]),
          builder: (_, _) {
            final shakeX = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 8;
            final t = Curves.easeOutBack.transform(_vanRide.value.clamp(0.0, 1.0));
            final leave = Curves.easeInCubic.transform(_vanDepart.value);
            final vanX = (1 - t) * (box.maxWidth * 0.95) - leave * (box.maxWidth * 1.35);
            final van = Transform.translate(offset: Offset(vanX, 0), child: _vanFigure(vanW));
            if (road) {
              final manH = math.min(box.maxHeight * 0.72, vanW * 0.46);
              return Transform.translate(
                offset: Offset(shakeX, 0),
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Align(alignment: Alignment.bottomCenter, child: van),
                    SizedBox(width: box.maxWidth * 0.4, height: manH, child: _vanMan()),
                  ],
                ),
              );
            }
            return Transform.translate(
              offset: Offset(shakeX, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _vanMan()),
                  SizedBox(width: vanW, child: van),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _vanFigure(double width) {
    final height = width * 0.5;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Image.asset('assets/zero_loss/scene/prop_truck.webp', width: width, height: height, fit: BoxFit.contain),
          if (_vanBoarded) ...[
            Positioned(
              left: width * 0.18,
              right: width * 0.18,
              bottom: height * 0.08,
              top: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutCubic,
                builder: (_, t, _) => Opacity(
                  opacity: ((1 - t) * 0.9).clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.35 + t * 1.7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF6E7B0), width: 2.2),
                        boxShadow: const [BoxShadow(color: Color(0x66F6E7B0), blurRadius: 18)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.24,
              bottom: height * 0.06,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                builder: (_, t, child) {
                  final shown = t.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: shown,
                    child: Transform.scale(scale: 0.72 + 0.28 * shown, child: child),
                  );
                },
                child: Image.asset('assets/duty_slip/dress/head_helmet.webp', height: height * 0.92, fit: BoxFit.contain),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vanBed() {
    final hot = _dragZone == 'bench';
    final missing = _blameZone == 'bench';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: DragTarget<_Piece>(
        hitTestBehavior: HitTestBehavior.opaque,
        onWillAcceptWithDetails: (d) => _vanParked && !_checking && !_finishing && !_vanBoarded,
        onAcceptWithDetails: (d) => _wear(d.data, d.offset),
        builder: (context, candidate, _) {
          final lit = hot || candidate.isNotEmpty;
          return Container(
            key: _benchPaneKey,
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: missing ? const Color(0xFFFFF1F0) : const Color(0xF7FFF8EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: missing
                    ? const Color(0xFFFF5A4A)
                    : lit
                        ? const Color(0xFFC9A227)
                        : const Color(0xFFD7C39A),
                width: lit || missing ? 2.6 : 1.4,
              ),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _vanBoarded ? _vanLoaded() : _vanOpenCargo(),
            ),
          );
        },
      ),
    );
  }

  Widget _vanOpenCargo() {
    final pieces = _benchPieces;
    if (pieces.isEmpty) return const SizedBox.expand();
    return _vanFit(
      count: pieces.length,
      item: (i, _, _) => _vanTile(pieces[i]),
    );
  }

  Widget _vanLoaded() {
    final icons = <String>[
      for (final id in _roomKeep)
        if (_byId(id) != null) _byId(id)!.asset,
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      child: _vanFit(
        count: icons.length,
        item: (i, _, _) => Image.asset(icons[i], fit: BoxFit.contain),
      ),
    );
  }

  Widget _vanFit({required int count, required Widget Function(int index, double w, double h) item}) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 16 || box.maxHeight < 16 || !box.maxWidth.isFinite || !box.maxHeight.isFinite) {
          return const SizedBox.expand();
        }
        final n = math.max(count, 1);
        const gap = 8.0;
        final cols = n <= 2
            ? n
            : n <= 4
                ? 2
                : n <= 6
                    ? 3
                    : 4;
        final rows = (n / cols).ceil();
        final maxW = (box.maxWidth - gap * (cols - 1)) / cols;
        final maxH = rows <= 1 ? box.maxHeight : (box.maxHeight - gap * (rows - 1)) / rows;
        final h = math.min(96.0, maxH.isFinite ? maxH : 72.0);
        final w = math.min(maxW, h * 1.12);
        return Align(
          alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < count; i++) SizedBox(width: w, height: h, child: item(i, w, h)),
            ],
          ),
        );
      },
    );
  }

  Widget _vanTile(_Piece piece) {
    final blamed = _blameZone == piece.id;
    final land = _landId == piece.id;
    final face = DecoratedBox(
      decoration: BoxDecoration(
        color: blamed ? const Color(0xFFFFE4E1) : const Color(0x00000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blamed ? const Color(0xFFFF5A4A) : const Color(0x00000000), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Image.asset(piece.asset, fit: BoxFit.contain),
      ),
    );
    return Opacity(
      opacity: _frontId == piece.id ? 0 : 1,
      child: Draggable<_Piece>(
        data: piece,
        onDragStarted: () => setState(() {
          _dragZone = 'bench';
          _clearMark();
        }),
        onDragEnd: (_) => setState(() => _dragZone = ''),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 84, height: 84, child: Image.asset(piece.asset, fit: BoxFit.contain)),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: face),
        child: GestureDetector(
          onTap: () => _take(piece),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('${piece.id}-$land'),
            tween: Tween(begin: land ? 0.55 : 1, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: face,
          ),
        ),
      ),
    );
  }

  Widget _roomStage() {
    return ClipRect(
      child: TweenAnimationBuilder<_Cam>(
        tween: _CamTween(_cam),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (_, cam, child) => Transform.scale(
          scale: cam.scale,
          alignment: cam.align,
          filterQuality: FilterQuality.medium,
          child: child,
        ),
        child: KeyedSubtree(
          key: _roomKey,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final shakeX = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 10;
              return Transform.translate(offset: Offset(shakeX, 0), child: child);
            },
            child: Column(
              children: [
                const Expanded(child: Image(image: AssetImage('assets/duty_slip/dress/body.webp'), fit: BoxFit.contain)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _bench(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bench() {
    final pieces = _benchPieces;
    final missing = _blameZone == 'bench';
    final hot = _dragZone == 'bench';
    return DragTarget<_Piece>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (d) => !_checking && !_finishing,
      onAcceptWithDetails: (d) => _wear(d.data, d.offset),
      builder: (context, candidate, _) {
        final lit = hot || candidate.isNotEmpty;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          offset: Offset(0, lit ? -0.06 : 0),
          child: AnimatedContainer(
          key: _benchPaneKey,
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: missing
                  ? const [Color(0xFF5A2420), Color(0xFF2A100E)]
                  : const [Color(0xFF3A2A1C), Color(0xFF1B140E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: missing
                  ? const Color(0xFFFF5A4A)
                  : lit
                      ? const Color(0xFFC9A227)
                      : const Color(0x44C9A227),
              width: missing || lit ? 2.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: missing ? const Color(0x88E53935) : const Color(0x66000000),
                blurRadius: missing ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: pieces.isEmpty
              ? const SizedBox(height: 64)
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final piece in pieces) _benchItem(piece)],
                ),
          ),
        );
      },
    );
  }

  Widget _benchItem(_Piece piece, {bool large = false}) {
    final blamed = _blameZone == piece.id;
    final land = _landId == piece.id;
    final tall = _tallPiece(piece.id);
    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: tall ? (large ? 72 : 44) : (large ? 92 : 64),
      height: tall ? (large ? 120 : 84) : (large ? 84 : 56),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: blamed ? const Color(0xFF3A1412) : const Color(0x00000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: blamed ? const Color(0xFFFF5A4A) : const Color(0x00000000), width: 2),
        boxShadow: blamed ? const [BoxShadow(color: Color(0x88E53935), blurRadius: 10)] : null,
      ),
      child: Image.asset(piece.asset, fit: BoxFit.contain),
    );
    return KeyedSubtree(
      key: _pieceKey(piece.id),
      child: Opacity(
        opacity: _frontId == piece.id ? 0 : 1,
        child: Draggable<_Piece>(
        data: piece,
        onDragStarted: () => setState(() {
          _dragZone = 'bench';
          _clearMark();
        }),
        onDragEnd: (_) => setState(() => _dragZone = ''),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 84, height: 84, child: Image.asset(piece.asset, fit: BoxFit.contain)),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: face),
        child: GestureDetector(
          onTap: () => _take(piece),
          child: AnimatedBuilder(
            animation: Listenable.merge([_sway, _shake]),
            builder: (_, child) {
              final pulse = blamed ? 1 + math.sin(_sway.value * math.pi) * 0.08 : 1.0;
              final kick = blamed ? math.sin(_shake.value * math.pi * 5) * (1 - _shake.value) * 7 : 0.0;
              return Transform.translate(
                offset: Offset(kick, 0),
                child: Transform.scale(scale: pulse, child: child),
              );
            },
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${piece.id}-$land'),
              tween: Tween(begin: land ? 0.42 : 1, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: face,
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _reviewFront() {
    final hint = _frontId == 'hint';
    final piece = hint ? null : _byId(_frontId);
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: const Color(0xB3080C12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!hint)
                SizedBox(
                  width: 188,
                  height: 188,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ring,
                        builder: (_, _) => CustomPaint(
                          size: const Size(180, 180),
                          painter: _ReviewRingPainter(_ring.value),
                        ),
                      ),
                      if (piece != null)
                        SizedBox(width: 108, height: 108, child: Image.asset(piece.asset, fit: BoxFit.contain)),
                    ],
                  ),
                ),
              DsCoach(
                mood: hint ? DsCoachMood.talk : DsCoachMood.oops,
                line: _frontWhy,
                bubbleWidth: 250,
                sprite: hint ? 156 : 132,
                centered: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tossFlight() {
    return AnimatedBuilder(
      animation: _toss,
      builder: (_, _) {
        final t = Curves.easeInCubic.transform(_toss.value);
        final pos = Offset.lerp(_tossFrom, _tossTo, t)!;
        final lift = math.sin(t * math.pi) * 78;
        return Positioned(
          left: pos.dx - 40,
          top: pos.dy - lift - 40,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: t * 1.15,
              child: Transform.scale(
                scale: 1.2 - (0.62 * t),
                child: SizedBox(width: 80, height: 80, child: Image.asset(_tossAsset, fit: BoxFit.contain)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bobbingMan() {
    return AnimatedBuilder(
      animation: Listenable.merge([_sway, _shake, _link]),
      builder: (_, child) {
        final bob = math.sin(_sway.value * math.pi) * 3;
        final shakeX = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 12;
        return Transform.translate(offset: Offset(shakeX, bob), child: child);
      },
      child: _man(),
    );
  }

  Widget _guideRail() {
    return SizedBox(
      width: 132,
      child: AnimatedBuilder(
        animation: _rowFx,
        builder: (_, _) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 132,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < _guideRows.length; i++) _guideTile(i)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _guideTile(int i) {
    final done = i < _guide;
    final live = i == _guide && _guide < _guideRows.length;
    final tick = done || (live && _rowOk);
    final cross = _rowBad && _badRow == i;
    final tone = tick
        ? const Color(0xFF2F6B3A)
        : cross
            ? const Color(0xFF8C1D18)
            : live
                ? const Color(0xFF3A2A16)
                : const Color(0xFF9A8660);
    final t = live || cross ? _rowFx.value : 1.0;
    final button = i > 0 && !done && !_rowOk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: live ? const Color(0xFFFFF6E4) : const Color(0x00000000),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: button ? (d) => _tapGuide(i, d.globalPosition) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 4, 4, 4),
            child: Row(
              children: [
                Transform.translate(
                  offset: Offset(cross ? math.sin(t * math.pi * 6) * 3 : 0, 0),
                  child: _GuideMark(tick: tick, cross: cross, live: live, t: t),
                ),
                const SizedBox(width: 4),
                _StepIcon(step: i, color: tone),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _guideRows[i].title,
                    maxLines: 2,
                    style: zlText(12, weight: live || tick ? FontWeight.w800 : FontWeight.w600, height: 1.15, color: tone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _Spot? _zoomSpot() {
    return switch (_step) {
      _HStep.chest => _spotRing,
      _HStep.chestFit => _spotChestGoal,
      _HStep.legL => _spotBuckleL,
      _HStep.legR => _spotBuckleR,
      _HStep.waistL => _spotWaistBuckleL,
      _HStep.waistR => _spotWaistBuckleR,
      _HStep.tuckL => _spotTuckToL,
      _HStep.tuckR => _spotTuckToR,
      _HStep.fitL => _spotFitGoalL,
      _HStep.fitR => _spotFitGoalR,
      _ => null,
    };
  }

  Widget _canvasPark() {
    return Positioned.fill(
      child: DragTarget<_Piece>(
        hitTestBehavior: HitTestBehavior.translucent,
        onWillAcceptWithDetails: (d) => d.data.id == 'harness',
        onAcceptWithDetails: (d) => _parkHarness(d.offset),
        builder: (_, _, _) => const IgnorePointer(child: SizedBox.expand()),
      ),
    );
  }

  Widget _waitingHarness(Rect board) {
    final rect = Rect.fromLTWH(board.width * 0.46, board.height * 0.26, board.width * 0.52, board.height * 0.60);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Opacity(
          opacity: _dragZone == 'pullRing' ? 0.2 : 1,
          child: Image.asset(_strapAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _pullGhost(_Piece piece) {
    if (piece.id == 'pullRing') {
      return Material(
        color: Colors.transparent,
        child: SizedBox(width: 120, height: 156, child: Image.asset(_strapAsset, fit: BoxFit.contain)),
      );
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFC9A227),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3A2A12), width: 2),
        ),
      ),
    );
  }

  Rect _grown(_Spot spot, Rect rect) {
    final lock = spot.shape == _MarkShape.clasp || spot.shape == _MarkShape.ring || spot.shape == _MarkShape.pull;
    final strap = spot.shape == _MarkShape.openC;
    if (!lock && !strap) return rect;
    final chosen = _chosen.isNotEmpty && spot.zone != _chosen;
    final scale = lock ? (chosen ? 1.7 : 1.2) : 1.35;
    return Rect.fromCenter(center: rect.center, width: rect.width * scale, height: rect.height * scale);
  }

  double _tickSpread(_Spot spot) {
    if (spot.zone != 'gapL' && spot.zone != 'gapR') return 1;
    final gap = spot.zone == 'gapL' ? _left : _right;
    return switch (gap) {
      _Gap.loose => 1.8,
      _Gap.tight => 0.28,
      _ => 1,
    };
  }

  Widget _jointMark(_Spot spot, Rect rect) {
    if (spot.zone.startsWith('g')) {
      return IgnorePointer(child: CustomPaint(painter: _SoftRingPainter(_sway.value)));
    }
    if (spot.shape == _MarkShape.dots) {
      return const IgnorePointer(child: CustomPaint(painter: _DotRingPainter()));
    }
    final paint = CustomPaint(
      painter: _JointPainter(spot.shape, picked: _chosen == spot.zone, spread: _tickSpread(spot)),
    );
    if (_harnessLesson) return IgnorePointer(child: paint);
    final tap = GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _tapMark(spot, rect), child: paint);
    if (spot.zone != 'gapL' && spot.zone != 'gapR') return tap;
    return Stack(
      fit: StackFit.expand,
      children: [
        tap,
        DragTarget<_Piece>(
          hitTestBehavior: HitTestBehavior.translucent,
          onWillAcceptWithDetails: (d) => _canDrop(d.data, spot),
          onAcceptWithDetails: (d) => _dropOn(spot, d.data, d.offset),
          builder: (context, _, _) => const IgnorePointer(child: SizedBox.expand()),
        ),
      ],
    );
  }

  bool _isStrap(String zone) => zone == 'endL' || zone == 'endR' || zone == 'endWaistL' || zone == 'endWaistR' || zone == 'endChest';

  Offset _globalCenter(Rect rect) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return rect.center;
    return box.localToGlobal(rect.center);
  }

  Rect? _rectFor(String zone) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final image = Offset.zero & box.size;
    for (final spot in _spots) {
      if (spot.zone == zone && spot.mark) return spot.of(image);
    }
    return null;
  }

  void _tapMark(_Spot spot, Rect rect) {
    if (_finishing || _linking || !_harnessLesson || !_on.contains('harness')) return;
    final zone = spot.zone;
    if (_isStrap(zone) || (zone == 'ring' && _canTug)) {
      setState(() {
        _chosen = zone;
        _linkFrom = null;
        _linkTo = null;
        _linkBad = false;
        _clearMark();
      });
      return;
    }
    if (zone == 'gapL' || zone == 'gapR') {
      _pullGap(zone == 'gapL', _globalCenter(rect));
      return;
    }
    if (_chosen.isEmpty) return;
    if (spot.shape != _MarkShape.clasp && spot.shape != _MarkShape.ring && spot.shape != _MarkShape.pull) return;
    _commitLink(_chosen, zone, rect);
  }

  bool _pairOk(String from, String to) {
    return switch (from) {
      'endL' => to == 'buckleL' && _left == _Gap.open,
      'endR' => to == 'buckleR' && _right == _Gap.open,
      'endWaistL' => to == 'buckleWaistL' && !_waistL,
      'endWaistR' => to == 'buckleWaistR' && !_waistR,
      'endChest' => to == 'ring' && _legsBuckled && !_chest,
      'ring' => to == 'tug' && _canTug,
      _ => false,
    };
  }

  void _commitLink(String from, String to, Rect target) {
    final origin = _rectFor(from);
    if (origin == null) return;
    final global = _globalCenter(target);
    final ok = _pairOk(from, to);
    setState(() {
      _linkFrom = origin.center;
      _linkTo = target.center;
      _linkBad = !ok;
    });
    _link.forward(from: 0);
    if (!ok) {
      _explainMiss(from, to, global);
      return;
    }
    _linking = true;
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _linking = false;
      if (!_pairOk(from, to)) return;
      _applyPair(from, global);
      setState(() {
        _chosen = '';
        _linkFrom = null;
        _linkTo = null;
        _linkBad = false;
      });
    });
  }

  void _explainMiss(String from, String to, Offset global) {
    final piece = _isStrap(from) ? _endPiece(from) : _endChest;
    final why = switch (from) {
      'endL' || 'endR' => switch (to) {
          'ring' => _legOnRing,
          'buckleWaistL' || 'buckleWaistR' => _thighOnWaist,
          _ => _wrongLeg,
        },
      'endWaistL' || 'endWaistR' => switch (to) {
          'ring' => _waistOnRing,
          'buckleL' || 'buckleR' => _waistOnThigh,
          _ => _wrongWaist,
        },
      'endChest' => to == 'ring' ? _legsFirst : _chestOnBuckle,
      _ => _tugEarly,
    };
    _fail(to, why, piece, global);
  }

  void _applyPair(String from, Offset global) {
    setState(() {
      switch (from) {
        case 'endL':
          _left = _Gap.loose;
        case 'endR':
          _right = _Gap.loose;
        case 'endWaistL':
          _waistL = true;
        case 'endWaistR':
          _waistR = true;
        case 'endChest':
          _chest = true;
        case 'ring':
          _tugged = true;
      }
      _clearMark();
    });
    _point(global);
    if (from == 'endL' || from == 'endR') {
      unawaited(widget.onSpeak('ভরা ডটটা খালি ডটের উপর তুলুন।'));
    }
    if (from == 'ring') _doneLesson(_tugHeld);
  }

  void _pullGap(bool left, Offset global) {
    final gap = left ? _left : _right;
    if (gap == _Gap.open || (left ? _fingerL : _fingerR)) return;
    final paid = left ? _paidL : _paidR;
    final toSnug = gap != _Gap.snug;
    setState(() {
      if (left) {
        _left = toSnug ? _Gap.snug : _Gap.tight;
        if (toSnug) _paidL = true;
      } else {
        _right = toSnug ? _Gap.snug : _Gap.tight;
        if (toSnug) _paidR = true;
      }
      _clearMark();
    });
    if (toSnug && !paid) _point(global);
  }

  Widget _handle(_Spot spot, Rect rect) {
    final worn = _grab(spot);
    if (worn == null || _finishing) return const SizedBox.shrink();
    const pad = DecoratedBox(decoration: BoxDecoration(), child: SizedBox.expand());
    return Positioned.fromRect(
      rect: rect,
      child: ClipPath(
        clipper: const _OvalClip(),
        child: Draggable<_Piece>(
          data: worn,
          onDragStarted: () {
            final focus = worn.id.startsWith('pull') ? _zoomSpot() : null;
            setState(() {
              _dragZone = worn.id.startsWith('pull') ? worn.id : spot.zone;
              _pullLanded = false;
              _clearMark();
              if (focus != null) {
                final c = focus.of(const Rect.fromLTWH(0, 0, 1, 1)).center;
                _zoom = 2.2;
                _zoomAt = Alignment((c.dx * 2 - 1).clamp(-1.0, 1.0).toDouble(), (c.dy * 2 - 1).clamp(-1.0, 1.0).toDouble());
              }
            });
          },
          onDragEnd: (d) {
            if (!mounted) return;
            if (worn.id == 'pullStrap' && !_pullLanded) {
              _fail('liftRing', _holdRing, worn, d.offset);
            }
            setState(() {
              _dragZone = '';
              _zoom = 1;
            });
          },
          feedbackOffset: worn.id == 'pullRing'
              ? const Offset(-60, -30)
              : worn.id.startsWith('pull')
                  ? const Offset(-14, -14)
                  : Offset.zero,
          feedback: worn.id.startsWith('pull')
              ? _pullGhost(worn)
              : Material(
                  color: Colors.transparent,
                  child: SizedBox(width: 84, height: 84, child: Image.asset(worn.asset, fit: BoxFit.contain)),
                ),
          childWhenDragging: pad,
          child: pad,
        ),
      ),
    );
  }

  Widget _reach(_Spot spot, Rect image) {
    return Positioned.fromRect(
      rect: spot.reach(image),
      child: ClipPath(
        clipper: const _OvalClip(),
        child: DragTarget<_Piece>(
          hitTestBehavior: HitTestBehavior.translucent,
          onWillAcceptWithDetails: (d) => _canDrop(d.data, spot),
          onAcceptWithDetails: (d) => _dropOn(spot, d.data, d.offset),
          builder: (context, _, _) => const IgnorePointer(child: SizedBox.expand()),
        ),
      ),
    );
  }

  Widget _chip(List<({_Spot spot, Rect rect})> spots, Size size) {
    final mark = _mark;
    if (mark == null) return const SizedBox.shrink();
    Rect? anchor;
    for (final s in spots) {
      if (s.spot.zone == mark.zone && s.spot.mark) anchor = s.rect;
    }
    anchor ??= spots.where((s) => s.spot.zone == mark.zone).map((s) => s.rect).firstOrNull;
    if (anchor == null) return const SizedBox.shrink();
    const chipW = 148.0;
    const chipH = 48.0;
    final toRight = anchor.center.dx < size.width * 0.58;
    final left = (toRight ? anchor.right + 6 : anchor.left - chipW - 6).clamp(4.0, math.max(4.0, size.width - chipW - 4)).toDouble();
    final top = (anchor.center.dy - chipH / 2).clamp(4.0, math.max(4.0, size.height - chipH - 4)).toDouble();
    return Positioned(left: left, top: top, child: _crossAsk());
  }

  Widget _crossAsk() {
    final asset = _mark?.asset;
    return Center(
      child: FittedBox(
        child: Material(
          color: const Color(0xF2FFF8EE),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _openAsk,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFC62828), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (asset != null) SizedBox(width: 40, height: 36, child: Image.asset(asset, fit: BoxFit.contain)),
                    const SizedBox(width: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(Icons.question_mark_rounded, color: Color(0xFF3A2A16), size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _cornerCoach => !_vanLesson && !_hero && _frontId.isEmpty;

  Widget _playCoach() {
    return Positioned(
      left: 4,
      bottom: 4,
      child: IgnorePointer(
        child: DsCoach(
          mood: _coachMood,
          line: _coachLine,
          bubbleWidth: 228,
        ),
      ),
    );
  }

  Widget _shelf() {
    final byId = {for (final piece in _kit) piece.id: piece};
    final seen = <String>{};
    final open = <_Piece>[];
    for (final id in _shelfOrder) {
      final piece = byId[id];
      if (piece != null && !_on.contains(id) && _shelfShows(id) && !_heldBack.contains(id) && seen.add(id)) open.add(piece);
    }
    for (final piece in _kit) {
      if (!_on.contains(piece.id) && _shelfShows(piece.id) && !_heldBack.contains(piece.id) && seen.add(piece.id)) open.add(piece);
    }
    return DragTarget<_Piece>(
      onWillAcceptWithDetails: (d) => _on.contains(d.data.id) && !(_fullLesson && _blockedTake(d.data)),
      onAcceptWithDetails: (d) => _take(d.data),
      builder: (context, candidate, _) {
        return AnimatedContainer(
          key: _shelfKey,
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            color: _vanLesson ? const Color(0xCCF6E7C8) : _roomLesson ? const Color(0xE61B140E) : null,
            border: Border(
              top: BorderSide(color: candidate.isNotEmpty ? const Color(0xFFC9A227) : const Color(0x00000000), width: 2),
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in open) KeyedSubtree(key: ValueKey(p.id), child: _token(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _token(_Piece piece) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Draggable<_Piece>(
          data: piece,
          onDragStarted: () => setState(() {
            _dragZone = _roomLesson
                ? 'bench'
                : piece.id == 'fingers'
                    ? (_fingerL ? 'gapR' : 'gapL')
                    : piece.zone;
            _clearMark();
          }),
          onDragEnd: (_) => setState(() => _dragZone = ''),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 84, height: 84, child: Image.asset(piece.asset, fit: BoxFit.contain)),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: _thumb(piece)),
          child: _thumb(piece),
        ),
      ],
    );
  }


  Widget _thumb(_Piece piece) {
    final full = _fullLesson || _roomLesson;
    final tall = _tallPiece(piece.id);
    return SizedBox(
      width: tall ? 34 : (full ? 50 : 64),
      height: tall ? 62 : (full ? 44 : 58),
      child: Image.asset(piece.asset, fit: BoxFit.contain),
    );
  }

  Widget _modal(String why) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(why, textAlign: TextAlign.center, style: zlText(16, weight: FontWeight.w700, height: 1.45, color: const Color(0xFF3A2A16))),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(_clearMark),
                      child: Text('বন্ধ', style: zlText(15, weight: FontWeight.w800, color: const Color(0xFF8C1D18))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewRingPainter extends CustomPainter {
  const _ReviewRingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x66FF3B30),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      t * math.pi * 2,
      1.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFF2A24),
    );
    final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      center,
      radius * (0.84 + 0.16 * wave),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = Color.fromARGB((60 + (150 * (1 - wave))).round(), 255, 64, 52),
    );
  }

  @override
  bool shouldRepaint(covariant _ReviewRingPainter oldDelegate) => oldDelegate.t != t;
}

class _WinGlow extends StatefulWidget {
  const _WinGlow({required this.child});

  final Widget child;

  @override
  State<_WinGlow> createState() => _WinGlowState();
}

class _WinGlowState extends State<_WinGlow> with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..repeat();
  }

  @override
  void dispose() {
    _burst.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_burst, _spin]),
      builder: (_, child) {
        final pop = Curves.easeOutBack.transform((_burst.value / 0.26).clamp(0.0, 1.0));
        final settle = Curves.easeOutCubic.transform(_burst.value.clamp(0.0, 1.0));
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _WinAuraPainter(
                      burst: still ? 1 : _burst.value,
                      spin: still ? 0.22 : _spin.value,
                      rich: !still,
                    ),
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: still ? 1.03 : 1 + 0.07 * pop * (1 - 0.5 * settle),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _WinAuraPainter extends CustomPainter {
  const _WinAuraPainter({required this.burst, required this.spin, required this.rich});

  final double burst;
  final double spin;
  final bool rich;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.46;
    final rx = size.width * 0.26;
    final ry = size.height * 0.36;
    final ignite = Curves.easeOut.transform((burst / 0.16).clamp(0.0, 1.0));
    final hold = Curves.easeOutCubic.transform(burst.clamp(0.0, 1.0));

    final coreRect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2.35, height: ry * 2.4);
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromARGB((230 * ignite).round(), 255, 252, 236),
          Color.fromARGB((170 * ignite).round(), 255, 204, 64),
          Color.fromARGB((92 * ignite).round(), 251, 146, 24),
          const Color(0x00F59E0B),
        ],
        stops: const [0.0, 0.26, 0.54, 1.0],
      ).createShader(coreRect);
    if (rich) core.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(coreRect, core);

    for (var i = 0; i < 3; i++) {
      final u = ((burst * 1.2) - i * 0.14).clamp(0.0, 1.0);
      if (u <= 0.02) continue;
      final grow = Curves.easeOutCubic.transform(u);
      final a = ((1 - u) * ignite * 0.92).clamp(0.0, 1.0);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, 3.4 - 1.6 * u)
        ..color = Color.fromARGB((230 * a).round(), 255, 220, 96);
      if (rich) ring.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * (1.05 + 1.95 * grow),
          height: ry * (1.02 + 1.62 * grow),
        ),
        ring,
      );
    }

    if (!rich) return;

    const n = 14;
    for (var i = 0; i < n; i++) {
      final dir = i.isEven ? 1.55 : -1.18;
      final ang = (i / n) * math.pi * 2 + spin * math.pi * 2 * dir;
      final rad = 0.58 + 0.26 * math.sin(spin * math.pi * 2 + i * 0.9);
      final out = 0.28 + 1.05 * hold;
      final p = Offset(
        cx + math.cos(ang) * rx * rad * out * 1.42,
        cy + math.sin(ang) * ry * rad * out * 1.18,
      );
      final flick = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(spin * math.pi * 8 + i * 1.7));
      final a = (210 * flick * ignite).round().clamp(0, 255);
      final spark = Paint()..color = Color.fromARGB(a, 255, i.isEven ? 244 : 196, i.isEven ? 176 : 58);
      canvas.drawCircle(p, 1.8 + 2.6 * flick, spark);
      canvas.drawCircle(
        p,
        4.6 + 3.2 * flick,
        Paint()
          ..color = Color.fromARGB((90 * flick * ignite).round().clamp(0, 255), 255, 230, 140)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_WinAuraPainter old) => old.burst != burst || old.spin != spin || old.rich != rich;
}

class _VanCheckRow extends StatelessWidget {
  const _VanCheckRow({super.key, required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) {
        final rise = t.clamp(0.0, 1.0);
        final tick = ((t - 0.42) / 0.58).clamp(0.0, 1.0);
        final pop = Curves.easeOutBack.transform(tick);
        return Opacity(
          opacity: rise,
          child: Transform.translate(
            offset: Offset(36 * (1 - rise), 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0x14F6E7B0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: asset.isEmpty ? const SizedBox.shrink() : Image.asset(asset, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: zlText(16, weight: FontWeight.w700, color: const Color(0xFFF6E7C8)))),
                  Transform.scale(
                    scale: pop,
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF7DCEA0), size: 26),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroEntrance extends StatelessWidget {
  const _HeroEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 780),
      curve: Curves.easeOutBack,
      builder: (_, t, child) {
        final rise = t.clamp(0.0, 1.0);
        final pop = t.clamp(0.0, 1.15);
        return Opacity(
          opacity: rise,
          child: Transform.translate(
            offset: Offset(0, 72 * (1 - rise)),
            child: Transform.scale(scale: 0.28 + 0.72 * pop, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

enum DsCoachMood { ready, talk, glad, oops, thanks }

class DsCoach extends StatefulWidget {
  const DsCoach({
    super.key,
    required this.mood,
    required this.line,
    this.bubbleWidth = 176,
    this.sprite = 96,
    this.centered = false,
  });

  final DsCoachMood mood;
  final String line;
  final double bubbleWidth;
  final double sprite;
  final bool centered;

  @override
  State<DsCoach> createState() => _DsCoachState();
}

class _DsCoachState extends State<DsCoach> with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final AnimationController _eyes;
  late final AnimationController _mouth;
  var _eyeLap = 0;
  var _eyeArmed = true;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..forward();
    _eyes = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
    _mouth = AnimationController(vsync: this, duration: const Duration(milliseconds: 1320));
    _eyes.addListener(_countLaps);
    _syncMouth();
  }

  void _countLaps() {
    if (_eyes.value < 0.03 && _eyeArmed) {
      _eyeArmed = false;
      _eyeLap++;
    } else if (_eyes.value > 0.2) {
      _eyeArmed = true;
    }
  }

  @override
  void didUpdateWidget(DsCoach old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _pop.forward(from: 0);
    if (old.mood != widget.mood || old.line != widget.line) _syncMouth(restart: true);
  }

  bool get _speaking => widget.mood == DsCoachMood.talk && widget.line.isNotEmpty;

  void _syncMouth({bool restart = false}) {
    if (_speaking) {
      if (restart || !_mouth.isAnimating) _mouth.repeat(period: const Duration(milliseconds: 1320));
    } else if (_mouth.isAnimating || _mouth.value != 0) {
      _mouth
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _eyes.removeListener(_countLaps);
    _pop.dispose();
    _eyes.dispose();
    _mouth.dispose();
    super.dispose();
  }

  String _asset(double t) {
    final blink = t > 0.06 && t < 0.13;
    final glance = _eyeLap.isOdd && t > 0.42 && t < 0.68;
    return switch (widget.mood) {
      DsCoachMood.thanks || DsCoachMood.glad => 'coach_happy',
      DsCoachMood.oops => blink
          ? 'coach_oops_blink'
          : glance
              ? 'coach_oops_glance'
              : 'coach_oops',
      DsCoachMood.talk => blink
          ? 'coach_talk_blink'
          : widget.line.isEmpty && glance
              ? 'coach_talk_glance'
              : 'coach_talk',
      DsCoachMood.ready => blink
          ? 'coach_blink'
          : glance
              ? 'coach_glance'
              : 'coach_ready',
    };
  }

  double _lipClose(double t) {
    const keys = <(double, double)>[
      (0.00, 0.16),
      (0.05, 0.00),
      (0.16, 0.00),
      (0.19, 1.00),
      (0.23, 0.00),
      (0.35, 0.00),
      (0.39, 0.58),
      (0.45, 0.00),
      (0.56, 0.00),
      (0.59, 1.00),
      (0.64, 0.00),
      (0.76, 0.00),
      (0.82, 0.34),
      (0.88, 0.00),
      (0.95, 0.86),
      (1.00, 0.16),
    ];
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i];
      final b = keys[i + 1];
      if (t < a.$1 || t > b.$1) continue;
      final u = ((t - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0);
      final snap = (b.$2 - a.$2).abs() > 0.7;
      final s = snap ? Curves.easeInOutQuart.transform(u) : Curves.easeInOutCubic.transform(u);
      return a.$2 + (b.$2 - a.$2) * s;
    }
    return keys.last.$2;
  }

  Widget _talkMouth() {
    final close = _lipClose(_mouth.value);
    if (close < 0.08) return const SizedBox.shrink();
    final s = widget.sprite;
    const imageAspect = 597 / 888;
    final imageW = s * imageAspect;
    final left = (s - imageW) / 2;
    return Positioned(
      left: left + imageW * 0.455,
      top: s * 0.442,
      width: imageW * 0.16,
      height: s * 0.076,
      child: CustomPaint(painter: _LipPainter(close)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oops = widget.mood == DsCoachMood.oops;
    final joy = widget.mood == DsCoachMood.thanks;
    final lift = joy || widget.mood == DsCoachMood.glad;
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _eyes, _mouth]),
      builder: (_, _) {
        final spring = Curves.elasticOut.transform(_pop.value.clamp(0.0, 1.0));
        final t = _eyes.value;
        final dx = oops ? math.sin(_pop.value * math.pi * 6) * 6 : 0.0;
        final hop = lift ? -12 * math.sin(_pop.value.clamp(0.0, 1.0) * math.pi) : 0.0;
        final nod = _speaking ? 1.4 * math.sin(_mouth.value * math.pi * 2) : 0.0;
        final asset = _asset(t);
        final align = widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
        final stars = widget.sprite > 120 ? 6 : 3;
        return Transform.translate(
          offset: Offset(dx, 28 * (1 - spring) + hop + nod),
          child: Transform.scale(
            scale: 0.72 + 0.28 * spring,
            alignment: widget.centered ? Alignment.center : Alignment.bottomLeft,
            child: SizedBox(
              width: widget.bubbleWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: align,
                children: [
                  if (widget.line.isNotEmpty) _CoachBubble(line: widget.line, bad: oops, maxWidth: widget.bubbleWidth),
                  if (widget.line.isNotEmpty) const SizedBox(height: 2),
                  SizedBox(
                    width: widget.sprite,
                    height: widget.sprite,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset('assets/duty_slip/dress/$asset.webp', fit: BoxFit.contain),
                        if (widget.mood == DsCoachMood.talk && widget.line.isNotEmpty) _talkMouth(),
                        if (joy)
                          for (var i = 0; i < stars; i++)
                            Positioned(
                              left: widget.sprite * 0.72 + 18 * math.cos(t * math.pi * 2 + i * 1.05),
                              top: 4 + 16 * math.sin(t * math.pi * 2 + i),
                              child: Icon(Icons.auto_awesome, size: widget.sprite > 120 ? 18 : 14, color: const Color(0xFFE2B15A)),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LipPainter extends CustomPainter {
  const _LipPainter(this.close);

  final double close;

  @override
  void paint(Canvas canvas, Size size) {
    final c = close.clamp(0.0, 1.0);
    if (c < 0.06 || size.width < 2 || size.height < 2) return;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromLTWH(0, size.height * 0.04, size.width, size.height * 0.92)),
    );
    final skin = Paint()..color = const Color(0xFFC67C4C);
    final meet = size.height * 0.40;
    final upperH = (meet + size.height * 0.08) * c;
    final lowerH = (size.height - meet + size.height * 0.08) * c;
    final upper = Path()
      ..moveTo(-2, -2)
      ..lineTo(size.width + 2, -2)
      ..lineTo(size.width + 2, upperH * 0.62)
      ..quadraticBezierTo(size.width * 0.5, upperH * 1.18, -2, upperH * 0.62)
      ..close();
    canvas.drawPath(upper, skin);
    final ly = size.height - lowerH;
    final lower = Path()
      ..moveTo(-2, size.height + 2)
      ..lineTo(size.width + 2, size.height + 2)
      ..lineTo(size.width + 2, ly + lowerH * 0.42)
      ..quadraticBezierTo(size.width * 0.5, ly - lowerH * 0.16, -2, ly + lowerH * 0.42)
      ..close();
    canvas.drawPath(lower, skin);
    if (c > 0.82) {
      final lip = Paint()
        ..color = const Color(0xFF2C1A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.15, size.width * 0.048)
        ..strokeCap = StrokeCap.round;
      final smile = Path()
        ..moveTo(size.width * 0.20, meet)
        ..quadraticBezierTo(size.width * 0.5, meet + size.height * 0.14, size.width * 0.80, meet);
      canvas.drawPath(smile, lip);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LipPainter old) => old.close != close;
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.line, required this.bad, required this.maxWidth});

  final String line;
  final bool bad;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: bad ? const Color(0xFFFFF1F0) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Text(enDigits(line), style: zlText(13, weight: FontWeight.w700, height: 1.35, color: const Color(0xFF3A2A16))),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 12, height: 12, color: bad ? const Color(0xFFFFF1F0) : Colors.white),
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.step, required this.color});

  final int step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _StepIconPainter(step, color));
  }
}

class _StepIconPainter extends CustomPainter {
  const _StepIconPainter(this.step, this.color);

  final int step;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    switch (step) {
      case 0:
        canvas.drawCircle(Offset(w * 0.50, h * 0.32), w * 0.15, p);
        canvas.drawArc(Rect.fromLTWH(w * 0.20, h * 0.46, w * 0.60, h * 0.42), math.pi, math.pi, false, p);
      case 1:
        canvas.drawArc(Rect.fromLTWH(w * 0.10, h * 0.22, w * 0.36, h * 0.40), math.pi, math.pi, false, p);
        canvas.drawArc(Rect.fromLTWH(w * 0.54, h * 0.22, w * 0.36, h * 0.40), math.pi, math.pi, false, p);
        canvas.drawLine(Offset(w * 0.28, h * 0.62), Offset(w * 0.28, h * 0.86), p);
        canvas.drawLine(Offset(w * 0.72, h * 0.62), Offset(w * 0.72, h * 0.86), p);
      case 2:
        canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(w * 0.32, h * 0.50), p);
        canvas.drawLine(Offset(w * 0.68, h * 0.50), Offset(w * 0.92, h * 0.50), p);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.30, w * 0.36, h * 0.40), const Radius.circular(2)), p);
      case 3:
        canvas.drawLine(Offset(w * 0.50, h * 0.08), Offset(w * 0.50, h * 0.30), p);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.40, h * 0.32), const Radius.circular(2)), p);
        canvas.drawLine(Offset(w * 0.50, h * 0.62), Offset(w * 0.50, h * 0.90), p);
      case 4:
        canvas.drawArc(Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.56), 0.15, math.pi - 0.3, false, p);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.58, w * 0.28, h * 0.24), const Radius.circular(2)), p);
      case 5:
        canvas.drawCircle(Offset(w * 0.64, h * 0.56), w * 0.18, p);
        canvas.drawLine(Offset(w * 0.12, h * 0.28), Offset(w * 0.50, h * 0.52), p);
      case 6:
        canvas.drawCircle(Offset(w * 0.46, h * 0.26), w * 0.15, p);
        canvas.drawArc(Rect.fromLTWH(w * 0.22, h * 0.40, w * 0.48, h * 0.36), 0, math.pi, false, p);
        canvas.drawCircle(Offset(w * 0.74, h * 0.36), 2.4, Paint()..color = color);
      default:
        canvas.drawLine(Offset(w * 0.16, h * 0.36), Offset(w * 0.84, h * 0.36), p);
        canvas.drawLine(Offset(w * 0.40, h * 0.36), Offset(w * 0.40, h * 0.80), p);
        canvas.drawLine(Offset(w * 0.58, h * 0.36), Offset(w * 0.58, h * 0.80), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StepIconPainter old) => old.step != step || old.color != color;
}

class _GuideMark extends StatelessWidget {
  const _GuideMark({required this.tick, required this.cross, required this.live, required this.t});

  final bool tick;
  final bool cross;
  final bool live;
  final double t;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _GuideMarkPainter(tick: tick, cross: cross, live: live, t: t),
    );
  }
}

class _GuideMarkPainter extends CustomPainter {
  const _GuideMarkPainter({required this.tick, required this.cross, required this.live, required this.t});

  final bool tick;
  final bool cross;
  final bool live;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final color = cross ? const Color(0xFFB4332A) : tick || live ? const Color(0xFFC9A227) : const Color(0xFFC9B89A);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = live ? 2.4 : 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, 7.2, pen);
    if (tick) {
      final check = Path()
        ..moveTo(size.width * 0.28, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.68)
        ..lineTo(size.width * 0.74, size.height * 0.34);
      final metric = check.computeMetrics().first;
      final drawn = metric.extractPath(0, metric.length * t.clamp(0.0, 1.0).toDouble());
      canvas.drawPath(
        drawn,
        pen
          ..color = const Color(0xFF2F6B3A)
          ..strokeWidth = 2.2,
      );
    }
    if (cross) {
      final ink = Paint()
        ..color = const Color(0xFFB4332A).withValues(alpha: t.clamp(0.0, 1.0))
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(size.width * 0.32, size.height * 0.32), Offset(size.width * 0.68, size.height * 0.68), ink);
      canvas.drawLine(Offset(size.width * 0.68, size.height * 0.32), Offset(size.width * 0.32, size.height * 0.68), ink);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideMarkPainter old) => old.tick != tick || old.cross != cross || old.live != live || old.t != t;
}

class DsYardPainter extends CustomPainter {
  const DsYardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Offset(size.width * 0.82, size.height * 0.10);
    canvas.drawCircle(sun, size.width * 0.09, Paint()..color = const Color(0x55FFF1C2));
    canvas.drawCircle(sun, size.width * 0.038, Paint()..color = const Color(0x99FFE7A0));
    final horizon = size.height * 0.40;
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 1.2,
    );
    void pole(double x, double h) {
      final ink = Paint()
        ..color = const Color(0x443A2A16)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, horizon), Offset(x, horizon - h), ink);
      canvas.drawLine(Offset(x - 8, horizon - h), Offset(x + 14, horizon - h - 4), ink);
    }

    pole(size.width * 0.08, size.height * 0.11);
    pole(size.width * 0.46, size.height * 0.08);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
