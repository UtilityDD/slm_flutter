import 'package:flutter/widgets.dart';

import 'content_catalog.dart';
import 'discharge_order.dart';
import 'distance_spot.dart';
import 'fire_choose.dart';
import 'fire_pass.dart';
import 'glove_check.dart';
import 'golden_minute.dart';
import 'harness_check.dart';
import 'harness_fit.dart';
import 'kit_check.dart';
import 'level_shell.dart';
import 'pole_read.dart';
import 'ptw_match.dart';
import 'ptw_steps.dart';
import 'rod_pick.dart';
import 'shock_rescue.dart';
import 'sky_read.dart';
import 'storm_push.dart';
import 'tool_tip.dart';

/// Builds the page of a Do game inside the level shell.
typedef DoGameBuilder = Widget Function(LevelContext ctx, bool muted);

/// The Do game for a catalog pack: its `engineType` names the game, its `id`
/// picks the content. Null = no shell game yet; the ladder then opens the old
/// level named by `legacyLevel`. A lesson may have any number of Do rungs,
/// each with its own pack, so each can be a different game.
DoGameBuilder? doGameFor(CatalogGamePack pack) {
  switch (pack.engineType) {
    case 'kit_check':
      final content = kitCheckPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => KitCheckPage(ctx: ctx, pack: content, muted: muted);
    case 'glove_check':
      final content = gloveCheckPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => GloveCheckPage(ctx: ctx, pack: content, muted: muted);
    case 'distance_spot':
      final content = distancePacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => DistanceSpotPage(ctx: ctx, pack: content, muted: muted);
    case 'tool_tip':
      final content = toolTipPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => ToolTipPage(ctx: ctx, pack: content, muted: muted);
    case 'harness_check':
      final content = harnessPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => HarnessCheckPage(ctx: ctx, pack: content, muted: muted);
    case 'harness_fit':
      final content = fitPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => HarnessFitPage(ctx: ctx, pack: content, muted: muted);
    case 'pole_read':
      final content = poleReadPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => PoleReadPage(ctx: ctx, pack: content, muted: muted);
    case 'ptw_match':
      final content = ptwPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => PtwMatchPage(ctx: ctx, pack: content, muted: muted);
    case 'ptw_steps':
      final content = stepsPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => PtwStepsPage(ctx: ctx, pack: content, muted: muted);
    case 'golden_minute':
      final content = goldenPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => GoldenMinutePage(ctx: ctx, pack: content, muted: muted);
    case 'fire_choose':
      final content = firePacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => FireChoosePage(ctx: ctx, pack: content, muted: muted);
    case 'fire_pass':
      final content = passPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => FirePassPage(ctx: ctx, pack: content, muted: muted);
    case 'shock_rescue':
      final content = rescuePacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => ShockRescuePage(ctx: ctx, pack: content, muted: muted);
    case 'rod_pick':
      final content = rodPickPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => RodPickPage(ctx: ctx, pack: content, muted: muted);
    case 'discharge_order':
      final content = dischargePacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => DischargeOrderPage(ctx: ctx, pack: content, muted: muted);
    case 'sky_read':
      final content = skyReadPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => SkyReadPage(ctx: ctx, pack: content, muted: muted);
    case 'storm_push':
      final content = stormPushPacks[pack.id];
      if (content == null) return null;
      return (ctx, muted) => StormPushPage(ctx: ctx, pack: content, muted: muted);
  }
  return null;
}
