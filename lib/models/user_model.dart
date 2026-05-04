import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a user profile stored under users/{uid} in Firestore.
// This document is created during signup by AuthService and updated by
// ProfileScreen (photo, courses, preferences) and FCMService (token).
//
// The shape here must match the security rules in firestore.rules —
// specifically the email field is validated at the rule layer on create.
class UserModel {
  final String uid;           // matches the Firebase Auth UID
  final String displayName;
  final String email;         // must end in @student.gsu.edu
  final List<String> courses; // course codes the student added (e.g. CS450)
  final String photoURL;      // Firebase Storage download URL, empty until uploaded
  final String fcmToken;      // device token used by FCM to route push notifications
  final bool notificationsEnabled; // deadline reminders toggle
  final bool groupAlertsEnabled;   // group session alerts toggle
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

  // Serializes to a Map for writing to Firestore.
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

  // Builds a UserModel from a Firestore document snapshot.
  // Null-safe defaults handle documents that are missing newer fields.
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
