import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';

// Weekly schedule screen — generates a priority-first 7-day plan from the user's tasks.
//
// Algorithm:
//   1. Sort tasks by priorityScore DESC so urgent work fills the earliest slots.
//   2. For each task, walk from today through deadline-1 (leaving the deadline day free)
//      and assign hours up to the 4h daily cap until the task is fully covered.
//   3. Any hours that don't fit get flagged as a conflict with a plain-language suggestion.
//
// The screen is a StatelessWidget — it re-runs the algorithm every time the
// Firestore task stream emits, so the schedule stays live as tasks are added.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const double _dailyCap = 4.0;

  static const _bgColor = Color(0xFF0F1117);
  static const _cardColor = Color(0xFF1A1D2E);
  static const _accentColor = Color(0xFF4F8EF7);
  static const _textColor = Color(0xFFE8EAED);
  static const _subtextColor = Color(0xFF9AA0A6);

  static _ScheduleResult _buildSchedule(List<TaskModel> tasks) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final hoursUsed = List<double>.filled(7, 0.0);
    final daySlots = List<List<_TaskSlot>>.generate(7, (_) => []);
    final conflicts = <_Conflict>[];

    final sorted = [...tasks]
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    for (final task in sorted) {
      double remaining = task.estimatedHours;

      // Stop the day before the deadline to leave a review buffer.
      // Clamped to 6 so we never schedule outside the 7-day window.
      final deadlineDay = task.deadline.difference(today).inDays;
      final lastDay = (deadlineDay - 1).clamp(0, 6);

      for (int d = 0; d <= lastDay && remaining > 0.01; d++) {
        final available = _dailyCap - hoursUsed[d];
        if (available <= 0.01) continue;
        final assign = remaining < available ? remaining : available;
        hoursUsed[d] += assign;
        daySlots[d].add(_TaskSlot(task: task, hours: assign));
        remaining -= assign;
      }

      if (remaining > 0.01) {
        final String suggestion;
        if (deadlineDay <= 0) {
          suggestion = 'Task is overdue — complete it immediately.';
        } else if (deadlineDay == 1) {
          suggestion = 'Due tomorrow. Start now to cover ${remaining.toStringAsFixed(1)}h.';
        } else {
          suggestion =
              'Reduce other tasks or extend daily cap to fit the remaining '
              '${remaining.toStringAsFixed(1)}h before the deadline.';
        }
        conflicts.add(_Conflict(
            task: task, unscheduledHours: remaining, suggestion: suggestion));
      }
    }

    return _ScheduleResult(
      days: List.generate(
        7,
        (i) => _DayPlan(
            date: today.add(Duration(days: i)),
            totalHours: hoursUsed[i],
            slots: daySlots[i]),
      ),
      conflicts: conflicts,
    );
  }

  static Color _priorityColor(TaskModel task) {
    final label = TaskModel.getPriorityLabel(task.deadline, task.courseWeight);
    if (label == 'High') return Colors.redAccent;
    if (label == 'Med') return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  static String _dayLabel(int index, DateTime date) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[date.weekday - 1]} ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Schedule',
                style: TextStyle(
                    color: _textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Priority-first · 4h/day cap',
                style: TextStyle(color: _subtextColor, fontSize: 12)),
          ],
        ),
      ),
      // Live stream — schedule regenerates whenever tasks are added or completed
      body: StreamBuilder<List<TaskModel>>(
        stream: FirestoreService().getTasks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, color: _subtextColor, size: 48),
                  const SizedBox(height: 16),
                  const Text('No tasks to schedule',
                      style: TextStyle(color: _subtextColor)),
                  const SizedBox(height: 8),
                  const Text('Add tasks from the Tasks tab first',
                      style: TextStyle(color: _subtextColor, fontSize: 13)),
                ],
              ),
            );
          }

          final result = _buildSchedule(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 7-day grid
                ...List.generate(7, (i) {
                  final day = result.days[i];
                  final overloaded = day.totalHours > _dailyCap;

                  // Green = light load, orange = heavy, red = overloaded
                  final Color loadColor;
                  if (day.totalHours == 0) {
                    loadColor = _subtextColor;
                  } else if (day.totalHours <= 2) {
                    loadColor = Colors.greenAccent;
                  } else if (!overloaded) {
                    loadColor = Colors.orangeAccent;
                  } else {
                    loadColor = Colors.redAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: overloaded
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : i == 0
                                  ? _accentColor.withValues(alpha: 0.3)
                                  : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_dayLabel(i, day.date),
                                  style: TextStyle(
                                      color: i == 0 ? _accentColor : _textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: loadColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  day.totalHours == 0
                                      ? 'Free'
                                      : '${day.totalHours.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                      color: loadColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (day.slots.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...day.slots.map((slot) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Coloured priority bar
                                      Container(
                                        width: 3, height: 36,
                                        decoration: BoxDecoration(
                                          color: _priorityColor(slot.task),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${slot.task.courseName} — ${slot.task.title}',
                                              style: const TextStyle(
                                                  color: _textColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${slot.hours.toStringAsFixed(1)}h  •  due ${slot.task.deadline.day}/${slot.task.deadline.month}',
                                              style: const TextStyle(
                                                  color: _subtextColor, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Nothing scheduled',
                                  style: const TextStyle(
                                      color: _subtextColor, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // Conflict warnings — tasks that couldn't fit before their deadline
                if (result.conflicts.isNotEmpty) ...[
                  const Text('Conflict Warnings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 4),
                  const Text(
                      'These tasks cannot be fully scheduled before their deadline.',
                      style: TextStyle(color: _subtextColor, fontSize: 13)),
                  const SizedBox(height: 12),
                  ...result.conflicts.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${c.task.courseName} — ${c.task.title}',
                                        style: const TextStyle(
                                            color: _textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${c.unscheduledHours.toStringAsFixed(1)}h cannot fit before deadline',
                                      style: const TextStyle(
                                          color: Colors.redAccent, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Suggestion: ${c.suggestion}',
                                        style: const TextStyle(
                                            color: _subtextColor, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ] else ...[
                  // All tasks scheduled — green success banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.greenAccent, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All tasks fit within the 7-day window. No conflicts.',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskSlot {
  final TaskModel task;
  final double hours;
  const _TaskSlot({required this.task, required this.hours});
}

class _DayPlan {
  final DateTime date;
  final double totalHours;
  final List<_TaskSlot> slots;
  const _DayPlan({required this.date, required this.totalHours, required this.slots});
}

class _Conflict {
  final TaskModel task;
  final double unscheduledHours;
  final String suggestion;
  const _Conflict(
      {required this.task, required this.unscheduledHours, required this.suggestion});
}

class _ScheduleResult {
  final List<_DayPlan> days;
  final List<_Conflict> conflicts;
  const _ScheduleResult({required this.days, required this.conflicts});
}
