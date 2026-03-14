import 'dart:math';

import 'session_mode.dart';
import 'writer_mode.dart';

class SessionConfig {
  const SessionConfig({
    required this.intervalMinutes,
    required this.averageStepsPerInterval,
    required this.mode,
    required this.writerMode,
    this.totalMinutes,
    this.jitterRatio = 0.18,
  });

  factory SessionConfig.defaults() {
    return const SessionConfig(
      intervalMinutes: 5,
      averageStepsPerInterval: 280,
      mode: SessionMode.fixedDuration,
      writerMode: WriterMode.mock,
      totalMinutes: 30,
    );
  }

  factory SessionConfig.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String?;
    final mode = SessionMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => SessionMode.fixedDuration,
    );
    final writerModeName = json['writerMode'] as String?;
    final writerMode = WriterMode.values.firstWhere(
      (value) => value.name == writerModeName,
      orElse: () => WriterMode.mock,
    );

    return SessionConfig(
      intervalMinutes: json['intervalMinutes'] as int? ?? 5,
      averageStepsPerInterval: json['averageStepsPerInterval'] as int? ?? 280,
      mode: mode,
      writerMode: writerMode,
      totalMinutes: json['totalMinutes'] as int?,
      jitterRatio: (json['jitterRatio'] as num?)?.toDouble() ?? 0.18,
    );
  }

  final int intervalMinutes;
  final int averageStepsPerInterval;
  final SessionMode mode;
  final WriterMode writerMode;
  final int? totalMinutes;
  final double jitterRatio;

  Duration get intervalDuration => Duration(minutes: intervalMinutes);

  int get estimatedTickCount {
    if (mode.isInfiniteLoop) {
      return 0;
    }

    final minutes = totalMinutes ?? intervalMinutes;
    return max(1, (minutes / intervalMinutes).ceil());
  }

  int get estimatedTotalSteps {
    if (mode.isInfiniteLoop) {
      return averageStepsPerInterval;
    }

    return estimatedTickCount * averageStepsPerInterval;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'intervalMinutes': intervalMinutes,
      'averageStepsPerInterval': averageStepsPerInterval,
      'mode': mode.name,
      'writerMode': writerMode.name,
      'totalMinutes': totalMinutes,
      'jitterRatio': jitterRatio,
    };
  }

  SessionConfig copyWith({
    int? intervalMinutes,
    int? averageStepsPerInterval,
    SessionMode? mode,
    WriterMode? writerMode,
    int? totalMinutes,
    double? jitterRatio,
  }) {
    return SessionConfig(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      averageStepsPerInterval:
          averageStepsPerInterval ?? this.averageStepsPerInterval,
      mode: mode ?? this.mode,
      writerMode: writerMode ?? this.writerMode,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      jitterRatio: jitterRatio ?? this.jitterRatio,
    );
  }
}
