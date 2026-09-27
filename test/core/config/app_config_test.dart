import 'package:dio/dio.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../network/scripted_adapter.dart';

/// `GET /app/config` as the live server answers it today, inside `data`.
const Map<String, Object?> _liveConfig = <String, Object?>{
  'minAppVersion': '1.2.0',
  'maintenanceMode': false,
  'maintenanceMessage': null,
  'supportEmail': null,
  'termsUrl': 'https://eventor.dz/terms',
  'privacyUrl': 'https://eventor.dz/privacy',
  'passwordPolicy': <String, Object?>{
    'minLength': 10,
    'needsLetterAndDigit': true,
  },
  'uploads': <String, Object?>{'maxDocumentMb': 5},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig.fromJson', () {
    test('reads the live shape', () {
      final AppConfig config = AppConfig.fromJson(_liveConfig);

      expect(config.minAppVersion, '1.2.0');
      expect(config.maintenanceMode, isFalse);
      expect(config.maintenanceMessage, isNull);
      expect(config.supportEmail, isNull);
      expect(config.termsUrl, 'https://eventor.dz/terms');
      expect(config.privacyUrl, 'https://eventor.dz/privacy');
      expect(config.passwordMinLength, 10);
      expect(config.passwordNeedsLetterAndDigit, isTrue);
      expect(config.maxDocumentMb, 5);
    });

    test('reads a maintenance window and a changed policy', () {
      final AppConfig config = AppConfig.fromJson(<String, Object?>{
        'maintenanceMode': true,
        'maintenanceMessage': 'Back at 14:00.',
        'supportEmail': 'help@eventor.dz',
        'passwordPolicy': <String, Object?>{
          'minLength': 12.0,
          'needsLetterAndDigit': false,
        },
        'uploads': <String, Object?>{'maxDocumentMb': 10},
      });

      expect(config.maintenanceMode, isTrue);
      expect(config.maintenanceMessage, 'Back at 14:00.');
      expect(config.supportEmail, 'help@eventor.dz');
      expect(config.passwordMinLength, 12);
      expect(config.passwordNeedsLetterAndDigit, isFalse);
      expect(config.maxDocumentMb, 10);
    });

    test('falls back field by field when they are missing', () {
      const AppConfig fallback = AppConfig();
      final AppConfig config = AppConfig.fromJson(const <String, Object?>{});

      expect(config.minAppVersion, fallback.minAppVersion);
      expect(config.maintenanceMode, isFalse);
      expect(config.passwordMinLength, fallback.passwordMinLength);
      expect(
        config.passwordNeedsLetterAndDigit,
        fallback.passwordNeedsLetterAndDigit,
      );
      expect(config.maxDocumentMb, fallback.maxDocumentMb);
    });

    test('lets one mistyped field fall back alone, keeping the rest', () {
      // A single wrong type used to throw, and the whole config — valid
      // fields included — was replaced by the fallback.
      final AppConfig config = AppConfig.fromJson(<String, Object?>{
        'minAppVersion': 2,
        'maintenanceMode': 'yes',
        'supportEmail': 'help@eventor.dz',
        'passwordPolicy': <String, Object?>{
          'minLength': 12,
          'needsLetterAndDigit': 'true',
        },
      });

      expect(config.minAppVersion, const AppConfig().minAppVersion);
      expect(config.maintenanceMode, isFalse);
      expect(config.passwordNeedsLetterAndDigit, isTrue);
      expect(config.supportEmail, 'help@eventor.dz');
      expect(config.passwordMinLength, 12);
    });

    test('treats a blank link as no link', () {
      // "Contact support" hides itself on null; an empty string would show a
      // link that opens nothing.
      final AppConfig config = AppConfig.fromJson(<String, Object?>{
        'supportEmail': '',
        'termsUrl': '   ',
        'privacyUrl': 42,
      });

      expect(config.supportEmail, isNull);
      expect(config.termsUrl, isNull);
      expect(config.privacyUrl, isNull);
    });

    test('shrugs off nested blocks that are not objects', () {
      final AppConfig config = AppConfig.fromJson(<String, Object?>{
        'passwordPolicy': 'strict',
        'uploads': <Object?>[5],
      });

      expect(config.passwordMinLength, 10);
      expect(config.maxDocumentMb, 5);
    });
  });

  group('AppConfigRepository', () {
    late ScriptedAdapter adapter;
    late AppConfigRepository repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      adapter = ScriptedAdapter(
        (RequestOptions request) async =>
            jsonResponse(<String, Object?>{'data': _liveConfig}),
      );
      repository = AppConfigRepository(scriptedClient(adapter, TokenStore()));
    });

    test('serves the fallback before anything has loaded', () {
      expect(repository.current.passwordMinLength, 10);
      expect(repository.current.maintenanceMode, isFalse);
    });

    test('loads and keeps the server config', () async {
      final AppConfig loaded = await repository.load();

      expect(adapter.requests.single.path, '/app/config');
      expect(loaded.minAppVersion, '1.2.0');
      expect(repository.current.minAppVersion, '1.2.0');
    });

    test('keeps the fallback when offline, without throwing', () async {
      adapter.respond = (RequestOptions request) async => noAnswer(request);

      final AppConfig loaded = await repository.load();

      expect(loaded.minAppVersion, const AppConfig().minAppVersion);
    });

    test('keeps the fallback when the server errors', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(500, 'INTERNAL_ERROR');

      await expectLater(repository.load(), completes);
      expect(repository.current.minAppVersion, const AppConfig().minAppVersion);
    });

    test('keeps what it last loaded when a later load fails', () async {
      await repository.load();
      adapter.respond = (RequestOptions request) async => noAnswer(request);

      await repository.load();

      expect(repository.current.minAppVersion, '1.2.0');
    });

    test('survives a field of the wrong type', () async {
      // fromJson casts its scalars, so this lands in load()'s catch and the
      // whole fallback is kept — not just the one bad field.
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{
            'data': <String, Object?>{
              ..._liveConfig,
              'maintenanceMode': 'no',
            },
          });

      await expectLater(repository.load(), completes);
      expect(repository.current.maintenanceMode, isFalse);
    });

    test('ignores an answer that is not an object', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{'data': <Object?>[]});

      await repository.load();

      expect(repository.current.minAppVersion, const AppConfig().minAppVersion);
    });
  });

}
