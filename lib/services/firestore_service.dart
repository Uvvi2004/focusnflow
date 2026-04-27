import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/room_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── TASKS ──

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
      tasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      return tasks;
    });
  }

  Future<void> completeTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'completed': true});
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // ── ROOMS ──

  Stream<List<RoomModel>> getRooms() {
    return _db
        .collection('rooms')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addRoom(RoomModel room) async {
    final ref = _db.collection('rooms').doc();
    await ref.set({
      ...room.toMap(),
      'roomId': ref.id,
    });
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db.collection('rooms').doc(roomId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> seedRooms() async {
    final existing = await _db.collection('rooms').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final rooms = [
      {
        'name': 'Room 201',
        'building': 'Science Bldg',
        'floor': '2nd Floor',
        'capacity': 20,
        'status': 'open',
        'amenities': ['Whiteboard', 'Projector', 'WiFi'],
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Study Hall A',
        'building': 'Library',
        'floor': '1st Floor',
        'capacity': 50,
        'status': 'occupied',
        'amenities': ['WiFi', 'Power Outlets'],
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Seminar Rm 304',
        'building': 'Business Bldg',
        'floor': '3rd Floor',
        'capacity': 15,
        'status': 'reserved',
        'amenities': ['Whiteboard', 'TV Screen', 'WiFi'],
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Quiet Zone B',
        'building': 'Library',
        'floor': '2nd Floor',
        'capacity': 30,
        'status': 'open',
        'amenities': ['WiFi', 'Power Outlets', 'Natural Light'],
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Innovation Lab',
        'building': 'Tech Center',
        'floor': '1st Floor',
        'capacity': 25,
        'status': 'open',
        'amenities': ['Whiteboard', 'Projector', 'Standing Desks', 'WiFi'],
        'updatedAt': Timestamp.now(),
      },
      {
        'name': 'Room 102',
        'building': 'Humanities Bldg',
        'floor': '1st Floor',
        'capacity': 12,
        'status': 'open',
        'amenities': ['Whiteboard', 'WiFi'],
        'updatedAt': Timestamp.now(),
      },
    ];

    final batch = _db.batch();
    for (final room in rooms) {
      final ref = _db.collection('rooms').doc();
      batch.set(ref, {...room, 'roomId': ref.id});
    }
    await batch.commit();
  }
}