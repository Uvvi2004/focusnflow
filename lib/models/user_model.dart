import 'package:cloud_firestore/cloud_firestore.dart';

// Mirrors users/{uid} in Firestore. Created at signup by AuthService and
// updated by ProfileScreen and the FCM token-refresh handler. Fields here
// must match the shape enforced by firestore.rules (especially `email`).
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final List<String> courses;
  final String photoURL;
  final String fcmToken;
  final bool notificationsEnabled;
  final bool groupAlertsEnabled;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.courses,
    required this.photoURL,
    required this.fcmToken,
    required this.notificationsEnabled,
    required this.groupAlertsEnabled,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'courses': courses,
        'photoURL': photoURL,
        'fcmToken': fcmToken,
        'notificationsEnabled': notificationsEnabled,
        'groupAlertsEnabled': groupAlertsEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        displayName: map['displayName'] ?? '',
        email: map['email'] ?? '',
        courses: List<String>.from(map['courses'] ?? const []),
        photoURL: map['photoURL'] ?? '',
        fcmToken: map['fcmToken'] ?? '',
        notificationsEnabled: map['notificationsEnabled'] ?? true,
        groupAlertsEnabled: map['groupAlertsEnabled'] ?? true,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
