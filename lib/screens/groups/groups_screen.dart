import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group_model.dart';
import '../../services/firestore_service.dart';
import '../../services/fcm_service.dart';
import 'pomodoro_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _firestoreService = FirestoreService();
  // GroupsScreen is only reachable when auth is confirmed — bang is safe.
  final _user = FirebaseAuth.instance.currentUser!;

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  void _showCreateGroupSheet() {
    final nameController = TextEditingController();
    final courseController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Study Group',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 20),
            _SheetTextField(
              controller: nameController,
              label: 'Group Name (e.g. CS450 Study Buddies)',
            ),
            const SizedBox(height: 12),
            _SheetTextField(
              controller: courseController,
              label: 'Course Tag (e.g. CS450)',
            ),
            const SizedBox(height: 12),
            _SheetTextField(
              controller: descController,
              label: 'Description (e.g. Weekly exam prep)',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || courseController.text.isEmpty) {
                  return;
                }

                final group = GroupModel(
                  groupId: '',
                  name: nameController.text.trim(),
                  courseTag: courseController.text.trim(),
                  description: descController.text.trim(),
                  members: [_user.uid],
                  createdBy: _user.uid,
                  createdAt: DateTime.now(),
                );

                await _firestoreService.createGroup(group);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupDetail(GroupModel group) {
    final isCreator = group.createdBy == _user.uid;
    final isMember = group.members.contains(_user.uid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.courseTag,
                    style: const TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (group.description.isNotEmpty)
              Text(
                group.description,
                style: const TextStyle(color: _subtextColor, fontSize: 14),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people_rounded,
                    color: _accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(color: _subtextColor, fontSize: 14),
                ),
              ],
            ),
            if (group.nextSession != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Next session: ${group.nextSession!.day}/${group.nextSession!.month}/${group.nextSession!.year}',
                    style: const TextStyle(
                        color: _subtextColor, fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (!isMember)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestoreService.joinGroup(
                        group.groupId, _user.uid);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not join group: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Join Group',
                    style: TextStyle(color: Colors.white)),
              ),
            if (isMember && !isCreator)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestoreService.leaveGroup(
                        group.groupId, _user.uid);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not leave group: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                ),
                child: const Text('Leave Group'),
              ),
            if (isCreator) ...[
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark(),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    await _firestoreService.updateNextSession(
                        group.groupId, picked);

                    final fcm = FCMService();
                    // Notify all members the session has been scheduled.
                    await fcm.sendGroupSessionScheduled(
                      groupName: group.name,
                      sessionDate: picked,
                      memberUids: group.members,
                    );
                    // Also send the 24-hour reminder right away if the
                    // session is already within the next 25 hours.
                    final hoursUntil =
                        picked.difference(DateTime.now()).inHours;
                    if (hoursUntil <= 25 && hoursUntil > 0) {
                      await fcm.sendGroupSession24HourReminder(
                        groupName: group.name,
                        sessionDate: picked,
                        memberUids: group.members,
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Set Next Session',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  // Confirm before deleting — this removes the group for all members.
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1D2E),
                      title: const Text('Delete Group',
                          style: TextStyle(color: Color(0xFFE8EAED))),
                      content: Text(
                        'Delete "${group.name}"? This removes the group for all ${group.members.length} member(s) and cannot be undone.',
                        style: const TextStyle(color: Color(0xFF9AA0A6)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await _firestoreService.deleteGroup(group.groupId);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not delete group: $e')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                ),
                child: const Text('Delete Group'),
              ),
            ],
            if (isMember) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PomodoroScreen(
                        groupId: group.groupId,
                        groupName: group.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.timer_rounded, color: Colors.white),
                label: const Text('Start Pomodoro Timer',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Groups',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Join or create a group for your course',
                    style: TextStyle(color: _subtextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<GroupModel>>(
                stream: _firestoreService.getGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_rounded,
                              color: _subtextColor, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No groups yet',
                            style: TextStyle(color: _subtextColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to create the first one',
                            style: TextStyle(
                                color: _subtextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  final groups = snapshot.data!;
                  final myGroups = groups
                      .where((g) => g.members.contains(_user.uid))
                      .toList();
                  final otherGroups = groups
                      .where((g) => !g.members.contains(_user.uid))
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      if (myGroups.isNotEmpty) ...[
                        const Text(
                          'My Groups',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...myGroups.map((g) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GroupCard(
                                group: g,
                                userId: _user.uid,
                                onTap: () => _showGroupDetail(g),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (otherGroups.isNotEmpty) ...[
                        const Text(
                          'All Groups',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...otherGroups.map((g) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GroupCard(
                                group: g,
                                userId: _user.uid,
                                onTap: () => _showGroupDetail(g),
                              ),
                            )),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupSheet,
        backgroundColor: _accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final String userId;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.userId,
    required this.onTap,
  });

  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    final isMember = group.members.contains(userId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMember
                ? _accentColor.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_rounded,
                  color: _accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.members.length} member${group.members.length == 1 ? '' : 's'} · ${group.courseTag}',
                    style: const TextStyle(color: _subtextColor, fontSize: 12),
                  ),
                  if (group.nextSession != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: _accentColor, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'Next: ${group.nextSession!.day}/${group.nextSession!.month}/${group.nextSession!.year}',
                          style: const TextStyle(
                              color: _accentColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isMember)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Joined',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _SheetTextField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Color(0xFFE8EAED)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9AA0A6)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}