import 'money.dart';
import '../../models/split_expense_model.dart';

/// Representation of a simplified pairwise settlement between two roommates (S8).
class PairwiseDebt {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final Money netAmount;
  final String? groupId;
  final String? groupTitle;
  final bool hasPendingReview;
  final List<String> relatedExpenseIds;

  const PairwiseDebt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.netAmount,
    this.groupId,
    this.groupTitle,
    this.hasPendingReview = false,
    this.relatedExpenseIds = const [],
  });

  double get netAmountInRupees => netAmount.inRupees;

  @override
  String toString() =>
      '$fromUserName owes $toUserName ${netAmount.format()}${hasPendingReview ? ' (Under Review)' : ''}';
}

/// Pure Dart Netting Settlement Engine (S8, F5).
/// Implements graph reduction / pairwise debt netting per group or across groups.
class NettingCalculator {
  /// Computes pairwise net settlements.
  /// - [aggregateAllGroups]: false = net separately per group (default); true = cross-group netting.
  /// - Excludes Settled and Verified splits.
  /// - Flags UnderReview splits as pending review on the specific pairwise debt.
  /// - Ignores net amounts below 1 paisa (0.01 Rs).
  static List<PairwiseDebt> computeNetSettlements({
    required List<SplitExpenseModel> expenses,
    bool aggregateAllGroups = false,
    String? filterGroupId,
  }) {
    if (expenses.isEmpty) return [];

    var targetExpenses = expenses;
    if (filterGroupId != null && filterGroupId != 'all') {
      targetExpenses = expenses.where((e) => e.groupId == filterGroupId).toList();
    }

    if (aggregateAllGroups) {
      return _netExpenseSubset(targetExpenses, groupId: null, groupTitle: 'All Groups');
    }

    // Group by groupId for per-group netting (S8)
    final expensesByGroup = <String, List<SplitExpenseModel>>{};
    final groupTitles = <String, String>{};

    for (final exp in targetExpenses) {
      final gId = exp.groupId ?? 'default';
      expensesByGroup.putIfAbsent(gId, () => []).add(exp);
      groupTitles[gId] = exp.groupName.isNotEmpty ? exp.groupName : 'Group';
    }

    final allNetDebts = <PairwiseDebt>[];
    for (final entry in expensesByGroup.entries) {
      final groupDebts = _netExpenseSubset(
        entry.value,
        groupId: entry.key,
        groupTitle: groupTitles[entry.key] ?? 'Group',
      );
      allNetDebts.addAll(groupDebts);
    }

    return allNetDebts;
  }

  /// Separates "Your balances" from "Everyone's balances" for the current user.
  static ({
    List<PairwiseDebt> yourBalances,
    List<PairwiseDebt> otherBalances,
  }) partitionByUser({
    required List<PairwiseDebt> debts,
    required String currentUserId,
  }) {
    final your = <PairwiseDebt>[];
    final others = <PairwiseDebt>[];

    for (final d in debts) {
      if (d.fromUserId == currentUserId || d.toUserId == currentUserId) {
        your.add(d);
      } else {
        others.add(d);
      }
    }

    return (yourBalances: your, otherBalances: others);
  }

  static List<PairwiseDebt> _netExpenseSubset(
    List<SplitExpenseModel> expenses, {
    String? groupId,
    String? groupTitle,
  }) {
    // directDebts[debtor][creditor] in paisa
    final directDebts = <String, Map<String, int>>{};
    final userNames = <String, String>{};
    final pendingReviews = <String, bool>{}; // key: "debtor_creditor"
    final relatedExpenses = <String, Set<String>>{}; // key: "debtor_creditor"

    for (final exp in expenses) {
      final creditor = exp.paidByUserId;
      userNames[creditor] = exp.paidByName;

      for (final s in exp.splits) {
        userNames[s.userId] = s.name;
        // Ignore self-debt
        if (s.userId == creditor) continue;

        // Rules: Settled and Verified do NOT count as outstanding
        if (s.status == 'Settled' || s.status == 'Verified') continue;

        final sharePaisa = Money.parse(s.amount).paisa;
        if (sharePaisa <= 0) continue;

        directDebts.putIfAbsent(s.userId, () => {});
        directDebts[s.userId]![creditor] =
            (directDebts[s.userId]![creditor] ?? 0) + sharePaisa;

        final directKey = '${s.userId}_$creditor';
        relatedExpenses.putIfAbsent(directKey, () => <String>{}).add(exp.id);

        if (s.status == 'UnderReview') {
          pendingReviews[directKey] = true;
        }
      }
    }

    final netList = <PairwiseDebt>[];
    final processedPairs = <String>{};

    final allUsers = <String>{
      ...directDebts.keys,
      for (final m in directDebts.values) ...m.keys,
    };

    final userList = allUsers.toList();
    for (var i = 0; i < userList.length; i++) {
      for (var j = i + 1; j < userList.length; j++) {
        final u1 = userList[i];
        final u2 = userList[j];

        final pairKey = u1.compareTo(u2) < 0 ? '${u1}_$u2' : '${u2}_$u1';
        if (processedPairs.contains(pairKey)) continue;
        processedPairs.add(pairKey);

        final u1OwesU2 = directDebts[u1]?[u2] ?? 0;
        final u2OwesU1 = directDebts[u2]?[u1] ?? 0;

        if (u1OwesU2 == u2OwesU1) {
          // Exactly opposing debts cancel out completely (no debt)
          continue;
        }

        final String debtor;
        final String creditor;
        final int netPaisa;

        if (u1OwesU2 > u2OwesU1) {
          debtor = u1;
          creditor = u2;
          netPaisa = u1OwesU2 - u2OwesU1;
        } else {
          debtor = u2;
          creditor = u1;
          netPaisa = u2OwesU1 - u1OwesU2;
        }

        // Ignore amounts below 1 paisa
        if (netPaisa < 1) continue;

        final directKey1 = '${u1}_$u2';
        final directKey2 = '${u2}_$u1';

        final hasPending =
            (pendingReviews[directKey1] ?? false) ||
            (pendingReviews[directKey2] ?? false);

        final expIds = <String>{
          ...?relatedExpenses[directKey1],
          ...?relatedExpenses[directKey2],
        }.toList();

        netList.add(PairwiseDebt(
          fromUserId: debtor,
          fromUserName: userNames[debtor] ?? 'Member',
          toUserId: creditor,
          toUserName: userNames[creditor] ?? 'Member',
          netAmount: Money.fromPaisa(netPaisa),
          groupId: groupId,
          groupTitle: groupTitle,
          hasPendingReview: hasPending,
          relatedExpenseIds: expIds,
        ));
      }
    }

    return netList;
  }
}
