// ChoiceDeck's two-step pick (owner's brief 2026-11-12): a tap on a card only
// opens it big with ✕ বাদ দিন / ✓ বেছে নিন; ✕ sets it aside (dimmed, struck,
// not red) and answers nothing; only ✓ calls onPick, once; the buttons take no
// tap while the preview opens; the preview gives nothing away (the same two
// buttons for every card) and fits a small phone and a landscape screen. A
// wrong pick's mistake card stays until the player's button.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';

import 'support/reason_proceed.dart';

const _right = ChoiceOption('ঠিক কারণটা এখানে লেখা আছে', true);
const _wrong1 = ChoiceOption('ভুল কারণ এক নম্বর এখানে', false);
const _wrong2 = ChoiceOption('ভুল কারণ দুই নম্বর এখানে', false);
const _opts = [_wrong1, _right, _wrong2];

final _confirm = find.byKey(const ValueKey('choice-confirm'));
final _reject = find.byKey(const ValueKey('choice-reject'));
final _preview = find.byKey(const ValueKey('choice-preview-text'));

/// A level-like page: the deck on the scene's bottom edge; a wrong pick shows
/// a mistake card until its button, as the Do levels do.
class _Host extends StatefulWidget {
  const _Host({this.options = _opts, this.quiet = true});
  final List<ChoiceOption> options;
  final bool quiet;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final picks = <String>[];
  final wrong = <String>{};
  String? picked;
  DoMistake? card;
  int goes = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(key: ValueKey('scene'), child: ColoredBox(color: Color(0xFF0B1630))),
          Positioned(
            key: const ValueKey('deck'),
            left: 0,
            right: 0,
            bottom: 0,
            child: ChoiceDeck(
              options: widget.options,
              quiet: widget.quiet,
              muted: true,
              wrong: wrong,
              picked: picked,
              onPick: (o, _) => setState(() {
                picks.add(o.textBn);
                if (o.correct) {
                  picked = o.textBn;
                } else {
                  wrong.add(o.textBn);
                  card = const DoMistake(key: 't/wrong', textBn: 'এই কাজটা ভুল — আগে লাইন মরা কিনা পরীক্ষা করুন।', art: 'assets/game/art/fire/gauge.svg');
                }
              }),
            ),
          ),
          if (card != null)
            MistakeCard(
              key: const ValueKey('mistake'),
              mistake: card!,
              tone: MistakeTone.slip,
              quiet: true,
              onRead: null,
              onGo: () => setState(() {
                goes++;
                card = null;
              }),
            ),
        ],
      ),
    );
  }
}

Future<_HostState> _open(WidgetTester t, {Size size = const Size(360, 640), List<ChoiceOption> options = _opts, bool quiet = true}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: _Host(options: options, quiet: quiet)));
  await waitChoiceDeck(t);
  return t.state<_HostState>(find.byType(_Host));
}

Finder _card(String text) => find.byKey(ValueKey('deal-$text'));

/// The colours, labels and sizes of the preview's buttons (to compare cards).
List<Object?> _buttonLook(WidgetTester t) => [
      for (final f in [_reject, _confirm]) ...[
        t.getSize(f),
        find.descendant(of: find.ancestor(of: f, matching: find.byType(Material)).first, matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data).join(),
        (t.widget<Material>(find.ancestor(of: f, matching: find.byType(Material)).first)).color,
      ],
    ];

void main() {
  testWidgets('a tap opens the preview and answers nothing; full text; buttons ≥ 48 dp', (t) async {
    const long = 'খুব লম্বা একটা কারণ যেটা কার্ডে দুই লাইনে আঁটে না, তাই বড় করে খুললে পুরোটা পড়া যায় — '
        'লাইনে কাজের আগে শাটডাউন নিশ্চিত, ডকেট মিলিয়ে দেখা, টেস্টার দিয়ে মরা পরীক্ষা আর দুই দিকে আর্থ লাগানো।';
    final s = await _open(t, options: const [ChoiceOption(long, false), _right, _wrong2]);
    await t.tap(_card(long));
    await t.pump();
    expect(s.picks, isEmpty, reason: 'a tap never evaluates');
    expect(_preview, findsOneWidget);
    final text = t.widget<Text>(_preview);
    expect(text.data, long);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull, reason: 'no ellipsis on the preview');
    expect(_card(long), findsNothing, reason: 'the cards wait under the preview');
    expect(t.getSize(_confirm).height, greaterThanOrEqualTo(48));
    expect(t.getSize(_reject).height, greaterThanOrEqualTo(48));
    expect(find.text(ChoiceDeckLines.confirm), findsOneWidget);
    expect(find.text(ChoiceDeckLines.reject), findsOneWidget);
    await t.pump(const Duration(seconds: 10));
    expect(s.picks, isEmpty, reason: 'nothing picks by itself');
    expect(t.takeException(), isNull);
  });

  testWidgets('taps while the preview opens are ignored (no double-tap pick)', (t) async {
    final s = await _open(t, quiet: false);
    await t.tap(_card(_wrong1.textBn));
    await t.pump(const Duration(milliseconds: 60));
    await t.tap(_confirm, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 60));
    await t.tap(_reject, warnIfMissed: false);
    await t.pump();
    expect(s.picks, isEmpty);
    expect(_preview, findsOneWidget, reason: 'still open, nothing set aside');
    await t.pump(ChoiceDeck.armDelay);
    await t.tap(_confirm);
    await t.pump();
    expect(s.picks, [_wrong1.textBn]);
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('✕ sets the card aside (not red), calls nothing; it can be opened and chosen later', (t) async {
    final s = await _open(t);
    await t.tap(_card(_right.textBn));
    await t.pump(ChoiceDeck.armDelay + const Duration(milliseconds: 50));
    await t.tap(_reject);
    await t.pump();
    expect(s.picks, isEmpty);
    expect(_preview, findsNothing, reason: '✕ closes the preview');
    final aside = find.descendant(of: _card(_right.textBn), matching: find.byKey(const ValueKey('choice-aside-mark')));
    expect(aside, findsOneWidget, reason: 'set aside is marked');
    expect(find.descendant(of: _card(_right.textBn), matching: find.byIcon(Icons.close_rounded)), findsNothing, reason: 'not the wrong (red ✕) look');
    expect(find.descendant(of: _card(_wrong1.textBn), matching: find.byKey(const ValueKey('choice-aside-mark'))), findsNothing);
    // Open again and choose it.
    await pickChoice(t, _right.textBn, proceed: false);
    expect(s.picks, [_right.textBn]);
    expect(find.byKey(const ValueKey('choice-aside-mark')), findsNothing, reason: 'chosen: no longer aside');
  });

  testWidgets('✓ calls onPick once with the card; the card shows the verdict', (t) async {
    final s = await _open(t);
    await t.tap(_card(_wrong2.textBn));
    await t.pump(ChoiceDeck.armDelay + const Duration(milliseconds: 50));
    await t.tap(_confirm);
    await t.tap(_confirm, warnIfMissed: false);
    await t.pump();
    expect(s.picks, [_wrong2.textBn], reason: 'exactly once');
    expect(_confirm, findsNothing, reason: 'the preview closed');
    await t.tap(find.text(MistakeLines.gotIt));
    await t.pump();
    expect(find.descendant(of: _card(_wrong2.textBn), matching: find.byIcon(Icons.close_rounded)), findsOneWidget, reason: 'red ✕ on the wrong card');
    // A wrong card does not open again.
    await t.tap(_card(_wrong2.textBn));
    await t.pump();
    expect(_preview, findsNothing);
    await pickChoice(t, _right.textBn, proceed: false);
    expect(s.picks, [_wrong2.textBn, _right.textBn]);
    expect(find.descendant(of: _card(_right.textBn), matching: find.byIcon(Icons.check_rounded)), findsOneWidget, reason: 'green ✓ on the right card');
    // Picked: no card opens any more.
    await t.tap(_card(_wrong1.textBn));
    await t.pump();
    expect(_preview, findsNothing);
  });

  testWidgets('the preview gives nothing away: the same buttons for a right and a wrong card', (t) async {
    await _open(t);
    await t.tap(_card(_right.textBn));
    await t.pump(ChoiceDeck.armDelay + const Duration(milliseconds: 50));
    final rightLook = _buttonLook(t);
    await t.tap(_reject);
    await t.pump();
    await t.tap(_card(_wrong1.textBn));
    await t.pump(ChoiceDeck.armDelay + const Duration(milliseconds: 50));
    expect(_buttonLook(t), rightLook);
  });

  for (final size in const [Size(320, 568), Size(800, 360)]) {
    testWidgets('a long card preview fits ${size.width.toInt()}×${size.height.toInt()} without overflow', (t) async {
      final long = List.filled(9, 'লাইনে কাজের আগে শাটডাউন নিশ্চিত করুন, ডকেট মিলিয়ে নিন।').join(' ');
      await _open(t, size: size, options: [ChoiceOption(long, false), _right, _wrong2], quiet: false);
      await t.tap(_card(long), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 400));
      expect(t.takeException(), isNull);
      final screen = Offset.zero & size;
      for (final f in [_confirm, _reject]) {
        final r = t.getRect(f);
        expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(0.1, 0.1)), isTrue, reason: '$f on screen: $r');
        expect(f.hitTestable(), findsOneWidget);
      }
      // The long text scrolls inside the card instead of pushing it off screen.
      expect(find.byKey(const ValueKey('choice-preview-scroll')), findsOneWidget);
      final textTop = t.getRect(find.byKey(const ValueKey('choice-preview-scroll'))).top;
      expect(textTop, greaterThanOrEqualTo(0));
      await t.tap(_confirm);
      await t.pump();
      expect(t.takeException(), isNull);
      // The mistake card fits too, and its button is in reach.
      expect(find.byKey(const ValueKey('mistake')), findsOneWidget);
      final go = t.getRect(find.text(MistakeLines.gotIt));
      expect(screen.contains(go.center), isTrue, reason: 'mistake card button on screen: $go');
      await t.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('a wrong pick: its mistake card stays until the player taps the button', (t) async {
    final s = await _open(t);
    await pickChoice(t, _wrong1.textBn, proceed: false);
    expect(s.picks, [_wrong1.textBn]);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 10));
      expect(find.byKey(const ValueKey('mistake')), findsOneWidget, reason: 'no timer closes it (${(i + 1) * 10} s)');
    }
    expect(s.goes, 0);
    await t.tap(find.text(MistakeLines.gotIt));
    await t.pump();
    expect(s.goes, 1);
    expect(find.byKey(const ValueKey('mistake')), findsNothing);
  });
}
