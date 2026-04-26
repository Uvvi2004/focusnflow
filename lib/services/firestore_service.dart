import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── TASKS ──

  // Add a task
  Future<void> addTask(TaskModel task) async {
    final ref = _db.collection('tasks').doc();
    final taskWithId = TaskModel(
      taskId: ref.id,
      userId: task.userId,
      courseName: task.courseName,
      title: task.title,
      deadline: task.deadline,
      estimatedHours: task.estimatedHours,
      courseWeight: task.courseWeight,
      priorityScore: task.priorityScore,
      completed: task.completed,
      createdAt: task.createdAt,
    );
    await ref.set(taskWithId.toMap());
  }

  // Get tasks for a user in real time
  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by priority score descending
      tasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      return tasks;
    });
  }

  // Mark task as complete
  Future<void> completeTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'completed': true});
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}