import 'dart:math';

import 'session_config.dart';

class StepPlanner {
  const StepPlanner._();

  static int planNextSteps({
    required SessionConfig config,
    required int completedTicks,
    required int totalWrittenSteps,
    required Random random,
  }) {
    final minPerTick = max(
      1,
      (config.averageStepsPerInterval * (1 - config.jitterRatio)).round(),
    );
    final maxPerTick = max(
      minPerTick,
      (config.averageStepsPerInterval * (1 + config.jitterRatio)).round(),
    );

    if (config.mode.isInfiniteLoop) {
      final jittered =
          (config.averageStepsPerInterval *
                  (1 + _nextJitter(random, config.jitterRatio)))
              .round();
      return jittered.clamp(minPerTick, maxPerTick);
    }

    final remainingTicks = config.estimatedTickCount - completedTicks;
    final remainingTarget = config.estimatedTotalSteps - totalWrittenSteps;

    if (remainingTicks <= 1) {
      return max(1, remainingTarget);
    }

    final averageRemaining = remainingTarget / remainingTicks;
    final jittered =
        (averageRemaining * (1 + _nextJitter(random, config.jitterRatio)))
            .round();

    final minAllowed = max(
      1,
      remainingTarget - ((remainingTicks - 1) * maxPerTick),
    );
    final maxAllowed = max(
      minAllowed,
      remainingTarget - ((remainingTicks - 1) * minPerTick),
    );

    return jittered.clamp(minAllowed, maxAllowed);
  }

  static double _nextJitter(Random random, double ratio) {
    return ((random.nextDouble() * 2) - 1) * ratio;
  }
}
