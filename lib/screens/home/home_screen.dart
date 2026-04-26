import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tasks/tasks_screen.dart';
import '../rooms/rooms_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  final List<Widget> _screens = [
    const HomeDashboard(),
    const TasksScreen(),
    const RoomsScreen(),
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: _cardColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: _subtextColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_rounded),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.displayName ?? 'Student'} 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Let's get focused today",
                      style: TextStyle(color: _subtextColor, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: _accentColor),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Stats row
            Row(
              children: [
                _StatCard(
                  label: 'Tasks Due',
                  value: '3',
                  icon: Icons.task_alt_rounded,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Open Rooms',
                  value: '5',
                  icon: Icons.meeting_room_rounded,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'My Groups',
                  value: '2',
                  icon: Icons.group_rounded,
                  color: _accentColor,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Today's priorities
            const Text(
              "Today's Priorities",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),

            _PriorityTaskCard(
              course: 'CS450',
              title: 'Assignment 2',
              dueDate: 'Due Nov 20',
              priority: 'High',
              priorityColor: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            _PriorityTaskCard(
              course: 'MATH201',
              title: 'Homework 5',
              dueDate: 'Due Nov 21',
              priority: 'Med',
              priorityColor: Colors.orangeAccent,
            ),
            const SizedBox(height: 10),
            _PriorityTaskCard(
              course: 'ART110',
              title: 'Project Draft',
              dueDate: 'Due Nov 30',
              priority: 'Low',
              priorityColor: Colors.greenAccent,
            ),
            const SizedBox(height: 28),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_task_rounded,
                  label: 'Add Task',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.meeting_room_rounded,
                  label: 'Find Room',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.group_add_rounded,
                  label: 'My Groups',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Focus tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: _accentColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
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
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  static const _cardColor = Color(0xFF1A1D2E);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

class _PriorityTaskCard extends StatelessWidget {
  final String course;
  final String title;
  final String dueDate;
  final String priority;
  final Color priorityColor;

  const _PriorityTaskCard({
    required this.course,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.priorityColor,
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
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              priority,
              style: TextStyle(
                  color: priorityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$course — $title',
                  style: const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(dueDate,
                    style:
                        const TextStyle(color: _subtextColor, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF9AA0A6), size: 20),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
              Text(label,
                  style:
                      const TextStyle(color: _subtextColor, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}