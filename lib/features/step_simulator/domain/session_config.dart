import 'dart:math';

import 'session_mode.dart';

class SessionConfig {
  const SessionConfig({
    required this.intervalMinutes,
    required this.averageStepsPerInterval,
    required this.mode,
    this.totalMinutes,
    this.jitterRatio = 0.18,
  });

  factory SessionConfig.defaults() {
    return const SessionConfig(
      intervalMinutes: 5,
      averageStepsPerInterval: 280,
      mode: SessionMode.fixedDuration,
      totalMinutes: 30,
    );
  }

  factory SessionConfig.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'] as String?;
    final mode = SessionMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => SessionMode.fixedDuration,
    );

    return SessionConfig(
      intervalMinutes: json['intervalMinutes'] as int? ?? 5,
      averageStepsPerInterval: json['averageStepsPerInterval'] as int? ?? 280,
      mode: mode,
      totalMinutes: json['totalMinutes'] as int?,
      jitterRatio: (json['jitterRatio'] as num?)?.toDouble() ?? 0.18,
    );
  }

  final int intervalMinutes;
  final int averageStepsPerInterval;
  final SessionMode mode;
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
      'totalMinutes': totalMinutes,
      'jitterRatio': jitterRatio,
    };
  }

  SessionConfig copyWith({
    int? intervalMinutes,
    int? averageStepsPerInterval,
    SessionMode? mode,
    int? totalMinutes,
    double? jitterRatio,
  }) {
    return SessionConfig(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      averageStepsPerInterval:
          averageStepsPerInterval ?? this.averageStepsPerInterval,
      mode: mode ?? this.mode,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      jitterRatio: jitterRatio ?? this.jitterRatio,
    );
  }
}
