import 'dart:io';

import 'package:health/health.dart';

import '../domain/writer_mode.dart';
import 'step_writer.dart';

class HealthKitStepWriter implements StepWriter {
  HealthKitStepWriter({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  @override
  WriterMode get writerMode => WriterMode.healthKit;

  @override
  Future<String> prepareForSession() async {
    if (!Platform.isIOS) {
      throw const StepWriterException(
        'HealthKit 模式只能在 iPhone/iOS 上使用。請先切回 Mock 模式，或改用實機驗證。',
      );
    }

    if (!_configured) {
      await _health.configure();
      _configured = true;
    }

    final granted = await _health.requestAuthorization(
      <HealthDataType>[HealthDataType.STEPS],
      permissions: <HealthDataAccess>[HealthDataAccess.READ_WRITE],
    );

    if (!granted) {
      throw const StepWriterException('HealthKit 授權未通過。請在 iPhone 上允許步數寫入權限。');
    }

    return 'HealthKit writer 已就緒。這次 session 會嘗試寫入 Apple Health。';
  }

  @override
  Future<StepWriteResult> writeSteps({
    required int steps,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final success = await _health.writeHealthData(
      value: steps.toDouble(),
      type: HealthDataType.STEPS,
      startTime: startedAt,
      endTime: endedAt,
      recordingMethod: RecordingMethod.manual,
    );

    if (!success) {
      throw const StepWriterException(
        'HealthKit 寫入失敗。請確認 entitlement、簽章與 Apple Health 權限。',
      );
    }

    final minutes = endedAt.difference(startedAt).inMinutes;
    final minutesLabel = minutes <= 0 ? 1 : minutes;

    return StepWriteResult(
      stepsWritten: steps,
      message: 'HealthKit 寫入成功：已將 $steps 步寫入這個 $minutesLabel 分鐘區段。',
    );
  }
}
