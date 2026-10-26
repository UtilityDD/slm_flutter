import 'library_catalog.dart';

/// Smart Parichiti search: Bangla text + English from photo names +
/// rough phonetic folding so voice "helmet" finds হেলমেট.
bool identifyMatches(LibraryItem item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final hay = _haystack(item);
  return q
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .every((token) => _tokenHits(hay, token));
}

String _haystack(LibraryItem item) {
  final buf = StringBuffer()
    ..write(item.nameBn)
    ..write(' ')
    ..write(item.functionBn)
    ..write(' ')
    ..write(item.guideBn)
    ..write(' ')
    ..write(item.id)
    ..write(' ')
    ..write(categoryLabel(item.category, true))
    ..write(' ')
    ..write(categoryLabel(item.category, false))
    ..write(' ')
    ..write(_englishFromImages(item.images))
    ..write(' ')
    ..write(banglaToLatin(item.nameBn))
    ..write(' ')
    ..write(banglaToLatin(item.id));

  // Keep a space-stripped twin so "safetyhelmet" still hits split tokens.
  final raw = buf.toString().toLowerCase();
  return '$raw ${raw.replaceAll(RegExp(r'[^a-z0-9\u0980-\u09ff]+'), '')}';
}

String _englishFromImages(List<String> images) {
  if (images.isEmpty) return '';
  final out = StringBuffer();
  for (final path in images) {
    final file = path.split('/').last.split('\\').last;
    final stem = file.contains('.') ? file.substring(0, file.lastIndexOf('.')) : file;
    final spaced = stem
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(RegExp(r'([A-Za-z])([0-9])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .toLowerCase();
    out
      ..write(' ')
      ..write(spaced)
      ..write(' ')
      ..write(spaced.replaceAll(' ', ''));
  }
  return out.toString();
}

bool _tokenHits(String hay, String token) {
  final variants = _expandToken(token);
  for (final v in variants) {
    if (v.isEmpty) continue;
    if (hay.contains(v)) return true;
  }

  // Soft phonetic: short English voice tokens vs latinized Bangla loanwords.
  if (token.length >= 4 && RegExp(r'^[a-z]+$').hasMatch(token)) {
    for (final word in _latinWords(hay)) {
      if (_soundsLike(token, word)) return true;
    }
  }
  return false;
}

Iterable<String> _latinWords(String hay) sync* {
  for (final w in hay.split(RegExp(r'[^a-z0-9]+'))) {
    if (w.length >= 3) yield w;
  }
}

/// Common voice / typed English ↔ field-loanword bridges.
List<String> _expandToken(String token) {
  final out = <String>{token, banglaToLatin(token)};
  const aliases = <String, List<String>>{
    'helmet': ['হেলমেট', 'helmet', 'safetyhelmet'],
    'helmate': ['হেলমেট', 'helmet'],
    'harness': ['হারনেস', 'harness', 'fullbodyharness'],
    'gloves': ['গ্লাভস', 'glove', 'gloves', 'electricalgloves'],
    'glove': ['গ্লাভস', 'gloves', 'glove'],
    'goggles': ['গগলস', 'চশমা', 'goggles', 'safetygoggles'],
    'boot': ['বুট', 'boot', 'boots', 'gumboot', 'linemanboot'],
    'boots': ['বুট', 'boot', 'boots', 'gumboot'],
    'ladder': ['মই', 'ladder', 'frpladder', 'bambooladder'],
    'belt': ['বেল্ট', 'belt', 'safetybelt'],
    'torch': ['টর্চ', 'torch'],
    'megger': ['মেগার', 'megger', 'insulation'],
    'clamp': ['ক্ল্যাম্প', 'clamp', 'clampmeter'],
    'earthing': ['আর্থিং', 'earth', 'earthing'],
    'earth': ['আর্থ', 'earth', 'earthing'],
    'insulator': ['ইনসুলেটর', 'insulator'],
    'ppe': ['পিপিই', 'ppe'],
    'vest': ['জ্যাকেট', 'ভেস্ট', 'vest'],
    'rope': ['দড়ি', 'rope'],
    'spanner': ['স্প্যানার', 'spanner', 'wrench'],
    'pliers': ['প্লায়ার', 'pliers'],
    'cutter': ['কাটার', 'cutter'],
    'crimping': ['ক্রিম্পিং', 'crimping', 'crimp'],
    'crimp': ['ক্রিম্প', 'crimping', 'crimp'],
  };
  final mapped = aliases[token];
  if (mapped != null) out.addAll(mapped);
  // Singular/plural soft fold.
  if (token.endsWith('s') && token.length > 4) out.add(token.substring(0, token.length - 1));
  if (!token.endsWith('s')) out.add('${token}s');
  return out.toList();
}

bool _soundsLike(String a, String b) {
  if (a == b) return true;
  if (a.length < 4 || b.length < 4) return false;
  if (a.startsWith(b) || b.startsWith(a)) return true;
  final na = _phoneticFold(a);
  final nb = _phoneticFold(b);
  if (na == nb) return true;
  if (na.length >= 4 && nb.length >= 4 && (na.startsWith(nb) || nb.startsWith(na))) return true;
  return _editDistance(na, nb) <= (na.length >= 6 ? 2 : 1);
}

String _phoneticFold(String s) {
  var t = s.toLowerCase();
  const swaps = <String, String>{
    'ph': 'f',
    'gh': 'g',
    'kh': 'k',
    'th': 't',
    'dh': 'd',
    'bh': 'b',
    'sh': 's',
    'ch': 'c',
    'ck': 'k',
    'qu': 'k',
    'oo': 'u',
    'ee': 'i',
    'ou': 'o',
    'ive': 'iv',
    'ves': 'vs',
  };
  swaps.forEach((from, to) => t = t.replaceAll(from, to));
  t = t.replaceAll(RegExp(r'(.)\1+'), r'$1'); // compress doubles
  t = t.replaceAll(RegExp(r'[aeiou]'), '');
  return t;
}

int _editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final prev = List<int>.generate(b.length + 1, (j) => j);
  final cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = cur[j];
    }
  }
  return prev[b.length];
}

/// Rough Bangla → Latin so loanwords like হেলমেট ≈ helmet.
String banglaToLatin(String input) {
  if (input.isEmpty) return '';
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    out.write(_bnLatin[ch] ?? (RegExp(r'[A-Za-z0-9]').hasMatch(ch) ? ch.toLowerCase() : ' '));
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _bnLatin = <String, String>{
  'অ': 'o', 'আ': 'a', 'ই': 'i', 'ঈ': 'i', 'উ': 'u', 'ঊ': 'u',
  'ঋ': 'ri', 'এ': 'e', 'ঐ': 'oi', 'ও': 'o', 'ঔ': 'ou',
  'া': 'a', 'ি': 'i', 'ী': 'i', 'ু': 'u', 'ূ': 'u',
  'ৃ': 'ri', 'ে': 'e', 'ৈ': 'oi', 'ো': 'o', 'ৌ': 'ou',
  '্': '', 'ঁ': 'n', 'ং': 'ng', 'ঃ': 'h',
  'ক': 'k', 'খ': 'kh', 'গ': 'g', 'ঘ': 'gh', 'ঙ': 'ng',
  'চ': 'ch', 'ছ': 'ch', 'জ': 'j', 'ঝ': 'jh', 'ঞ': 'n',
  'ট': 't', 'ঠ': 'th', 'ড': 'd', 'ঢ': 'dh', 'ণ': 'n',
  'ত': 't', 'থ': 'th', 'দ': 'd', 'ধ': 'dh', 'ন': 'n',
  'প': 'p', 'ফ': 'f', 'ব': 'b', 'ভ': 'v', 'ম': 'm',
  'য': 'y', 'র': 'r', 'ল': 'l', 'শ': 'sh', 'ষ': 'sh',
  'স': 's', 'হ': 'h', 'ড়': 'r', 'ঢ়': 'rh', 'য়': 'y',
  'ৎ': 't', '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
  '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
};
