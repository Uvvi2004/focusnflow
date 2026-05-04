import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single task stored under tasks/{taskId} in Firestore.
// Each task belongs to one user — ownership is enforced by firestore.rules.
//
// The priority engine lives here in two parts:
//   - getPriorityLabel() → simple High/Med/Low badge for the UI
//   - calculatePriority() → weighted numeric score used to sort the task list
class TaskModel {
  final String taskId;
  final String userId;      // links back to the auth user
  final String courseName;
  final String title;
  final DateTime deadline;
  final double estimatedHours;
  final double courseWeight; // percentage weight of the task in the course
  final double priorityScore; // computed score, higher = more urgent
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

  // Determines the High/Med/Low badge shown on each task card.
  // Rule-based so the student can understand why they got a certain label.
  static String getPriorityLabel(DateTime deadline, double courseWeight) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 3) return 'High';                        // always urgent if due in 3 days
    if (daysLeft <= 7 && courseWeight >= 15) return 'High'; // heavy course + soon = High
    if (courseWeight >= 15) return 'Med';                    // heavy course but time left
    if (daysLeft <= 14) return 'Med';                        // within 2 weeks
    return 'Low';
  }

  // Weighted scoring formula used to sort tasks by urgency.
  //   50% urgency  — how close the deadline is (0–100 scale)
  //   30% weight   — how much the task counts toward the course grade
  //   20% effort   — shorter tasks get a small bonus (quick wins)
  static double calculatePriority(
      DateTime deadline, double estimatedHours, double courseWeight) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    // Tasks past their deadline get max urgency (100). Future tasks scale down.
    final urgencyScore = (100 - daysLeft).clamp(0, 100).toDouble();

    // Guard against 0 hours to avoid a divide-by-zero crash.
    final hours = estimatedHours <= 0 ? 0.5 : estimatedHours;

    // Shorter tasks score higher here — rewards knocking out quick wins first.
    final effortScore = (10 / hours).clamp(0, 100).toDouble();

    return (urgencyScore * 0.5) + (courseWeight * 0.3) + (effortScore * 0.2);
  }

  // Human-readable deadline label shown on task cards and the dashboard.
  // Centralized here so home screen and tasks screen always say the same thing.
  static String daysLeftLabel(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) return 'Overdue';
    final days = diff.inDays;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return '$days days left';
  }

  // Converts the model to a Map for writing to Firestore.
  // Dates are stored as Firestore Timestamps (not plain DateTimes).
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

  // Reconstructs a TaskModel from a Firestore document snapshot.
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
