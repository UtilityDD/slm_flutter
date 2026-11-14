import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/verify_sheet.dart';

void main() {
  const full = LinemanProfile(
    id: 'u1',
    fullName: 'রাম দাস',
    slmId: 'SLM-1234',
    district: 'Malda',
    block: 'English Bazar',
    job: 'LT-Mobile Van',
  );

  test('the request needs a name and a district', () {
    expect(verifyRequestReady(full), isTrue);
    expect(verifyRequestReady(null), isFalse);
    expect(verifyRequestReady(const LinemanProfile(id: 'u2', fullName: 'রাম দাস')), isFalse);
    expect(verifyRequestReady(const LinemanProfile(id: 'u3', district: 'Malda', fullName: '  ')), isFalse);
  });

  test('the email goes to the support inbox with the profile filled in, never a phone number', () {
    final uri = verifyRequestMail(full, 'ram@example.com');
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'smartlinemanapp@gmail.com');
    final query = Uri.decodeComponent(uri.query);
    expect(query, contains('SmartLineman যাচাইয়ের অনুরোধ — SLM-1234'));
    for (final part in ['নাম: রাম দাস', 'জেলা: Malda', 'ব্লক: English Bazar', 'কাজ: LT-Mobile Van', 'ইমেইল: ram@example.com', 'SLM আইডি: SLM-1234']) {
      expect(query, contains(part));
    }
    expect(query.toLowerCase(), isNot(contains('phone')));
    expect(query, isNot(contains('ফোন')));
  });

  test('missing fields show a dash instead of "null"', () {
    final query = Uri.decodeComponent(verifyRequestMail(const LinemanProfile(id: 'u4', fullName: 'শ্যাম'), null).query);
    expect(query, contains('ব্লক: —'));
    expect(query, contains('ইমেইল: —'));
    expect(query, isNot(contains('null')));
  });
}
