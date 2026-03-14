enum WriterMode {
  mock,
  healthKit;

  String get label => switch (this) {
    WriterMode.mock => 'Mock',
    WriterMode.healthKit => 'HealthKit',
  };

  String get description => switch (this) {
    WriterMode.mock => '完整模擬流程，但不會修改 Apple Health 資料。',
    WriterMode.healthKit => '真正寫入 Apple Health，需 iPhone + entitlement + 授權。',
  };
}
