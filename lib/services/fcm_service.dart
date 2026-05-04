import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handles everything related to Firebase Cloud Messaging.
//
// FCM token lifecycle:
//   1. initialize() runs at app startup and asks the OS for permission.
//   2. _saveToken() gets the device's FCM token and stores it in Firestore
//      under users/{uid}.fcmToken so we know where to send pushes.
//   3. onTokenRefresh keeps the stored token up to date if the OS rotates it.
//
// Notification delivery:
//   - The sendX methods write a document to the notifications collection.
//   - storeIncomingMessageForBell() takes FCM messages received by the device
//     and writes them to the same collection so they show in the bell icon.
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Called from main.dart when a push arrives (foreground, background, or app open).
  // Writes the message to Firestore so it shows in the notification bell.
  // Uses the FCM messageId as the document ID to prevent duplicates.
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
      'source': 'fcm', // marks this as coming from a real push, not an in-app event
    };

    final notifications = FirebaseFirestore.instance.collection('notifications');

    // If we have a messageId, use it as the doc ID so the same message
    // can't be written twice (e.g. if onMessageOpenedApp fires multiple times).
    if (messageId != null && messageId.isNotEmpty) {
      await notifications.doc('fcm_$messageId').set(payload, SetOptions(merge: true));
      return;
    }

    await notifications.add(payload);
  }

  // Runs at startup — asks for permission and saves the device token.
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _saveToken();
    // Listen for token refreshes — iOS and Android can rotate the token.
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  // Gets the device's FCM token and saves it to the user's Firestore doc.
  // This token is what Firebase uses to route a push to this specific device.
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

  // Called automatically when the OS gives the app a new FCM token.
  Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  // Writes a high-priority task alert to the notifications collection.
  // Fires when a task is added with a deadline ≤ 3 days or high course weight.
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

  // Fires when a task is added with a deadline of today or tomorrow.
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

  // Sent to all group members immediately when the creator sets a session date.
  Future<void> sendGroupSessionScheduled({
    required String groupName,
    required DateTime sessionDate,
    required List<String> memberUids,
  }) async {
    final d = sessionDate;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Session Scheduled — $groupName',
      'body': 'Next session set for ${d.day}/${d.month}/${d.year}. Mark your calendar!',
      'recipients': memberUids, // fan-out to every member
      'createdAt': Timestamp.now(),
      'type': 'group',
    });
  }

  // Sent to all members when the session is within 25 hours.
  // If the creator picks tomorrow, both this and sendGroupSessionScheduled fire.
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
