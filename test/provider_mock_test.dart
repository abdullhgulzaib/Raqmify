import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/network/api_client.dart';
import 'package:raqmify/core/network/result.dart';
import 'package:raqmify/core/utils/id_extractor.dart';
import 'package:raqmify/models/expense_model.dart';
import 'package:raqmify/providers/expense_provider.dart';
import 'package:raqmify/providers/split_provider.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

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

  group('extractId Helper Tests (D2)', () {
    test('extractId handles plain String, Map with _id, Map with id, null, and empty', () {
      expect(extractId('12345'), '12345');
      expect(extractId('  12345  '), '12345');
      expect(extractId({'_id': 'abc1'}), 'abc1');
      expect(extractId({'id': 'abc2'}), 'abc2');
      expect(extractId({'userId': 'abc3'}), 'abc3');
      expect(extractId({'_id': {'_id': 'nested'}}), 'nested');
      expect(extractId(null), '');
      expect(extractId(''), '');
      expect(extractId({}), '');
    });
  });

  group('Provider Network Failure & Rollback Tests (S5, F5)', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
      apiClient.dio.httpClientAdapter = FailingHttpClientAdapter(statusCode: 500, errorMessage: 'Server crashed');
    });

    tearDown(() {
      apiClient.dio.httpClientAdapter = HttpClientAdapter();
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

      final exp = ExpenseModel(
        id: 'seeded_1',
        title: 'Seeded Item',
        amount: 200.0,
        category: 'Food',
        date: DateTime.now(),
      );
      provider.expenses.add(exp);

      final result = await provider.deleteExpense('seeded_1');

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

    test('SplitProvider createSplitExpense with network error removes temporary expense and returns Failure', () async {
      final provider = SplitProvider();
      provider.clearData();

      final result = await provider.createSplitExpense(
        title: 'Dinner',
        totalAmount: 1000.0,
        category: 'Food',
        groupId: 'grp_1',
        groupName: 'Hostel Room',
        splitType: 'Equal',
        paidByUserId: 'user_1',
        paidByName: 'Abdullah',
        notes: '',
        participants: [
          {'userId': 'user_1', 'name': 'Abdullah', 'amount': 500.0, 'percentage': 50.0},
          {'userId': 'user_2', 'name': 'Test', 'amount': 500.0, 'percentage': 50.0},
        ],
      );

      expect(result.isFailure, isTrue);
      expect(provider.groupExpenses, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('SplitProvider Success & Payload Parsing Tests (Cause A, Cause C, D2)', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('createSplitExpense with valid 201 response updates expense with server id and reconciles', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      apiClient.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.method == 'POST' && options.path.contains('/splitvault/expenses')) {
          final responseJson = jsonEncode({
            'expense': {
              '_id': 'server_exp_999',
              'title': 'Dinner',
              'totalAmount': 1000.0,
              'category': 'Food',
              'paidBy': 'user_1',
              'paidByName': 'Abdullah',
              'groupId': 'grp_1',
              'groupName': 'Living Room',
              'splitType': 'Equal',
              'date': DateTime.now().toIso8601String(),
              'splits': [
                {'user': 'user_1', 'name': 'Abdullah', 'amount': 500.0, 'status': 'Verified'},
                {'user': 'user_2', 'name': 'Test', 'amount': 500.0, 'status': 'Unpaid'},
              ],
            }
          });
          return ResponseBody.fromString(
            responseJson,
            201,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        if (options.method == 'GET' && options.path.contains('/splitvault/summary')) {
          final summaryJson = jsonEncode({
            'groups': [],
            'allExpenses': [
              {
                '_id': 'server_exp_999',
                'title': 'Dinner',
                'totalAmount': 1000.0,
                'category': 'Food',
                'paidBy': 'user_1',
                'paidByName': 'Abdullah',
                'groupId': 'grp_1',
                'groupName': 'Living Room',
                'splitType': 'Equal',
                'date': DateTime.now().toIso8601String(),
                'splits': [
                  {'user': 'user_1', 'name': 'Abdullah', 'amount': 500.0, 'status': 'Verified'},
                  {'user': 'user_2', 'name': 'Test', 'amount': 500.0, 'status': 'Unpaid'},
                ],
              }
            ],
          });
          return ResponseBody.fromString(
            summaryJson,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await provider.createSplitExpense(
        title: 'Dinner',
        totalAmount: 1000.0,
        category: 'Food',
        groupId: 'grp_1',
        groupName: 'Living Room',
        splitType: 'Equal',
        paidByUserId: 'user_1',
        paidByName: 'Abdullah',
        notes: '',
        participants: [
          {'userId': 'user_1', 'name': 'Abdullah', 'amount': 500.0, 'percentage': 50.0},
          {'userId': 'user_2', 'name': 'Test', 'amount': 500.0, 'percentage': 50.0},
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(provider.groupExpenses.length, 1);
      expect(provider.groupExpenses.first.id, 'server_exp_999');
    });

    test('createSplitExpense with invalid response body removes temporary expense and returns Failure', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      apiClient.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          '{"unexpected": true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await provider.createSplitExpense(
        title: 'Dinner',
        totalAmount: 1000.0,
        category: 'Food',
        groupId: 'grp_1',
        groupName: 'Living Room',
        splitType: 'Equal',
        paidByUserId: 'user_1',
        paidByName: 'Abdullah',
        notes: '',
        participants: [
          {'userId': 'user_1', 'name': 'Abdullah', 'amount': 500.0, 'percentage': 50.0},
          {'userId': 'user_2', 'name': 'Test', 'amount': 500.0, 'percentage': 50.0},
        ],
      );

      expect(result.isFailure, isTrue);
      expect(provider.groupExpenses, isEmpty);
    });

    test('fetchGroupsAndData parses both allExpenses and expenses keys and handles populated ObjectId structures', () async {
      final provider = SplitProvider(apiClient: apiClient);
      provider.clearData();

      apiClient.dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        final json = jsonEncode({
          'groups': [
            {
              '_id': 'grp_123',
              'name': 'Apartment 4B',
              'createdBy': {'_id': 'user_1', 'name': 'Abdullah'},
              'inviteCode': 'ABCDEF23',
              'members': [
                {
                  'user': {'_id': 'user_1', 'name': 'Abdullah', 'email': 'abdullah@test.com'},
                  'name': 'Abdullah',
                  'email': 'abdullah@test.com',
                  'role': 'Admin',
                },
                {
                  'user': {'_id': 'user_2', 'name': 'Test', 'email': 'test@test.com'},
                  'name': 'Test',
                  'email': 'test@test.com',
                  'role': 'Member',
                }
              ]
            }
          ],
          'allExpenses': [
            {
              '_id': 'exp_1',
              'title': 'Dinner',
              'totalAmount': 1000.0,
              'paidBy': {'_id': 'user_1', 'name': 'Abdullah'},
              'groupId': {'_id': 'grp_123', 'name': 'Apartment 4B'},
              'splits': [
                {'user': {'_id': 'user_1'}, 'amount': 500.0, 'status': 'Verified'},
                {'user': {'_id': 'user_2'}, 'amount': 500.0, 'status': 'Unpaid'},
              ]
            },
            {
              '_id': 'exp_2',
              'title': 'Groceries',
              'totalAmount': 1500.0,
              'paidBy': {'_id': 'user_2', 'name': 'Test'},
              'groupId': {'_id': 'grp_123', 'name': 'Apartment 4B'},
              'splits': [
                {'user': {'_id': 'user_2'}, 'amount': 750.0, 'status': 'Verified'},
                {'user': {'_id': 'user_1'}, 'amount': 750.0, 'status': 'Unpaid'},
              ]
            }
          ]
        });
        return ResponseBody.fromString(
          json,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await provider.fetchGroupsAndData();

      expect(provider.groups.length, 1);
      expect(provider.groups.first.id, 'grp_123');
      expect(provider.groups.first.members.length, 2);
      expect(provider.groups.first.members[0].userId, 'user_1');
      expect(provider.groups.first.members[1].userId, 'user_2');

      expect(provider.groupExpenses.length, 2);

      // Verify netting from Abdullah perspective
      final abdullahDebts = provider.calculateNetBalances('user_1');
      expect(abdullahDebts.length, 1);
      expect(abdullahDebts.first.fromUserId, 'user_1');
      expect(abdullahDebts.first.toUserId, 'user_2');
      expect(abdullahDebts.first.netAmount.inRupees, 250.0);

      // Verify netting from Test perspective
      final testDebts = provider.calculateNetBalances('user_2');
      expect(testDebts.length, 1);
      expect(testDebts.first.fromUserId, 'user_1');
      expect(testDebts.first.toUserId, 'user_2');
      expect(testDebts.first.netAmount.inRupees, 250.0);
    });
  });
}
