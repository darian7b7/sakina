import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/content.dart';

Map<String, dynamic> file({List<Map<String, dynamic>>? ayat}) => {
      'categories': [
        {'id': 'patience', 'name': {'de': 'Geduld', 'en': 'Patience'}},
        {'id': 'gratitude', 'name': {'de': 'Dankbarkeit', 'en': 'Gratitude'}},
      ],
      'ayat': ayat ??
          [
            {'surah': 1, 'ayah': 1, 'arabic': 'A', 'translation': {'de': 'D1', 'en': 'E1'}, 'categories': ['patience']},
            {'surah': 1, 'ayah': 2, 'arabic': 'B', 'translation': {'de': 'D2'}, 'categories': ['patience', 'gratitude']},
            {'surah': 1, 'ayah': 3, 'arabic': 'C', 'categories': ['gratitude']},
          ],
    };

void main() {
  test('parses categories and ayat', () {
    final c = Content.fromJson(file());
    expect(c.categories.map((x) => x.name('en')), ['Patience', 'Gratitude']);
    expect(c.byId('1:2')!.translation('de'), 'D2');
    expect(c.count('patience'), 2);
  });

  test('translation falls back to another language, or null', () {
    final c = Content.fromJson(file());
    expect(c.byId('1:2')!.translation('en'), 'D2');
    expect(c.byId('1:3')!.translation('en'), isNull);
  });

  test('pool contains each matching ayah once, in file order', () {
    final c = Content.fromJson(file());
    expect(c.poolIds({'patience', 'gratitude'}), ['1:1', '1:2', '1:3']);
    expect(c.poolIds({'gratitude'}), ['1:2', '1:3']);
    expect(c.poolIds({}), isEmpty);
  });

  test('an empty file is valid', () {
    expect(Content.fromJson({}).ayat, isEmpty);
  });

  test('reports duplicates, unknown categories and missing fields clearly', () {
    Matcher fails(String text) => throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(text)));
    final ayah = {'surah': 2, 'ayah': 153, 'arabic': 'X', 'categories': ['patience']};
    expect(() => Content.fromJson(file(ayat: [ayah, ayah])), fails('2:153 appears twice'));
    expect(() => Content.fromJson(file(ayat: [{...ayah, 'categories': ['hope']}])), fails('unknown category "hope"'));
    expect(() => Content.fromJson(file(ayat: [{...ayah, 'arabic': ' '}])), fails('ayat[0].arabic is missing'));
    expect(() => Content.fromJson(file(ayat: [{...ayah, 'surah': 0}])), fails('ayat[0].surah must be a positive number'));
  });
}
