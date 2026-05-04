import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/room_model.dart';
import '../models/group_model.dart';

// Central service for all Firestore reads and writes.
// Every collection in the app goes through here — no screen
// talks to Firestore directly. Makes it easy to change the
// data layer without touching the UI.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── TASKS ──────────────────────────────────────────────────────────────────

  // Adds a new task and lets Firestore auto-generate the document ID,
  // then writes that ID back into the document so we always have it.
  Future<void> addTask(TaskModel task) async {
    final ref = _db.collection('tasks').doc();
    await ref.set({...task.toMap(), 'taskId': ref.id});
  }

  // Real-time stream of the user's incomplete tasks, sorted by priority score.
  // This query uses a composite index on (userId, completed) — see firestore.indexes.json.
  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final tasks =
          snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
      // Sort by priority score so the most urgent task is always at the top.
      tasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      return tasks;
    });
  }

  // Marks a task as done — it disappears from the list immediately
  // because the stream filters out completed tasks.
  Future<void> completeTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'completed': true});
  }

  // Swipe-to-delete — permanently removes the task from Firestore.
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // ── ROOMS ──────────────────────────────────────────────────────────────────

  // Returns all study rooms ordered alphabetically, in real time.
  Stream<List<RoomModel>> getRooms() {
    return _db.collection('rooms').orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList());
  }

  // Lets a student manually add a room to the list.
  Future<void> addRoom(RoomModel room) async {
    final ref = _db.collection('rooms').doc();
    await ref.set({...room.toMap(), 'roomId': ref.id});
  }

  // Updates the live status of a room (open / occupied / reserved).
  // Any student can flip this — it's a collaborative system.
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db.collection('rooms').doc(roomId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Populates the rooms collection with demo data on first launch.
  // The guard check makes sure we only seed once.
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

    // Use a batch write so all 6 rooms either all succeed or all fail together.
    final batch = _db.batch();
    for (final room in rooms) {
      final ref = _db.collection('rooms').doc();
      batch.set(ref, {...room, 'roomId': ref.id, 'updatedAt': Timestamp.now()});
    }
    await batch.commit();
  }

  // ── GROUPS ─────────────────────────────────────────────────────────────────

  // Streams all study groups, newest first.
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

  // arrayUnion safely adds the user to the members list without duplicates,
  // even if two people tap "Join" at the same time.
  Future<void> joinGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // arrayRemove removes only the specific user without affecting other members.
  Future<void> leaveGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  // Creator sets the next group session date. Notifications are sent
  // by the calling screen (groups_screen.dart) after this write completes.
  Future<void> updateNextSession(String groupId, DateTime session) async {
    await _db.collection('groups').doc(groupId).update({
      'nextSession': Timestamp.fromDate(session),
    });
  }

  // Deletes the group for everyone — the real-time stream removes it
  // from all members' screens instantly.
  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }
}
