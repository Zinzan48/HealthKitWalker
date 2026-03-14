import '../domain/writer_mode.dart';

class StepWriteResult {
  const StepWriteResult({required this.stepsWritten, required this.message});

  final int stepsWritten;
  final String message;
}

class StepWriterException implements Exception {
  const StepWriterException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class StepWriter {
  WriterMode get writerMode;

  Future<String> prepareForSession();

  Future<StepWriteResult> writeSteps({
    required int steps,
    required DateTime startedAt,
    required DateTime endedAt,
  });
}
