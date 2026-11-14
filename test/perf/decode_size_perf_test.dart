// Memory guard: small on-screen spots decode their image at display size × DPR,
// not at the file's full size (audit-memory-10). Each test prints a
// `PERF` line with the decoded size so a before/after run can be compared.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/design/slm_design.dart';

Widget _app(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: SlmTheme.night(),
        home: Scaffold(body: Center(child: child)),
      ),
    );

ResizeImage _resized(WidgetTester tester, Finder f) {
  final image = tester.widget<Image>(f).image;
  expect(image, isA<ResizeImage>(), reason: 'decoded at full size');
  return image as ResizeImage;
}

void main() {
  testWidgets('SlmAvatar decodes a network photo at the circle size × DPR', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const SlmAvatar(name: 'A', url: 'https://example.invalid/a.png', size: 40)));
    final r = _resized(tester, find.byType(Image));
    debugPrint('PERF avatar 40 dp @3x: cacheWidth ${r.width}');
    expect(r.width, isNotNull);
    expect(r.width!, lessThanOrEqualTo(3 * 40 * 1.5), reason: 'about size × layout scale × DPR');
    await tester.pumpWidget(const SizedBox());
  });
}
