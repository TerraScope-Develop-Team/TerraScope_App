import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrascope/services/api_exception.dart';
import 'package:terrascope/services/api_response.dart';
import 'package:terrascope/providers/request_state.dart';

class TestNotifier with ChangeNotifier, RequestStateMixin {}

void main() {
  group('ApiException Tests', () {
    test('ApiException.fromResponse parses error object with message and statusCode', () {
      final ex = ApiException.fromResponse(
        statusCode: 404,
        body: '{"message": "Recurso no encontrado"}',
        endpoint: '/api/v1/test',
      );

      expect(ex, isA<NotFoundException>());
      expect(ex.statusCode, 404);
      expect(ex.message, 'Recurso no encontrado');
      expect(ex.endpoint, '/api/v1/test');
    });

    test('ApiException.fromResponse creates UnauthorizedException on 401', () {
      final ex = ApiException.fromResponse(
        statusCode: 401,
        body: '{"error": "Token expirado"}',
        endpoint: '/api/v1/auth',
      );

      expect(ex, isA<UnauthorizedException>());
      expect(ex.statusCode, 401);
      expect(ex.userFriendlyMessage, contains('expirado'));
    });

    test('ApiException.fromResponse creates ServerException on 500', () {
      final ex = ApiException.fromResponse(
        statusCode: 500,
        body: 'Internal server error',
        endpoint: '/api/v1/data',
      );

      expect(ex, isA<ServerException>());
      expect(ex.statusCode, 500);
      expect(ex.userFriendlyMessage, contains('servidor'));
    });

    test('NetworkException provides appropriate user friendly message', () {
      const ex = NetworkException(message: 'No connection', endpoint: '/test');
      expect(ex.statusCode, isNull);
      expect(ex.userFriendlyMessage, contains('conexión'));
    });
  });

  group('ApiResponse Parser Tests', () {
    test('extractList extracts list directly or from wrapped data field', () {
      final listDirect = ApiResponse.extractList('[{"id": "1"}, {"id": "2"}]');
      expect(listDirect.length, 2);

      final listWrapped = ApiResponse.extractList('{"status": "success", "data": [{"id": "3"}]}');
      expect(listWrapped.length, 1);
      expect(listWrapped.first['id'], '3');
    });

    test('extractMap extracts map directly or from wrapped data field', () {
      final directMap = ApiResponse.extractMap('{"key": "value"}');
      expect(directMap['key'], 'value');

      final wrappedMap = ApiResponse.extractMap('{"status": "success", "data": {"subKey": "subVal"}}');
      expect(wrappedMap['subKey'], 'subVal');
    });
  });

  group('RequestStateMixin Tests', () {
    test('executeRequest transitions through loading to success', () async {
      final notifier = TestNotifier();
      expect(notifier.requestState, RequestState.idle);

      final result = await notifier.executeRequest(() async {
        expect(notifier.isLoading, isTrue);
        return 'done';
      });

      expect(result, 'done');
      expect(notifier.requestState, RequestState.success);
      expect(notifier.hasError, isFalse);
    });

    test('executeRequest captures ApiException and sets error state', () async {
      final notifier = TestNotifier();

      await notifier.executeRequest(() async {
        throw const ApiException(statusCode: 400, message: 'Bad request');
      });

      expect(notifier.hasError, isTrue);
      expect(notifier.requestState, RequestState.error);
      expect(notifier.errorMessage, isNotNull);
    });
  });
}
