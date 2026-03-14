import 'session_config.dart';
import 'session_status.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.config,
    required this.status,
    required this.completedTicks,
    required this.totalWrittenSteps,
    required this.message,
    required this.savedAt,
    this.nextTickAt,
  });

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = SessionStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => SessionStatus.idle,
    );

    return SessionSnapshot(
      config: SessionConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map<dynamic, dynamic>),
      ),
      status: status,
      completedTicks: json['completedTicks'] as int? ?? 0,
      totalWrittenSteps: json['totalWrittenSteps'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      nextTickAt: json['nextTickAt'] == null
          ? null
          : DateTime.tryParse(json['nextTickAt'] as String),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final SessionConfig config;
  final SessionStatus status;
  final int completedTicks;
  final int totalWrittenSteps;
  final String message;
  final DateTime? nextTickAt;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'config': config.toJson(),
      'status': status.name,
      'completedTicks': completedTicks,
      'totalWrittenSteps': totalWrittenSteps,
      'message': message,
      'nextTickAt': nextTickAt?.toIso8601String(),
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
