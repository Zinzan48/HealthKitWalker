class SessionTick {
  const SessionTick({
    required this.index,
    required this.steps,
    required this.startedAt,
    required this.endedAt,
    required this.recordedAt,
    required this.totalWrittenStepsAfterTick,
    required this.message,
  });

  final int index;
  final int steps;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime recordedAt;
  final int totalWrittenStepsAfterTick;
  final String message;
}
