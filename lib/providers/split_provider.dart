import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/group_model.dart';
import '../models/split_expense_model.dart';

class PairwiseDebt {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double netAmount;

  PairwiseDebt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.netAmount,
  });
}

class PendingProofItem {
  final SplitExpenseModel expense;
  final SplitMemberShare share;

  PendingProofItem({
    required this.expense,
    required this.share,
  });
}

class SplitProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<GroupModel> _groups = [];
  List<SplitExpenseModel> _groupExpenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  double _amountYouOwe = 0.0;
  double _amountYoureOwed = 0.0;

  List<GroupModel> get groups => _groups;
  List<SplitExpenseModel> get groupExpenses => _groupExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get amountYouOwe => _amountYouOwe;
  double get amountYoureOwed => _amountYoureOwed;

  double get totalSharedSpend => _groupExpenses.fold(0.0, (sum, e) => sum + e.totalAmount);
  int get activeGroupsCount => _groups.length;

  List<PendingProofItem> getPendingVerificationsForCreditor(String creditorUserId) {
    final List<PendingProofItem> list = [];
    for (final exp in _groupExpenses) {
      if (exp.paidByUserId == creditorUserId) {
        for (final s in exp.splits) {
          if (s.status == 'UnderReview' && s.userId != creditorUserId) {
            list.add(PendingProofItem(expense: exp, share: s));
          }
        }
      }
    }
    return list;
  }

  List<PendingProofItem> getPendingSubmittedProofsForDebtor(String debtorUserId) {
    final List<PendingProofItem> list = [];
    for (final exp in _groupExpenses) {
      for (final s in exp.splits) {
        if (s.userId == debtorUserId && s.status == 'UnderReview') {
          list.add(PendingProofItem(expense: exp, share: s));
        }
      }
    }
    return list;
  }

  SplitProvider() {
    _groups = [];
    _groupExpenses = [];
  }

  void clearData() {
    _groups = [];
    _groupExpenses = [];
    _amountYouOwe = 0.0;
    _amountYoureOwed = 0.0;
    notifyListeners();
  }

  void loadDemoData() {
    _initSampleSplitData();
    notifyListeners();
  }

  // Fetch full SplitVault summary & groups from MongoDB API
  Future<void> fetchGroupsAndData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final summaryRes = await _apiClient.get(ApiConstants.splitVaultSummary);
      if (summaryRes.data != null && summaryRes.data is Map<String, dynamic>) {
        final data = summaryRes.data as Map<String, dynamic>;

        _amountYouOwe = (data['amountYouOwe'] is num) ? (data['amountYouOwe'] as num).toDouble() : 0.0;
        _amountYoureOwed = (data['amountYoureOwed'] is num) ? (data['amountYoureOwed'] as num).toDouble() : 0.0;

        // Parse Groups
        if (data['groups'] != null && data['groups'] is List) {
          final rawGroups = data['groups'] as List<dynamic>;
          _groups = rawGroups.map((g) => GroupModel.fromJson(g as Map<String, dynamic>)).toList();
        }

        // Parse All Expenses
        if (data['allExpenses'] != null && data['allExpenses'] is List) {
          final rawExp = data['allExpenses'] as List<dynamic>;
          _groupExpenses = rawExp.map((e) => SplitExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // Fallback: try direct groups endpoint
      try {
        final groupRes = await _apiClient.get(ApiConstants.groups);
        if (groupRes.data != null && groupRes.data is List) {
          final list = groupRes.data as List<dynamic>;
          _groups = list.map((g) => GroupModel.fromJson(g as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initSampleSplitData() {
    final now = DateTime.now();

    _amountYoureOwed = 846.67;
    _amountYouOwe = 500.0;

    // 1. Sample Hostel Group
    _groups = [
      GroupModel(
        id: 'grp_hostel_304',
        name: 'Hostel Room 304 (Lahore)',
        description: 'Roommate shared expenses, mess & utilities',
        category: 'Hostel',
        icon: 'home',
        createdBy: 'demo_user_101', // Rana Abdullah
        inviteCode: 'HOSTEL',
        createdAt: now.subtract(const Duration(days: 15)),
        members: [
          GroupMember(userId: 'demo_user_101', name: 'Rana Abdullah', email: 'rana@hostel.edu.pk', role: 'Admin'),
          GroupMember(userId: 'user_ali', name: 'Ali (Flatmate)', email: 'ali@tech.pk', role: 'Member'),
          GroupMember(userId: 'user_abdul', name: 'Abdul Rehman', email: 'abdul@hostel.edu.pk', role: 'Member'),
        ],
      ),
      GroupModel(
        id: 'grp_trip_north',
        name: 'Northern Areas Roadtrip',
        description: 'Fuel, hotel stays & snacks',
        category: 'Trip',
        icon: 'compass',
        createdBy: 'user_ali',
        inviteCode: 'TRIP26',
        createdAt: now.subtract(const Duration(days: 20)),
        members: [
          GroupMember(userId: 'demo_user_101', name: 'Rana Abdullah', email: 'rana@hostel.edu.pk'),
          GroupMember(userId: 'user_ali', name: 'Ali', email: 'ali@tech.pk'),
        ],
      ),
    ];

    // 2. Sample Shared Expenses within Hostel Room 304
    _groupExpenses = [
      SplitExpenseModel(
        id: 'split_1',
        title: 'Weekly Grocery & Mess Ration',
        totalAmount: 2540.0,
        category: 'Groceries',
        paidByUserId: 'demo_user_101', // Paid by Rana
        paidByName: 'Rana Abdullah',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 4)),
        splits: [
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 846.66, status: 'Settled'),
          SplitMemberShare(
            userId: 'user_ali',
            name: 'Ali (Flatmate)',
            amount: 846.67,
            status: 'Verified',
            proofTid: 'EP-9831772',
            paymentMethod: 'Easypaisa',
          ),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 846.67, status: 'Unpaid'),
        ],
      ),
      SplitExpenseModel(
        id: 'split_2',
        title: 'Generator Fuel & Utility Bill',
        totalAmount: 1800.0,
        category: 'Utilities',
        paidByUserId: 'demo_user_101', // Paid by Rana
        paidByName: 'Rana Abdullah',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 2)),
        splits: [
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 600.0, status: 'Settled'),
          SplitMemberShare(userId: 'user_ali', name: 'Ali (Flatmate)', amount: 600.0, status: 'Unpaid'),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 600.0, status: 'Unpaid'),
        ],
      ),
      SplitExpenseModel(
        id: 'split_3',
        title: 'Late Night Biryani & Chai',
        totalAmount: 1500.0,
        category: 'Food',
        paidByUserId: 'user_ali', // Paid by Ali
        paidByName: 'Ali (Flatmate)',
        groupId: 'grp_hostel_304',
        groupName: 'Hostel Room 304 (Lahore)',
        splitType: 'Equal',
        date: now.subtract(const Duration(days: 1)),
        splits: [
          SplitMemberShare(userId: 'user_ali', name: 'Ali (Flatmate)', amount: 500.0, status: 'Settled'),
          SplitMemberShare(userId: 'demo_user_101', name: 'Rana Abdullah', amount: 500.0, status: 'Unpaid'),
          SplitMemberShare(userId: 'user_abdul', name: 'Abdul Rehman', amount: 500.0, status: 'Unpaid'),
        ],
      ),
    ];
  }

  // --- Pairwise Netting Algorithm (Objective 05 in Proposal) ---
  List<PairwiseDebt> calculateNetBalances(String currentUserId) {
    final Map<String, Map<String, double>> directDebts = {};
    final Map<String, String> userNames = {};

    for (final exp in _groupExpenses) {
      final creditor = exp.paidByUserId;
      userNames[creditor] = exp.paidByName;

      for (final s in exp.splits) {
        userNames[s.userId] = s.name;
        if (s.userId != creditor && s.status != 'Settled' && s.status != 'Verified') {
          directDebts.putIfAbsent(s.userId, () => {});
          directDebts[s.userId]![creditor] = (directDebts[s.userId]![creditor] ?? 0.0) + s.amount;
        }
      }
    }

    final List<PairwiseDebt> netList = [];
    final Set<String> processedPairs = {};

    for (final debtor in directDebts.keys) {
      for (final creditor in directDebts[debtor]!.keys) {
        final pairKey = [debtor, creditor]..sort();
        final pairId = pairKey.join('_');

        if (processedPairs.contains(pairId)) continue;
        processedPairs.add(pairId);

        final dOwesC = directDebts[debtor]?[creditor] ?? 0.0;
        final cOwesD = directDebts[creditor]?[debtor] ?? 0.0;

        if (dOwesC > cOwesD) {
          final net = dOwesC - cOwesD;
          if (net > 0.01) {
            netList.add(PairwiseDebt(
              fromUserId: debtor,
              fromUserName: userNames[debtor] ?? 'Member',
              toUserId: creditor,
              toUserName: userNames[creditor] ?? 'Member',
              netAmount: net,
            ));
          }
        } else if (cOwesD > dOwesC) {
          final net = cOwesD - dOwesC;
          if (net > 0.01) {
            netList.add(PairwiseDebt(
              fromUserId: creditor,
              fromUserName: userNames[creditor] ?? 'Member',
              toUserId: debtor,
              toUserName: userNames[debtor] ?? 'Member',
              netAmount: net,
            ));
          }
        }
      }
    }

    return netList;
  }

  // Submit Single-Proof TID Batch Payment
  Future<void> submitProof({
    required String expenseId,
    required String userId,
    required String transactionId,
    required String paymentMethod,
  }) async {
    // 1. Optimistic local update
    for (int i = 0; i < _groupExpenses.length; i++) {
      if (_groupExpenses[i].id == expenseId) {
        final splits = _groupExpenses[i].splits.map((s) {
          if (s.userId == userId) {
            return SplitMemberShare(
              userId: s.userId,
              name: s.name,
              email: s.email,
              amount: s.amount,
              percentage: s.percentage,
              status: 'UnderReview',
              proofTid: transactionId,
              paymentMethod: paymentMethod,
            );
          }
          return s;
        }).toList();

        _groupExpenses[i] = SplitExpenseModel(
          id: _groupExpenses[i].id,
          title: _groupExpenses[i].title,
          totalAmount: _groupExpenses[i].totalAmount,
          category: _groupExpenses[i].category,
          paidByUserId: _groupExpenses[i].paidByUserId,
          paidByName: _groupExpenses[i].paidByName,
          groupId: _groupExpenses[i].groupId,
          groupName: _groupExpenses[i].groupName,
          splitType: _groupExpenses[i].splitType,
          date: _groupExpenses[i].date,
          notes: _groupExpenses[i].notes,
          splits: splits,
        );
        break;
      }
    }
    notifyListeners();

    // 2. Call backend
    try {
      await _apiClient.post(
        '${ApiConstants.groupExpenses}/$expenseId/splits/$userId/proof',
        data: {
          'proofTid': transactionId,
          'paymentMethod': paymentMethod,
        },
      );
    } catch (_) {}
  }

  // Creditor 1-Click Approval
  Future<void> verifyProof({
    required String expenseId,
    required String userId,
    required bool approve,
  }) async {
    // 1. Optimistic local update
    for (int i = 0; i < _groupExpenses.length; i++) {
      if (_groupExpenses[i].id == expenseId) {
        final splits = _groupExpenses[i].splits.map((s) {
          if (s.userId == userId) {
            return SplitMemberShare(
              userId: s.userId,
              name: s.name,
              email: s.email,
              amount: s.amount,
              percentage: s.percentage,
              status: approve ? 'Verified' : 'Rejected',
              proofTid: s.proofTid,
              paymentMethod: s.paymentMethod,
            );
          }
          return s;
        }).toList();

        _groupExpenses[i] = SplitExpenseModel(
          id: _groupExpenses[i].id,
          title: _groupExpenses[i].title,
          totalAmount: _groupExpenses[i].totalAmount,
          category: _groupExpenses[i].category,
          paidByUserId: _groupExpenses[i].paidByUserId,
          paidByName: _groupExpenses[i].paidByName,
          groupId: _groupExpenses[i].groupId,
          groupName: _groupExpenses[i].groupName,
          splitType: _groupExpenses[i].splitType,
          date: _groupExpenses[i].date,
          notes: _groupExpenses[i].notes,
          splits: splits,
        );
        break;
      }
    }
    notifyListeners();

    // 2. Call backend
    try {
      await _apiClient.post(
        '${ApiConstants.groupExpenses}/$expenseId/splits/$userId/verify',
        data: {'approve': approve},
      );
    } catch (_) {}
  }

  // Create Group
  Future<bool> createGroup({
    required String name,
    required String description,
    required String category,
    required String currentUserId,
    required String currentUserName,
  }) async {
    final code = name.length >= 3 ? '${name.substring(0, 3).toUpperCase()}26' : 'GRP26';
    final newGroup = GroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      icon: category == 'Hostel' ? 'home' : (category == 'Trip' ? 'compass' : 'users'),
      createdBy: currentUserId,
      inviteCode: code,
      createdAt: DateTime.now(),
      members: [
        GroupMember(userId: currentUserId, name: currentUserName, email: '', role: 'Admin'),
      ],
    );

    _groups.insert(0, newGroup);
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.createGroup,
        data: {
          'name': name,
          'description': description,
          'category': category,
          'icon': newGroup.icon,
        },
      );
      if (res.data != null && res.data is Map<String, dynamic>) {
        final created = GroupModel.fromJson(res.data as Map<String, dynamic>);
        final idx = _groups.indexWhere((g) => g.id == newGroup.id);
        if (idx != -1) {
          _groups[idx] = created;
          notifyListeners();
        }
      }
      return true;
    } catch (_) {
      return true; // Local creation preserved
    }
  }

  // Delete Group (Requested by user)
  Future<bool> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    _groupExpenses.removeWhere((e) => e.groupId == groupId);
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.groups}/$groupId');
      return true;
    } catch (_) {
      return true;
    }
  }

  // Add Member to Group by Email
  Future<Map<String, dynamic>> addMemberToGroup(String groupId, String email, {String? fallbackName}) async {
    try {
      final res = await _apiClient.post(
        '${ApiConstants.groups}/$groupId/members',
        data: {'email': email.trim()},
      );
      if (res.data != null && res.data['group'] != null) {
        final updatedGroup = GroupModel.fromJson(res.data['group'] as Map<String, dynamic>);
        final idx = _groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          _groups[idx] = updatedGroup;
        }
        notifyListeners();
        return {'success': true, 'message': res.data['message'] ?? 'Member added successfully'};
      }
    } catch (e) {
      // Offline / fallback addition
      final cleanEmail = email.trim();
      final idx = _groups.indexWhere((g) => g.id == groupId);
      if (idx != -1) {
        final g = _groups[idx];
        if (!g.members.any((m) => m.email.toLowerCase() == cleanEmail.toLowerCase())) {
          final newMember = GroupMember(
            userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
            name: (fallbackName != null && fallbackName.isNotEmpty) ? fallbackName : cleanEmail.split('@').first,
            email: cleanEmail,
            role: 'Member',
            joinedAt: DateTime.now(),
          );
          final updatedMembers = List<GroupMember>.from(g.members)..add(newMember);
          _groups[idx] = GroupModel(
            id: g.id,
            name: g.name,
            description: g.description,
            category: g.category,
            icon: g.icon,
            createdBy: g.createdBy,
            inviteCode: g.inviteCode,
            createdAt: g.createdAt,
            members: updatedMembers,
          );
          notifyListeners();
          return {'success': true, 'message': 'Member added successfully'};
        }
      }
      return {'success': false, 'message': 'Failed to add member: $e'};
    }
    return {'success': false, 'message': 'Could not add member'};
  }

  // Remove Member from Group
  Future<bool> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      final res = await _apiClient.delete('${ApiConstants.groups}/$groupId/members/$memberId');
      if (res.data != null && res.data['group'] != null) {
        final updatedGroup = GroupModel.fromJson(res.data['group'] as Map<String, dynamic>);
        final idx = _groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          _groups[idx] = updatedGroup;
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}

    // Fallback: local remove
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final g = _groups[idx];
      final updatedMembers = g.members.where((m) => m.userId != memberId).toList();
      _groups[idx] = GroupModel(
        id: g.id,
        name: g.name,
        description: g.description,
        category: g.category,
        icon: g.icon,
        createdBy: g.createdBy,
        inviteCode: g.inviteCode,
        createdAt: g.createdAt,
        members: updatedMembers,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // Delete Split Expense
  Future<bool> deleteSplitExpense(String id) async {
    _groupExpenses.removeWhere((e) => e.id == id);
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.groupExpenses}/$id');
      return true;
    } catch (_) {
      return true;
    }
  }

  // Create Custom Split Expense (With exact/percentage/equal custom participant lists)
  Future<bool> createSplitExpense({
    required String title,
    required double totalAmount,
    required String category,
    required String groupId,
    required String groupName,
    required String splitType,
    required String paidByUserId,
    required String paidByName,
    required String notes,
    required List<Map<String, dynamic>> participants,
  }) async {
    final splits = participants.map((p) {
      final uid = p['userId'] as String;
      final isPayer = uid == paidByUserId;
      return SplitMemberShare(
        userId: uid,
        name: p['name'] as String,
        amount: (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0,
        percentage: (p['percentage'] is num) ? (p['percentage'] as num).toDouble() : 0.0,
        status: isPayer ? 'Settled' : 'Unpaid',
      );
    }).toList();

    final newSplitExp = SplitExpenseModel(
      id: 'split_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      totalAmount: totalAmount,
      category: category,
      paidByUserId: paidByUserId,
      paidByName: paidByName,
      groupId: groupId,
      groupName: groupName,
      splitType: splitType,
      date: DateTime.now(),
      notes: notes,
      splits: splits,
    );

    _groupExpenses.insert(0, newSplitExp);
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.groupExpenses,
        data: {
          'title': title,
          'totalAmount': totalAmount,
          'category': category,
          'groupId': groupId,
          'splitType': splitType,
          'notes': notes,
          'participants': participants,
        },
      );
      if (res.data != null && res.data is Map<String, dynamic>) {
        final created = SplitExpenseModel.fromJson(res.data as Map<String, dynamic>);
        final idx = _groupExpenses.indexWhere((e) => e.id == newSplitExp.id);
        if (idx != -1) {
          _groupExpenses[idx] = created;
          notifyListeners();
        }
      }
    } catch (_) {}
    return true;
  }

  // Convenience Aliases for UI Binding
  List<PairwiseDebt> getDebtsForUser(String userId) {
    return calculateNetBalances(userId);
  }

  List<SplitExpenseModel> getExpensesForGroup(String groupId) {
    if (groupId.isEmpty || groupId == 'all') {
      return _groupExpenses;
    }
    return _groupExpenses.where((e) => e.groupId == groupId).toList();
  }

  void submitProofOfPayment({
    required String expenseId,
    required String memberUserId,
    required String proofTid,
    required String method,
  }) {
    submitProof(
      expenseId: expenseId,
      userId: memberUserId,
      transactionId: proofTid,
      paymentMethod: method,
    );
  }

  void verifyPaymentProof({
    required String expenseId,
    required String memberUserId,
  }) {
    verifyProof(
      expenseId: expenseId,
      userId: memberUserId,
      approve: true,
    );
  }

  void addGroupExpense(SplitExpenseModel expense) {
    _groupExpenses.insert(0, expense);
    notifyListeners();
  }

  Future<bool> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      final res = await _apiClient.post(
        ApiConstants.joinGroup,
        data: {'inviteCode': inviteCode.trim().toUpperCase()},
      );
      if (res.data != null && res.data['group'] != null) {
        final joinedGroup = GroupModel.fromJson(res.data['group'] as Map<String, dynamic>);
        final existingIdx = _groups.indexWhere((g) => g.id == joinedGroup.id);
        if (existingIdx != -1) {
          _groups[existingIdx] = joinedGroup;
        } else {
          _groups.insert(0, joinedGroup);
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}

    // Fallback: local join
    for (int i = 0; i < _groups.length; i++) {
      if (_groups[i].inviteCode.toUpperCase() == inviteCode.toUpperCase()) {
        final existing = _groups[i].members.any((m) => m.userId == userId);
        if (!existing) {
          final updatedMembers = List<GroupMember>.from(_groups[i].members)
            ..add(GroupMember(userId: userId, name: userName, email: userEmail, role: 'Member'));

          _groups[i] = GroupModel(
            id: _groups[i].id,
            name: _groups[i].name,
            description: _groups[i].description,
            category: _groups[i].category,
            icon: _groups[i].icon,
            createdBy: _groups[i].createdBy,
            inviteCode: _groups[i].inviteCode,
            createdAt: _groups[i].createdAt,
            members: updatedMembers,
          );
          notifyListeners();
        }
        return true;
      }
    }
    return false;
  }
}
