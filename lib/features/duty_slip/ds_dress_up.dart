import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  _Piece(id: 'fatua', asset: 'assets/duty_slip/dress/tray_fatua.webp', zone: 'torso', good: false, why: 'ফতুয়া ঢিলা। তারে জড়িয়ে যায়। বিদ্যুতের কাজে সুতির ফুল শার্ট পরুন।'),
  _Piece(id: 'halftee', asset: 'assets/duty_slip/dress/tray_halftee.webp', zone: 'torso', good: false, why: 'হাফ টি-শার্টে হাত খোলা থাকে। হাতাওয়ালা সুতির শার্ট চাই।'),
  _Piece(id: 'poly', asset: 'assets/duty_slip/dress/tray_poly.webp', zone: 'torso', good: false, why: 'পলিয়েস্টার শার্ট আর্কে গলে গায়ের সঙ্গে লেগে যায়। বিদ্যুতের কাজে সুতির ফুল শার্ট পরুন।'),
  _Piece(id: 'shirt', asset: 'assets/duty_slip/dress/tray_shirt.webp', zone: 'torso', good: true, why: ''),
  _Piece(id: 'halfpant', asset: 'assets/duty_slip/dress/tray_halfpant.webp', zone: 'legs', good: false, why: 'হাফপ্যান্টে পা খোলা থাকে। সুতির ফুল প্যান্ট পরুন।'),
  _Piece(id: 'pajama', asset: 'assets/duty_slip/dress/tray_pajama.webp', zone: 'legs', good: false, why: 'ঢিলা পাজামা যন্ত্রে জড়ায়। সুতির ফুল প্যান্ট পরুন।'),
  _Piece(id: 'pant', asset: 'assets/duty_slip/dress/tray_pant.webp', zone: 'legs', good: true, why: ''),
  _Piece(id: 'slip', asset: 'assets/duty_slip/dress/tray_slipper.webp', zone: 'feet', good: false, why: 'চপ্পলে পা পিছলায়। সেফটি সু পরুন।'),
  _Piece(id: 'normal', asset: 'assets/duty_slip/dress/tray_normalshoe.webp', zone: 'feet', good: false, why: 'সাধারণ জুতোয় সেফটি সোল নেই। সেফটি সু পরুন।'),
  _Piece(id: 'boot', asset: 'assets/duty_slip/dress/tray_boot.webp', zone: 'feet', good: true, why: ''),
];

const _shoeBlock = 'জুতো পরা থাকলে প্যান্ট ওঠে না। আগে প্যান্ট, তারপর সেফটি সু।';

const _headPieces = <_Piece>[
  _Piece(id: 'gamcha', asset: 'assets/duty_slip/dress/tray_gamcha.webp', zone: 'head', good: true, why: ''),
  _Piece(id: 'road', asset: 'assets/duty_slip/dress/tray_road_helmet.webp', zone: 'head', good: false, why: 'এটা রাস্তার হেলমেট। বিদ্যুতের কাজে এটা বসবে না। শক আটকায় না।'),
  _Piece(id: 'vent', asset: 'assets/duty_slip/dress/tray_vent_helmet.webp', zone: 'head', good: false, why: 'এই হেলমেটে বাতাসের ফুটো আছে। ফুটো দিয়ে জল ঢোকে, শকও আটকায় না। বিদ্যুতের হেলমেট বন্ধ থাকে, চিবুকে ফিতা বাঁধা থাকে।'),
  _Piece(id: 'helmet', asset: 'assets/duty_slip/dress/tray_elec_helmet.webp', zone: 'head', good: true, why: ''),
];

const _gamchaBlock = 'গামছার ওপর হেলমেট বসে না। আগে গামছা নামান।';
const _gamchaNoSave = 'এটা বিপদ থেকে বাঁচাবে না। গামছা নয়, বিদ্যুতের হেলমেট পরুন।';

const _handPieces = <_Piece>[
  _Piece(id: 'cotton', asset: 'assets/duty_slip/dress/tray_cotton_gloves.webp', zone: 'hands', good: false, why: 'সুতির গ্লাভস শক আটকায় না। বিদ্যুতের রাবার গ্লাভস পরুন।'),
  _Piece(id: 'wet', asset: 'assets/duty_slip/dress/tray_wet_gloves.webp', zone: 'hands', good: false, why: 'ভেজা গ্লাভসে জল আছে। জল বিদ্যুৎ বয়ে আনে। শুকনো বিদ্যুতের গ্লাভস পরুন।'),
  _Piece(id: 'hole', asset: 'assets/duty_slip/dress/tray_hole_gloves.webp', zone: 'hands', good: false, why: 'এই গ্লাভসে ছোট ছিদ্র আছে। ছিদ্র দিয়ে শক ঢোকে। ছেঁড়া গ্লাভস পরবেন না।'),
  _Piece(id: 'bike', asset: 'assets/duty_slip/dress/tray_bike_gloves.webp', zone: 'hands', good: false, why: 'এটা বাইকের গ্লাভস। বিদ্যুতের কাজে এটা বসবে না। শক আটকায় না।'),
  _Piece(id: 'rubber', asset: 'assets/duty_slip/dress/tray_rubber_gloves.webp', zone: 'hands', good: true, why: ''),
];

const _gloveBlock = 'গ্লাভস পরা থাকলে বাকল বন্ধ করবেন কীভাবে? আগে গ্লাভস খুলুন।';
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
  _Piece(id: 'belt', asset: 'assets/duty_slip/dress/tray_waist_belt.webp', zone: 'torso', good: false, why: 'কোমরের বেল্ট পড়ে গেলে বাঁচায় না। ফুল বডি হারনেস পরুন।'),
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

const _earlyStep = 'এই ধাপ এখনো না। আগেরটা আগে।';
const _tapStep = 'এই ধাপ তালিকায় টিপুন।';

const _guideRows = <_GuideRow>[
  _GuideRow('রিং ধরুন', 'head_helmet', 'gPalm', 'harness', 'পিঠের রিং হাতের কাছে তুলুন।'),
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
class DsDressUp extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onDone;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, Offset global) onDelta;

  const DsDressUp({
    super.key,
    required this.engine,
    required this.onDone,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
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

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
    _link = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _rowFx = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    if (_headLesson) _on.add('gamcha');
    if (_harnessLesson) _on.add('rubber');
    _mixShelf(sound: false);
    widget.engine.beginDress();
    ZlFx.holdClock();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: widget.muted));
    final hello = switch (widget.engine.level.number) {
      2 => 'মাথার জিনিস টেনে ছোঁয়ান।',
      3 => 'হাতের গ্লাভস টেনে ছোঁয়ান।',
      4 => 'গ্লাভস খুলে হারনেস একবার হাতে ছোঁয়ান। তারপর তালিকায় টিপুন।',
      5 => 'সব জিনিস টেনে ঠিক জায়গায় ছোঁয়ান।',
      _ => 'পোশাক টেনে শরীরে ছোঁয়ান।',
    };
    _coachSay = hello;
    unawaited(widget.onSpeak(hello));
    _holdCoach(const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _markTimer?.cancel();
    _sway.dispose();
    _shake.dispose();
    _link.dispose();
    _rowFx.dispose();
    _coachTimer?.cancel();
    ZlFx.releaseClock();
    super.dispose();
  }

  bool get _headLesson => widget.engine.level.number == 2;

  bool get _handsLesson => widget.engine.level.number == 3;

  bool get _harnessLesson => widget.engine.level.number == 4;

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
    _mark = null;
    _ask = false;
    if (!_finishing) _coachFace = DsCoachMood.ready;
  }

  void _holdCoach(Duration hold) {
    _coachTimer?.cancel();
    _coachTimer = Timer(hold, () {
      if (!mounted || _finishing || _mark != null) return;
      setState(() => _coachFace = DsCoachMood.ready);
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

  void _armMark(_Mark mark) {
    _markTimer?.cancel();
    _mark = mark;
    _ask = false;
    _markTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _ask) return;
      setState(_clearMark);
    });
  }

  void _mixShelf({required bool sound}) {
    final ids = [for (final piece in _kit) if (!_on.contains(piece.id)) piece.id];
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
    _coachTimer?.cancel();
    _coachFace = DsCoachMood.oops;
    _coachSay = why;
    _mixShelf(sound: true);
    setState(() => _armMark(_Mark(zone, why, piece.asset)));
    _holdCoach(const Duration(seconds: 3));
    unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: widget.muted));
    unawaited(widget.onSpeak(why));
    HapticFeedback.heavyImpact();
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
    HapticFeedback.mediumImpact();
    if (!_finishing) _showCoach(DsCoachMood.glad, 'ঠিক আছে।', const Duration(milliseconds: 900));
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
    unawaited(widget.onSpeak(glovesOn ? 'হারনেস সামনে আছে। আগে গ্লাভস খুলুন।' : 'পিঠের রিং ধরে হাতের কাছে তুলুন।'));
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
        const ring = 'পিঠে ডি রিংয়ের পজিশন চেক করুন।';
        _showCoach(DsCoachMood.talk, ring, const Duration(seconds: 4));
        unawaited(widget.onSpeak(ring));
      }
      if (next >= _guideRows.length) _doneLesson('হারনেস ঠিক আছে। নড়াচড়া করা যায়।');
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

  void _wear(_Piece piece, Offset global) {
    if (_finishing || _on.contains(piece.id)) return;
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
      2 => 'ঠিক আছে। এভাবেই হেলমেট পরুন।',
      3 => 'ঠিক আছে। এভাবেই গ্লাভস পরুন।',
      5 => 'ঠিক আছে। এভাবেই পুরো কিট পরুন।',
      _ => 'ঠিক আছে। এভাবেই কাজে যান।',
    });
  }

  bool _blockedTake(_Piece piece) {
    if (piece.id == 'helmet' && _on.contains('shield')) return true;
    if (piece.id == 'harness' && _on.contains('helmet')) return true;
    if ((piece.id == 'shirt' || piece.id == 'pant' || piece.id == 'boot') && _on.contains('harness')) return true;
    return false;
  }

  void _take(_Piece piece) {
    if (_finishing || !_on.contains(piece.id)) return;
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6E2B8), Color(0xFFE7C98A), Color(0xFFC9A36A)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _hero ? 0 : 1,
                      duration: const Duration(milliseconds: 460),
                      curve: Curves.easeInOutCubic,
                      child: IgnorePointer(
                        ignoring: _finishing,
                        child: _glow
                            ? _WinGlow(
                                pulse: _sway,
                                child: _harnessLesson
                                    ? Row(
                                        children: [
                                          Expanded(child: _bobbingMan()),
                                          _guideRail(),
                                        ],
                                      )
                                    : _bobbingMan(),
                              )
                            : _harnessLesson
                                ? Row(
                                    children: [
                                      Expanded(child: _bobbingMan()),
                                      _guideRail(),
                                    ],
                                  )
                                : _bobbingMan(),
                      ),
                    ),
                    if (_hero)
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
              AnimatedSlide(
                offset: _hero ? const Offset(0, 0.45) : Offset.zero,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: _hero ? 0 : 1,
                  duration: const Duration(milliseconds: 420),
                  child: IgnorePointer(ignoring: _finishing, child: _shelf()),
                ),
              ),
            ],
          ),
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
    if (_finishing) return false;
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

  Widget _coachSlot() {
    return SizedBox(
      width: 96,
      height: 96,
      child: OverflowBox(
        alignment: Alignment.bottomLeft,
        maxWidth: 210,
        maxHeight: 340,
        child: IgnorePointer(
          child: DsCoach(mood: _coachMood, line: _coachLine, bubbleWidth: 200),
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
      if (piece != null && !_on.contains(id) && seen.add(id)) open.add(piece);
    }
    for (final piece in _kit) {
      if (!_on.contains(piece.id) && seen.add(piece.id)) open.add(piece);
    }
    return DragTarget<_Piece>(
      onWillAcceptWithDetails: (d) => _on.contains(d.data.id) && !(_fullLesson && _blockedTake(d.data)),
      onAcceptWithDetails: (d) => _take(d.data),
      builder: (context, candidate, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: candidate.isNotEmpty ? const Color(0xFFC9A227) : const Color(0x00000000), width: 2),
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (!_hero) _coachSlot(),
              for (final p in open) KeyedSubtree(key: ValueKey(p.id), child: _token(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _token(_Piece piece) {
    return Draggable<_Piece>(
      data: piece,
      onDragStarted: () => setState(() {
        _dragZone = piece.id == 'fingers' ? (_fingerL ? 'gapR' : 'gapL') : piece.zone;
        _clearMark();
      }),
      onDragEnd: (_) => setState(() => _dragZone = ''),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 84, height: 84, child: Image.asset(piece.asset, fit: BoxFit.contain)),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: _thumb(piece)),
      child: _thumb(piece),
    );
  }

  Widget _thumb(_Piece piece) {
    final full = _fullLesson;
    return SizedBox(width: full ? 50 : 64, height: full ? 44 : 58, child: Image.asset(piece.asset, fit: BoxFit.contain));
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

class _WinGlow extends StatelessWidget {
  const _WinGlow({required this.pulse, required this.child});

  final Animation<double> pulse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(pulse.value);
        final bias = 16 + 42 * t;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.62 + 0.08 * t,
                      colors: [
                        Color.fromARGB((70 + (80 * t).round()), 255, 196, 64),
                        const Color(0x00FFC840),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 1 + 0.03 * t,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  1, 0, 0, 0, bias,
                  0, 1, 0, 0, bias * 0.7,
                  0, 0, 1, 0, bias * 0.08,
                  0, 0, 0, 1, 0,
                ]),
                child: child,
              ),
            ),
          ],
        );
      },
      child: child,
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
  var _eyeLap = 0;
  var _eyeArmed = true;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 640))..forward();
    _eyes = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
    _eyes.addListener(_countLaps);
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
  }

  @override
  void dispose() {
    _eyes.removeListener(_countLaps);
    _pop.dispose();
    _eyes.dispose();
    super.dispose();
  }

  String _asset(double t) {
    return switch (widget.mood) {
      DsCoachMood.thanks || DsCoachMood.glad => 'coach_happy',
      DsCoachMood.oops => 'coach_oops',
      DsCoachMood.talk => 'coach_talk',
      DsCoachMood.ready => t > 0.06 && t < 0.13
          ? 'coach_blink'
          : _eyeLap.isOdd && t > 0.42 && t < 0.68
              ? 'coach_glance'
              : 'coach_ready',
    };
  }

  @override
  Widget build(BuildContext context) {
    final oops = widget.mood == DsCoachMood.oops;
    final joy = widget.mood == DsCoachMood.thanks;
    final lift = joy || widget.mood == DsCoachMood.glad;
    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _eyes]),
      builder: (_, _) {
        final spring = Curves.elasticOut.transform(_pop.value.clamp(0.0, 1.0));
        final dx = oops ? math.sin(_pop.value * math.pi * 6) * 6 : 0.0;
        final hop = lift ? -12 * math.sin(_pop.value.clamp(0.0, 1.0) * math.pi) : 0.0;
        final asset = _asset(_eyes.value);
        final align = widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
        final stars = widget.sprite > 120 ? 6 : 3;
        return Transform.translate(
          offset: Offset(dx, 28 * (1 - spring) + hop),
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
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset('assets/duty_slip/dress/$asset.webp', fit: BoxFit.contain),
                        if (joy)
                          for (var i = 0; i < stars; i++)
                            Positioned(
                              left: widget.sprite * 0.72 + 18 * math.cos(_eyes.value * math.pi * 2 + i * 1.05),
                              top: 4 + 16 * math.sin(_eyes.value * math.pi * 2 + i),
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
          child: Text(line, style: zlText(13, weight: FontWeight.w700, height: 1.35, color: const Color(0xFF3A2A16))),
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
