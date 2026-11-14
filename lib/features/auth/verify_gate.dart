import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/lineman_profile.dart';
import '../admin/dev_unlock.dart';
import 'auth_provider.dart';
import 'verify_hold.dart';

const gameOpenThrough = 5;

bool linemanIsVerified(AuthState auth, Set<String> holds) {
  if (auth.isAdmin) return true;
  final profile = auth.profile;
  if (profile == null || profile.isGuest) return false;
  if (profile.role == 'pending') return false;
  if (profile.verified == true) return true;
  if (profile.verified == false) return false;
  if (holds.contains(profile.id)) return false;
  return true;
}

/// Someone who already has progress keeps the lessons and games they earned.
/// A verify tick does not take that away, and it does not touch web play.
bool _alreadyPlaying(LinemanProfile? profile) {
  if (profile == null || profile.isGuest) return false;
  if (profile.points > 0) return true;
  if (profile.trainingLevel > 1) return true;
  return profile.completedLessons.isNotEmpty;
}

bool gameNeedsVerify(
  AuthState auth,
  Set<String> holds,
  bool devOpen,
  int level,
) {
  if (_alreadyPlaying(auth.profile)) return false;
  return !linemanIsVerified(auth, holds) && !devOpen && level > gameOpenThrough;
}

bool gameNeedsVerifyNow(BuildContext context, int level) {
  final container = ProviderScope.containerOf(context);
  return gameNeedsVerify(
    container.read(authProvider),
    container.read(verifyHoldProvider),
    container.read(devUnlockProvider),
    level,
  );
}
