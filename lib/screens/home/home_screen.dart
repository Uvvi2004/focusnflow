import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tasks/tasks_screen.dart';
import '../rooms/rooms_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/task_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _subtextColor = Color(0xFF9AA0A6);

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboard(onSwitchTab: _switchTab),
      const TasksScreen(),
      const RoomsScreen(),
      const GroupsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _cardColor,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          backgroundColor: _cardColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: _subtextColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.meeting_room_rounded), label: 'Rooms'),
            BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Groups'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final Function(int) onSwitchTab;
  const HomeDashboard({super.key, required this.onSwitchTab});

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  void _showNotificationsSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('recipients', arrayContains: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load notifications.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: _subtextColor),
                        ),
                      );
                    }

                    final notifs = docs.toList()
                      ..sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aCreatedAt = aData['createdAt'] as Timestamp?;
                        final bCreatedAt = bData['createdAt'] as Timestamp?;
                        return (bCreatedAt?.millisecondsSinceEpoch ?? 0)
                            .compareTo(aCreatedAt?.millisecondsSinceEpoch ?? 0);
                      });

                    return ListView.separated(
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data = notifs[index].data() as Map<String, dynamic>;
                        final title = data['title'] ?? '';
                        final body = data['body'] ?? '';
                        final type = data['type'] ?? 'general';
                        final icon = type == 'deadline' ? Icons.timer_rounded : Icons.group_rounded;
                        final color = type == 'deadline' ? Colors.orangeAccent : _accentColor;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: _textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        color: _subtextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.displayName ?? 'Student'} 👋',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: _textColor),
                    ),
                    const SizedBox(height: 4),
                    const Text("Let's get focused today",
                        style: TextStyle(color: _subtextColor, fontSize: 14)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showNotificationsSheet(context, user?.uid ?? ''),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: _accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Stats row — three nested StreamBuilders kept intentionally flat
            // to avoid pulling all data into a single stream merge.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: user?.uid)
                  .where('completed', isEqualTo: false)
                  .snapshots(),
              builder: (context, taskSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .where('status', isEqualTo: 'open')
                      .snapshots(),
                  builder: (context, roomSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .snapshots(),
                      builder: (context, groupSnap) {
                        final taskCount = taskSnap.data?.docs.length ?? 0;
                        final roomCount = roomSnap.data?.docs.length ?? 0;
                        final groupCount = groupSnap.data?.docs
                                .where((d) => ((d.data() as Map<String, dynamic>)['members']
                                        as List?)
                                    ?.contains(user?.uid) ==
                                    true)
                                .length ??
                            0;
                        return Row(
                          children: [
                            _StatCard(label: 'Tasks Due', value: '$taskCount',
                                icon: Icons.task_alt_rounded, color: Colors.orangeAccent,
                                onTap: () => onSwitchTab(1)),
                            const SizedBox(width: 12),
                            _StatCard(label: 'Open Rooms', value: '$roomCount',
                                icon: Icons.meeting_room_rounded, color: Colors.greenAccent,
                                onTap: () => onSwitchTab(2)),
                            const SizedBox(width: 12),
                            _StatCard(label: 'My Groups', value: '$groupCount',
                                icon: Icons.group_rounded, color: _accentColor,
                                onTap: () => onSwitchTab(3)),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // Upcoming group sessions — only renders when the user has at
            // least one group with a future nextSession date.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .snapshots(),
              builder: (context, groupSnap) {
                if (!groupSnap.hasData) return const SizedBox.shrink();

                final now = DateTime.now();
                final upcoming = groupSnap.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .where((d) {
                      final members = d['members'] as List?;
                      if (members == null ||
                          !members.contains(user?.uid)) {
                        return false;
                      }
                      final ts = d['nextSession'] as Timestamp?;
                      if (ts == null) { return false; }
                      return ts.toDate().isAfter(now);
                    })
                    .toList()
                  ..sort((a, b) {
                    final aTs = (a['nextSession'] as Timestamp).toDate();
                    final bTs = (b['nextSession'] as Timestamp).toDate();
                    return aTs.compareTo(bTs);
                  });

                if (upcoming.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upcoming Sessions',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textColor)),
                    const SizedBox(height: 12),
                    ...upcoming.take(3).map((g) {
                      final session =
                          (g['nextSession'] as Timestamp).toDate();
                      final daysUntil =
                          session.difference(now).inDays;
                      final label = daysUntil == 0
                          ? 'Today'
                          : daysUntil == 1
                              ? 'Tomorrow'
                              : '${session.day}/${session.month}/${session.year}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => onSwitchTab(3),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      _accentColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        _accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.groups_rounded,
                                      color: _accentColor,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(g['name'] ?? '',
                                          style: const TextStyle(
                                              color: _textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(g['courseTag'] ?? '',
                                          style: const TextStyle(
                                              color: _subtextColor,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        _accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(label,
                                      style: const TextStyle(
                                          color: _accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),

            const Text("Today's Priorities",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: user?.uid)
                  .where('completed', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Text('No tasks yet — go to Tasks tab to add one',
                          style: TextStyle(color: _subtextColor)),
                    ),
                  );
                }

                final tasks = snapshot.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList()
                  ..sort((a, b) => (b['priorityScore'] as num)
                      .compareTo(a['priorityScore'] as num));
                final top = tasks.take(3).toList();

                return Column(
                  children: top.map((task) {
                    final deadline = (task['deadline'] as Timestamp).toDate();
                    final weight = (task['courseWeight'] as num).toDouble();
                    final label = TaskModel.getPriorityLabel(deadline, weight);
                    final dueLabel = TaskModel.daysLeftLabel(deadline);
                    final priorityColor = label == 'High'
                        ? Colors.redAccent
                        : label == 'Med'
                            ? Colors.orangeAccent
                            : Colors.greenAccent;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => onSwitchTab(1),
                        child: _PriorityTaskCard(
                          course: task['courseName'] ?? '',
                          title: task['title'] ?? '',
                          dueLabel: dueLabel,
                          priority: label,
                          priorityColor: priorityColor,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),

            const Text('Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(icon: Icons.add_task_rounded, label: 'Add Task',
                    onTap: () => onSwitchTab(1)),
                const SizedBox(width: 12),
                _QuickAction(icon: Icons.meeting_room_rounded, label: 'Find Room',
                    onTap: () => onSwitchTab(2)),
                const SizedBox(width: 12),
                _QuickAction(icon: Icons.group_add_rounded, label: 'My Groups',
                    onTap: () => onSwitchTab(3)),
              ],
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: _accentColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Break your highest priority task into 25-min Pomodoro sessions for maximum focus.',
                      style: TextStyle(color: _subtextColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, required this.onTap,
  });

  static const _cardColor = Color(0xFF1A1D2E);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: _subtextColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityTaskCard extends StatelessWidget {
  final String course, title, dueLabel, priority;
  final Color priorityColor;

  const _PriorityTaskCard({
    required this.course, required this.title, required this.dueLabel,
    required this.priority, required this.priorityColor,
  });

  static const _cardColor = Color(0xFF1A1D2E);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(priority,
                style: TextStyle(
                    color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$course — $title',
                    style: const TextStyle(
                        color: _textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(dueLabel,
                    style: const TextStyle(color: _subtextColor, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA0A6), size: 20),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: _accentColor, size: 24),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: _subtextColor, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
