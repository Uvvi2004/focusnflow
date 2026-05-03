import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveToken();

    _messaging.onTokenRefresh.listen(_updateToken);

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

  // Called when a task is added and is High priority
  Future<void> sendHighPriorityAlert({
    required String taskTitle,
    required String courseName,
    required String userId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': '🔴 High Priority Task',
      'body': '$courseName — $taskTitle needs your attention now!',
      'recipients': [userId],
      'createdAt': Timestamp.now(),
      'type': 'deadline',
    });
  }

  // Called when a task is due within 24 hours
  Future<void> send24HourReminder({
    required String taskTitle,
    required String courseName,
    required String userId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': '⏰ Due in 24 Hours',
      'body': '$courseName — $taskTitle is due tomorrow!',
      'recipients': [userId],
      'createdAt': Timestamp.now(),
      'type': 'deadline',
    });
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