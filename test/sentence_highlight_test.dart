import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/home/reader/sentence_highlight.dart';

void main() {
  group('splitBanglaSentences', () {
    test('splits on danda and keeps it', () {
      expect(splitBanglaSentences('লাইন বন্ধ করুন। আর্থিং দিন।'), ['লাইন বন্ধ করুন।', 'আর্থিং দিন।']);
    });

    test('decimal numbers stay whole', () {
      expect(splitBanglaSentences('দূরত্ব ৬.৫ মিটার। তারপর কাজ।'), ['দূরত্ব ৬.৫ মিটার।', 'তারপর কাজ।']);
      expect(splitBanglaSentences('৬.৫ মিটার।'), ['৬.৫ মিটার।']);
      expect(splitBanglaSentences('Keep 6.5 m away. Then work.'), ['Keep 6.5 m away.', 'Then work.']);
    });

    test('kV and other abbreviations stay whole', () {
      expect(splitBanglaSentences('11 kV লাইনে কাজ। সাবধান।'), ['11 kV লাইনে কাজ।', 'সাবধান।']);
      expect(splitBanglaSentences('এটা 11 kV. লাইন, e.g. ফিডার।'), ['এটা 11 kV. লাইন, e.g. ফিডার।']);
    });

    test('question and exclamation marks end sentences', () {
      expect(splitBanglaSentences('গ্লাভস পরেছেন? না!! এখনই পরুন।'), ['গ্লাভস পরেছেন?', 'না!!', 'এখনই পরুন।']);
      expect(splitBanglaSentences('কেন?! কারণ জীবন আগে।'), ['কেন?!', 'কারণ জীবন আগে।']);
    });

    test('newlines split, trims and drops empties', () {
      expect(splitBanglaSentences('  প্রথম লাইন\n\n   দ্বিতীয় লাইন।  \n'), ['প্রথম লাইন', 'দ্বিতীয় লাইন।']);
      expect(splitBanglaSentences(''), isEmpty);
      expect(splitBanglaSentences('   \n  '), isEmpty);
    });

    test('closing quote stays with its sentence; text without end mark kept', () {
      expect(splitBanglaSentences('তিনি বললেন, "থামুন!" তারপর চলে গেলেন'),
          ['তিনি বললেন, "থামুন!"', 'তারপর চলে গেলেন']);
    });

    test('list numbers are not sentence ends', () {
      expect(splitBanglaSentences('1. শাটডাউন নিন।'), ['1. শাটডাউন নিন।']);
    });
  });

  group('HighlightedParagraph', () {
    const text = 'প্রথম বাক্য। দ্বিতীয় বাক্য? তৃতীয়!';
    const style = TextStyle(fontSize: 18, color: Color(0xCC112233));
    const hl = Color(0xFFFFC107);

    Future<TextSpan> spanOf(WidgetTester t, int? active) async {
      await t.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ));
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: HighlightedParagraph(text: text, activeSentence: active, style: style, highlight: hl),
      ));
      expect(find.byType(RichText), findsOneWidget);
      final rich = t.widget<RichText>(find.byType(RichText));
      return rich.text as TextSpan;
    }

    TextSpan inner(TextSpan root) => root.children!.single as TextSpan;

    testWidgets('null active is plain text', (t) async {
      final span = inner(await spanOf(t, null));
      expect(span.toPlainText(), text);
      expect(span.children, isNull);
      expect(span.style, style);
    });

    testWidgets('active sentence gets a soft background and full ink', (t) async {
      final span = inner(await spanOf(t, 1));
      expect(span.toPlainText(), text);
      final kids = span.children!.cast<TextSpan>();
      expect(kids.map((k) => k.text).toList(), ['প্রথম বাক্য। ', 'দ্বিতীয় বাক্য?', ' তৃতীয়!']);
      expect(kids[0].style, isNull);
      expect(kids[2].style, isNull);
      final active = kids[1].style!;
      expect(active.backgroundColor, hl.withValues(alpha: HighlightedParagraph.highlightAlpha));
      expect(active.color!.a, 1.0);
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('first and last sentences have no empty side spans', (t) async {
      final first = inner(await spanOf(t, 0)).children!.cast<TextSpan>();
      expect(first.map((k) => k.text).toList(), ['প্রথম বাক্য।', ' দ্বিতীয় বাক্য? তৃতীয়!']);
      final last = inner(await spanOf(t, 2)).children!.cast<TextSpan>();
      expect(last.map((k) => k.text).toList(), ['প্রথম বাক্য। দ্বিতীয় বাক্য? ', 'তৃতীয়!']);
    });

    testWidgets('out-of-range active falls back to plain text', (t) async {
      final span = inner(await spanOf(t, 9));
      expect(span.children, isNull);
      expect(span.text, text);
    });
  });

  group('SentenceReader', () {
    test('speaks in order and publishes the active index', () async {
      final spoken = <String>[];
      final seen = <int?>[];
      var done = 0;
      final r = SentenceReader(
        ['এক।', 'দুই।', 'তিন।'],
        speak: (s) async {
          spoken.add(s);
          return true;
        },
        gap: Duration.zero,
        onDone: () => done++,
      );
      r.active.addListener(() => seen.add(r.active.value));
      final ok = await r.start();
      expect(ok, isTrue);
      expect(spoken, ['এক।', 'দুই।', 'তিন।']);
      expect(seen, [0, 1, 2, null]);
      expect(r.speaking, isFalse);
      expect(done, 1);
      await r.dispose();
    });

    test('stop cuts the run and stops the voice', () async {
      final spoken = <String>[];
      final pending = <Completer<bool>>[];
      var stops = 0;
      final r = SentenceReader(
        ['এক।', 'দুই।', 'তিন।'],
        speak: (s) {
          spoken.add(s);
          final c = Completer<bool>();
          pending.add(c);
          return c.future;
        },
        stopSpeech: () async => stops++,
        gap: Duration.zero,
      );
      final run = r.start();
      await Future<void>.delayed(Duration.zero);
      expect(r.speaking, isTrue);
      expect(r.active.value, 0);
      await r.stop();
      expect(r.speaking, isFalse);
      expect(r.active.value, isNull);
      expect(stops, 1);
      pending.single.complete(true);
      expect(await run, isFalse);
      expect(spoken, ['এক।']);
      // Stopping when silent leaves the shared voice alone.
      await r.stop();
      expect(stops, 1);
      await r.dispose();
    });

    test('no voice ends the run and reports false', () async {
      var calls = 0;
      final r = SentenceReader(['এক।', 'দুই।'], speak: (_) async {
        calls++;
        return false;
      }, gap: Duration.zero);
      expect(await r.start(), isFalse);
      expect(calls, 1);
      expect(r.active.value, isNull);
      expect(r.speaking, isFalse);
      await r.dispose();
    });

    test('muted says nothing; muting mid-run stops', () async {
      var calls = 0;
      final r = SentenceReader(['এক।', 'দুই।'], speak: (_) async {
        calls++;
        return true;
      }, muted: true, gap: Duration.zero);
      expect(await r.start(), isFalse);
      expect(calls, 0);

      r.muted = false;
      final pending = Completer<bool>();
      final r2 = SentenceReader(['এক।', 'দুই।'], speak: (_) => pending.future, gap: Duration.zero);
      final run = r2.start();
      await Future<void>.delayed(Duration.zero);
      r2.muted = true;
      expect(r2.speaking, isFalse);
      pending.complete(true);
      expect(await run, isFalse);
      await r.dispose();
      await r2.dispose();
    });

    test('start from a later sentence and restart replaces the run', () async {
      final spoken = <String>[];
      final r = SentenceReader(['এক।', 'দুই।', 'তিন।'], speak: (s) async {
        spoken.add(s);
        return true;
      }, gap: Duration.zero);
      await r.start(from: 1);
      expect(spoken, ['দুই।', 'তিন।']);
      expect(await r.start(from: 5), isFalse);
      r.setSentences(['নতুন।']);
      await r.start();
      expect(spoken.last, 'নতুন।');
      await r.dispose();
    });
  });
}
