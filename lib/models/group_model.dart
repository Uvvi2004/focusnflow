import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String name;
  final String courseTag;
  final String description;
  final List<String> members;
  final String coverImageUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? nextSession;

  GroupModel({
    required this.groupId,
    required this.name,
    required this.courseTag,
    required this.description,
    required this.members,
    required this.coverImageUrl,
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
      'coverImageUrl': coverImageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
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
      coverImageUrl: map['coverImageUrl'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      nextSession: map['nextSession'] != null
          ? (map['nextSession'] as Timestamp).toDate()
          : null,
    );
  }
}