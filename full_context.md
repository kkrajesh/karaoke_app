# Karaoke Night Live - Full Context & Architecture

This document provides a comprehensive technical overview of the Karaoke Night Live application. It is designed to act as a knowledge base if this repository is cloned or migrated to a different machine, or picked up by another developer in the future.

---

## 1. High-Level Architecture

The application is built on a **Server-Host Hybrid Architecture** using Flutter.

Instead of relying on cloud databases like Firebase, the application is **offline-first and local-network driven**. The core concept is that a primary computer (usually a Windows laptop) runs the application natively and acts as the **Host Server**. All other devices (smartphones, tablets, other laptops) connect to this Host over the local Wi-Fi.

### The Host (Native Windows)
1. Runs a `shelf` web server on port `8080`.
2. Serves the static Flutter Web build (`build/web`) to clients.
3. Hosts REST API endpoints for queue management, state synchronization, and YouTube proxying.
4. Uses `media_kit` (VLC/MPV wrapper) to natively extract and play YouTube streams, bypassing YouTube's iframe DRM and web browser limitations ("Video Unavailable").

### The Clients (Web Browsers)
1. Access the application by typing the Host's local IP address (e.g., `http://192.168.1.50:8080`).
2. Run as a Flutter Web SPA (Single Page Application).
3. Poll the Host API to stay synchronized with the currently playing song and queue.
4. Cannot query YouTube directly due to strict browser CORS (Cross-Origin Resource Sharing) policies, so they proxy search queries through the Host API.

---

## 2. Tech Stack & Key Dependencies

* **Framework:** Flutter (Web and Windows Desktop)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Local Networking:** `shelf`, `shelf_router`, `shelf_static`
* **Network Info:** `network_info_plus` (to get the LAN IP address)
* **Native Video Player:** `media_kit`, `media_kit_video`
* **Web Video Player:** `youtube_player_iframe`
* **YouTube Extraction:** `youtube_explode_dart`

---

## 3. The API Routing (`LocalServerService`)

The Host boots up a background `shelf` server upon startup in `HostDashboard`. It defines the following routes:

* `GET /`: Serves the `build/web/index.html` file.
* `GET /queue`: Returns the current list of songs in the queue as JSON.
* `POST /queue`: Allows a web client to add a new song. The server auto-generates a unique `id` for the song.
* `DELETE /queue/<id>`: Removes a song from the queue.
* `POST /play-next`: Advances the queue to the next singer.
* `GET /now-playing`: Returns the currently playing `Song` object.
* `GET /reactions`: Returns the latest 20 audience emoji/comment reactions.
* `POST /reactions`: Posts a new reaction.
* `GET /search?q=...`: Proxies a YouTube search. The Host's native `youtube_explode_dart` instance fetches the data and returns the JSON payload, circumventing browser CORS issues.

---

## 4. State Management (`SessionStateNotifier`)

The global state for the karaoke room is maintained by Riverpod via `SessionStateNotifier`.

* **If running natively (`kIsWeb == false`):** The Notifier acts as the authoritative source of truth. It manages the lists, performs sorting, and applies changes immediately.
* **If running on the web (`kIsWeb == true`):** The Notifier acts as a *follower*. It spins up a `Timer.periodic` polling mechanism that fetches `/queue`, `/now-playing`, and `/reactions` every 2 seconds. When a web user takes an action (like joining the queue), it optimistically updates its local UI and sends a `POST` request to the server.

---

## 5. Media Playback Architecture (`PlayerScreen`)

Because YouTube blocks its videos from playing in IFrames on unknown domains or local IPs, the Web client is fundamentally limited in what it can play. To solve this, the application uses a dual-engine `PlayerScreen`.

```dart
if (kIsWeb) {
  return YoutubePlayer(...); // Uses iframe. Subject to "Video Unavailable" restrictions.
} else {
  return Video(controller: _nativeController); // media_kit
}
```

The native Windows player uses `youtubeServiceProvider.getVideoStreamUrl()` to extract the raw `.mp4` stream directly from YouTube's servers, completely bypassing the browser. 

**The Public Display Rule:** 
Because of this, the "Stage TV" (where the lyrics actually play) should **always** be driven by the Native Windows app. You open a *second instance* of the `.exe` on the host laptop, drag it to the TV HDMI output, and select the **Public Display** role. 

---

## 6. Build & Deployment Lifecycle

If you make *any* changes to the UI, logic, or dependencies of the Flutter application, you **must** rebuild the web client so the Host can serve the updated static files.

**Build Workflow:**
1. Code your changes.
2. Run `flutter build web` to compile the JS/Wasm bundles into the `build/web` directory.
3. Run `flutter run -d windows` (or build a release `.exe`) to start the host.
4. Clients connecting via IP will now receive the newly compiled application.
