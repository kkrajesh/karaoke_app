# Karaoke Night Live (Host App)

The core public-facing application for the Karaoke Ecosystem. It serves as the DJ/Host dashboard, allowing the user to manage the active song queue, stream high-quality audio/video from YouTube or local files, and display a public Karaoke screen.

## 🚀 Current State
- **Stable**: Robust media playback using the newly integrated `vox_player_core` engine.
- **Stable**: Natively integrates SQLite tracking for AI Artifacts via `VoxAiTrackingService`.
- **Stable**: Queue management and local state persistence.

## 🛠 Tech Stack
- **Frontend**: Flutter, Dart, Riverpod.
- **Playback**: `vox_player_core` (media_kit, youtube_player_iframe, audioplayers).
- **Data**: shared_preferences, sqflite_common_ffi (MediaMonkey DB tracking).

## 🐛 Known Gaps/Bugs
- **Search capabilities**: Fully transitioned away from `es.exe` in favor of unified `MediaMonkeySearchProvider`. Currently monitoring performance with massive databases.

## 📦 Install Instructions
1. Clone the repository.
2. Run Flutter pub get: `flutter pub get`

## 🕹 Usage Instructions
1. Start the application: `flutter run -d windows`
2. Search for a YouTube song or select a local file to add it to the queue.
3. Click play to launch the public video overlay.
