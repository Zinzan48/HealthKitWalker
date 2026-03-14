# HealthKitWalker

`HealthKitWalker` is an **iOS-first Flutter prototype** for simulating timed step-writing sessions.

Right now this repository is intentionally built as a **mock / prototype first** project:

- build the UI
- validate the session flow
- validate the random step allocation
- validate pause / resume behavior
- keep the cost near zero

Actual on-device HealthKit writing is deferred until Apple Developer Program access is available.

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

The current app is expected to support:

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

- real Apple Health writes
- signed IPA distribution
- HealthKit entitlement setup
- any attempt to bypass Apple signing requirements

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

Each clear phase should be committed locally before moving on.

## Upgrade path to real HealthKit

When the project is ready to move from prototype to real HealthKit:

1. join Apple Developer Program
2. prepare macOS + Xcode access
3. add the `health` Flutter package
4. configure iOS `Info.plist`
5. enable `HealthKit` capability in Xcode
6. replace the mock writer with a real HealthKit writer
7. verify authorization, writing, and sideload flow on a real iPhone
