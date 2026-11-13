import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/logic/money.dart';
import 'package:raqmify/core/logic/split_calculator.dart';
import 'package:raqmify/core/logic/netting_calculator.dart';
import 'package:raqmify/models/split_expense_model.dart';

void main() {
  group('Money Value Type (S7)', () {
    test('integer paisa arithmetic avoids floating-point drift', () {
      final m1 = Money.fromRupees(0.1);
      final m2 = Money.fromRupees(0.2);
      final sum = m1 + m2;
      expect(sum.inRupees, 0.3);
      expect(sum.paisa, 30);
      expect(sum.format(), 'Rs 0.30');
    });

    test('parsing handles rupees, doubles, strings, and null', () {
      expect(Money.parse(100).paisa, 10000);
      expect(Money.parse(100.5).paisa, 10050);
      expect(Money.parse('Rs 1,234.56').paisa, 123456);
      expect(Money.parse(null).paisa, 0);
    });

    test('formatting displays commas and 2 decimals when paisa is non-zero', () {
      expect(const Money.fromPaisa(125000).format(), 'Rs 1,250');
      expect(const Money.fromPaisa(125075).format(), 'Rs 1,250.75');
      expect(const Money.fromPaisa(-5050).format(), '-Rs 50.50');
    });
  });

  group('SplitCalculator (S7, F5)', () {
    test('equal split distributes remainder paisa to first remainder participants (2540 split 3)', () {
      final total = Money.fromRupees(2540);
      final participants = ['userA', 'userB', 'userC'];
      final splits = SplitCalculator.calculateEqualSplit(
        total: total,
        participantIds: participants,
      );

      expect(splits['userA']!.inRupees, 846.67);
      expect(splits['userB']!.inRupees, 846.67);
      expect(splits['userC']!.inRupees, 846.66);

      // Verify exact sum equals total
      final sumPaisa = splits.values.fold(0, (sum, m) => sum + m.paisa);
      expect(sumPaisa, total.paisa);
      expect(Money.fromPaisa(sumPaisa).inRupees, 2540.00);
    });

    test('percentage split rounds down and distributes leftover paisa deterministically', () {
      final total = Money.fromRupees(100);
      final percentages = {
        'u1': 33.33,
        'u2': 33.33,
        'u3': 33.34,
      };

      final splits = SplitCalculator.calculatePercentageSplit(
        total: total,
        percentages: percentages,
      );

      final sumPaisa = splits.values.fold(0, (sum, m) => sum + m.paisa);
      expect(sumPaisa, total.paisa);
      // Highest percentage u3 gets prioritized for leftover paisa
      expect(splits['u3']!.inRupees, 33.34);
    });

    test('percentage split throws when percentages do not sum to 100', () {
      expect(
        () => SplitCalculator.calculatePercentageSplit(
          total: Money.fromRupees(100),
          percentages: {'u1': 50.0, 'u2': 40.0},
        ),
        throwsA(isA<SplitCalculationException>()),
      );
    });

    test('custom split throws clear inline error when other shares exceed total', () {
      expect(
        () => SplitCalculator.calculateCustomSplit(
          total: Money.fromRupees(100),
          payerId: 'payer',
          nonPayerShares: {
            'u1': Money.fromRupees(60),
            'u2': Money.fromRupees(50),
          },
        ),
        throwsA(isA<SplitCalculationException>()),
      );
    });

    test('custom split assigns exact remainder to payer', () {
      final splits = SplitCalculator.calculateCustomSplit(
        total: Money.fromRupees(100),
        payerId: 'payer',
        nonPayerShares: {
          'u1': Money.fromRupees(30),
          'u2': Money.fromRupees(25),
        },
      );

      expect(splits['payer']!.inRupees, 45.00);
      expect(splits['u1']!.inRupees, 30.00);
      expect(splits['u2']!.inRupees, 25.00);
    });
  });

  group('NettingCalculator (S8, F5)', () {
    test('proposal example: opposing direct debts net to single remainder', () {
      // Expense 1: User B pays 150, User A owes 150
      final exp1 = SplitExpenseModel(
        id: 'exp1',
        title: 'Dinner',
        totalAmount: 150,
        paidByUserId: 'userB',
        paidByName: 'Bob',
        groupId: 'grp1',
        groupName: 'Flat 4B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'userA', name: 'Alice', email: 'a@test.com', amount: 150),
        ],
      );

      // Expense 2: User A pays 100, User B owes 100
      final exp2 = SplitExpenseModel(
        id: 'exp2',
        title: 'Groceries',
        totalAmount: 100,
        paidByUserId: 'userA',
        paidByName: 'Alice',
        groupId: 'grp1',
        groupName: 'Flat 4B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'userB', name: 'Bob', email: 'b@test.com', amount: 100),
        ],
      );

      final settlements = NettingCalculator.computeNetSettlements(
        expenses: [exp1, exp2],
      );

      expect(settlements.length, 1);
      final debt = settlements.first;
      expect(debt.fromUserId, 'userA');
      expect(debt.toUserId, 'userB');
      expect(debt.netAmount.inRupees, 50.0);
    });

    test('exactly opposing debts cancel completely resulting in zero debt', () {
      final exp1 = SplitExpenseModel(
        id: 'exp1',
        title: 'Lunch',
        totalAmount: 100,
        paidByUserId: 'userB',
        paidByName: 'Bob',
        groupId: 'grp1',
        groupName: 'Flat 4B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'userA', name: 'Alice', email: 'a@test.com', amount: 100),
        ],
      );

      final exp2 = SplitExpenseModel(
        id: 'exp2',
        title: 'Dinner',
        totalAmount: 100,
        paidByUserId: 'userA',
        paidByName: 'Alice',
        groupId: 'grp1',
        groupName: 'Flat 4B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'userB', name: 'Bob', email: 'b@test.com', amount: 100),
        ],
      );

      final settlements = NettingCalculator.computeNetSettlements(
        expenses: [exp1, exp2],
      );

      expect(settlements, isEmpty);
    });

    test('settled and verified shares are excluded; UnderReview is flagged as pending', () {
      final exp = SplitExpenseModel(
        id: 'exp1',
        title: 'Rent',
        totalAmount: 300,
        paidByUserId: 'userAdmin',
        paidByName: 'Admin',
        groupId: 'grp1',
        groupName: 'Flat 4B',
        date: DateTime.now(),
        splits: [
          // Settled: excluded
          SplitMemberShare(userId: 'u1', name: 'User 1', email: '1@test.com', amount: 100, status: 'Settled'),
          // Verified: excluded
          SplitMemberShare(userId: 'u2', name: 'User 2', email: '2@test.com', amount: 100, status: 'Verified'),
          // UnderReview: included, flagged as hasPendingReview = true
          SplitMemberShare(userId: 'u3', name: 'User 3', email: '3@test.com', amount: 100, status: 'UnderReview'),
        ],
      );

      final settlements = NettingCalculator.computeNetSettlements(
        expenses: [exp],
      );

      expect(settlements.length, 1);
      final debt = settlements.first;
      expect(debt.fromUserId, 'u3');
      expect(debt.toUserId, 'userAdmin');
      expect(debt.netAmount.inRupees, 100.0);
      expect(debt.hasPendingReview, isTrue);
      expect(debt.relatedExpenseIds, contains('exp1'));
    });

    test('per-group netting vs aggregate netting behaves as expected', () {
      // In Group 1: Alice owes Bob 100
      final g1Exp = SplitExpenseModel(
        id: 'g1',
        title: 'Water',
        totalAmount: 100,
        paidByUserId: 'bob',
        paidByName: 'Bob',
        groupId: 'group1',
        groupName: 'Hostel A',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'alice', name: 'Alice', email: 'a@test.com', amount: 100),
        ],
      );

      // In Group 2: Bob owes Alice 100
      final g2Exp = SplitExpenseModel(
        id: 'g2',
        title: 'Electricity',
        totalAmount: 100,
        paidByUserId: 'alice',
        paidByName: 'Alice',
        groupId: 'group2',
        groupName: 'Society B',
        date: DateTime.now(),
        splits: [
          SplitMemberShare(userId: 'bob', name: 'Bob', email: 'b@test.com', amount: 100),
        ],
      );

      // Per-group netting (default): keeps debts separate per group
      final perGroup = NettingCalculator.computeNetSettlements(
        expenses: [g1Exp, g2Exp],
        aggregateAllGroups: false,
      );
      expect(perGroup.length, 2);

      // Aggregate netting: cross-nets all groups, resulting in 0 net debt
      final aggregate = NettingCalculator.computeNetSettlements(
        expenses: [g1Exp, g2Exp],
        aggregateAllGroups: true,
      );
      expect(aggregate, isEmpty);
    });

    test('partitionByUser separates current user debts from everyone else', () {
      const currentUserId = 'alice';
      final debts = [
        PairwiseDebt(
          fromUserId: 'alice',
          fromUserName: 'Alice',
          toUserId: 'bob',
          toUserName: 'Bob',
          netAmount: Money.fromRupees(50),
        ),
        PairwiseDebt(
          fromUserId: 'charlie',
          fromUserName: 'Charlie',
          toUserId: 'david',
          toUserName: 'David',
          netAmount: Money.fromRupees(75),
        ),
      ];

      final partition = NettingCalculator.partitionByUser(
        debts: debts,
        currentUserId: currentUserId,
      );

      expect(partition.yourBalances.length, 1);
      expect(partition.yourBalances.first.toUserId, 'bob');
      expect(partition.otherBalances.length, 1);
      expect(partition.otherBalances.first.fromUserId, 'charlie');
    });
  });
}
