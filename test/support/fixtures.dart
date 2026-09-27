import 'dart:convert';
import 'dart:io';

/// A saved API response from `test/fixtures/<dir>/` — real live responses
/// (2026-09-24), trimmed; `home.json` and `favourites_page.json` are written
/// by hand from the schema, because both need a session to fetch. [dir]
/// defaults to `catalog`, where every fixture lived before other feature
/// areas — messaging, notifications — got folders of their own.
Map<String, Object?> fixture(String name, {String dir = 'catalog'}) =>
    jsonDecode(File('test/fixtures/$dir/$name').readAsStringSync())
        as Map<String, Object?>;

/// The envelope's `data`, as an object.
Map<String, Object?> fixtureData(String name, {String dir = 'catalog'}) =>
    fixture(name, dir: dir)['data']! as Map<String, Object?>;

/// The envelope's `data`, as a list of objects.
List<Map<String, Object?>> fixtureList(String name, {String dir = 'catalog'}) =>
    (fixture(name, dir: dir)['data']! as List<Object?>)
        .cast<Map<String, Object?>>();
