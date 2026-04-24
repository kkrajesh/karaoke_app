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
* **Roles:**
  * **Host:** Manages the queue, plays the next song, manages the library, and controls the room.
  * **Singer:** Browses songs, selects from local or YouTube libraries, and joins the queue.
  * **Audience:** Watches the currently playing song and sends live emoji reactions to the screen.
  * **Public Display:** A TV-optimized full-screen stage mode for the current singer, complete with a live-streaming chat overlay for audience reactions.

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
