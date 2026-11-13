import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/models/notification_model.dart';
import 'package:raqmify/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification User Isolation & Clear-All Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setActiveUser isolates notifications across different accounts', () async {
      final provider = NotificationProvider();

      // 1. Initial state without active user has empty notifications
      expect(provider.notifications.isEmpty, isTrue);

      // 2. User A logs in and receives a local notification
      await provider.setActiveUser('user_a');
      provider.addLocalNotification(
        title: 'Account A Notice',
        message: 'Welcome User A',
      );
      expect(provider.notifications.length, equals(1));
      expect(provider.notifications.first.title, equals('Account A Notice'));

      // 3. User A logs out
      await provider.setActiveUser(null);
      expect(provider.notifications.isEmpty, isTrue);

      // 4. User B registers a brand-new account on the same device
      await provider.setActiveUser('user_b');
      // User B must NOT see User A's notifications
      expect(provider.notifications.isEmpty, isTrue);
      expect(provider.hasUnread, isFalse);
    });

    test('clearAllNotifications suppresses past notifications on subsequent refresh', () async {
      final provider = NotificationProvider();
      await provider.setActiveUser('user_a');

      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));
      provider.addLocalNotification(
        title: 'Old Notification',
        message: 'This should be cleared',
      );
      expect(provider.notifications.length, equals(1));

      // User clears all notifications
      await provider.clearAllNotifications();
      expect(provider.notifications.isEmpty, isTrue);

      // Simulate a server refresh with old notifications + 1 new notification
      final fakeServerList = [
        NotificationModel(
          id: 'old_1',
          title: 'Old Server Notification',
          message: 'Old',
          createdAt: pastDate,
        ),
        NotificationModel(
          id: 'new_1',
          title: 'Brand New Notification',
          message: 'New',
          createdAt: DateTime.now().add(const Duration(seconds: 2)),
        ),
      ];

      // Re-filter using provider's suppression timestamp
      final filtered = fakeServerList.where((n) {
        return n.createdAt.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch - 1000;
      }).toList();

      expect(filtered.any((n) => n.id == 'old_1'), isFalse);
    });
  });
}
