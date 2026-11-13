import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/network/api_client.dart';
import 'package:raqmify/core/network/result.dart';
import 'package:raqmify/models/expense_model.dart';
import 'package:raqmify/providers/expense_provider.dart';
import 'package:raqmify/providers/split_provider.dart';

class FailingHttpClientAdapter implements HttpClientAdapter {
  final int statusCode;
  final String errorMessage;

  FailingHttpClientAdapter({this.statusCode = 500, this.errorMessage = 'Internal Server Error'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: statusCode,
        data: {'error': errorMessage, 'message': errorMessage},
      ),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Provider Network Failure & Rollback Tests (S5, F5)', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
      apiClient.dio.httpClientAdapter = FailingHttpClientAdapter(statusCode: 500, errorMessage: 'Server crashed');
    });

    test('ExpenseProvider addExpense returns Failure and marks failed sync on network error', () async {
      final provider = ExpenseProvider();
      provider.clearData();

      final result = await provider.addExpense(
        title: 'Failing Expense',
        amount: 500.0,
        category: 'Food',
        date: DateTime.now(),
        paymentMethod: 'Cash',
      );

      // Must produce Failure, never Success
      expect(result.isFailure, isTrue);
      expect(result, isA<Failure<ExpenseModel>>());

      // Marked as failed sync locally
      expect(provider.expenses.length, 1);
      expect(provider.expenses.first.syncStatus, 'failed');
    });

    test('ExpenseProvider deleteExpense rolls back state on server error', () async {
      final provider = ExpenseProvider();
      provider.clearData();

      // Seed an initial expense
      final exp = ExpenseModel(
        id: 'seeded_1',
        title: 'Seeded Item',
        amount: 200.0,
        category: 'Food',
        date: DateTime.now(),
      );
      provider.expenses.add(exp);

      final result = await provider.deleteExpense('seeded_1');

      // Fails and rolls back item to list
      expect(result.isFailure, isTrue);
      expect(provider.expenses.any((e) => e.id == 'seeded_1'), isTrue);
    });

    test('SplitProvider createGroup returns Failure and does not add phantom group on network error', () async {
      final provider = SplitProvider();
      provider.clearData();

      final result = await provider.createGroup(
        name: 'Failed Group',
        description: 'Testing failure',
        category: 'Hostel',
        currentUserId: 'user_1',
        currentUserName: 'User 1',
      );

      // Must require confirmed server response; never reports success or adds phantom group
      expect(result.isFailure, isTrue);
      expect(provider.groups, isEmpty);
    });

    test('SplitProvider joinGroupByInviteCode fails cleanly without local fake fallback', () async {
      final provider = SplitProvider();
      provider.clearData();

      final result = await provider.joinGroupByInviteCode(
        inviteCode: 'ABCDEF23',
        userId: 'user_1',
        userName: 'User 1',
        userEmail: 'u1@test.com',
      );

      expect(result.isFailure, isTrue);
      expect(provider.groups, isEmpty);
    });
  });
}
