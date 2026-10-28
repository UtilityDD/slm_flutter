/// Western digits 0–9, even when the rest of the line is Bangla.
String enDigits(String raw) {
  const map = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };
  if (raw.isEmpty) return raw;
  final out = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

String enNum(int n) => n.toString();
