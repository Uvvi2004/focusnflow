import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String userId;
  final String courseName;
  final String title;
  final DateTime deadline;
  final double estimatedHours;
  final double courseWeight;
  final double priorityScore;
  final bool completed;
  final DateTime createdAt;

  TaskModel({
    required this.taskId,
    required this.userId,
    required this.courseName,
    required this.title,
    required this.deadline,
    required this.estimatedHours,
    required this.courseWeight,
    required this.priorityScore,
    required this.completed,
    required this.createdAt,
  });

  static String getPriorityLabel(DateTime deadline, double courseWeight) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 3) return 'High';
    if (daysLeft <= 7 && courseWeight >= 15) return 'High';
    if (courseWeight >= 15) return 'Med';
    if (daysLeft <= 14) return 'Med';
    return 'Low';
  }

  static double calculatePriority(
      DateTime deadline, double estimatedHours, double courseWeight) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    final urgencyScore = (100 - daysLeft).clamp(0, 100).toDouble();
    final effortScore = (1 / estimatedHours * 10).clamp(0, 100).toDouble();
    return (urgencyScore * 0.5) + (courseWeight * 0.3) + (effortScore * 0.2);
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'courseName': courseName,
      'title': title,
      'deadline': Timestamp.fromDate(deadline),
      'estimatedHours': estimatedHours,
      'courseWeight': courseWeight,
      'priorityScore': priorityScore,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      taskId: id,
      userId: map['userId'] ?? '',
      courseName: map['courseName'] ?? '',
      title: map['title'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      estimatedHours: (map['estimatedHours'] ?? 1).toDouble(),
      courseWeight: (map['courseWeight'] ?? 10).toDouble(),
      priorityScore: (map['priorityScore'] ?? 0).toDouble(),
      completed: map['completed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}