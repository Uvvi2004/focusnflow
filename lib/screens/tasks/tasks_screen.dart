import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../services/fcm_service.dart';
import '../schedule/schedule_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _firestoreService = FirestoreService();
  final _fcmService = FCMService();
  final _user = FirebaseAuth.instance.currentUser;

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  Color _priorityColor(TaskModel task) {
    final label = TaskModel.getPriorityLabel(task.deadline, task.courseWeight);
    if (label == 'High') return Colors.redAccent;
    if (label == 'Med') return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _priorityLabel(TaskModel task) =>
      TaskModel.getPriorityLabel(task.deadline, task.courseWeight);

  void _showAddTaskSheet() {
    final courseController = TextEditingController();
    final titleController = TextEditingController();
    final hoursController = TextEditingController();
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Task',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
              const SizedBox(height: 20),
              _SheetTextField(controller: courseController,
                  label: 'Course Name (e.g. CS450)'),
              const SizedBox(height: 12),
              _SheetTextField(controller: titleController,
                  label: 'Task Title (e.g. Assignment 2)'),
              const SizedBox(height: 12),
              _SheetTextField(controller: hoursController,
                  label: 'Estimated Hours (e.g. 3)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _SheetTextField(controller: weightController,
                  label: 'Course Weight % (e.g. 20)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) =>
                        Theme(data: ThemeData.dark(), child: child!),
                  );
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: _accentColor, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Deadline: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(color: _textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitTask(
                  ctx: ctx,
                  courseController: courseController,
                  titleController: titleController,
                  hoursController: hoursController,
                  weightController: weightController,
                  selectedDate: selectedDate,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Task',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose sheet controllers when the sheet closes.
      courseController.dispose();
      titleController.dispose();
      hoursController.dispose();
      weightController.dispose();
    });
  }

  Future<void> _submitTask({
    required BuildContext ctx,
    required TextEditingController courseController,
    required TextEditingController titleController,
    required TextEditingController hoursController,
    required TextEditingController weightController,
    required DateTime selectedDate,
  }) async {
    final course = courseController.text.trim();
    final title = titleController.text.trim();
    if (course.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Course name and title are required')));
      return;
    }

    final hours = double.tryParse(hoursController.text);
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Estimated hours must be a positive number')));
      return;
    }

    final weight = double.tryParse(weightController.text);
    if (weight == null || weight < 0 || weight > 100) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Course weight must be between 0 and 100')));
      return;
    }

    final score = TaskModel.calculatePriority(selectedDate, hours, weight);
    final task = TaskModel(
      taskId: '',
      userId: _user!.uid,
      courseName: course,
      title: title,
      deadline: selectedDate,
      estimatedHours: hours,
      courseWeight: weight,
      priorityScore: score,
      completed: false,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addTask(task);

    // Read the user's notification preference before writing any alerts so
    // the toggle in Profile > Notification Preferences is actually respected.
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();
    final notifsOn =
        (userDoc.data()?['notificationsEnabled'] ?? true) as bool;

    if (notifsOn) {
      final label = TaskModel.getPriorityLabel(selectedDate, weight);
      final daysLeft = selectedDate.difference(DateTime.now()).inDays;

      if (label == 'High') {
        await _fcmService.sendHighPriorityAlert(
            taskTitle: title, courseName: course, userId: _user.uid);
      }
      if (daysLeft <= 1) {
        await _fcmService.send24HourReminder(
            taskTitle: title, courseName: course, userId: _user.uid);
      }
    }

    if (ctx.mounted) Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Tasks',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColor)),
                      SizedBox(height: 4),
                      Text('Sorted by priority score',
                          style: TextStyle(color: _subtextColor, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      _LegendDot(color: Colors.redAccent, label: 'High'),
                      const SizedBox(width: 8),
                      _LegendDot(color: Colors.orangeAccent, label: 'Med'),
                      const SizedBox(width: 8),
                      _LegendDot(color: Colors.greenAccent, label: 'Low'),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScheduleScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _accentColor.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              color: _accentColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: _firestoreService.getTasks(_user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt_rounded,
                              color: _subtextColor, size: 48),
                          const SizedBox(height: 16),
                          const Text('No tasks yet',
                              style: TextStyle(color: _subtextColor)),
                          const SizedBox(height: 8),
                          const Text('Tap + to add your first task',
                              style: TextStyle(
                                  color: _subtextColor, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  final tasks = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: tasks.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final color = _priorityColor(task);
                      final label = _priorityLabel(task);
                      final dueLabel = TaskModel.daysLeftLabel(task.deadline);

                      return Dismissible(
                        key: Key(task.taskId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent),
                        ),
                        onDismissed: (_) =>
                            _firestoreService.deleteTask(task.taskId),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              // Tap to mark complete.
                              GestureDetector(
                                onTap: () =>
                                    _firestoreService.completeTask(task.taskId),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${task.courseName} — ${task.title}',
                                      style: const TextStyle(
                                          color: _textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$dueLabel  •  ${task.estimatedHours}h  •  ${task.courseWeight}% weight',
                                      style: const TextStyle(
                                          color: _subtextColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(label,
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Score: ${task.priorityScore.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        color: _subtextColor, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: _accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 11)),
      ],
    );
  }
}
