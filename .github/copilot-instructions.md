# Copilot instructions for HealthKitWalker

## Build, test, and lint commands

- Use FVM locally. The pinned Flutter version lives in `.fvmrc`.
- Install dependencies: `fvm flutter pub get`
- Analyze: `fvm flutter analyze`
- Run all tests: `fvm flutter test`
- Run one test file: `fvm flutter test test\widget_test.dart`
- Run one named test: `fvm flutter test test\features\step_simulator\application\step_session_controller_test.dart --plain-name "switches between mock and healthkit writers by config"`
- Run on an iOS device: `fvm flutter run -d <ios-device-id>`
- Build a signed IPA later, when macOS/Xcode/signing are available:
  - `fvm flutter build ipa --export-method development`
  - `fvm flutter build ipa --export-method ad-hoc`

CI in `.github\workflows\flutter-ci.yml` reads the Flutter version from `.fvmrc` and runs `flutter pub get`, `flutter analyze`, and `flutter test`. Keep local commands aligned with that workflow.

## High-level architecture

This is an iOS-first Flutter app centered on a single feature: a timed step-writing simulator with switchable `Mock` and `HealthKit` writer modes.

- `lib\main.dart` is the composition root. It creates `SessionPersistence`, registers the writer implementations in a `Map<WriterMode, StepWriter>`, initializes `StepSessionController`, and passes that controller into the app shell.
- `lib\app\app.dart` is only the Material app wrapper. The real behavior starts in `features\step_simulator`.
- `lib\features\step_simulator\application\step_session_controller.dart` is the orchestration layer. It owns session state, lifecycle handling, timer scheduling, persistence, writer selection, and user-facing status messages.
- `lib\features\step_simulator\domain\` contains the core session model:
  - `SessionConfig` carries all user-editable settings, including `writerMode`.
  - `SessionMode` controls fixed-duration vs infinite-loop behavior.
  - `WriterMode` controls `Mock` vs `HealthKit`.
  - `StepPlanner` contains the randomness logic.
  - snapshot/tick/status types support persistence and UI state.
- `lib\features\step_simulator\data\` contains boundary integrations:
  - `StepWriter` is the abstraction future writer implementations should follow.
  - `MockStepWriter` simulates writes without touching Apple Health.
  - `HealthKitStepWriter` uses the `health` package, requests authorization in `prepareForSession()`, and writes step samples in `writeSteps()`.
  - `SessionPersistence` stores the last config and the latest session snapshot in `shared_preferences`.
- `lib\features\step_simulator\presentation\step_simulator_page.dart` is the only screen. It builds the form, writer-mode toggle, session-mode toggle, action buttons, and tick log, and listens to `StepSessionController` directly with `ListenableBuilder`.
- iOS HealthKit setup is partially checked into source:
  - `ios\Runner\Info.plist` contains HealthKit usage descriptions.
  - `ios\Runner\Runner.entitlements` contains the HealthKit entitlement key.
  - `ios\Runner.xcodeproj\project.pbxproj` points `CODE_SIGN_ENTITLEMENTS` at that entitlements file.

The app is intentionally foreground-first. When the app leaves the foreground, `StepSessionController.handleLifecycleChange()` auto-pauses the session instead of trying to keep background scheduling alive.

## Key conventions

- New session settings belong in `SessionConfig`. If you add one, update `defaults()`, `fromJson()`, `toJson()`, `copyWith()`, and the form/summary UI together so persistence and display stay in sync.
- Writer behavior must go through `StepWriter`. New writer implementations should:
  - declare a `WriterMode`
  - perform capability/permission checks in `prepareForSession()`
  - throw `StepWriterException` for user-facing failures so the controller can pause or stay idle cleanly
- Do not put randomness directly in UI or writer code. Keep step distribution rules inside `StepPlanner`.
- Preserve the fixed-duration guarantee in `StepPlanner`: jitter is allowed per tick, but the final total must still land on the configured target by the last tick.
- The writer-mode toggle in the UI edits draft config for the next start. Current copy already tells users that changed settings apply on the next session start; keep that behavior unless you intentionally redesign runtime reconfiguration.
- Most runtime UI/status copy is in Traditional Chinese. Keep new user-facing strings consistent with that tone, even though repo docs are in English.
- Tests mirror the feature structure under `test\features\step_simulator\...`. Controller tests use fake writers and mocked `SharedPreferences`; they should not depend on the real `health` plugin or iOS availability.
- Real HealthKit behavior is present in code, but still depends on Apple Developer signing, iPhone/iOS, entitlement setup, and user authorization. When changing HealthKit-related code, keep the mock path working because it is the default low-cost development path described in `README.MD`.
