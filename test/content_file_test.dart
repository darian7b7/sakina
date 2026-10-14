import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/content.dart';

void main() {
  test('assets/ayat.json loads and every verse has Arabic, German and English', () {
    final content = Content.fromJson(jsonDecode(File('assets/ayat.json').readAsStringSync()) as Map<String, dynamic>);
    expect(content.ayat, isNotEmpty);
    for (final a in content.ayat) {
      expect([a.translations['de'], a.translations['en']], everyElement(isNotEmpty), reason: a.id);
    }
    for (final c in content.categories) {
      expect(content.count(c.id), greaterThan(0), reason: 'category ${c.id} has no verses');
    }
  });
}
