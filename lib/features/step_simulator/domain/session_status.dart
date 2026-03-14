enum SessionStatus {
  idle,
  running,
  paused,
  stopped,
  completed,
}

extension SessionStatusX on SessionStatus {
  String get label => switch (this) {
    SessionStatus.idle => '待命',
    SessionStatus.running => '執行中',
    SessionStatus.paused => '已暫停',
    SessionStatus.stopped => '已停止',
    SessionStatus.completed => '已完成',
  };

  bool get isActive => this == SessionStatus.running || this == SessionStatus.paused;
}
