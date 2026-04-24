# Karaoke Night Live 🎤

An all-in-one web application for hosting and participating in karaoke events. Built with React, Vite, and powered by Gemini AI.

## 🌟 Features

- **Multi-Role Interaction**: Choose your role as **Host**, **Singer**, or **Audience member**.
- **Smart Song Library**:
  - Integrated **YouTube Search** for finding karaoke versions instantly.
  - Support for **MediaMonkey** database (MM.DB) imports.
  - Support for **Smule** and **Local Files**.
  - Manual song entry.
- **AI-Powered Suggestions**: Get creative song ideas using Gemini AI based on your mood or theme (e.g., "80s power ballads").
- **Dynamic Queue Management**: Sign up for songs, reorder the queue, and track what's playing.
- **Audience Engagement**:
  - Send real-time emoji reactions.
  - Participate in the live chat/comments.
  - Request songs for specific singers.
- **Performance Tools**:
  - Built-in YouTube player with preview mode.
  - Performance timer and history log.
  - Library management (rating, editing, and deleting songs).
- **PWA Ready**: Offline support with a service worker.

## 🛠️ Technology Stack

- **Frontend**: React 19, TypeScript, Tailwind CSS.
- **AI**: Google Gemini API (`@google/genai`).
- **Build Tool**: Vite.
- **External Libraries**: 
  - `SQL.js` (for MediaMonkey DB parsing - loaded via CDN).
  - Web Audio/Video APIs for local playback.

## 🚀 Local Development Setup

To run this project locally on your laptop:

### 1. Prerequisites
- **Node.js**: v18 or higher recommended.
- **npm** or **yarn**.

### 2. Installation
```bash
# Clone the repository (or download the files)
cd karaoke-night-live

# Install dependencies
npm install
```

### 3. Environment Variables
Create a `.env` file in the root directory (based on `.env.example`):
```env
VITE_GEMINI_API_KEY=your_google_gemini_api_key_here
```
*Note: The app requires a Gemini API key for song suggestions and YouTube search features.*

### 4. Run the App
```bash
npm run dev
```
The application will be available at `http://localhost:3000`.

## 📁 Project Structure

- `src/App.tsx`: Central state management and routing logic.
- `src/components/`:
  - `KaraokeUI.tsx`: The main interface containing Host, Singer, and Audience views.
  - `RoleSelector.tsx`: Initial screen to choose a participant role.
  - `ApiKeyBanner.tsx`: Helper to warn users if the API key is missing.
- `src/services/`:
  - `geminiService.ts`: AI suggestion logic and YouTube Data API interaction.
- `src/types.ts`: Shared TypeScript interfaces and enums.
- `src/constants.tsx`: Initial song library, icons, and configuration values.

## 📝 Important Notes

- **MediaMonkey Import**: This feature requires the `sql.js` WASM file. It is currently configured to load from `cdnjs`. If you are working offline, you may need to host these files locally.
- **YouTube Embedding**: Some videos might not play if the owner has disabled embedding. The app provides a fallback link to watch directly on YouTube.
- **Service Worker**: The app includes a `sw.js` for offline caching. In dev mode, you might want to disable it in Browser DevTools if you encounter caching issues during development.

## 🔮 Future Enhancements (Ideas)
- Firebase integration for true multi-device real-time sync.
- Singer profiles and "top performers" leaderboard.
- Song lyrical display integration.
