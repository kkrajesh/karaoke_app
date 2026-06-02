# Karaoke Night Live (Host App)

The core public-facing application for the Karaoke Ecosystem. It serves as the DJ/Host dashboard, allowing the user to manage the active song queue, stream high-quality audio/video from YouTube or local files, and display a public Karaoke screen.

## 🚀 Release Notes (v2.7.1)
- **Remote Local-Media Search**: Fixed network routing bugs where remote clients (Web/Android) incorrectly polled their own `localhost` for local media DB lookups. They now intelligently route API queries dynamically to the Host PC.
- **Web App Parity**: Ensured `kIsWeb` guards were put in place to avoid `Unsupported operation: _Namespace` sandbox crashes caused by `dart:io` when rendering search results in the browser.

## 🚀 Release Notes (v2.7.0)
- **FastAPI Migration**: Completely integrated with the new `karaoke_orchestrator.py` server, allowing WebSockets-based AI Queue management directly from the Host App dashboard.
- **Improved Reprocessing**: Enhanced Library menu to natively support "Force Full Reprocess" and "Re-download Audio" actions seamlessly through `vox_player_core`.
- **Bug Fixes**: Resolved internal payload syncing issues resulting in failed Audio fetches for Library components.

## 🚀 Release Notes (v2.6.1)
- **Settings & Dashboard Integration**: Inherited `vox_player_core` upgrades, exposing the new "Services" tab within the unified settings screen.
- **Backend Service Monitoring**: Hosts can now natively monitor the health of `api_server.py` and `queue_watcher.py` (with heartbeat detection) directly from the app.
- **AI Queue**: Enhanced log reviewing capabilities in the AI queue manager, featuring real-time terminal-style logging with timestamps.

## 🚀 Release Notes (v2.6.0)
- **Host Dashboard UI Redesign**: Transitioned to a clean, highly efficient two-column layout. Eliminated intermediate menus for a smoother Host experience.
- **Interactive Hover Menus**: Replaced standard Wifi Tooltips with a custom Interactive Hover Overlay, displaying Live Server status, QR code, and a one-click copyable IP address.
- **Media Playback Fixes**: Resolved local media playback issues by properly classifying alternative sources (like MediaMonkey) to use the native player.
- **UX Improvements**: Fixed "Add to Queue" closing bug from the Song Library and resolved dialog overflow layout issues.

## 🚀 Release Notes (v2.5.1)
- Synced `VoxPlayerCore` v0.3.0 core library which fixes massive lifecycle teardown issues and the dual-playback bug for Android instances.
- Exposed powerful `LyricAgent` bi-directional script capabilities within the player ecosystem.
- Enabled queue syncing and AI file reprocessing under the hood via the shared framework updates.

## 🚀 Release Notes (v2.5.0)
- Fully supported Background Audio Playback on Android devices via `vox_player_core`.
- Huge UI Improvements for Host Screen, including single page layout, re-orderable upcoming songs, and quick dashboard flips.
- AI Features: Teleprompter for host intros and AI generated song trivia.
- Updated Starting Pages with QR code connect functionality and separate attendee workflows.
- Improved Song Library previews and browser support.
- Fixed public display updates and trackpad scrolling issues.

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

## 🕹 Unified Startup Sequence
To run the full ecosystem (Backend Services + Flutter Apps):

**1. Start the Orchestrator API Server**
```bash
cd ../Karaoke_Maker/core_engine
python karaoke_orchestrator.py
```

**3. Start the Host App**
```bash
flutter run -d windows
```

*Pro Tip: You can now monitor and start these Python backend services directly from the Settings > Services dashboard in the Flutter apps!*
