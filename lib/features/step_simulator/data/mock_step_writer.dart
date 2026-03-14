import 'step_writer.dart';
import '../domain/writer_mode.dart';

class MockStepWriter implements StepWriter {
  const MockStepWriter();

  @override
  WriterMode get writerMode => WriterMode.mock;

  @override
  Future<String> prepareForSession() async {
    return 'Mock writer 已就緒。這次 session 不會修改 Apple Health。';
  }

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
      message: 'Mock 寫入完成：這個 $minutesLabel 分鐘區段模擬了 $steps 步，沒有修改 Apple Health。',
    );
  }
}
