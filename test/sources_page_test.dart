import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/more/delete_account.dart' show linkOpenerProvider;
import 'package:slm_flutter/features/more/sources_page.dart';

void main() {
  test('every source is an https link to an official site', () {
    expect(SafetySources.all, isNotEmpty);
    for (final s in SafetySources.all) {
      final u = Uri.parse(s.url);
      expect(u.scheme, 'https', reason: s.url);
      expect(u.host, anyOf(endsWith('.gov.in'), endsWith('.nic.in'), endsWith('wbsedcl.in')), reason: s.url);
    }
    expect(SafetySources.noticeBn, contains('সরকারি অ্যাপ নয়'));
  });

  testWidgets('the page lists the notice and opens each source', (t) async {
    final opened = <Uri>[];
    t.view.physicalSize = const Size(360, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [linkOpenerProvider.overrideWithValue((u) async { opened.add(u); })],
      child: const MaterialApp(home: SourcesPage()),
    ));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text(SafetySources.noticeBn), findsOneWidget);
    final first = SafetySources.all.first;
    await t.tap(find.text(first.titleBn));
    await t.pump();
    expect(opened, [Uri.parse(first.url)]);
  });

  test('a store build can launch with fewer modules (SLM_MAX_MODULE)', () {
    final json = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>;
    final all = ContentCatalog.fromJson(json, maxModule: 0);
    final five = ContentCatalog.fromJson(json, maxModule: 5);
    bool open(CatalogRungDef r) => r.status == CatalogRungStatus.playable;
    expect(all.rungDefs.where((r) => r.moduleId == 'm6').every(open), isTrue);
    expect(five.rungDefs.where((r) => r.moduleId == 'm6').any(open), isFalse);
    expect(five.rungDefs.where(open).length, 150);
    expect(five.packsById['do_6_1_a']!.status, CatalogRungStatus.comingSoon);
    expect(five.packsById['do_5_1_a']!.status, all.packsById['do_5_1_a']!.status);
    five.validate();
  });
}
