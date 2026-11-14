import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/home/reader/reader_prefs.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('ReaderTextSize', () {
    test('scales', () {
      expect(ReaderTextSize.small.scale, 0.9);
      expect(ReaderTextSize.normal.scale, 1.0);
      expect(ReaderTextSize.large.scale, 1.15);
    });

    test('defaults to normal, steps and clamps', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(readerTextSizeProvider.notifier);
      expect(c.read(readerTextSizeProvider), ReaderTextSize.normal);
      await _settle();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.normal);

      n.bigger();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.large);
      n.bigger();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.large);
      n.smaller();
      n.smaller();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.small);
      n.smaller();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.small);
      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reader.textSize'), 'small');
    });

    test('loads the saved size after the first read', () async {
      SharedPreferences.setMockInitialValues({'reader.textSize': 'large'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      // First frame gets the default without waiting.
      expect(c.read(readerTextSizeProvider), ReaderTextSize.normal);
      await _settle();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.large);
    });

    test('a tap during loading beats the saved value', () async {
      SharedPreferences.setMockInitialValues({'reader.textSize': 'large'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(readerTextSizeProvider.notifier).smaller();
      await _settle();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.small);
    });

    test('ignores unknown saved values', () async {
      SharedPreferences.setMockInitialValues({'reader.textSize': 'huge'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(readerTextSizeProvider);
      await _settle();
      expect(c.read(readerTextSizeProvider), ReaderTextSize.normal);
    });
  });

  group('ReaderTheme', () {
    test('defaults to system, persists and restores', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(readerThemeProvider), ReaderTheme.system);
      await _settle();
      c.read(readerThemeProvider.notifier).setTheme(ReaderTheme.night);
      expect(c.read(readerThemeProvider), ReaderTheme.night);
      await _settle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reader.theme'), 'night');

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(readerThemeProvider);
      await _settle();
      expect(c2.read(readerThemeProvider), ReaderTheme.night);
    });

    test('cycle goes day, night, system', () async {
      SharedPreferences.setMockInitialValues({'reader.theme': 'day'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(readerThemeProvider);
      await _settle();
      final n = c.read(readerThemeProvider.notifier);
      expect(c.read(readerThemeProvider), ReaderTheme.day);
      n.cycle();
      expect(c.read(readerThemeProvider), ReaderTheme.night);
      n.cycle();
      expect(c.read(readerThemeProvider), ReaderTheme.system);
      n.cycle();
      expect(c.read(readerThemeProvider), ReaderTheme.day);
    });

    Future<Map<ReaderTheme, bool>> nightFor(WidgetTester t, Brightness platform) async {
      t.platformDispatcher.platformBrightnessTestValue = platform;
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      late Map<ReaderTheme, bool> out;
      await t.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          out = {for (final th in ReaderTheme.values) th: readerIsNight(context, th)};
          return const SizedBox();
        }),
      ));
      return out;
    }

    testWidgets('readerIsNight follows the phone for system', (t) async {
      final dark = await nightFor(t, Brightness.dark);
      expect(dark, {ReaderTheme.day: false, ReaderTheme.night: true, ReaderTheme.system: true});
      final light = await nightFor(t, Brightness.light);
      expect(light, {ReaderTheme.day: false, ReaderTheme.night: true, ReaderTheme.system: false});
    });
  });
}
