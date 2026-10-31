import 'dart:async';

import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _setSession({
  required String accessToken,
  required String refreshToken,
  required String userId,
}) {
  SharedPreferences.setMockInitialValues({
    'isLoggedIn': true,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userData':
        '{"id":"$userId","accessToken":"$accessToken","refreshToken":"$refreshToken"}',
  });
}

void main() {
  setUp(() async {
    _setSession(
      accessToken: 'access-a',
      refreshToken: 'refresh-a',
      userId: 'user-a',
    );
    ApiService.onSessionExpired = null;
    ApiService.onTokensRefreshed = null;
  });

  tearDown(() {
    ApiService.onSessionExpired = null;
    ApiService.onTokensRefreshed = null;
  });

  test(
    'A request cannot refresh or retry with account B after account switch',
    () async {
      final firstRequestStarted = Completer<void>();
      final protectedResponse = Completer<http.Response>();
      var protectedCalls = 0;
      var refreshCalls = 0;

      final requestFuture = http.runWithClient(
        () => ApiService.getRequest('/protected', 'access-a'),
        () => MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            refreshCalls++;
            return http.Response('{"success":true}', 200);
          }
          protectedCalls++;
          firstRequestStarted.complete();
          return protectedResponse.future;
        }),
      );

      await firstRequestStarted.future;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', 'access-b');
      await prefs.setString('refreshToken', 'refresh-b');
      await prefs.setString(
        'userData',
        '{"id":"user-b","accessToken":"access-b","refreshToken":"refresh-b"}',
      );
      protectedResponse.complete(
        http.Response('{"message":"Invalid token"}', 401),
      );

      final response = await requestFuture;
      expect(response.statusCode, 401);
      expect(protectedCalls, 1);
      expect(refreshCalls, 0);
      expect(prefs.getString('accessToken'), 'access-b');
      expect(prefs.getString('refreshToken'), 'refresh-b');
      expect(prefs.getString('userData'), contains('user-b'));
    },
  );

  test('successful refresh retries once with the same session', () async {
    final observedProtectedTokens = <String?>[];
    var refreshCalls = 0;

    final response = await http.runWithClient(
      () => ApiService.getRequest('/protected', 'access-a'),
      () => MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          return http.Response(
            '{"success":true,"accessToken":"access-a2","refreshToken":"refresh-a2"}',
            200,
          );
        }
        observedProtectedTokens.add(request.headers['Authorization']);
        if (observedProtectedTokens.length == 1) {
          return http.Response('{"message":"Session expired"}', 401);
        }
        return http.Response('{"success":true}', 200);
      }),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(response.statusCode, 200);
    expect(observedProtectedTokens, ['Bearer access-a', 'Bearer access-a2']);
    expect(refreshCalls, 1);
    expect(prefs.getString('accessToken'), 'access-a2');
    expect(prefs.getString('refreshToken'), 'refresh-a2');
    expect(prefs.getString('userData'), contains('user-a'));
  });

  test(
    'temporary 503 preserves session and 401 response does not log out',
    () async {
      var expired = false;
      ApiService.onSessionExpired = (_) => expired = true;

      final response = await http.runWithClient(
        () => ApiService.getRequest('/protected', 'access-a'),
        () => MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return http.Response('service unavailable', 503);
          }
          return http.Response('{"message":"Session expired"}', 401);
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(response.statusCode, 401);
      expect(expired, isFalse);
      expect(prefs.getString('accessToken'), 'access-a');
      expect(prefs.getString('refreshToken'), 'refresh-a');
      expect(prefs.getBool('isLoggedIn'), isTrue);
    },
  );

  test(
    'rejected refresh expires persisted and in-memory session without Navigator',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthProvider();
      await http.runWithClient(() async {
        await auth.loadUserData();
        // Let the startup profile sync settle before testing the expiry callback.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, () => MockClient((_) async => http.Response('{"success":false}', 500)));
      expect(auth.isLoggedIn, isTrue);

      ApiService.onSessionExpired = (token) {
        return auth.expireSessionIfTokenMatches(token);
      };

      final response = await http.runWithClient(
        () => ApiService.getRequest('/protected', 'access-a'),
        () => MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return http.Response('{"message":"Invalid refresh token"}', 401);
          }
          return http.Response('{"message":"Session expired"}', 401);
        }),
      );

      expect(response.statusCode, 401);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.user, isEmpty);
      expect(prefs.getString('accessToken'), isNull);
      expect(prefs.getString('refreshToken'), isNull);
      expect(prefs.getString('userData'), isNull);
      expect(prefs.getBool('isLoggedIn'), isFalse);
    },
  );

  test('403 does not refresh or expire session', () async {
    var refreshCalls = 0;
    var expired = false;
    ApiService.onSessionExpired = (_) => expired = true;

    final response = await http.runWithClient(
      () => ApiService.getRequest('/protected', 'access-a'),
      () => MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          return http.Response('{"success":true}', 200);
        }
        return http.Response('{"message":"Access denied"}', 403);
      }),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(response.statusCode, 403);
    expect(refreshCalls, 0);
    expect(expired, isFalse);
    expect(prefs.getString('accessToken'), 'access-a');
    expect(prefs.getBool('isLoggedIn'), isTrue);
  });

  test(
    'Checkout and Orders protected reads use ApiService refresh path',
    () async {
      final checkoutTokens = <String?>[];
      final ordersTokens = <String?>[];
      var refreshNumber = 0;

      await http.runWithClient(
        () async {
          final checkout = CheckoutProvider();
          await checkout.fetchAddresses();
          expect(checkout.error, isNull);

          final orders = OrdersProvider();
          await orders.fetchOrders();
          expect(orders.error, isNull);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/refresh')) {
            refreshNumber++;
            final next = refreshNumber == 1 ? 'a2' : 'a3';
            return http.Response(
              '{"success":true,"accessToken":"access-$next","refreshToken":"refresh-$next"}',
              200,
            );
          }
          if (path.endsWith('/addresses')) {
            checkoutTokens.add(request.headers['Authorization']);
            return checkoutTokens.length == 1
                ? http.Response('{"message":"Session expired"}', 401)
                : http.Response('{"success":true,"data":[]}', 200);
          }
          if (path.endsWith('/orders')) {
            ordersTokens.add(request.headers['Authorization']);
            return ordersTokens.length == 1
                ? http.Response('{"message":"Session expired"}', 401)
                : http.Response('{"success":true,"data":[]}', 200);
          }
          return http.Response('not found', 404);
        }),
      );

      expect(checkoutTokens, ['Bearer access-a', 'Bearer access-a2']);
      expect(ordersTokens, ['Bearer access-a2', 'Bearer access-a3']);
      expect(refreshNumber, 2);
    },
  );
}
