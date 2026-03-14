enum SessionMode {
  fixedDuration,
  infiniteLoop;

  bool get isFixedDuration => this == SessionMode.fixedDuration;

  bool get isInfiniteLoop => this == SessionMode.infiniteLoop;

  String get label => switch (this) {
    SessionMode.fixedDuration => '固定總時長',
    SessionMode.infiniteLoop => '無限循環',
  };
}
