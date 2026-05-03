import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/room_model.dart';
import '../models/group_model.dart';

// All Firestore reads and writes go through this class. Every method maps to
// a single collection and uses the paths documented in firestore.rules.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── TASKS ──────────────────────────────────────────────────────────────────
  // Compound query (userId + completed=false) requires a composite index —
  // see firestore.indexes.json.

  Future<void> addTask(TaskModel task) async {
    final ref = _db.collection('tasks').doc();
    await ref.set({...task.toMap(), 'taskId': ref.id});
  }

  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final tasks =
          snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
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

  // ── ROOMS ──────────────────────────────────────────────────────────────────

  Stream<List<RoomModel>> getRooms() {
    return _db.collection('rooms').orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addRoom(RoomModel room) async {
    final ref = _db.collection('rooms').doc();
    await ref.set({...room.toMap(), 'roomId': ref.id});
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db.collection('rooms').doc(roomId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Seeds demo data on first launch; the Firestore rule allows any auth user
  // to create rooms, so this works from the client. A real deployment would
  // seed via a Cloud Function or the Firebase Admin SDK.
  Future<void> seedRooms() async {
    final existing = await _db.collection('rooms').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final rooms = [
      {'name': 'Room 201', 'building': 'Science Bldg', 'floor': '2nd Floor', 'capacity': 20, 'status': 'open', 'amenities': ['Whiteboard', 'Projector', 'WiFi']},
      {'name': 'Study Hall A', 'building': 'Library', 'floor': '1st Floor', 'capacity': 50, 'status': 'occupied', 'amenities': ['WiFi', 'Power Outlets']},
      {'name': 'Seminar Rm 304', 'building': 'Business Bldg', 'floor': '3rd Floor', 'capacity': 15, 'status': 'reserved', 'amenities': ['Whiteboard', 'TV Screen', 'WiFi']},
      {'name': 'Quiet Zone B', 'building': 'Library', 'floor': '2nd Floor', 'capacity': 30, 'status': 'open', 'amenities': ['WiFi', 'Power Outlets', 'Natural Light']},
      {'name': 'Innovation Lab', 'building': 'Tech Center', 'floor': '1st Floor', 'capacity': 25, 'status': 'open', 'amenities': ['Whiteboard', 'Projector', 'Standing Desks', 'WiFi']},
      {'name': 'Room 102', 'building': 'Humanities Bldg', 'floor': '1st Floor', 'capacity': 12, 'status': 'open', 'amenities': ['Whiteboard', 'WiFi']},
    ];

    final batch = _db.batch();
    for (final room in rooms) {
      final ref = _db.collection('rooms').doc();
      batch.set(ref, {...room, 'roomId': ref.id, 'updatedAt': Timestamp.now()});
    }
    await batch.commit();
  }

  // ── GROUPS ─────────────────────────────────────────────────────────────────

  Stream<List<GroupModel>> getGroups() {
    return _db
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> createGroup(GroupModel group) async {
    final ref = _db.collection('groups').doc();
    await ref.set({...group.toMap(), 'groupId': ref.id});
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> updateNextSession(String groupId, DateTime session) async {
    await _db.collection('groups').doc(groupId).update({
      'nextSession': Timestamp.fromDate(session),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }
}
