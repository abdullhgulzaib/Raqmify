import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/logic/netting_calculator.dart';
import '../core/network/api_client.dart';
import '../core/network/app_failure.dart';
import '../core/network/result.dart';
import '../dev/demo_data.dart';
import '../models/group_model.dart';
import '../models/net_settlement_model.dart';
import '../models/split_expense_model.dart';

// Re-export PairwiseDebt from logic so screens import consistently
export '../core/logic/netting_calculator.dart' show PairwiseDebt;

class PendingProofItem {
  final SplitExpenseModel expense;
  final SplitMemberShare share;

  PendingProofItem({
    required this.expense,
    required this.share,
  });
}

class SplitProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<GroupModel> _groups = [];
  List<SplitExpenseModel> _groupExpenses = [];
  List<NetSettlementModel> _netSettlements = [];
  List<SettlementModel> _settlements = [];
  List<SettlementModel> _pendingSettlementsToVerify = [];
  List<SettlementModel> _pendingSettlementsSubmitted = [];
  final Map<String, DateTime> _lastNudgeTimes = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupModel> get groups => _groups;
  List<SplitExpenseModel> get groupExpenses => _groupExpenses;
  List<NetSettlementModel> get netSettlements => _netSettlements;
  List<SettlementModel> get settlements => _settlements;
  List<SettlementModel> get pendingSettlementsToVerify => _pendingSettlementsToVerify;
  List<SettlementModel> get pendingSettlementsSubmitted => _pendingSettlementsSubmitted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalSharedSpend =>
      _groupExpenses.fold(0.0, (sum, e) => sum + e.totalAmount);
  int get activeGroupsCount => _groups.length;

  SplitProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient() {
    _groups = [];
    _groupExpenses = [];
    _netSettlements = [];
    _settlements = [];
    _pendingSettlementsToVerify = [];
    _pendingSettlementsSubmitted = [];
  }

  void clearData() {
    _groups = [];
    _groupExpenses = [];
    _netSettlements = [];
    _settlements = [];
    _pendingSettlementsToVerify = [];
    _pendingSettlementsSubmitted = [];
    _errorMessage = null;
    notifyListeners();
  }

  void loadDemoData() {
    if (!kDebugMode) return;
    final demo = DemoData.getSampleSplitData();
    _groups = demo.groups;
    _groupExpenses = demo.expenses;
    notifyListeners();
  }

  // --- Analytical Aggregations ---
  double getAmountYouOwe(String currentUserId) {
    final debts = calculateNetBalances(currentUserId);
    return debts
        .where((d) => d.fromUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount.inRupees);
  }

  double getAmountYoureOwed(String currentUserId) {
    final debts = calculateNetBalances(currentUserId);
    return debts
        .where((d) => d.toUserId == currentUserId)
        .fold(0.0, (sum, d) => sum + d.netAmount.inRupees);
  }

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

  // Fetch full SplitVault summary & groups from API
  Future<void> fetchGroupsAndData({bool silent = false, String? currentUserId}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final res = await _apiClient.get(ApiConstants.splitVaultSummary);
      if (res.data != null) {
        final data = res.data is Map<String, dynamic> ? res.data : <String, dynamic>{};

        final rawGroups = ((data['groups'] ?? data['data']?['groups']) as List<dynamic>? ?? []);
        _groups = rawGroups
            .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
            .toList();

        // Support both 'expenses' and 'allExpenses' keys from backend response
        final rawExpenses = ((data['expenses'] ??
                data['allExpenses'] ??
                data['data']?['expenses'] ??
                data['data']?['allExpenses']) as List<dynamic>? ??
            []);
        _groupExpenses = rawExpenses
            .map((e) => SplitExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawNetSettlements = ((data['netSettlements'] ?? data['data']?['netSettlements']) as List<dynamic>? ?? []);
        _netSettlements = rawNetSettlements
            .whereType<Map<String, dynamic>>()
            .map((s) => NetSettlementModel.fromJson(s))
            .toList();

        final rawSettlements = ((data['settlements'] ?? data['data']?['settlements']) as List<dynamic>? ?? []);
        _settlements = rawSettlements
            .whereType<Map<String, dynamic>>()
            .map((s) => SettlementModel.fromJson(s))
            .toList();

        final rawPendingVerify = ((data['pendingSettlementsToVerify'] ?? data['data']?['pendingSettlementsToVerify']) as List<dynamic>? ?? []);
        _pendingSettlementsToVerify = rawPendingVerify
            .whereType<Map<String, dynamic>>()
            .map((s) => SettlementModel.fromJson(s))
            .toList();

        final rawPendingSubmitted = ((data['pendingSettlementsSubmitted'] ?? data['data']?['pendingSettlementsSubmitted']) as List<dynamic>? ?? []);
        _pendingSettlementsSubmitted = rawPendingSubmitted
            .whereType<Map<String, dynamic>>()
            .map((s) => SettlementModel.fromJson(s))
            .toList();

        // Debug logging in debug mode only (D3)
        if (kDebugMode) {
          debugPrint(
            '[SplitProvider.fetchGroupsAndData] Loaded ${_groups.length} groups, ${_groupExpenses.length} expenses. CurrentUser: ${currentUserId ?? "unknown"}',
          );
          for (final exp in _groupExpenses) {
            final splitUserIds = exp.splits.map((s) => s.userId).join(', ');
            debugPrint(
              '  -> Expense: id=${exp.id}, title="${exp.title}", total=${exp.totalAmount}, paidByUserId=${exp.paidByUserId}, splitUserIds=[$splitUserIds]',
            );
          }
        }
      }
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // --- Pairwise Netting Engine (S8) ---
  List<PairwiseDebt> calculateNetBalances(
    String currentUserId, {
    String? groupId,
    bool aggregateAllGroups = false,
  }) {
    return NettingCalculator.computeNetSettlements(
      expenses: _groupExpenses,
      aggregateAllGroups: aggregateAllGroups,
      filterGroupId: groupId,
    );
  }

  List<PairwiseDebt> getYourBalances(
    String currentUserId, {
    String? groupId,
    bool aggregateAllGroups = false,
  }) {
    final all = calculateNetBalances(
      currentUserId,
      groupId: groupId,
      aggregateAllGroups: aggregateAllGroups,
    );
    return NettingCalculator.partitionByUser(
      debts: all,
      currentUserId: currentUserId,
    ).yourBalances;
  }

  List<PairwiseDebt> getOtherBalances(
    String currentUserId, {
    String? groupId,
    bool aggregateAllGroups = false,
  }) {
    final all = calculateNetBalances(
      currentUserId,
      groupId: groupId,
      aggregateAllGroups: aggregateAllGroups,
    );
    return NettingCalculator.partitionByUser(
      debts: all,
      currentUserId: currentUserId,
    ).otherBalances;
  }

  // Submit Proof with Receipt Image (JSON contract)
  Future<Result<void>> submitProof({
    required String expenseId,
    required String userId,
    required String transactionId,
    required String paymentMethod,
    String? receiptImagePath,
    String? imageUrl,
    String? senderNote,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? finalImageUrl = imageUrl;
      if (finalImageUrl == null && receiptImagePath != null && File(receiptImagePath).existsSync()) {
        final bytes = await File(receiptImagePath).readAsBytes();
        final ext = receiptImagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
        finalImageUrl = 'data:image/$ext;base64,${base64Encode(bytes)}';
      }

      final postData = {
        'method': paymentMethod,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId.trim(),
        'proofTid': transactionId.trim(),
        if (finalImageUrl != null && finalImageUrl.isNotEmpty) 'imageUrl': finalImageUrl,
        if (senderNote != null && senderNote.isNotEmpty) 'senderNote': senderNote,
      };

      await _apiClient.post(
        '${ApiConstants.groupExpenses}/$expenseId/splits/$userId/proof',
        data: postData,
      );

      for (int i = 0; i < _groupExpenses.length; i++) {
        if (_groupExpenses[i].id == expenseId) {
          final updatedSplits = _groupExpenses[i].splits.map<SplitMemberShare>((s) {
            if (s.userId == userId) {
              return s.copyWith(
                status: 'UnderReview',
                proofTid: transactionId.trim(),
                paymentMethod: paymentMethod,
                proofImageUrl: finalImageUrl,
              );
            }
            return s;
          }).toList();
          _groupExpenses[i] = _groupExpenses[i].copyWith(splits: updatedSplits);
          break;
        }
      }

      await fetchGroupsAndData(silent: true, currentUserId: userId);
      return const Success(null);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify Proof (Approve or Reject with reason)
  Future<Result<void>> verifyProof({
    required String expenseId,
    required String userId,
    required bool approve,
    String reason = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        '${ApiConstants.groupExpenses}/$expenseId/splits/$userId/verify',
        data: {
          'action': approve ? 'APPROVE' : 'REJECT',
          'reason': reason,
        },
      );

      final newStatus = approve ? 'Verified' : 'Unpaid';
      for (int i = 0; i < _groupExpenses.length; i++) {
        if (_groupExpenses[i].id == expenseId) {
          final updatedSplits = _groupExpenses[i].splits.map<SplitMemberShare>((s) {
            if (s.userId == userId) {
              return s.copyWith(
                status: newStatus,
                proofTid: approve ? s.proofTid : null,
              );
            }
            return s;
          }).toList();
          _groupExpenses[i] = _groupExpenses[i].copyWith(splits: updatedSplits);
          break;
        }
      }

      await fetchGroupsAndData(silent: true, currentUserId: userId);
      return const Success(null);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create One-Shot Net Balance Settlement
  Future<Result<SettlementModel>> createSettlement({
    required String toUserId,
    String? groupId,
    required double amount,
    required String method,
    required String transactionId,
    String? imageUrl,
    String? senderNote,
    String? currentUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'toUserId': toUserId,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        'amount': amount,
        'method': method,
        'transactionId': transactionId.trim(),
        'proofTid': transactionId.trim(),
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (senderNote != null && senderNote.isNotEmpty) 'senderNote': senderNote,
        'paymentDate': DateTime.now().toIso8601String(),
      };

      final res = await _apiClient.post(
        ApiConstants.settlements,
        data: payload,
      );

      final rawData = res.data is Map ? res.data['settlement'] ?? res.data : <String, dynamic>{};
      final settlement = SettlementModel.fromJson(Map<String, dynamic>.from(rawData as Map));

      await fetchGroupsAndData(silent: true, currentUserId: currentUserId);
      return Success(settlement);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      if (e is DioException && e.response?.statusCode == 409) {
        await fetchGroupsAndData(silent: true, currentUserId: currentUserId);
      }
      notifyListeners();
      return Failure(failure);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify or Reject Net Balance Settlement
  Future<Result<void>> verifySettlement({
    required String settlementId,
    required bool approve,
    String reason = '',
    String? currentUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        '${ApiConstants.settlements}/$settlementId/verify',
        data: {
          'action': approve ? 'APPROVE' : 'REJECT',
          'reason': reason,
        },
      );

      await fetchGroupsAndData(silent: true, currentUserId: currentUserId);
      return const Success(null);
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send In-App Nudge Reminder (24-hour client debounce per debt)
  Future<bool> sendNudge({
    required String debtorId,
    required double amount,
    String? groupName,
  }) async {
    final key = '$debtorId-$amount';
    final now = DateTime.now();
    final lastTime = _lastNudgeTimes[key];
    if (lastTime != null && now.difference(lastTime).inHours < 24) {
      return false;
    }

    _lastNudgeTimes[key] = now;
    try {
      await _apiClient.post(
        ApiConstants.nudge,
        data: {
          'debtorId': debtorId,
          'amount': amount,
          if (groupName != null && groupName.isNotEmpty) 'groupName': groupName,
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  // Create Group (S5, S6)
  Future<Result<GroupModel>> createGroup({
    required String name,
    required String description,
    required String category,
    required String currentUserId,
    required String currentUserName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.createGroup,
        data: {
          'name': name.trim(),
          'description': description.trim(),
          'category': category,
          'icon': category == 'Hostel' ? 'home' : (category == 'Trip' ? 'compass' : 'users'),
        },
      );

      if (res.data != null && res.data is Map<String, dynamic>) {
        final created = GroupModel.fromJson(res.data as Map<String, dynamic>);
        _groups.insert(0, created);
        _isLoading = false;
        notifyListeners();
        return Success(created);
      }

      _isLoading = false;
      const failure = AppFailure(message: 'Failed to create group');
      _errorMessage = failure.message;
      notifyListeners();
      return const Failure(failure);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Delete Group (S5)
  Future<Result<void>> deleteGroup(String groupId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.groups}/$groupId');
      _groups.removeWhere((g) => g.id == groupId);
      _groupExpenses.removeWhere((e) => e.groupId == groupId);
      _isLoading = false;
      notifyListeners();
      return const Success(null);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Add Member to Group by Email (Online-only, S6)
  Future<Result<GroupModel>> addMemberToGroup(String groupId, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        '${ApiConstants.groups}/$groupId/members',
        data: {'email': email.trim()},
      );

      final groupData = res.data?['group'] ?? (res.data?['_id'] != null ? res.data : null);
      if (groupData != null) {
        final updatedGroup = GroupModel.fromJson(groupData as Map<String, dynamic>);
        final idx = _groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          _groups[idx] = updatedGroup;
        }
        _isLoading = false;
        notifyListeners();
        return Success(updatedGroup);
      }

      _isLoading = false;
      const failure = AppFailure(message: 'Could not add member');
      _errorMessage = failure.message;
      notifyListeners();
      return const Failure(failure);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Remove Member from Group (Online-only, S6)
  Future<Result<GroupModel>> removeMemberFromGroup(String groupId, String memberId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.delete('${ApiConstants.groups}/$groupId/members/$memberId');
      final groupData = res.data?['group'] ?? (res.data?['_id'] != null ? res.data : null);
      if (groupData != null) {
        final updatedGroup = GroupModel.fromJson(groupData as Map<String, dynamic>);
        final idx = _groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          _groups[idx] = updatedGroup;
        }
        _isLoading = false;
        notifyListeners();
        return Success(updatedGroup);
      }

      _isLoading = false;
      const failure = AppFailure(message: 'Could not remove member');
      _errorMessage = failure.message;
      notifyListeners();
      return const Failure(failure);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Join Group by Invite Code (S6: strict 8-char validation, unambiguous alphabet, online-only)
  Future<Result<GroupModel>> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();

    // S6: Client-side validation: exactly 8 allowed characters (no 0/O/1/I/L)
    final validCodeRegex = RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$');
    if (!validCodeRegex.hasMatch(normalized)) {
      return Failure.fromMessage(
        'Invite code must be exactly 8 characters from allowed letters and numbers (no 0, O, 1, I, L).',
      );
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.joinGroup,
        data: {'inviteCode': normalized},
      );

      if (res.data != null && res.data['group'] != null) {
        final joinedGroup = GroupModel.fromJson(res.data['group'] as Map<String, dynamic>);
        final existingIdx = _groups.indexWhere((g) => g.id == joinedGroup.id);
        if (existingIdx != -1) {
          _groups[existingIdx] = joinedGroup;
        } else {
          _groups.insert(0, joinedGroup);
        }
        _isLoading = false;
        notifyListeners();
        return Success(joinedGroup);
      }

      _isLoading = false;
      const failure = AppFailure(message: 'Invalid invite code or group not found.');
      _errorMessage = failure.message;
      notifyListeners();
      return const Failure(failure);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Create Split Expense (S5, S7)
  Future<Result<SplitExpenseModel>> createSplitExpense({
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
    _isLoading = true;
    _errorMessage = null;

    // 1. Convert participants map to SplitMemberShare list
    final List<SplitMemberShare> localSplits = participants.map((p) {
      final pUserId = (p['userId'] ?? p['user'] ?? '').toString();
      final pName = (p['name'] ?? '').toString();
      final pEmail = (p['email'] ?? '').toString();
      final pAmount = (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
      final pPct = (p['percentage'] is num) ? (p['percentage'] as num).toDouble() : 0.0;
      final isPayer = pUserId == paidByUserId;
      return SplitMemberShare(
        userId: pUserId,
        name: pName,
        email: pEmail,
        amount: pAmount,
        percentage: pPct,
        status: isPayer ? 'Paid' : 'Unpaid',
      );
    }).toList();

    // 2. Create local optimistic model
    final tempId = 'split_${DateTime.now().millisecondsSinceEpoch}';
    final localExpense = SplitExpenseModel(
      id: tempId,
      title: title.trim(),
      totalAmount: totalAmount,
      category: category,
      paidByUserId: paidByUserId,
      paidByName: paidByName,
      groupId: groupId.isNotEmpty ? groupId : null,
      groupName: groupName,
      splitType: splitType,
      date: DateTime.now(),
      notes: notes,
      isFullySettled: false,
      splits: localSplits,
    );

    // Optimistically insert locally so state and UI reflect immediately
    _groupExpenses.insert(0, localExpense);
    _isLoading = false;
    notifyListeners();

    // 3. Attempt server sync
    try {
      final res = await _apiClient.post(
        ApiConstants.groupExpenses,
        data: {
          'title': title.trim(),
          'totalAmount': totalAmount,
          'category': category,
          'paidBy': paidByUserId,
          'paidByUserId': paidByUserId,
          'paidByName': paidByName,
          'groupId': groupId,
          'groupName': groupName,
          'splitType': splitType,
          'notes': notes,
          'participants': participants,
          'splits': localSplits.map((s) => s.toJson()).toList(),
        },
      );

      if (res.data != null) {
        final Map<String, dynamic> rawMap =
            res.data is Map<String, dynamic> ? res.data : {};
        final expenseMap = rawMap['expense'] ??
            rawMap['data']?['expense'] ??
            rawMap['data'] ??
            rawMap;

        if (expenseMap is Map<String, dynamic> &&
            (expenseMap['_id'] != null ||
                expenseMap['id'] != null ||
                expenseMap['title'] != null)) {
          final serverExpense = SplitExpenseModel.fromJson(expenseMap);
          final resolvedSplits = serverExpense.splits.isNotEmpty
              ? serverExpense.splits
              : localSplits;

          final updated = serverExpense.copyWith(
            paidByUserId: serverExpense.paidByUserId.isNotEmpty
                ? serverExpense.paidByUserId
                : paidByUserId,
            paidByName: serverExpense.paidByName.isNotEmpty
                ? serverExpense.paidByName
                : paidByName,
            splits: resolvedSplits,
          );

          final idx = _groupExpenses.indexWhere((e) => e.id == tempId);
          if (idx != -1) {
            _groupExpenses[idx] = updated;
          } else {
            _groupExpenses.insert(0, updated);
          }
          notifyListeners();

          // Authoritative reconcile with server
          await fetchGroupsAndData(silent: true, currentUserId: paidByUserId);
          return Success(updated);
        }
      }

      // If response is not recognizable as an expense, rollback temporary insertion
      _groupExpenses.removeWhere((e) => e.id == tempId);
      const failure = AppFailure(message: 'Server did not confirm this expense. Please try again.');
      _errorMessage = failure.message;
      notifyListeners();
      return const Failure(failure);
    } catch (e) {
      // Rollback temporary optimistic expense on exception
      _groupExpenses.removeWhere((e) => e.id == tempId);
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Delete Split Expense (S5)
  Future<Result<void>> deleteSplitExpense(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.groupExpenses}/$id');
      _groupExpenses.removeWhere((e) => e.id == id);
      _isLoading = false;
      notifyListeners();
      return const Success(null);
    } catch (e) {
      _isLoading = false;
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      notifyListeners();
      return Failure(failure);
    }
  }

  // Restore Split Expense for Undo (U5)
  void restoreSplitExpense(SplitExpenseModel expense) {
    if (!_groupExpenses.any((e) => e.id == expense.id)) {
      _groupExpenses.insert(0, expense);
      notifyListeners();
    }
  }

  List<SplitExpenseModel> getExpensesForGroup(String groupId) {
    if (groupId.isEmpty || groupId == 'all') {
      return _groupExpenses;
    }
    return _groupExpenses.where((e) => e.groupId == groupId).toList();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
