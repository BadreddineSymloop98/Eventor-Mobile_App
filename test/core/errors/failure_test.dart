import 'package:eventor/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiFailure.retryAfterSeconds', () {
    ApiFailure rateLimited(Map<String, Object?>? details) => ApiFailure(
          statusCode: 429,
          code: ApiErrorCode.rateLimited,
          message: 'Slow down.',
          details: details,
        );

    test('reads the wait the server asked for', () {
      expect(
        rateLimited(<String, Object?>{'retryAfterSeconds': 42})
            .retryAfterSeconds,
        42,
      );
    });

    test('takes a fractional wait as whole seconds', () {
      // JSON has one number type; a server sending 30.0 means 30.
      expect(
        rateLimited(<String, Object?>{'retryAfterSeconds': 30.0})
            .retryAfterSeconds,
        30,
      );
    });

    test('is null when there is nothing to read', () {
      expect(rateLimited(null).retryAfterSeconds, isNull);
      expect(rateLimited(<String, Object?>{}).retryAfterSeconds, isNull);
    });

    test('is null rather than a crash when the value is not a number', () {
      expect(
        rateLimited(<String, Object?>{'retryAfterSeconds': '42'})
            .retryAfterSeconds,
        isNull,
      );
    });
  });

  group('Failure', () {
    test('can be thrown and caught as an Exception', () {
      // Repositories throw these and BaseViewModel catches them; if Failure
      // stopped being an Exception, `on Exception` handlers would miss it.
      expect(const NetworkFailure(), isA<Exception>());
      expect(
        () => throw const SessionExpiredFailure(),
        throwsA(isA<Exception>()),
      );
    });

    test('keeps its cause for logging', () {
      final Object cause = StateError('socket closed');

      expect(NetworkFailure(cause: cause).cause, same(cause));
    });

    test('an API failure carries no field errors by default', () {
      const ApiFailure failure = ApiFailure(
        statusCode: 401,
        code: ApiErrorCode.invalidCredentials,
        message: 'Wrong email or password.',
      );

      expect(failure.fieldErrors, isEmpty);
      expect(failure.details, isNull);
      expect(failure.toString(), contains('INVALID_CREDENTIALS'));
      expect(failure.toString(), contains('401'));
    });
  });
}
