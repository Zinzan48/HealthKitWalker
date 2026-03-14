import 'step_writer.dart';

class MockStepWriter implements StepWriter {
  const MockStepWriter();

  @override
  Future<StepWriteResult> writeSteps({
    required int steps,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final minutes = endedAt.difference(startedAt).inMinutes;
    final minutesLabel = minutes <= 0 ? 1 : minutes;

    return StepWriteResult(
      stepsWritten: steps,
      message:
          'Mock write only: $steps steps for a $minutesLabel-minute segment. No HealthKit data was changed.',
    );
  }
}
