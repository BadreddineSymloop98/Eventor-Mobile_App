import 'dart:convert';
import 'dart:io';

/// A saved API response from `test/fixtures/catalog/` — real live responses
/// (2026-09-24), trimmed; `home.json` and `favourites_page.json` are written
/// by hand from the schema, because both need a session to fetch.
Map<String, Object?> fixture(String name) =>
    jsonDecode(File('test/fixtures/catalog/$name').readAsStringSync())
        as Map<String, Object?>;

/// The envelope's `data`, as an object.
Map<String, Object?> fixtureData(String name) =>
    fixture(name)['data']! as Map<String, Object?>;

/// The envelope's `data`, as a list of objects.
List<Map<String, Object?>> fixtureList(String name) =>
    (fixture(name)['data']! as List<Object?>)
        .cast<Map<String, Object?>>();
