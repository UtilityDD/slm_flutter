import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/dev_unlock.dart';
import 'auth_provider.dart';
import 'verify_hold.dart';

const lessonOpenThrough = 3;
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

bool lessonNeedsVerify(
  AuthState auth,
  Set<String> holds,
  bool devOpen,
  int step,
) {
  return !linemanIsVerified(auth, holds) &&
      !devOpen &&
      step > lessonOpenThrough;
}

bool gameNeedsVerify(
  AuthState auth,
  Set<String> holds,
  bool devOpen,
  int level,
) {
  return !linemanIsVerified(auth, holds) && !devOpen && level > gameOpenThrough;
}

bool lessonNeedsVerifyNow(BuildContext context, int step) {
  final container = ProviderScope.containerOf(context);
  return lessonNeedsVerify(
    container.read(authProvider),
    container.read(verifyHoldProvider),
    container.read(devUnlockProvider),
    step,
  );
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
