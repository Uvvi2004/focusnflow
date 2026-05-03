import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FCM token lifecycle:
//   1. initialize() is called at app startup (see main.dart).
//   2. requestPermission asks the OS for notification rights.
//   3. _saveToken writes the device token to users/{uid}.fcmToken.
//   4. onTokenRefresh keeps the stored token current across OS token rotations.
//
// Foreground message display is handled by the global listener in main.dart
// so the ScaffoldMessenger can show a SnackBar regardless of which screen
// is active.
//
// The sendX helpers write to the notifications collection. A Cloud Function
// (functions/index.js) must listen to notifications.onCreate and call
// messaging.sendMulticast() to deliver the actual push. Without the Cloud
// Function the docs land in Firestore and appear in the in-app bell, but
// the OS push does not fire.
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> storeIncomingMessageForBell(RemoteMessage message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title =
        message.notification?.title ?? (message.data['title'] as String?) ?? '';
    final body =
        message.notification?.body ?? (message.data['body'] as String?) ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final type = (message.data['type'] as String?) ?? 'campaign';
    final messageId = message.messageId;

    final payload = {
      'title': title,
      'body': body,
      'recipients': [uid],
      'createdAt': Timestamp.now(),
      'type': type,
      'source': 'fcm',
    };

    final notifications = FirebaseFirestore.instance.collection('notifications');
    if (messageId != null && messageId.isNotEmpty) {
      await notifications.doc('fcm_$messageId').set(payload, SetOptions(merge: true));
      return;
    }

    await notifications.add(payload);
  }

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _saveToken();
    _messaging.onTokenRefresh.listen(_updateToken);
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

  Future<void> sendHighPriorityAlert({
    required String taskTitle,
    required String courseName,
    required String userId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'High Priority Task',
      'body': '$courseName — $taskTitle needs your attention now!',
      'recipients': [userId],
      'createdAt': Timestamp.now(),
      'type': 'deadline',
    });
  }

  Future<void> send24HourReminder({
    required String taskTitle,
    required String courseName,
    required String userId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Due in 24 Hours',
      'body': '$courseName — $taskTitle is due tomorrow!',
      'recipients': [userId],
      'createdAt': Timestamp.now(),
      'type': 'deadline',
    });
  }

  // Sent immediately when a creator sets a next session date.
  Future<void> sendGroupSessionScheduled({
    required String groupName,
    required DateTime sessionDate,
    required List<String> memberUids,
  }) async {
    final d = sessionDate;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Session Scheduled — $groupName',
      'body': 'Next session set for ${d.day}/${d.month}/${d.year}. Mark your calendar!',
      'recipients': memberUids,
      'createdAt': Timestamp.now(),
      'type': 'group',
    });
  }

  // Sent when the session is within 25 hours so members get a same-day heads-up.
  Future<void> sendGroupSession24HourReminder({
    required String groupName,
    required DateTime sessionDate,
    required List<String> memberUids,
  }) async {
    final d = sessionDate;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Session Tomorrow — $groupName',
      'body': 'Your group session is tomorrow (${d.day}/${d.month}/${d.year}). Don\'t miss it!',
      'recipients': memberUids,
      'createdAt': Timestamp.now(),
      'type': 'group',
    });
  }
}
