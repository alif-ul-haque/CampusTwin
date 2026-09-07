import 'package:campus_twin/habitTracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HabitMetric metricFor(HabitType type, double target) => HabitMetric(
        type: type,
        title: 'x',
        icon: Icons.star_rounded,
        color: const Color(0xFF000000),
        current: 0,
        target: target,
        unit: 'u',
        weekValues: List.filled(7, 0),
        streak: 0,
      );

  group('isGoalMet', () {
    test('sleep: within 80%–120% of goal is met, above or below is not', () {
      final sleep = metricFor(HabitType.sleep, 8);

      expect(sleep.isGoalMet(6.4), isTrue); // exactly 80%
      expect(sleep.isGoalMet(9.6), isTrue); // exactly 120%
      expect(sleep.isGoalMet(7), isTrue);
      expect(sleep.isGoalMet(21), isFalse); // the reported 21h bug
      expect(sleep.isGoalMet(10), isFalse); // 125% → sad
      expect(sleep.isGoalMet(5), isFalse); // 62.5% → sad
    });

    test('water & exercise: >=80% of goal is met', () {
      final water = metricFor(HabitType.water, 3);
      final exercise = metricFor(HabitType.exercise, 45);

      expect(water.isGoalMet(2.4), isTrue);
      expect(water.isGoalMet(1.0), isFalse);
      expect(water.isGoalMet(6), isTrue); // exceeding is fine for water
      expect(exercise.isGoalMet(36), isTrue);
      expect(exercise.isGoalMet(10), isFalse);
    });

    test('screen time: at/under goal is met, crossing is not', () {
      final screen = metricFor(HabitType.screenTime, 4);

      expect(screen.isGoalMet(3.5), isTrue);
      expect(screen.isGoalMet(4), isTrue);
      expect(screen.isGoalMet(4.01), isFalse);
    });

    test('no goal (target 0) is never met', () {
      expect(metricFor(HabitType.sleep, 0).isGoalMet(7), isFalse);
      expect(metricFor(HabitType.screenTime, 0).isGoalMet(0), isFalse);
    });
  });

  test('max allowed goals match the requested limits', () {
    expect(HabitRepository.maxGoalFor(HabitType.sleep), 15);
    expect(HabitRepository.maxGoalFor(HabitType.water), 5);
    expect(HabitRepository.maxGoalFor(HabitType.exercise), 180);
    expect(HabitRepository.maxGoalFor(HabitType.screenTime), 8);
  });
}