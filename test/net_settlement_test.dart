import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/network/api_client.dart';
import 'package:raqmify/core/utils/phone_normalizer.dart';
import 'package:raqmify/models/net_settlement_model.dart';
import 'package:raqmify/providers/split_provider.dart';

class SettlementMockAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> settlements = [];
  bool shouldReturn409 = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    dynamic requestStream,
    dynamic cancelFuture,
  ) async {
    if (shouldReturn409) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'Balances have changed. Please refresh and review updated debts.'}),
        409,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && options.path.contains('/splitvault/settlements') && options.path.contains('/verify')) {
      final isApprove = options.data?['action'] == 'APPROVE';
      return ResponseBody.fromString(
        jsonEncode({
          'message': isApprove ? 'Settlement verified and debts settled' : 'Settlement rejected',
          'settlement': {
            '_id': 'stl_verified_1',
            'status': isApprove ? 'Verified' : 'Rejected',
            'amount': 1500.0,
            'fromUser': 'user_a',
            'fromUserName': 'Alice',
            'toUser': 'user_b',
            'toUserName': 'Bob',
          },
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && options.path.contains('/splitvault/settlements')) {
      final stl = {
        '_id': 'stl_123',
        'fromUser': 'user_a',
        'fromUserName': 'Alice',
        'toUser': 'user_b',
        'toUserName': 'Bob',
        'amount': options.data?['amount'] ?? 1500.0,
        'status': 'UnderReview',
        'proof': {
          'method': options.data?['method'] ?? 'Easypaisa',
          'transactionId': options.data?['transactionId'] ?? 'TID-12345',
          'imageUrl': options.data?['imageUrl'],
        },
        'coveredExpenses': [
          {
            'splitExpenseId': 'exp_1',
            'title': 'Dinner',
            'splitUserId': 'user_a',
            'direction': 'forward',
            'amount': 1500.0,
          }
        ],
      };
      settlements.insert(0, stl);
      return ResponseBody.fromString(
        jsonEncode({'message': 'Settlement proof submitted successfully', 'settlement': stl}),
        201,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'POST' && options.path.contains('/splitvault/nudge')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Reminder sent to debtor'}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    if (options.method == 'GET' && options.path.contains('/splitvault/summary')) {
      return ResponseBody.fromString(
        jsonEncode({
          'groups': [],
          'allExpenses': [],
          'netSettlements': [
            {
              'fromUserId': 'user_a',
              'fromUser': 'Alice',
              'toUserId': 'user_b',
              'toUser': 'Bob',
              'amount': 1500.0,
              'hasPendingSettlement': true,
              'pendingSettlementId': 'stl_123',
              'pendingSettlementAmount': 1500.0,
            }
          ],
          'settlements': settlements,
        }),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phone Normalization & WhatsApp URL Tests', () {
    test('normalizes Pakistani local mobile numbers starting with 03', () {
      expect(normalizePhoneToInternationalDigits('0300 1234567'), equals('923001234567'));
      expect(normalizePhoneToInternationalDigits('0300-1234567'), equals('923001234567'));
      expect(normalizePhoneToInternationalDigits('03451122334'), equals('923451122334'));
    });

    test('normalizes numbers with international prefix +92 and 0092', () {
      expect(normalizePhoneToInternationalDigits('+92 300 1234567'), equals('923001234567'));
      expect(normalizePhoneToInternationalDigits('00923001234567'), equals('923001234567'));
    });

    test('leaves non-PK international numbers with valid digits intact', () {
      expect(normalizePhoneToInternationalDigits('+1 (555) 234-5678'), equals('15552345678'));
      expect(normalizePhoneToInternationalDigits('+44 7911 123456'), equals('447911123456'));
    });

    test('builds direct and web WhatsApp URLs correctly encoded', () {
      final direct = buildWhatsAppDirectUrl('0300 1234567', 'Hi Ali, you owe Rs 500.');
      expect(direct, startsWith('whatsapp://send?phone=923001234567&text=Hi%20Ali'));

      final web = buildWhatsAppWebUrl('0300 1234567', 'Hi Ali, you owe Rs 500.');
      expect(web, startsWith('https://wa.me/923001234567?text=Hi%20Ali'));
    });
  });

  group('NetSettlementModel and SettlementModel JSON Deserialization', () {
    test('parses NetSettlementModel from server summary payload', () {
      final json = {
        'fromUserId': 'user_alice',
        'fromUser': 'Alice',
        'toUserId': 'user_bob_1',
        'toUser': 'Bob Smith',
        'amount': 1250.0,
        'hasPendingSettlement': true,
        'pendingSettlementId': 'stl_test_999',
        'pendingSettlementAmount': 1250.0,
        'recipientPaymentDetails': {
          'phone': '03001234567',
          'easypaisa': '03001234567',
          'jazzcash': '',
          'bankName': 'Meezan Bank',
          'accountNumber': '0101010101',
        },
        'breakdown': [
          {
            'expenseId': 'exp_dinner',
            'title': 'Dinner',
            'category': 'Food',
            'amount': 2000.0,
            'status': 'Unpaid',
          },
          {
            'expenseId': 'exp_fuel',
            'title': 'Fuel',
            'category': 'Transport',
            'amount': 750.0,
            'status': 'Unpaid',
          }
        ]
      };

      final model = NetSettlementModel.fromJson(json);
      expect(model.fromUserId, equals('user_alice'));
      expect(model.fromUser, equals('Alice'));
      expect(model.toUserId, equals('user_bob_1'));
      expect(model.toUser, equals('Bob Smith'));
      expect(model.amount, equals(1250.0));
      expect(model.hasPendingSettlement, isTrue);
      expect(model.pendingSettlementId, equals('stl_test_999'));
      expect(model.pendingSettlementAmount, equals(1250.0));
      expect(model.recipientPaymentDetails.bankName, equals('Meezan Bank'));
      expect(model.breakdown.length, equals(2));
      expect(model.breakdown[0].title, equals('Dinner'));
      expect(model.breakdown[1].title, equals('Fuel'));
    });

    test('parses SettlementModel with coveredExpenses and proof', () {
      final json = {
        '_id': 'stl_test_999',
        'fromUser': 'user_alice',
        'fromUserName': 'Alice',
        'toUser': 'user_bob_1',
        'toUserName': 'Bob Smith',
        'amount': 1250.0,
        'status': 'UnderReview',
        'proof': {
          'method': 'Easypaisa',
          'transactionId': 'EP-888999',
          'imageUrl': 'data:image/png;base64,abc123xyz',
        },
        'coveredExpenses': [
          {
            'expenseId': 'exp_dinner',
            'title': 'Dinner',
            'splitUserId': 'user_alice',
            'direction': 'forward',
            'amount': 2000.0,
          },
          {
            'expenseId': 'exp_fuel',
            'title': 'Fuel',
            'splitUserId': 'user_bob_1',
            'direction': 'reverse',
            'amount': 750.0,
          }
        ]
      };

      final stl = SettlementModel.fromJson(json);
      expect(stl.id, equals('stl_test_999'));
      expect(stl.fromUser, equals('user_alice'));
      expect(stl.fromUserName, equals('Alice'));
      expect(stl.toUser, equals('user_bob_1'));
      expect(stl.toUserName, equals('Bob Smith'));
      expect(stl.amount, equals(1250.0));
      expect(stl.status, equals('UnderReview'));
      expect(stl.proof?.method, equals('Easypaisa'));
      expect(stl.proof?.transactionId, equals('EP-888999'));
      expect(stl.coveredExpenses.length, equals(2));
      expect(stl.coveredExpenses[0].title, equals('Dinner'));
      expect(stl.coveredExpenses[0].direction, equals('forward'));
      expect(stl.coveredExpenses[1].title, equals('Fuel'));
      expect(stl.coveredExpenses[1].direction, equals('reverse'));
    });
  });

  group('SplitProvider Settlement and Nudge Actions', () {
    late ApiClient apiClient;
    late SettlementMockAdapter adapter;

    setUp(() {
      adapter = SettlementMockAdapter();
      apiClient = ApiClient();
      apiClient.dio.httpClientAdapter = adapter;
    });

    test('createSettlement submits proof and updates settlement state', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      final res = await provider.createSettlement(
        toUserId: 'user_b',
        amount: 1500.0,
        method: 'Nayapay',
        transactionId: 'NP-554433',
        currentUserId: 'user_a',
      );

      expect(res.isSuccess, isTrue);
      final settlement = res.dataOrNull!;
      expect(settlement.id, equals('stl_123'));
      expect(settlement.amount, equals(1500.0));
      expect(settlement.status, equals('UnderReview'));
      expect(provider.netSettlements.length, equals(1));
    });

    test('createSettlement handles 409 Conflict when balance changed', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      adapter.shouldReturn409 = true;

      final res = await provider.createSettlement(
        toUserId: 'user_b',
        amount: 1500.0,
        method: 'Nayapay',
        transactionId: 'NP-554433',
        currentUserId: 'user_a',
      );

      expect(res.isFailure, isTrue);
    });

    test('verifySettlement calls verify endpoint successfully', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      final res = await provider.verifySettlement(
        settlementId: 'stl_123',
        approve: true,
        currentUserId: 'user_b',
      );

      expect(res.isSuccess, isTrue);
    });

    test('sendNudge enforces 24-hour debounce per debt key', () async {
      final provider = SplitProvider(apiClient: apiClient);

      final firstCall = await provider.sendNudge(
        debtorId: 'user_debtor',
        amount: 2500.0,
        groupName: 'Hostel 304',
      );
      expect(firstCall, isTrue);

      final secondCall = await provider.sendNudge(
        debtorId: 'user_debtor',
        amount: 2500.0,
        groupName: 'Hostel 304',
      );
      // Suppressed due to 24h debounce
      expect(secondCall, isFalse);
    });
  });
}
