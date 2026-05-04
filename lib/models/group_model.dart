import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a study group stored under groups/{groupId} in Firestore.
// Groups are shared across all students — any authenticated user can read them,
// but only members can update (enforced by firestore.rules).
class GroupModel {
  final String groupId;
  final String name;
  final String courseTag;   // short course code, e.g. CS450
  final String description;
  final List<String> members; // list of Firebase Auth UIDs
  final String createdBy;     // UID of whoever created the group
  final DateTime createdAt;
  final DateTime? nextSession; // optional — set by the creator when scheduling a session

  GroupModel({
    required this.groupId,
    required this.name,
    required this.courseTag,
    required this.description,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    this.nextSession,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'courseTag': courseTag,
      'description': description,
      'members': members,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      // Store nextSession as null if not set so Firestore doesn't have an empty field.
      'nextSession':
          nextSession != null ? Timestamp.fromDate(nextSession!) : null,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] ?? '',
      courseTag: map['courseTag'] ?? '',
      description: map['description'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      // nextSession is optional — check for null before converting.
      nextSession: map['nextSession'] != null
          ? (map['nextSession'] as Timestamp).toDate()
          : null,
    );
  }
}
