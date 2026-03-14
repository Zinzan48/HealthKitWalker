import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_config.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_mode.dart';
import 'package:healthkitwalker/features/step_simulator/domain/step_planner.dart';
import 'package:healthkitwalker/features/step_simulator/domain/writer_mode.dart';

void main() {
  group('StepPlanner', () {
    test('matches the fixed-duration target total across all ticks', () {
      const config = SessionConfig(
        intervalMinutes: 5,
        averageStepsPerInterval: 200,
        mode: SessionMode.fixedDuration,
        writerMode: WriterMode.mock,
        totalMinutes: 30,
      );
      final random = Random(42);
      var completedTicks = 0;
      var totalWrittenSteps = 0;

      while (completedTicks < config.estimatedTickCount) {
        totalWrittenSteps += StepPlanner.planNextSteps(
          config: config,
          completedTicks: completedTicks,
          totalWrittenSteps: totalWrittenSteps,
          random: random,
        );
        completedTicks += 1;
      }

      expect(totalWrittenSteps, config.estimatedTotalSteps);
    });

    test('keeps infinite-loop steps within the jitter window', () {
      const config = SessionConfig(
        intervalMinutes: 3,
        averageStepsPerInterval: 150,
        mode: SessionMode.infiniteLoop,
        writerMode: WriterMode.mock,
      );
      final random = Random(7);

      for (var i = 0; i < 20; i++) {
        final steps = StepPlanner.planNextSteps(
          config: config,
          completedTicks: 0,
          totalWrittenSteps: 0,
          random: random,
        );

        expect(steps, greaterThanOrEqualTo(123));
        expect(steps, lessThanOrEqualTo(177));
      }
    });
  });
}
