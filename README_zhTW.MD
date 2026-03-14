# HealthKitWalker

語言： [English](README.MD) | **繁體中文**

`HealthKitWalker` 是一個 **以 iOS 為優先的 Flutter prototype**，用來進行可切換 writer mode 的定時步數寫入流程。

目前這個 repository 採用 **mock-first，但已預留 HealthKit 路線** 的做法：

- 建立 UI
- 驗證 session 流程
- 驗證隨機步數分配
- 驗證 pause / resume 行為
- 讓 `Mock` 與 `HealthKit` 兩種 writer 都能透過設定切換
- 先把整體成本壓低

目前程式碼已包含真實 HealthKit writer，但只有在具備 Apple Developer Program 簽章、HealthKit entitlement 與 iPhone 授權時，才可以真的寫入 Apple Health。

## 為什麼這個專案是 mock-first

要在真實 iPhone 上把資料寫進 `HealthKit`，需要的不只是 Flutter App：

- `Apple Developer Program`
- `HealthKit` entitlement
- 任一種 macOS + Xcode 環境（本機 Mac、借用 Mac、雲端 Mac，或 GitHub Actions macOS runner）

因為免費 Apple 帳號 **無法** 為這個 App 解鎖 `HealthKit` capability，所以目前最省成本的路徑是：

1. 先做一個夠真實的 prototype
2. 先確認整個流程值得保留
3. 之後再決定要不要支付 Apple 年費

## 目前範圍

目前 App 已支援：

- `Mock` / `HealthKit` writer mode 切換
- 每次寫入間隔（分鐘）
- 每回合平均步數
- 固定總時長模式
- 無限循環模式
- 預估總步數
- 每個 tick 都帶隨機抖動的步數
- 前景優先的 session 執行策略
- 依 lifecycle 自動 pause
- 儲存上一次設定與暫停中的狀態

## 目前還沒包含

- 已簽章的 IPA 分發流程
- 任何繞過 Apple signing 規則的做法

## Writer modes

### Mock

- 安全的預設模式
- 會完整模擬每次 tick 與 log
- **不會** 修改 Apple Health 資料
- 適合本機開發、widget tests，以及低成本驗證流程

### HealthKit

- 使用 Flutter `health` 套件
- session 開始時會要求 Apple Health 授權
- 寫入步數時使用 `RecordingMethod.manual`
- 需要：
  - iPhone / iOS
  - Apple Developer Program 簽章
  - `HealthKit` entitlement
  - `Info.plist` 權限說明

App 會儲存你上次選的 writer mode，所以你之後可以直接切換回來，不需要改程式碼。

## 成本摘要

### 目前的 mock / prototype 路線

- Apple Developer Program：**0**
- 付費 AI API / LLM 成本：**0**
- GitHub Actions：**0 ~ 低成本**，視 repo 類型與使用量而定

### 未來真實 HealthKit 路線

- Apple Developer Program：**99 USD / 年**
- 沒有月費方案
- 就算只用兩個月，實際現金支出仍然是 **99 USD 一次付清**

## Toolchain

- Windows 本機開發
- 使用 FVM 管理 Flutter SDK
- 鎖定的 Flutter 版本：`3.35.7`
- iOS 最低 deployment target：`14.0`（`health` 套件目前需要）

## 指令

```bash
dart pub global activate fvm
fvm use 3.35.7
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

## 本機工作流程

- 用 VS Code 開啟 workspace。
- repo 已包含 `.vscode/settings.json`，Dart / Flutter 會指向 `.fvm/flutter_sdk`。
- 建議先從 mock 路線開始，先確認 app 行為是否符合需求，再決定是否花錢處理 Apple signing。

當你之後具備真實 HealthKit 所需條件時，可使用：

```bash
fvm flutter run -d <ios-device-id>
fvm flutter build ipa --export-method development
fvm flutter build ipa --export-method ad-hoc
```

## Git 策略

這個 repo 目前採本地優先：

1. scaffold
2. README / docs
3. mock simulation flow
4. UI / controls
5. CI / docs reinforcement

每完成一個明確階段，就先做本地 commit 再往下走。這個 repository 目前已經有 scaffold、docs、mock flow、CI / editor 設定等階段性的 local commits。

## 升級到真實 HealthKit 的路徑

當專案準備從 prototype 走向真實 HealthKit 時：

1. 加入 Apple Developer Program
2. 準備 macOS + Xcode 環境
3. 用 Xcode 開啟 `ios\Runner.xcworkspace`，確認已啟用 `HealthKit` capability
4. 確認 `Runner.entitlements` 與 `Info.plist` 符合你的簽章目標
5. 在真實 iPhone 上跑既有的 `HealthKit` writer
6. 驗證授權、寫入與 sideload / 分發流程

## CI

本 repo 已包含 `.github/workflows/flutter-ci.yml`。

workflow 目前會：

1. 從 `.fvmrc` 讀取鎖定的 Flutter 版本
2. 在 `ubuntu-latest` 上執行 `flutter pub get`
3. 在 `ubuntu-latest` 上執行 `flutter analyze`
4. 在 `ubuntu-latest` 上執行 `flutter test`
5. 在 `macos-latest` 上執行 `flutter build ios --no-codesign`
