// Ayat and categories, loaded from assets/ayat.json. Pure Dart: no Flutter imports.

class Category {
  const Category(this.id, this.names);

  final String id;
  final Map<String, String> names; // language code → name

  String name(String lang) => names[lang] ?? (names.isEmpty ? id : names.values.first);
}

class Ayah {
  const Ayah({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.translations,
    required this.categories,
  });

  final int surah;
  final int ayah;
  final String arabic;
  final Map<String, String> translations; // language code → text
  final List<String> categories;

  /// "2:153" — unique, stable, used in notifications and saved lists.
  String get id => '$surah:$ayah';

  /// Translation in [lang], falling back to any available one.
  String? translation(String lang) =>
      translations[lang] ?? (translations.isEmpty ? null : translations.values.first);
}

class Content {
  Content(this.categories, this.ayat) : _byId = {for (final a in ayat) a.id: a};

  final List<Category> categories;
  final List<Ayah> ayat;
  final Map<String, Ayah> _byId;

  Ayah? byId(String id) => _byId[id];

  int count(String categoryId) => ayat.where((a) => a.categories.contains(categoryId)).length;

  /// Ids of ayat in any of [categoryIds], in file order, each once.
  List<String> poolIds(Set<String> categoryIds) =>
      [for (final a in ayat) if (a.categories.any(categoryIds.contains)) a.id];

  /// Parses the content file. Throws a [FormatException] naming the problem, so mistakes
  /// in a hand-edited file are easy to find.
  factory Content.fromJson(Map<String, dynamic> json) {
    final categories = <Category>[];
    for (final (i, c) in _list(json, 'categories').indexed) {
      final map = _map(c, 'categories[$i]');
      categories.add(Category(_string(map, 'id', 'categories[$i]'), _strings(map['name'], 'categories[$i].name')));
    }
    final known = {for (final c in categories) c.id};

    final ayat = <Ayah>[];
    final seen = <String>{};
    for (final (i, a) in _list(json, 'ayat').indexed) {
      final where = 'ayat[$i]';
      final map = _map(a, where);
      final ayah = Ayah(
        surah: _int(map, 'surah', where),
        ayah: _int(map, 'ayah', where),
        arabic: _string(map, 'arabic', where),
        translations: _strings(map['translation'] ?? const {}, '$where.translation'),
        categories: [for (final c in _list(map, 'categories', where)) '$c'],
      );
      if (!seen.add(ayah.id)) throw FormatException('$where: ${ayah.id} appears twice');
      final unknown = ayah.categories.where((c) => !known.contains(c));
      if (unknown.isNotEmpty) throw FormatException('$where (${ayah.id}): unknown category "${unknown.first}"');
      ayat.add(ayah);
    }
    return Content(categories, ayat);
  }
}

List<dynamic> _list(Map<String, dynamic> map, String key, [String where = '']) {
  final v = map[key] ?? const [];
  if (v is! List) throw FormatException('${where.isEmpty ? '' : '$where.'}$key must be a list');
  return v;
}

Map<String, dynamic> _map(Object? v, String where) {
  if (v is! Map<String, dynamic>) throw FormatException('$where must be an object');
  return v;
}

String _string(Map<String, dynamic> map, String key, String where) {
  final v = map[key];
  if (v is! String || v.trim().isEmpty) throw FormatException('$where.$key is missing');
  return v.trim();
}

int _int(Map<String, dynamic> map, String key, String where) {
  final v = map[key];
  if (v is! int || v < 1) throw FormatException('$where.$key must be a positive number');
  return v;
}

Map<String, String> _strings(Object? v, String where) {
  if (v is! Map) throw FormatException('$where must be an object like {"de": "…", "en": "…"}');
  return {for (final e in v.entries) if ('${e.value}'.trim().isNotEmpty) '${e.key}': '${e.value}'.trim()};
}
