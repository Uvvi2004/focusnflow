import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'focusnflow_channel',
      'FocusNFlow Notifications',
      description: 'Notifications for study reminders and group updates',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Save FCM token to Firestore
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _saveToken() async {
    final token = await _messaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (token != null && uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focusnflow_channel',
          'FocusNFlow Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Send notification via Firestore trigger
  // In production this would use Cloud Functions
  // For demo we store notification requests in Firestore
  Future<void> sendGroupNotification({
    required String groupName,
    required String message,
    required List<String> memberUids,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'FocusNFlow — $groupName',
      'body': message,
      'recipients': memberUids,
      'createdAt': Timestamp.now(),
      'type': 'group',
    });
  }

  Future<void> sendDeadlineReminder({
    required String taskTitle,
    required String courseName,
    required String userId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Deadline Reminder',
      'body': '$courseName — $taskTitle is due soon!',
      'recipients': [userId],
      'createdAt': Timestamp.now(),
      'type': 'deadline',
    });
  }
}