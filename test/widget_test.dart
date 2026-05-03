// Unit tests for pure-Dart logic that does not require a running Flutter
// engine or Firebase — safe to run with `flutter test` on any machine.
import 'package:flutter_test/flutter_test.dart';
import 'package:focusnflow/models/task_model.dart';

void main() {
  group('TaskModel.calculatePriority', () {
    test('high urgency + heavy course → score above 60', () {
      final score = TaskModel.calculatePriority(
        DateTime.now().add(const Duration(days: 1)),
        2,   // estimatedHours
        25,  // courseWeight
      );
      expect(score, greaterThan(55)); // daysLeft truncates to 0 → score ≈ 58.5
    });

    test('far deadline + light course → score below 40', () {
      final score = TaskModel.calculatePriority(
        DateTime.now().add(const Duration(days: 60)),
        20,
        5,
      );
      expect(score, lessThan(40));
    });

    test('zero estimatedHours does not throw or produce infinity', () {
      final score = TaskModel.calculatePriority(
        DateTime.now().add(const Duration(days: 7)),
        0,  // previously divided by zero
        10,
      );
      expect(score.isFinite, isTrue);
      expect(score, greaterThan(0));
    });

    test('past-due task (negative daysLeft) still returns finite score', () {
      final score = TaskModel.calculatePriority(
        DateTime.now().subtract(const Duration(days: 3)),
        2,
        20,
      );
      expect(score.isFinite, isTrue);
    });
  });

  group('TaskModel.getPriorityLabel', () {
    test('within 3 days → High regardless of weight', () {
      expect(
        TaskModel.getPriorityLabel(
            DateTime.now().add(const Duration(days: 2)), 5),
        'High',
      );
    });

    test('4–7 days + weight ≥ 15 → High', () {
      expect(
        TaskModel.getPriorityLabel(
            DateTime.now().add(const Duration(days: 5)), 25),
        'High',
      );
    });

    test('4–7 days + weight < 15 → Med (deadline ≤ 14)', () {
      expect(
        TaskModel.getPriorityLabel(
            DateTime.now().add(const Duration(days: 5)), 10),
        'Med',
      );
    });

    test('far deadline + low weight → Low', () {
      expect(
        TaskModel.getPriorityLabel(
            DateTime.now().add(const Duration(days: 30)), 5),
        'Low',
      );
    });
  });

  group('TaskModel.daysLeftLabel', () {
    test('past deadline → Overdue', () {
      expect(
        TaskModel.daysLeftLabel(
            DateTime.now().subtract(const Duration(hours: 1))),
        'Overdue',
      );
    });

    test('within today → Due today', () {
      expect(
        TaskModel.daysLeftLabel(
            DateTime.now().add(const Duration(hours: 3))),
        'Due today',
      );
    });

    test('tomorrow → Due tomorrow', () {
      expect(
        TaskModel.daysLeftLabel(
            DateTime.now().add(const Duration(hours: 25))),
        'Due tomorrow',
      );
    });

    test('5 days away → 5 days left', () {
      expect(
        TaskModel.daysLeftLabel(
            DateTime.now().add(const Duration(days: 5, hours: 1))),
        '5 days left',
      );
    });
  });
}
