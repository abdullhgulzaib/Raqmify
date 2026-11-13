import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/services/retention_service.dart';
import 'package:raqmify/models/expense_model.dart';
import 'package:raqmify/providers/split_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Split Vault Expense & Proof Tests', () {
    test('createSplitExpense optimistically adds expense and computes net balances', () async {
      final provider = SplitProvider();
      provider.clearData();

      const currentUserId = 'user_rana';
      const roommateId = 'user_ali';

      final result = await provider.createSplitExpense(
        title: 'Room Dinner',
        totalAmount: 2000.0,
        category: 'Food',
        groupId: 'grp_1',
        groupName: 'Hostel 304',
        splitType: 'Equal',
        paidByUserId: currentUserId,
        paidByName: 'Rana Abdullah',
        notes: 'Biryani split',
        participants: [
          {'userId': currentUserId, 'name': 'Rana Abdullah', 'amount': 1000.0, 'percentage': 50.0},
          {'userId': roommateId, 'name': 'Ali', 'amount': 1000.0, 'percentage': 50.0},
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(provider.groupExpenses.length, equals(1));
      expect(provider.totalSharedSpend, equals(2000.0));

      final owedToRana = provider.getAmountYoureOwed(currentUserId);
      expect(owedToRana, equals(1000.0));

      final debts = provider.calculateNetBalances(currentUserId);
      expect(debts.length, equals(1));
      expect(debts.first.fromUserId, equals(roommateId));
      expect(debts.first.toUserId, equals(currentUserId));
      expect(debts.first.netAmount.inRupees, equals(1000.0));
    });

    test('submitProof and verifyProof update split share status and adjust debt', () async {
      final provider = SplitProvider();
      provider.clearData();

      const currentUserId = 'user_rana';
      const roommateId = 'user_ali';

      final createRes = await provider.createSplitExpense(
        title: 'Electricity Bill',
        totalAmount: 4000.0,
        category: 'Utilities',
        groupId: 'grp_1',
        groupName: 'Hostel 304',
        splitType: 'Equal',
        paidByUserId: currentUserId,
        paidByName: 'Rana Abdullah',
        notes: 'Monthly bill',
        participants: [
          {'userId': currentUserId, 'name': 'Rana Abdullah', 'amount': 2000.0, 'percentage': 50.0},
          {'userId': roommateId, 'name': 'Ali', 'amount': 2000.0, 'percentage': 50.0},
        ],
      );

      final expId = createRes.dataOrNull!.id;

      // 1. Submit proof
      await provider.submitProof(
        expenseId: expId,
        userId: roommateId,
        transactionId: 'EP-12345678',
        paymentMethod: 'Easypaisa',
      );

      final pendingProofs = provider.getPendingVerificationsForCreditor(currentUserId);
      expect(pendingProofs.length, equals(1));
      expect(pendingProofs.first.share.proofTid, equals('EP-12345678'));
      expect(pendingProofs.first.share.status, equals('UnderReview'));

      // 2. Verify proof (approve)
      await provider.verifyProof(
        expenseId: expId,
        userId: roommateId,
        approve: true,
      );

      final updatedPending = provider.getPendingVerificationsForCreditor(currentUserId);
      expect(updatedPending.isEmpty, isTrue);

      final remainingOwed = provider.getAmountYoureOwed(currentUserId);
      expect(remainingOwed, equals(0.0));
    });
  });

  group('Retention Notice Dismissal Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('dismissRetentionNotice marks dismissed and suppresses alert', () async {
      final retentionService = RetentionService();
      expect(await retentionService.isRetentionNoticeDismissed(), isFalse);

      final expenses = [
        ExpenseModel(
          id: 'exp_old',
          title: 'Old Expense',
          amount: 500.0,
          category: 'Food',
          date: DateTime.now().subtract(const Duration(days: 56)),
          paymentMethod: 'Cash',
        ),
      ];

      final statusBefore = await retentionService.checkCleanupStatus(expenses);
      expect(statusBefore, isNotNull);
      expect(statusBefore!.isApproachingPrune, isTrue);

      // Dismiss notice
      await retentionService.dismissRetentionNotice();
      expect(await retentionService.isRetentionNoticeDismissed(), isTrue);

      final statusAfter = await retentionService.checkCleanupStatus(expenses);
      expect(statusAfter, isNull);
    });
  });
}
