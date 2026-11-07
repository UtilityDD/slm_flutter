import 'package:flutter/widgets.dart';

import 'content_catalog.dart';
import 'glove_check.dart';
import 'kit_check.dart';
import 'level_shell.dart';

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
  }
  return null;
}
