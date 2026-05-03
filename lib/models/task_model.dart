import 'package:cloud_firestore/cloud_firestore.dart';

// Backs tasks/{taskId} in Firestore. Each task is owned by one user; the rule
// layer enforces that ownership (see firestore.rules > tasks).
//
// Two related concepts live here:
//   - getPriorityLabel: a coarse High/Med/Low bucket used in UI badges. It
//     is intentionally rule-based (deadline + course weight) so the badge
//     stays explainable to the student.
//   - calculatePriority: the numeric score used to sort the tasks list. It
//     blends urgency, course weight, and effort so quick high-impact wins
//     surface above slow low-impact ones.
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
    // Closer deadline → higher urgency. Past-due tasks max out at 100.
    final urgencyScore = (100 - daysLeft).clamp(0, 100).toDouble();
    // Floor estimatedHours so a user entering 0 doesn't blow up to infinity.
    final hours = estimatedHours <= 0 ? 0.5 : estimatedHours;
    // Shorter tasks get a small bonus — encourages knocking out quick wins.
    final effortScore = (10 / hours).clamp(0, 100).toDouble();
    return (urgencyScore * 0.5) + (courseWeight * 0.3) + (effortScore * 0.2);
  }

  // Friendly relative-deadline label used by every task card. Centralised
  // here so the home dashboard and tasks list stay consistent.
  static String daysLeftLabel(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) return 'Overdue';
    final days = diff.inDays;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return '$days days left';
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
