# HealthKitWalker

`HealthKitWalker` is an **iOS-first Flutter prototype** for timed step-writing sessions with a switchable writer mode.

Right now this repository is intentionally built as a **mock-first but HealthKit-ready** project:

- build the UI
- validate the session flow
- validate the random step allocation
- validate pause / resume behavior
- keep both `Mock` and `HealthKit` writers behind a simple config switch
- keep the cost near zero

Actual on-device HealthKit writing is implemented in code, but only works when Apple Developer Program signing, HealthKit entitlement, and iPhone authorization are available.

## Why this repo is mock-first

Writing to real `HealthKit` on a real iPhone requires more than just a Flutter app:

- `Apple Developer Program`
- `HealthKit` entitlement
- macOS + Xcode somewhere (local Mac, borrowed Mac, cloud Mac, or GitHub Actions macOS runner)

Because a free Apple account does **not** unlock the `HealthKit` capability for this app, the current cheapest path is:

1. build a realistic prototype first
2. confirm the flow is worth keeping
3. only then decide whether to pay the annual Apple fee

## Current scope

The current app already supports:

- switchable `Mock` / `HealthKit` writer mode
- interval minutes
- average steps per interval
- fixed-duration mode
- infinite-loop mode
- estimated total steps
- randomized per-tick step counts
- foreground-only session handling
- lifecycle-driven pause behavior
- local persistence for the last config and paused state

## Not included yet

- signed IPA distribution
- any attempt to bypass Apple signing requirements

## Writer modes

### Mock

- safe default
- simulates every tick and log entry
- does **not** change Apple Health data
- works for local development, widget tests, and no-cost flow validation

### HealthKit

- uses the Flutter `health` package
- asks for Apple Health authorization when a session starts
- writes step samples with `RecordingMethod.manual`
- requires:
  - iPhone / iOS
  - Apple Developer Program signing
  - `HealthKit` entitlement
  - `Info.plist` usage descriptions

The app persists your last selected writer mode, so you can switch and come back later without editing code.

## Cost summary

### Current mock / prototype route

- Apple Developer Program: **0**
- paid AI API / LLM cost: **0**
- GitHub Actions: **0 ~ low cost**, depending on repo type and usage

### Future real HealthKit route

- Apple Developer Program: **99 USD / year**
- no monthly option
- if used for only two months, the cash outlay is still **99 USD upfront**

## Toolchain

- Windows local development
- FVM-managed Flutter SDK
- pinned Flutter version: `3.35.7`

## Commands

```bash
dart pub global activate fvm
fvm use 3.35.7
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

## Local workflow

- Open the workspace in VS Code.
- The repo includes `.vscode/settings.json` so Dart / Flutter should point to `.fvm/flutter_sdk`.
- Start with the mock route first. This lets you validate the app behavior before spending money on Apple signing.

When the real HealthKit route becomes available later:

```bash
fvm flutter run -d <ios-device-id>
fvm flutter build ipa --export-method development
fvm flutter build ipa --export-method ad-hoc
```

## Git strategy

This repo is currently local-first:

1. scaffold
2. README / docs
3. mock simulation flow
4. UI / controls
5. CI / docs reinforcement

Each clear phase should be committed locally before moving on. This repository already has local phase commits for scaffold, docs, mock flow, and CI/editor setup.

## Upgrade path to real HealthKit

When the project is ready to move from prototype to real HealthKit:

1. join Apple Developer Program
2. prepare macOS + Xcode access
3. open `ios\Runner.xcworkspace` in Xcode and confirm the `HealthKit` capability is enabled
4. confirm `Runner.entitlements` and `Info.plist` match your signing target
5. run the existing `HealthKit` writer on a real iPhone
6. verify authorization, writing, and sideload flow

## CI

This repo includes `.github/workflows/flutter-ci.yml`.

The workflow:

1. reads the pinned Flutter version from `.fvmrc`
2. installs that version in GitHub Actions
3. runs `flutter pub get`
4. runs `flutter analyze`
5. runs `flutter test`
