import 'package:shared_preferences/shared_preferences.dart';
import '../../models/expense_model.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class RetentionStatus {
  final int daysRemaining;
  final int affectedRecordCount;
  final DateTime pruneDate;
  final bool isApproachingPrune;
  final bool isClientFallback;

  const RetentionStatus({
    required this.daysRemaining,
    required this.affectedRecordCount,
    required this.pruneDate,
    required this.isApproachingPrune,
    this.isClientFallback = false,
  });
}

class RetentionService {
  final ApiClient _apiClient = ApiClient();
  static const String _kRetentionDismissedKey = 'retention_alert_dismissed';

  Future<bool> isRetentionNoticeDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRetentionDismissedKey) ?? false;
  }

  Future<void> dismissRetentionNotice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRetentionDismissedKey, true);
  }

  Future<void> resetRetentionNoticeDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRetentionDismissedKey);
  }

  /// Checks server cleanup status, falling back to client-side calculation if endpoint unavailable (F2).
  Future<RetentionStatus?> checkCleanupStatus(List<ExpenseModel> localExpenses) async {
    if (await isRetentionNoticeDismissed()) {
      return null;
    }

    try {
      final res = await _apiClient.get(ApiConstants.cleanupStatus);
      if (res.data != null && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final days = (data['daysRemaining'] as num?)?.toInt() ?? 60;
        final count = (data['affectedRecordsCount'] as num?)?.toInt() ?? 0;
        final pruneDate = data['pruneDate'] != null
            ? DateTime.tryParse(data['pruneDate']) ?? DateTime.now().add(Duration(days: days))
            : DateTime.now().add(Duration(days: days));

        return RetentionStatus(
          daysRemaining: days,
          affectedRecordCount: count,
          pruneDate: pruneDate,
          isApproachingPrune: days <= 7 && count > 0,
          isClientFallback: false,
        );
      }
    } catch (_) {
      // Fallback: client-side calculation from oldest expense date (F2)
    }

    if (localExpenses.isEmpty) return null;

    final now = DateTime.now();
    var oldestDate = now;
    var affectedCount = 0;

    for (final exp in localExpenses) {
      if (exp.date.isBefore(oldestDate)) {
        oldestDate = exp.date;
      }
      final ageDays = now.difference(exp.date).inDays;
      if (ageDays >= 53) {
        affectedCount++;
      }
    }

    final oldestAgeDays = now.difference(oldestDate).inDays;
    final remainingDays = (60 - oldestAgeDays).clamp(0, 60);

    return RetentionStatus(
      daysRemaining: remainingDays,
      affectedRecordCount: affectedCount,
      pruneDate: oldestDate.add(const Duration(days: 60)),
      isApproachingPrune: remainingDays <= 7 && affectedCount > 0,
      isClientFallback: true,
    );
  }
}
