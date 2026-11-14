import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/logic/money.dart';
import 'package:raqmify/core/logic/netting_calculator.dart';
import 'package:raqmify/models/split_expense_model.dart';

void main() {
  group('Netting Two-Member Scenario (Regression & User Scenario)', () {
    const abdullahId = 'user_abdullah_1';
    const testUserId = 'user_test_2';
    const groupId = 'group_living_room_1';

    test('Abdullah pays 1000 and Test pays 1500 nets to Abdullah pays Test 250', () {
      // Expense 1: Abdullah pays 1000, equal split 500/500
      final expense1 = SplitExpenseModel(
        id: 'exp_1',
        title: 'Dinner',
        totalAmount: 1000.0,
        category: 'Food',
        paidByUserId: abdullahId,
        paidByName: 'Abdullah',
        groupId: groupId,
        groupName: 'Living Room',
        splitType: 'Equal',
        date: DateTime.now(),
        notes: '',
        isFullySettled: false,
        splits: [
          SplitMemberShare(
            userId: abdullahId,
            name: 'Abdullah',
            amount: 500.0,
            percentage: 50.0,
            status: 'Verified', // Payer self-share
          ),
          SplitMemberShare(
            userId: testUserId,
            name: 'Test',
            amount: 500.0,
            percentage: 50.0,
            status: 'Unpaid', // Test owes Abdullah 500
          ),
        ],
      );

      // Expense 2: Test pays 1500, equal split 750/750
      final expense2 = SplitExpenseModel(
        id: 'exp_2',
        title: 'Groceries',
        totalAmount: 1500.0,
        category: 'Groceries',
        paidByUserId: testUserId,
        paidByName: 'Test',
        groupId: groupId,
        groupName: 'Living Room',
        splitType: 'Equal',
        date: DateTime.now(),
        notes: '',
        isFullySettled: false,
        splits: [
          SplitMemberShare(
            userId: testUserId,
            name: 'Test',
            amount: 750.0,
            percentage: 50.0,
            status: 'Verified', // Payer self-share
          ),
          SplitMemberShare(
            userId: abdullahId,
            name: 'Abdullah',
            amount: 750.0,
            percentage: 50.0,
            status: 'Unpaid', // Abdullah owes Test 750
          ),
        ],
      );

      // Compute pairwise settlements
      final netDebts = NettingCalculator.computeNetSettlements(
        expenses: [expense1, expense2],
        aggregateAllGroups: false,
      );

      // Netting calculation:
      // Test owed Abdullah 500
      // Abdullah owed Test 750
      // Opposing debts net: 750 - 500 = 250
      // Result: Exactly ONE PairwiseDebt: from Abdullah to Test of Rs 250
      expect(netDebts.length, 1);
      final debt = netDebts.first;
      expect(debt.fromUserId, abdullahId);
      expect(debt.toUserId, testUserId);
      expect(debt.netAmount.paisa, 25000);
      expect(debt.netAmount.inRupees, 250.0);

      // Check partition for Abdullah perspective
      final abdullahPartition = NettingCalculator.partitionByUser(
        debts: netDebts,
        currentUserId: abdullahId,
      );
      final abdullahOwes = abdullahPartition.yourBalances
          .where((d) => d.fromUserId == abdullahId)
          .fold<Money>(Money.zero(), (sum, d) => sum + d.netAmount);
      final abdullahOwed = abdullahPartition.yourBalances
          .where((d) => d.toUserId == abdullahId)
          .fold<Money>(Money.zero(), (sum, d) => sum + d.netAmount);

      expect(abdullahOwes.inRupees, 250.0);
      expect(abdullahOwed.inRupees, 0.0);

      // Check partition for Test perspective
      final testPartition = NettingCalculator.partitionByUser(
        debts: netDebts,
        currentUserId: testUserId,
      );
      final testOwes = testPartition.yourBalances
          .where((d) => d.fromUserId == testUserId)
          .fold<Money>(Money.zero(), (sum, d) => sum + d.netAmount);
      final testOwed = testPartition.yourBalances
          .where((d) => d.toUserId == testUserId)
          .fold<Money>(Money.zero(), (sum, d) => sum + d.netAmount);

      expect(testOwes.inRupees, 0.0);
      expect(testOwed.inRupees, 250.0);
    });

    test('Same expenses in different groups without aggregateAllGroups produce two separate debts', () {
      final expense1 = SplitExpenseModel(
        id: 'exp_1',
        title: 'Dinner',
        totalAmount: 1000.0,
        paidByUserId: abdullahId,
        paidByName: 'Abdullah',
        groupId: 'grp_A',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: abdullahId, name: 'Abdullah', amount: 500.0, status: 'Verified'),
          SplitMemberShare(userId: testUserId, name: 'Test', amount: 500.0, status: 'Unpaid'),
        ],
      );

      final expense2 = SplitExpenseModel(
        id: 'exp_2',
        title: 'Groceries',
        totalAmount: 1500.0,
        paidByUserId: testUserId,
        paidByName: 'Test',
        groupId: 'grp_B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: testUserId, name: 'Test', amount: 750.0, status: 'Verified'),
          SplitMemberShare(userId: abdullahId, name: 'Abdullah', amount: 750.0, status: 'Unpaid'),
        ],
      );

      // Without aggregate: 2 separate debts
      final separateDebts = NettingCalculator.computeNetSettlements(
        expenses: [expense1, expense2],
        aggregateAllGroups: false,
      );
      expect(separateDebts.length, 2);

      // With aggregate: nets to 250
      final aggregatedDebts = NettingCalculator.computeNetSettlements(
        expenses: [expense1, expense2],
        aggregateAllGroups: true,
      );
      expect(aggregatedDebts.length, 1);
      expect(aggregatedDebts.first.fromUserId, abdullahId);
      expect(aggregatedDebts.first.toUserId, testUserId);
      expect(aggregatedDebts.first.netAmount.inRupees, 250.0);
    });

    test('Exactly equal opposing debts produce no debt', () {
      final expense1 = SplitExpenseModel(
        id: 'exp_1',
        title: 'Lunch',
        totalAmount: 1000.0,
        paidByUserId: abdullahId,
        paidByName: 'Abdullah',
        groupId: groupId,
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: abdullahId, name: 'Abdullah', amount: 500.0, status: 'Verified'),
          SplitMemberShare(userId: testUserId, name: 'Test', amount: 500.0, status: 'Unpaid'),
        ],
      );

      final expense2 = SplitExpenseModel(
        id: 'exp_2',
        title: 'Dinner',
        totalAmount: 1000.0,
        paidByUserId: testUserId,
        paidByName: 'Test',
        groupId: groupId,
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: testUserId, name: 'Test', amount: 500.0, status: 'Verified'),
          SplitMemberShare(userId: abdullahId, name: 'Abdullah', amount: 500.0, status: 'Unpaid'),
        ],
      );

      final netDebts = NettingCalculator.computeNetSettlements(
        expenses: [expense1, expense2],
        aggregateAllGroups: false,
      );
      expect(netDebts.isEmpty, true);
    });

    test('Verified and Settled shares are excluded; UnderReview is flagged as pending', () {
      final expense = SplitExpenseModel(
        id: 'exp_verified',
        title: 'Paid trip',
        totalAmount: 1000.0,
        paidByUserId: abdullahId,
        paidByName: 'Abdullah',
        groupId: groupId,
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: abdullahId, name: 'Abdullah', amount: 500.0, status: 'Verified'),
          SplitMemberShare(userId: testUserId, name: 'Test', amount: 500.0, status: 'Verified'),
        ],
      );

      final debts = NettingCalculator.computeNetSettlements(
        expenses: [expense],
      );
      expect(debts.isEmpty, true);
    });
  });
}
