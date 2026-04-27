import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save FCM token to Firestore
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground message: ${message.notification?.title}');
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