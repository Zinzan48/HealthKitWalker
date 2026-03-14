import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthkitwalker/features/step_simulator/application/step_session_controller.dart';
import 'package:healthkitwalker/features/step_simulator/data/mock_step_writer.dart';
import 'package:healthkitwalker/features/step_simulator/data/session_persistence.dart';
import 'package:healthkitwalker/features/step_simulator/data/step_writer.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_config.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_mode.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_snapshot.dart';
import 'package:healthkitwalker/features/step_simulator/domain/session_status.dart';
import 'package:healthkitwalker/features/step_simulator/domain/writer_mode.dart';

void main() {
  group('StepSessionController', () {
    test('supports start, pause, resume, lifecycle pause, and stop', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final mockWriter = _FakeStepWriter(writerMode: WriterMode.mock);
      final controller = StepSessionController(
        writers: <WriterMode, StepWriter>{
          WriterMode.mock: mockWriter,
          WriterMode.healthKit: _FakeStepWriter(
            writerMode: WriterMode.healthKit,
          ),
        },
        persistence: SessionPersistence(preferences),
      );

      await controller.initialize();
      await controller.start(
        const SessionConfig(
          intervalMinutes: 1,
          averageStepsPerInterval: 100,
          mode: SessionMode.fixedDuration,
          writerMode: WriterMode.mock,
          totalMinutes: 5,
        ),
      );

      expect(controller.status, SessionStatus.running);
      expect(controller.completedTicks, 0);
      expect(mockWriter.prepareCalls, 1);

      await controller.pause();
      expect(controller.status, SessionStatus.paused);
      expect(controller.timeUntilNextTick, isNull);

      await controller.resume();
      expect(controller.status, SessionStatus.running);
      expect(controller.timeUntilNextTick, isNotNull);

      await controller.handleLifecycleChange(AppLifecycleState.paused);
      expect(controller.status, SessionStatus.paused);
      expect(controller.message, contains('自動暫停'));

      await controller.stop();
      expect(controller.status, SessionStatus.stopped);
    });

    test('restores a running snapshot as paused on initialize', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final persistence = SessionPersistence(preferences);
      final config = const SessionConfig(
        intervalMinutes: 5,
        averageStepsPerInterval: 280,
        mode: SessionMode.fixedDuration,
        writerMode: WriterMode.mock,
        totalMinutes: 30,
      );

      await persistence.saveSnapshot(
        SessionSnapshot(
          config: config,
          status: SessionStatus.running,
          completedTicks: 2,
          totalWrittenSteps: 560,
          message: 'running before app exit',
          nextTickAt: DateTime.now().add(const Duration(minutes: 5)),
          savedAt: DateTime.now(),
        ),
      );

      final controller = StepSessionController(
        writers: <WriterMode, StepWriter>{
          WriterMode.mock: const MockStepWriter(),
          WriterMode.healthKit: _FakeStepWriter(
            writerMode: WriterMode.healthKit,
          ),
        },
        persistence: persistence,
      );

      await controller.initialize();

      expect(controller.status, SessionStatus.paused);
      expect(controller.completedTicks, 2);
      expect(controller.totalWrittenSteps, 560);
      expect(controller.message, contains('請手動恢復'));
    });

    test('switches between mock and healthkit writers by config', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final mockWriter = _FakeStepWriter(writerMode: WriterMode.mock);
      final healthWriter = _FakeStepWriter(writerMode: WriterMode.healthKit);
      final controller = StepSessionController(
        writers: <WriterMode, StepWriter>{
          WriterMode.mock: mockWriter,
          WriterMode.healthKit: healthWriter,
        },
        persistence: SessionPersistence(preferences),
      );

      await controller.initialize();

      await controller.start(
        const SessionConfig(
          intervalMinutes: 1,
          averageStepsPerInterval: 90,
          mode: SessionMode.fixedDuration,
          writerMode: WriterMode.mock,
          totalMinutes: 1,
        ),
      );
      await controller.stop();

      await controller.start(
        const SessionConfig(
          intervalMinutes: 1,
          averageStepsPerInterval: 120,
          mode: SessionMode.fixedDuration,
          writerMode: WriterMode.healthKit,
          totalMinutes: 2,
        ),
      );

      expect(mockWriter.prepareCalls, 1);
      expect(healthWriter.prepareCalls, 1);
      expect(controller.currentConfig.writerMode, WriterMode.healthKit);
      expect(controller.message, contains('HealthKit'));
    });

    test('keeps app idle when selected writer cannot prepare', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final controller = StepSessionController(
        writers: <WriterMode, StepWriter>{
          WriterMode.mock: const MockStepWriter(),
          WriterMode.healthKit: _FakeStepWriter(
            writerMode: WriterMode.healthKit,
            prepareError: 'HealthKit unavailable',
          ),
        },
        persistence: SessionPersistence(preferences),
      );

      await controller.initialize();

      await controller.start(
        const SessionConfig(
          intervalMinutes: 1,
          averageStepsPerInterval: 80,
          mode: SessionMode.fixedDuration,
          writerMode: WriterMode.healthKit,
          totalMinutes: 5,
        ),
      );

      expect(controller.status, SessionStatus.idle);
      expect(controller.message, 'HealthKit unavailable');
      expect(controller.timeUntilNextTick, isNull);
      expect(controller.currentConfig.writerMode, WriterMode.healthKit);
    });
  });
}

class _FakeStepWriter implements StepWriter {
  _FakeStepWriter({required this.writerMode, this.prepareError});

  @override
  final WriterMode writerMode;
  final String? prepareError;
  static int _idSeed = 0;

  int prepareCalls = 0;

  @override
  Future<String> prepareForSession() async {
    prepareCalls += 1;
    if (prepareError != null) {
      throw StepWriterException(prepareError!);
    }

    return '${writerMode.label} writer 已就緒。';
  }

  @override
  Future<StepWriteResult> writeSteps({
    required int steps,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    _idSeed += 1;
    return StepWriteResult(
      stepsWritten: steps,
      message: '${writerMode.label} tick #$_idSeed',
    );
  }
}
