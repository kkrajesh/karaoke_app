# Copilot instructions for karaoke_app

This file gives focused, repo-specific guidance to AI coding agents working on this Flutter app.

## Quick summary
- Purpose: mobile/desktop/web Flutter app for playing karaoke (YouTube + local video). Entry: [lib/main.dart](lib/main.dart).
- Key deps: [pubspec.yaml](pubspec.yaml) declares `youtube_player_iframe`, `video_player`, and `shared_preferences`.

## Big picture
- Single Flutter app with platform runners in `android/`, `ios/`, `windows/`, `macos/`, `linux/`.
- UI and app logic live under `lib/` (start at [lib/main.dart](lib/main.dart)).
- Native integration and platform-specific settings live in the corresponding `*/Runner` or `app/` folders (e.g., [ios/Runner/Info.plist](ios/Runner/Info.plist), [android/app/build.gradle.kts](android/app/build.gradle.kts)).
- Data flow: playback sources come from YouTube iframe and local video plugin; queue persistence intended via `shared_preferences` (see `pubspec.yaml`).

## Build / run / debug workflows (practical commands)
- Install deps and analyze:

```bash
flutter pub get
flutter pub outdated   # see available upgrades
```

- Run on desktop (Windows):

```powershell
flutter run -d windows
```

- Run on Android (Gradle Kotlin DSL used):

```bash
flutter run -d android
cd android && ./gradlew assembleDebug
```

- Run tests and CI checks:

```bash
flutter test
flutter analyze
```

- Hot reload / restart during `flutter run`: press `r` (hot reload) or `R` (hot restart).

Notes: iOS builds require macOS + Xcode. Android Gradle files use Kotlin DSL (`*.kts`) — edit with care.

## Project-specific conventions and patterns
- Lints: `flutter_lints` is enabled (see `analysis_options.yaml`). Follow existing lint rules when editing Dart files.
- Native edits: modify Kotlin/Gradle in `android/` (Kotlin DSL), Swift/ObjC in `ios/Runner/` and native runner code in `windows/runner/`.
- Dependencies in `pubspec.yaml` are authoritative; add new packages there and run `flutter pub get`.
- Persistence: local queue should use `shared_preferences` (see dependency). If adding richer storage, document it in `pubspec.yaml` and `README.md`.

## Integration and cross-component notes
- YouTube playback will use `youtube_player_iframe` (web/embedded iframe), while `video_player` covers local file playback — prefer existing deps rather than swapping libraries.
- Platform channels: if native features are required, add platform-specific code under `android/` or `ios/` and expose via Dart platform channels or platform-specific plugins.
- When changing build scripts, remember Kotlin DSL syntax in files like [android/build.gradle.kts](android/build.gradle.kts) and [android/app/build.gradle.kts](android/app/build.gradle.kts).

## Files to inspect for context/examples
- App entry and UI: [lib/main.dart](lib/main.dart)
- Dependencies: [pubspec.yaml](pubspec.yaml)
- Lints & static analysis: [analysis_options.yaml](analysis_options.yaml)
- Android build: [android/app/build.gradle.kts](android/app/build.gradle.kts)
- iOS runner: [ios/Runner/Info.plist](ios/Runner/Info.plist)
- Tests: [test/widget_test.dart](test/widget_test.dart)

## What AI agents should do first (concrete checklist)
1. Run `flutter pub get` and `flutter analyze` locally to surface issues.
2. Open [lib/main.dart](lib/main.dart) to find the app start point for UI changes.
3. Search for usages of `youtube_player_iframe`, `video_player`, and `shared_preferences` before making changes to playback/queue logic.
4. When modifying Android/iOS build files, run platform-specific build commands to validate (see 'Build / run' above).

## Known unknowns and follow-ups
- The repository currently has a minimal `README.md` and no dedicated `lib/features` layout; when adding features, document new module locations in this file.
- If you need to introduce native permissions (camera/microphone/storage), update platform manifests (Android `AndroidManifest.xml`, iOS `Info.plist`) and note the change here.

If any section is unclear or you want more examples (e.g., where to add a YouTube player widget), tell me which area to expand and I will iterate.
