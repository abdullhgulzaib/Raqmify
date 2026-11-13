import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/app_failure.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  NotificationProvider() {
    fetchNotifications();
  }

  void clearData() {
    _notifications = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.notifications);
      if (response.data != null) {
        final listData = response.data is List
            ? response.data as List
            : (response.data['notifications'] ?? response.data['data'] ?? []) as List;

        _notifications = listData
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Sort descending by creation date
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    if (_notifications.isEmpty) return;

    _notifications = [];
    notifyListeners();

    try {
      await _apiClient.delete(ApiConstants.notifications);
    } catch (_) {
      // In offline/demo mode, keep local clearance
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    _notifications.removeAt(index);
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
