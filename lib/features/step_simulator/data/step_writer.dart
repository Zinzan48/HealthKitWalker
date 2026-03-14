class StepWriteResult {
  const StepWriteResult({
    required this.stepsWritten,
    required this.message,
  });

  final int stepsWritten;
  final String message;
}

abstract interface class StepWriter {
  Future<StepWriteResult> writeSteps({
    required int steps,
    required DateTime startedAt,
    required DateTime endedAt,
  });
}
