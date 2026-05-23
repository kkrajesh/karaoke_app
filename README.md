# Karaoke Night Live (Host App)

The core public-facing application for the Karaoke Ecosystem. It serves as the DJ/Host dashboard, allowing the user to manage the active song queue, stream high-quality audio/video from YouTube or local files, and display a public Karaoke screen.

## 🚀 Current State
- **Stable**: Robust media playback using `media_kit` (for local files) and `youtube_player_iframe` (for YouTube URLs).
- **Stable**: Queue management and local state persistence.
- **In Transition**: The internal media player logic is being stripped out and replaced with the new universal `vox_player_core` package.

## 🛠 Tech Stack
- **Frontend**: Flutter, Dart, Riverpod.
- **Playback**: media_kit, youtube_player_iframe, video_player.
- **Data**: shared_preferences, http (for backend integrations).

## 🐛 Known Gaps/Bugs
- **Search capabilities**: Uses unified `vox_player_core` search. We are currently transitioning away from `es.exe` entirely in favor of a unified MediaMonkey database search (Phase 9 ongoing).
- **Practice Tools Missing**: Practice tools are available via the `practice_app`. The core player is now migrated to `vox_player_core`.

## 📦 Install Instructions
1. Clone the repository.
2. Run Flutter pub get: `flutter pub get`

## 🕹 Usage Instructions
1. Start the application: `flutter run -d windows`
2. Search for a YouTube song or select a local file to add it to the queue.
3. Click play to launch the public video overlay.
