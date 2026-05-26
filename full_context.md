# Karaoke Night Live - Full Context

## Overview
The Host Application of the Karaoke Ecosystem. It is built to seamlessly manage a live karaoke party. The app handles fetching YouTube videos, handling local MP4s/MP3s, and maintaining a robust playback queue.

## Architecture
- **State Management**: Heavily utilizes `flutter_riverpod` for state management, decoupling UI from queue logic and player state.
- **Player Screen (`player_screen.dart`)**: A highly complex widget that dynamically switches between `YoutubePlayerIframe` (for web streams) and `media_kit` (for native windows accelerated decoding).
- **Local Media Server**: Includes a lightweight HTTP server to stream local files to web-based sub-views if necessary.

## Current Migration Phase
We have completed **Phase 9** of the ecosystem master plan regarding this app. The `vox_player_core` package is fully integrated, replacing the internal custom players with a unified, cross-platform media engine that supports intelligent dual-pane `.lrc` lyrics, pitch tracking, and SQLite AI Tracking.

## Ecosystem Role
The "Consumer". It securely reads the local `MM.DB` (MediaMonkey) and `vox_ai_metadata.db` to deliver a premium singing experience to the end-users, natively tracking AI artifacts like Vocals, Pitch Data, and Lyrics.
