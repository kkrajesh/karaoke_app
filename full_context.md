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

### The Clients (Web Browsers or Native Android/Windows apps)
1. Access the application by typing the Host's local IP address (e.g., `http://192.168.1.50:8080`) in a browser, or by launching the Native APK and entering the Host IP.
2. If using the browser, run as a Flutter Web SPA (Single Page Application). If using the APK, run natively.
3. Poll the Host API to stay synchronized with the currently playing song and queue.
4. Cannot query YouTube directly from the Web due to strict browser CORS policies, so they proxy search queries through the Host API.
5. Stream local media (`.mp4`, `.opus`) from the host via the `/local-media` HTTP endpoint.

---

## 2. Tech Stack & Key Dependencies

* **Framework:** Flutter (Web, Android, and Windows Desktop)
* **State Management:** Riverpod (`flutter_riverpod` 3.x with `NotifierProvider`)
* **Local Networking:** `shelf`, `shelf_router`, `shelf_static`
* **Network Info:** `network_info_plus` (to get the LAN IP address)
* **Native Video Player:** `media_kit`, `media_kit_video`
* **Web Video Player:** `youtube_player_iframe`, `video_player` (for local media)
* **YouTube Extraction:** `youtube_explode_dart`
* **Local Media Database:** `sqflite_common_ffi` (used to query the MediaMonkey `MM.DB`)

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
* `GET /display-state`: Returns the current event name, announcement, and countdown timer.
* `POST /display-state/announcement` & `POST /display-state/countdown`: Allows the Host to push state to the public and audience displays. The countdown timer includes an automatic 30-second native cleanup mechanism within `SessionStateNotifier` that resets the clock and clears the message across all connected screens globally.
* `GET /search?q=...`: Proxies a YouTube search or queries the local `MM.DB`. The Host's native instances fetch the data and return the JSON payload, circumventing browser CORS issues and avoiding exposing the local database directly.
* `GET /local-media?path=...`: Streams a physical media file (e.g., `.mp4`, `.mkv`) from the host's hard drive to web clients using `dart:io` chunked streaming.

---

## 4. AI Teleprompter Service (`AiService`)

The Host includes an integrated AI Teleprompter (`AiService`) to generate live facts and introductory scripts for the host.
This is implemented as an **Ahead-of-Time (AOT)** pipeline:
1. **Background Processing**: `SessionStateNotifier` runs a background task that watches the queue. When it detects songs in the top 3 spots without AI trivia, it initiates background generation.
2. **Key-less Web Scraping**: The service cleans the song title via the local LLM, then silently scrapes Wikipedia REST API and DuckDuckGo HTML search for real-world context without requiring paid API keys.
3. **Local LLM Generation**: The scraped context is fed into a local, user-configured LLM (e.g., LM Studio at `http://localhost:1234` or Ollama) to generate a full Markdown table, scene context, and a punchy 2-sentence Host Intro.
4. **UI Integration**: The Host can view the generated Markdown ahead of time via a dialog in the queue list, provide fine-tuning prompts to regenerate it, and ultimately read the perfectly-formatted `flutter_markdown` result on the teleprompter when the song begins.

---

## 5. State Management (`SessionStateNotifier`)

The global state for the karaoke room is maintained by Riverpod via `SessionStateNotifier`.

* **If running natively (`kIsWeb == false`):** The Notifier acts as the authoritative source of truth. It manages the lists, performs sorting, and applies changes immediately.
* **If running on the web (`kIsWeb == true`):** The Notifier acts as a *follower*. It spins up a `Timer.periodic` polling mechanism that fetches `/queue`, `/now-playing`, and `/reactions` every 2 seconds. When a web user takes an action (like joining the queue), it optimistically updates its local UI and sends a `POST` request to the server.

---

## 6. Media Playback Architecture (`PlayerScreen`)

Because YouTube blocks its videos from playing in IFrames on unknown domains or local IPs, the Web client is fundamentally limited in what it can play. To solve this, the application uses a dual-engine `PlayerScreen`.

```dart
if (kIsWeb) {
  return YoutubePlayer(...); // Uses iframe. Subject to "Video Unavailable" restrictions.
} else {
  return Video(controller: _nativeController); // media_kit
}
```

The native Windows/Android player uses `youtubeServiceProvider.getVideoStreamUrl()` to extract the raw `.mp4` stream directly from YouTube's servers, completely bypassing the browser. For local files (e.g., MediaMonkey library paths), it plays the `file:///` URI directly from the disk.

**The Public Display Rule:** 
Because of this, the "Stage TV" (where the lyrics actually play) should **always** be driven by the Native Windows/Android app. You open a *second instance* of the native app on the host laptop (or TV box), drag it to the TV HDMI output, and select the **Public Display** role. 
The Public Display logic utilizes a brief 600ms `null` reset during queue transitions initiated by the host. To ensure perfectly reliable video transitions and prevent native Windows `media_kit` crashes, the Public Display uses a deterministic `UniqueKey` swap combined with an asynchronous `Player.dispose()` delay. This guarantees Flutter safely tears down the underlying Direct3D hardware texture and builds a fresh player for the new song without race conditions. Additionally, local disk paths are dynamically stripped of backslashes (`\`) and converted to forward slashes (`/`) so the `libmpv` C++ backend can successfully parse them without escape-character corruption.

---

## 7. Build & Deployment Lifecycle

If you make *any* changes to the UI, logic, or dependencies of the Flutter application, you **must** rebuild the web client so the Host can serve the updated static files.

**Build Workflow:**
1. Code your changes.
2. Run `flutter build web` to compile the JS/Wasm bundles into the `build/web` directory.
3. Run `flutter run -d windows` (or build a release `.exe`) to start the host. Wait for the shelf server to boot up.
4. Clients connecting via IP will now receive the newly compiled application.

---

## 8. App Settings & Performance Logging

The application uses `SharedPreferences` to persist Host configuration via `SettingsNotifier`. This avoids hardcoding paths and secrets into the source code, allowing the host to dynamically configure the system from the dashboard.
* **Google Sheets Webhook:** An integration (`GoogleSheetsService`) that automatically pushes structured JSON payloads containing the song title, singer, URL, source type, and an aggregated count of audience emoji reactions (e.g., `🔥x5, 👏x3`) when a song finishes or the Host presses "Start Next Singer".
* **MediaMonkey DB Path:** The path to the local SQLite database used for querying and streaming file-based karaoke tracks.

---

## 9. User Interface & Responsive Layout

The **Host Dashboard** is designed to act as a centralized control room, specifically optimized for desktop or tablet screens. 
* **Responsive Layout:** On larger screens, the dashboard transitions into a 3-column single-page layout that eliminates the need for vertical page scrolling. Lists like the Queue and Song Library internally scroll within fixed flex constraints.
* **Multi-Window & Grid Optimizations:** The entire suite of dashboards (Singer, Audience, Host, Public Display) heavily utilizes `LayoutBuilder` to intelligently adapt to limited viewports (e.g., when tiling multiple windows on a single monitor). Text truncates gracefully, columns collapse into single stacks, and non-essential titles are dynamically hidden on the Public Display to conserve space.
* **Dynamic Event Branding:** The Event Name is configured in the Host's `SharedPreferences` and broadcast via the `/display-state` API endpoint so all remote web clients dynamically update their AppBar titles to match the event.
* **Expandable Cards:** Because screen real estate is critical, almost all sections (Singer Queue, Song Requests, Song Library, Settings, etc.) feature an "Expand" button in their headers. Clicking this opens a large, responsive modal overlay using Riverpod `Consumer` widgets to remain perfectly in sync with live data while providing maximum working area.
* **Live Reaction Overlays:** Rather than taking up sidebar space, audience emojis and text reactions overlay beautifully on top of the "Now Playing" video player. Text reactions dynamically overlap like a hand of playing cards to conserve horizontal space.
* **Compact Previews & URL Launching:** The Song Library implements compact popup modals for song previews with the ability to instantly expand to fullscreen. Additionally, leveraging `url_launcher`, hosts can seamlessly punt non-local streams (like YouTube or Smule URLs) directly into their native desktop web browser for advanced interaction outside of the Flutter application.

---

## 10. Smule Integration Status & Future Roadmap

The application has foundational components prepared for integrating Smule performances (e.g. `SmuleService`, `GoogleSheetsService` URL logging, and `.mp4` stream resolution in `PlayerScreen`). However, active UI elements for Smule searching have been temporarily disabled.

**The Blocker:** Smule has implemented aggressive Cloudflare Bot Management across their entire domain. Any standard HTTP requests (including `http.get` in Dart or raw `curl` commands) are immediately intercepted by a Cloudflare Javascript challenge (`window.__CF$cv$params`), completely blocking the scraper from extracting search results or media stream tags.

**Future Implementation (Option 3):** When the decision is made to re-activate Smule, the standard HTTP proxy endpoints in `LocalServerService` must be replaced with a headless browser approach. This will require running a background Chrome instance (e.g. using a Node.js `puppeteer-extra-plugin-stealth` script or Python `undetected-chromedriver` proxy) alongside the Dart server to seamlessly solve the JS challenges, scrape the DOM, and pass the pristine `.mp4` URLs back to the Flutter frontend.

---

## 11. Duet Support

The karaoke data model supports duet performances natively.
* **Song Model:** A nullable `duetSingerName` property is tracked alongside `requestedByName`. The UI exclusively binds to a dynamic `displaySingerName` getter, which seamlessly formats strings as `"Primary & Secondary"` if a duet partner is assigned, ensuring all displays (Public TV, Host, Audience) render correctly without UI layer conditionals.
* **State Management:** `SessionStateNotifier` includes specific `swapDuetSingers` (instantly inverting primary/secondary) and `editSongSingers` controls, directly accessible from the Host Dashboard queue list.

---

## 12. Flipped Dashboards & Multi-Window Mode

Because Flutter Desktop lacks robust native multi-window support without heavy C++ plugins, the application uses a dual-approach to allow the Host to view other dashboards (Singer, Audience, Public Display) concurrently:
1. **Modal Peeking (In-App):** The Host Dashboard AppBar contains a "Flip Dashboard" dropdown. Selecting a dashboard renders it locally inside a `Dialog.fullscreen()`. This overlay uses a `Stack` to position a floating "Return to Host" button in the corner, allowing the host to quickly peek at other views without losing their `Host` session role.
2. **Pop-Out (Browser Native Windows):** From the same dropdown, the host can launch dashboards in a separate window via `url_launcher`. This relies on the system's default Web Browser to act as the multi-window manager. The Flutter application uses `Uri.base.queryParameters['role']` inside `HomeScreen` to intercept auto-login queries (e.g., `http://localhost:8080/?role=singer`). The browser automatically skips the auth screen and logs directly into the requested view.
