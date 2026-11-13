import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/app_failure.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Local suppression sets per user
  int _clearedAtTimestamp = 0;
  final Set<String> _deletedIds = {};

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  String? get currentUserId => _currentUserId;

  NotificationProvider();

  Future<void> setActiveUser(String? userId) async {
    if (_currentUserId == userId && userId != null) return;

    _currentUserId = userId;
    _notifications = [];
    _deletedIds.clear();
    _clearedAtTimestamp = 0;
    _errorMessage = null;

    if (userId != null && userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _clearedAtTimestamp = prefs.getInt('notif_cleared_at_$userId') ?? 0;
      final savedDeleted = prefs.getStringList('notif_deleted_ids_$userId') ?? [];
      _deletedIds.addAll(savedDeleted);
      await fetchNotifications();
    } else {
      notifyListeners();
    }
  }

  void clearData() {
    _notifications = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    // If no active user is set, keep notifications empty to prevent cross-account leak
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _notifications = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.notifications);
      if (response.data != null) {
        final listData = response.data is List
            ? response.data as List
            : (response.data['notifications'] ?? response.data['data'] ?? []) as List;

        final parsed = listData
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Filter out:
        // 1. Any notification deleted by the user
        // 2. Any notification created before the user tapped "Clear All"
        _notifications = parsed.where((n) {
          if (_deletedIds.contains(n.id)) return false;
          if (_clearedAtTimestamp > 0 && n.createdAt.millisecondsSinceEpoch <= _clearedAtTimestamp) {
            return false;
          }
          return true;
        }).toList();

        // Sort descending by creation date
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _notifications = [];
      }
    } catch (e) {
      final failure = AppFailure.fromException(e);
      _errorMessage = failure.message;
      if (kDebugMode) {
        debugPrint('[NotificationProvider.fetchNotifications] $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    final oldItem = _notifications[index];
    _notifications[index] = oldItem.copyWith(isRead: true);
    notifyListeners();

    try {
      await _apiClient.put('${ApiConstants.notifications}/$notificationId/read');
    } catch (_) {
      // Revert if server call fails
      _notifications[index] = oldItem;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty || unreadCount == 0) return;

    final previous = List<NotificationModel>.from(_notifications);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _apiClient.put('${ApiConstants.notifications}/read-all');
    } catch (_) {
      _notifications = previous;
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    _notifications = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    _clearedAtTimestamp = now;

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_cleared_at_$_currentUserId', now);
    }

    notifyListeners();

    try {
      await _apiClient.delete(ApiConstants.notifications);
    } catch (_) {
      // Server may not support DELETE /api/notifications or device offline;
      // local suppression timestamp guarantees cleared notifications never return.
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _deletedIds.add(notificationId);

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notif_deleted_ids_$_currentUserId', _deletedIds.toList());
    }

    notifyListeners();

    try {
      await _apiClient.delete('${ApiConstants.notifications}/$notificationId');
    } catch (_) {
      // In offline/demo mode, keep local deletion
    }
  }

  void addLocalNotification({
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic> metadata = const {},
  }) {
    final newNotif = NotificationModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      metadata: metadata,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }
}
