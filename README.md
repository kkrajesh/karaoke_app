# Karaoke Night Live

A robust, offline-first, local-network karaoke application built with Flutter. 

Turn any Windows computer into a central Karaoke Host, and allow anyone on your local Wi-Fi network to browse songs, join the queue, and send live reactions from their smartphones—without needing to install any app.

## Features

* **No Installation for Guests:** The Host app automatically spins up a local web server and serves the Flutter Web build to any device on the network.
* **Dual Video Engine:** 
  * Natively powered by `media_kit` (C++) on Windows for flawless YouTube stream extraction without browser embedding restrictions.
  * Powered by `youtube_player_iframe` on the web.
* **Local Network API:** Queue management, current playing status, live audience reactions, and YouTube search proxying are all handled by the local server over HTTP.
* **CORS Proxy:** Built-in proxy using `youtube_explode_dart` allows web clients to search YouTube directly through the host, avoiding browser CORS blocks.
* **Local MediaMonkey DB Integration:** Direct integration with MediaMonkey SQLite databases (`MM.DB`) allows searching and playing locally stored MP4/Opus/MKV files directly from the hard drive, seamlessly merged with YouTube results.
* **Automated Performance Logging:** Integrates with Google Sheets to automatically push performance logs (singer name, song title, URL, source, and emoji reaction aggregations) via a Webhook URL configured in the Host settings.
* **Android Client Support:** Compiles into a standalone Android APK, so dedicated tablets can connect to the host without relying on web browser video limitations.
* **Roles:**
  * **Host:** Manages the queue, plays the next song, manages the library, and controls the room.
  * **Singer:** Browses songs, selects from local or YouTube libraries, and joins the queue.
  * **Audience:** Watches the currently playing song and sends live emoji reactions to the screen.
  * **Public Display:** A TV-optimized full-screen stage mode for the current singer, complete with a live-streaming chat overlay for audience reactions.

## Roadmap
* [x] Local library management
    * [x] File based library 
    * [x] MediaMonkey integration
* [ ] Smule integration (Temporarily blocked by Cloudflare, pending headless browser scraper)
* [x] Queue management - reorder singer, remove singer, approve requests
* [x] Display logo, song title, singer name (Audience View)
* [x] AI Teleprompter to help prepare intro message for each singer and song
* [x] AI to generate song trivia and fun facts for current song
* [x] Audience can select songs from library as a request (Host will review and add to queue). 
    * [x] Ability to nudge request to up or down the queue. 
    * [x] Ability to delete requests. 
    * [x] Ability to add a note to a request. 
* [x] Host should be able to add songs to the queue from library or YouTube or Smule for a specific singer
* [x] Ability to add songs to library or YouTube or Smule from the Queue
* [x] Host Controls - Push a count down timer/warning to the public display.
* [x] Host Controls - Push a message to the public display and audience display and chat.
* [x] Host Controls - Push a reminder message about where to find song requests and request songs.
* [x] Host Controls - Push messages about food and drinks, restrooms, etc on public display and audience display
* [x] Host Controls - Push messages about upcoming events, etc on public display and audience display
* [x] Public Display (TV) - display a queue of upcoming songs and singers, in between performances
  * [x] Public Display (TV) - display promotional messages/videos/slideshows in between performances
* [x] Public display - play the karaoke video in a separate frame and have side/bottom areas for additional message. Optimized for TV with real estate for the video, announcements, and up-next queue.
* [x] Emoji Reactions Counting & Aggregation - display live counts of distinct emojis sent by audience.
* [x] Windows Native Player Transitions - Deterministic `UniqueKey` synchronization to guarantee teardown and remount without relying on unreliable reactive listeners.
* [x] **Automated Google Sheets Logging**: Upsert performance metadata and audience reaction aggregations via Webhook.
* [x] **Dynamic App Settings UI**: Add a settings menu on the Host dashboard to select the `MM.DB` file path dynamically and configure Google Sheets integrations.
* [x] **Host Dashboard Redesign**: Fully responsive 3-column single-page layout featuring fullscreen expandable cards and live reaction overlays on the video player.
* [x] **Grid View & Multi-Window Optimization**: All dashboards (Host, Singer, Audience, Public Display) are fully responsive and compacted for tiled multi-window viewing. Includes dynamic Event Name syncing across all screens and an unconditionally available Refresh Video button on the public display.
* [ ] **Custom Emoji Support**: Allow users to upload or select custom emojis for the reaction pad.
* [ ] **Post-Performance Word Clouds**: Aggregate text comments into a visual word cloud after each singer's performance.
* [x] **Google Sheets YouTube Links**: When adding the youtube songs to the google sheet, prefix it with 'https://www.youtube.com/watch?v=' to make it a ready to access youtube link.
* [x] **Song Library Previews**: Songs now preview in a compact modal with options to expand to fullscreen or launch directly in the host's native web browser.
* [x] **Host Timer Controls**: 1, 3, 5, and Custom minute countdown timers can be pushed to all displays alongside a custom text message, with an automatic 30-second cleanup.
* [x] **Duet Support**: Singers can add an optional duet partner. Hosts can edit or instantly swap primary and secondary singers from the queue controls.
* [x] **Flipped Dashboards & Multi-Window Mode**: Host can peek at other dashboards (Singer, Audience, Public Display) via in-app fullscreen modals, or pop them out into independent native browser windows with auto-login URL routing.
* [x] **Streamlined Sign-In**: Combined role selection and login into single-action buttons with automated web QR code host IP resolution.
* [x] **Advanced Singer Registration**: Enforce collection of phone, email, or Instagram handle for singers, while offering smart bypasses for hosts and audience members.


## Getting Started

### Prerequisites
* Flutter SDK (with Web and Windows support enabled)
* A Windows machine (to run the Host application)

### Initial Setup

1. **Build the Web Client**
   Because the Windows app serves the Web application from its `build/web` directory, you must compile the web client first!
   ```bash
   flutter build web
   ```

2. **Run the Host on Windows**
   ```bash
   flutter run -d windows
   ```
   *Note: Ensure your Windows Firewall allows the app to communicate on port 8080.*

### How to Use

1. The Windows Host will display an IP address (e.g., `http://192.168.1.50:8080`).
2. Have your friends connect to that IP address on their smartphones via Chrome/Safari.
3. If connecting a Venue TV, open a *second instance* of the Windows application, select the **Public Display** role, and drag it to the TV monitor via HDMI.

## Project Architecture
For a deep dive into the network architecture, proxy system, and state management, see the [Full Context Documentation](full_context.md).
