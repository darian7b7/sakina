// Builds assets/ayat.json from data/selection.json (which verses, per category) and
// data/quran/quran.json (the full text). Run from the project folder:
//
//   dart run tool/build_content.dart
//
// The app only bundles the selected verses; the full Quran stays in data/ as the source.
import 'dart:convert';
import 'dart:io';

void main() {
  final quran = jsonDecode(File('data/quran/quran.json').readAsStringSync()) as Map<String, dynamic>;
  final verses = {for (final v in quran['verses'] as List) v['key'] as String: v as Map<String, dynamic>};
  final selection = jsonDecode(File('data/selection.json').readAsStringSync()) as Map<String, dynamic>;

  final categories = <Map<String, Object?>>[];
  final categoriesOf = <String, List<String>>{}; // verse key → category ids, in Quran order later
  for (final c in selection['categories'] as List) {
    final id = c['id'] as String;
    categories.add({'id': id, 'name': c['name']});
    for (final ref in c['verses'] as List) {
      for (final key in _expand(ref as String)) {
        if (!verses.containsKey(key)) _fail('Category "$id": verse $key does not exist');
        final ids = categoriesOf.putIfAbsent(key, () => []);
        if (!ids.contains(id)) ids.add(id);
      }
    }
  }

  // Quran order, so the content file reads naturally.
  final keys = categoriesOf.keys.toList()..sort((a, b) => _order(a).compareTo(_order(b)));
  final ayat = [
    for (final key in keys)
      {
        'surah': int.parse(key.split(':')[0]),
        'ayah': int.parse(key.split(':')[1]),
        'arabic': verses[key]!['ar'],
        'translation': {'de': verses[key]!['de'], 'en': verses[key]!['en']},
        'categories': categoriesOf[key],
      },
  ];

  final out = {'source': quran['source'], 'categories': categories, 'ayat': ayat};
  File('assets/ayat.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln('assets/ayat.json: ${categories.length} categories, ${ayat.length} verses');
  for (final c in categories) {
    stdout.writeln('  ${c['id']}: ${ayat.where((a) => (a['categories'] as List).contains(c['id'])).length}');
  }
}

/// "2:155" → [2:155]; "94:5-6" → [94:5, 94:6].
List<String> _expand(String ref) {
  final m = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$').firstMatch(ref.trim());
  if (m == null) _fail('Invalid reference "$ref" (use "2:153" or "94:5-6")');
  final surah = m.group(1)!;
  final from = int.parse(m.group(2)!);
  final to = int.parse(m.group(3) ?? m.group(2)!);
  if (to < from) _fail('Invalid range "$ref"');
  return [for (var a = from; a <= to; a++) '$surah:$a'];
}

int _order(String key) {
  final [s, a] = key.split(':').map(int.parse).toList();
  return s * 1000 + a;
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}
