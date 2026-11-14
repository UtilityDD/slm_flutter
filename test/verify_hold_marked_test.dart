import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/auth/verify_hold.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh signup is flipped to unverified only once per user', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final hold = c.read(verifyHoldProvider.notifier);

    expect(await hold.wasMarked('u1'), isFalse);
    await hold.markOnce('u1');
    await hold.markOnce('u1');
    expect(await hold.wasMarked('u1'), isTrue);
    expect(await hold.wasMarked('u2'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('slm_verify_marked'), ['u1']);
  });

  test('an empty id is never recorded', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final hold = c.read(verifyHoldProvider.notifier);
    await hold.markOnce('');
    expect(await hold.wasMarked(''), isFalse);
  });
}
