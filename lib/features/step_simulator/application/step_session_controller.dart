import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/session_persistence.dart';
import '../data/step_writer.dart';
import '../domain/session_config.dart';
import '../domain/session_snapshot.dart';
import '../domain/session_status.dart';
import '../domain/session_tick.dart';
import '../domain/step_planner.dart';

class StepSessionController extends ChangeNotifier {
  StepSessionController({
    required StepWriter writer,
    required SessionPersistence persistence,
    Random? random,
  })  : _writer = writer,
        _persistence = persistence,
        _random = random ?? Random();

  final StepWriter _writer;
  final SessionPersistence _persistence;
  final Random _random;

  SessionConfig _currentConfig = SessionConfig.defaults();
  SessionStatus _status = SessionStatus.idle;
  final List<SessionTick> _ticks = <SessionTick>[];
  Timer? _ticker;
  bool _tickInProgress = false;
  int _completedTicks = 0;
  int _totalWrittenSteps = 0;
  DateTime? _nextTickAt;
  String _message = '目前為 mock 模式，不會真的寫入 Apple Health。';

  SessionConfig get currentConfig => _currentConfig;
  SessionStatus get status => _status;
  List<SessionTick> get ticks => List<SessionTick>.unmodifiable(_ticks);
  int get completedTicks => _completedTicks;
  int get totalWrittenSteps => _totalWrittenSteps;
  String get message => _message;

  int? get estimatedTickCount =>
      _currentConfig.mode.isFixedDuration ? _currentConfig.estimatedTickCount : null;

  int? get estimatedTotalSteps =>
      _currentConfig.mode.isFixedDuration ? _currentConfig.estimatedTotalSteps : null;

  Duration? get timeUntilNextTick {
    if (_status != SessionStatus.running || _nextTickAt == null) {
      return null;
    }

    final difference = _nextTickAt!.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  Future<void> initialize() async {
    _currentConfig = _persistence.loadConfig();

    final snapshot = _persistence.loadSnapshot();
    if (snapshot != null) {
      _currentConfig = snapshot.config;
      _completedTicks = snapshot.completedTicks;
      _totalWrittenSteps = snapshot.totalWrittenSteps;
      _status = snapshot.status == SessionStatus.running
          ? SessionStatus.paused
          : snapshot.status;
      _message = snapshot.status == SessionStatus.running
          ? '先前 session 因離開前景而暫停，請手動恢復。'
          : snapshot.message;
    }

    notifyListeners();
  }

  Future<void> start(SessionConfig config) async {
    _cancelTicker();

    _currentConfig = config;
    _status = SessionStatus.running;
    _message = config.mode.isFixedDuration
        ? 'Session 已開始。第一個 tick 會在 ${config.intervalMinutes} 分鐘後觸發。'
        : '無限循環 session 已開始。第一個 tick 會在 ${config.intervalMinutes} 分鐘後觸發。';
    _ticks.clear();
    _completedTicks = 0;
    _totalWrittenSteps = 0;
    _nextTickAt = DateTime.now().add(config.intervalDuration);

    await _persistence.saveConfig(config);
    await _persistSnapshot();
    _startTicker();
    notifyListeners();
  }

  Future<void> pause({String reason = 'Session 已手動暫停。'}) async {
    if (_status != SessionStatus.running) {
      return;
    }

    _cancelTicker();
    _status = SessionStatus.paused;
    _nextTickAt = null;
    _message = reason;
    await _persistSnapshot();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_status != SessionStatus.paused) {
      return;
    }

    _status = SessionStatus.running;
    _message = 'Session 已恢復，下一個 tick 會在 ${_currentConfig.intervalMinutes} 分鐘後觸發。';
    _nextTickAt = DateTime.now().add(_currentConfig.intervalDuration);
    await _persistSnapshot();
    _startTicker();
    notifyListeners();
  }

  Future<void> stop({String reason = 'Session 已停止。'}) async {
    _cancelTicker();
    _status = SessionStatus.stopped;
    _nextTickAt = null;
    _message = reason;
    await _persistence.clearSnapshot();
    notifyListeners();
  }

  Future<void> handleLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_status == SessionStatus.running) {
          await pause(
            reason: 'App 離開前景，已自動暫停。這個 prototype 不會在背景持續排程。',
          );
        }
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  void dispose() {
    _cancelTicker();
    super.dispose();
  }

  void _startTicker() {
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_handleTicker());
    });
  }

  Future<void> _handleTicker() async {
    if (_status != SessionStatus.running || _nextTickAt == null) {
      return;
    }

    if (_tickInProgress) {
      return;
    }

    final now = DateTime.now();
    if (now.isBefore(_nextTickAt!)) {
      notifyListeners();
      return;
    }

    _tickInProgress = true;
    try {
      await _runTick(now);
    } finally {
      _tickInProgress = false;
    }
  }

  Future<void> _runTick(DateTime endedAt) async {
    final startedAt = endedAt.subtract(_currentConfig.intervalDuration);
    final steps = StepPlanner.planNextSteps(
      config: _currentConfig,
      completedTicks: _completedTicks,
      totalWrittenSteps: _totalWrittenSteps,
      random: _random,
    );

    final result = await _writer.writeSteps(
      steps: steps,
      startedAt: startedAt,
      endedAt: endedAt,
    );

    _completedTicks += 1;
    _totalWrittenSteps += result.stepsWritten;
    _ticks.insert(
      0,
      SessionTick(
        index: _completedTicks,
        steps: result.stepsWritten,
        startedAt: startedAt,
        endedAt: endedAt,
        recordedAt: DateTime.now(),
        totalWrittenStepsAfterTick: _totalWrittenSteps,
        message: result.message,
      ),
    );
    if (_ticks.length > 30) {
      _ticks.removeLast();
    }

    if (_currentConfig.mode.isFixedDuration &&
        _completedTicks >= _currentConfig.estimatedTickCount) {
      _cancelTicker();
      _status = SessionStatus.completed;
      _nextTickAt = null;
      _message =
          'Fixed session 已完成。預估 ${_currentConfig.estimatedTotalSteps} 步，實際 mock 累計 $_totalWrittenSteps 步。';
      await _persistSnapshot();
      notifyListeners();
      return;
    }

    _message = result.message;
    _nextTickAt = DateTime.now().add(_currentConfig.intervalDuration);
    await _persistSnapshot();
    notifyListeners();
  }

  Future<void> _persistSnapshot() async {
    final snapshot = SessionSnapshot(
      config: _currentConfig,
      status: _status,
      completedTicks: _completedTicks,
      totalWrittenSteps: _totalWrittenSteps,
      message: _message,
      nextTickAt: _nextTickAt,
      savedAt: DateTime.now(),
    );

    await _persistence.saveSnapshot(snapshot);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
