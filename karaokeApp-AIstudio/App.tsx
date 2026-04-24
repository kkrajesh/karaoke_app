
import React, { useReducer, useMemo } from 'react';
import { AppState, AppAction, Role, Song, QueueItem, SongRequest, Comment, PerformanceLog } from './types';
import { INITIAL_SONGS } from './constants';
import RoleSelector from './components/RoleSelector';
import KaraokeUI from './components/KaraokeUI';
import ApiKeyBanner from './components/ApiKeyBanner';

const initialState: AppState = {
  role: null,
  library: INITIAL_SONGS,
  queue: [],
  nowPlaying: null,
  performanceStartTime: null,
  history: [],
  requests: [],
  reactions: [],
  comments: [],
};

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_ROLE':
      return { ...state, role: action.payload };
    case 'ADD_SONG_TO_LIBRARY':
      // Prevent duplicates based on identifier
      if (state.library.some(song => song.identifier === action.payload.identifier && song.source === action.payload.source)) {
          return state;
      }
      return { ...state, library: [...state.library, action.payload] };
    case 'ADD_SONGS_TO_LIBRARY': {
        const newSongs = action.payload.filter(newSong => 
            !state.library.some(existingSong => 
                existingSong.identifier === newSong.identifier && existingSong.source === newSong.source
            )
        );
        return { ...state, library: [...state.library, ...newSongs] };
    }
    case 'UPDATE_SONG_IN_LIBRARY':
      return {
        ...state,
        library: state.library.map(song =>
          song.id === action.payload.id ? action.payload : song
        ),
      };
    case 'DELETE_SONG_FROM_LIBRARY':
      return {
        ...state,
        library: state.library.filter(song => song.id !== action.payload),
      };
    case 'SIGN_UP': {
      const newQueueItem: QueueItem = {
        id: new Date().toISOString(),
        singerName: action.payload.singerName,
        song: action.payload.song,
      };
      return { ...state, queue: [...state.queue, newQueueItem] };
    }
    case 'SET_NOW_PLAYING': {
      let newHistory = state.history;
      
      // If there was a song playing, add it to history before starting the new one
      if (state.nowPlaying) {
          const historyItem: PerformanceLog = {
              id: Date.now().toString(),
              singerName: state.nowPlaying.singerName,
              songTitle: state.nowPlaying.song.title,
              artist: state.nowPlaying.song.artist,
              timestamp: Date.now() // Captures when the song finished/was skipped
          };
          newHistory = [historyItem, ...state.history];
      }

      return { 
          ...state, 
          history: newHistory,
          nowPlaying: action.payload,
          performanceStartTime: action.payload ? Date.now() : null
      };
    }
    case 'STOP_PERFORMANCE': {
        let newHistory = state.history;
        if (state.nowPlaying) {
            const historyItem: PerformanceLog = {
                id: Date.now().toString(),
                singerName: state.nowPlaying.singerName,
                songTitle: state.nowPlaying.song.title,
                artist: state.nowPlaying.song.artist,
                timestamp: Date.now()
            };
            newHistory = [historyItem, ...state.history];
        }
        return {
            ...state,
            history: newHistory,
            nowPlaying: null,
            performanceStartTime: null
        };
    }
    case 'REMOVE_FROM_QUEUE':
      return { ...state, queue: state.queue.filter(item => item.id !== action.payload) };
    case 'MOVE_QUEUE_ITEM': {
      const { fromIndex, toIndex } = action.payload;
      if (fromIndex < 0 || fromIndex >= state.queue.length || toIndex < 0 || toIndex >= state.queue.length) {
        return state;
      }
      const newQueue = [...state.queue];
      const [movedItem] = newQueue.splice(fromIndex, 1);
      newQueue.splice(toIndex, 0, movedItem);
      return { ...state, queue: newQueue };
    }
    case 'ADD_REQUEST': {
        const newRequest: SongRequest = { ...action.payload, id: new Date().toISOString() };
        return {...state, requests: [...state.requests, newRequest] };
    }
    case 'ADD_REACTION': {
        const newReaction = { id: new Date().toISOString(), emoji: action.payload };
        const updatedReactions = [newReaction, ...state.reactions].slice(0, 50); // Keep last 50
        return { ...state, reactions: updatedReactions };
    }
    case 'ADD_COMMENT': {
        const newComment: Comment = { ...action.payload, id: new Date().toISOString() };
        const updatedComments = [...state.comments, newComment].slice(-50); // Keep last 50
        return { ...state, comments: updatedComments };
    }
    case 'CLEAR_INTERACTIONS':
        return {...state, reactions: [], comments: [] };
    default:
      return state;
  }
}

function App() {
  const [state, dispatch] = useReducer(appReducer, initialState);

  const memoizedDispatch = useMemo(() => dispatch, []);

  return (
    <div className="min-h-screen bg-gray-900 text-white p-4 sm:p-6 md:p-8">
      <div className="max-w-7xl mx-auto">
        <header className="text-center mb-8">
          <h1 className="text-4xl sm:text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-600">
            Karaoke Night Live
          </h1>
          <p className="text-gray-400 mt-2">Your ultimate karaoke party companion</p>
        </header>
        
        <main>
          <ApiKeyBanner />
          {!state.role ? (
            <RoleSelector onSelectRole={(role) => memoizedDispatch({ type: 'SET_ROLE', payload: role })} />
          ) : (
            <KaraokeUI state={state} dispatch={memoizedDispatch} />
          )}
        </main>
      </div>
    </div>
  );
}

export default App;
