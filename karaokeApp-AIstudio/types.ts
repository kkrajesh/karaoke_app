
// FIX: Removed circular import of 'Role'. A file cannot import a type from itself. This was causing a conflict with the local `Role` enum declaration.
export enum Role {
  HOST = 'Host',
  SINGER = 'Singer',
  AUDIENCE = 'Audience'
}

export enum SongSource {
  LOCAL = 'Local',
  YOUTUBE = 'YouTube',
  SMULE = 'Smule',
  MEDIAMONKEY = 'MediaMonkey'
}

export interface Song {
  id: string;
  title: string;
  artist: string;
  source: SongSource;
  identifier: string; // YouTube ID, Smule URL, or local file object URL. For MediaMonkey, this is the File Path.
  duration: string;
  rating?: number;
}

export interface QueueItem {
  id: string;
  singerName: string;
  song: Song;
}

export interface PerformanceLog {
  id: string;
  singerName: string;
  songTitle: string;
  artist: string;
  timestamp: number;
}

export interface AudienceReaction {
  id: string;
  emoji: string;
}

export interface SongRequest {
  id: string;
  songTitle: string;
  artistName: string;
  requestedBy: string;
  forSinger?: string;
}

export interface Comment {
    id: string;
    author: string;
    text: string;
}

export interface AppState {
  role: Role | null;
  library: Song[];
  queue: QueueItem[];
  nowPlaying: QueueItem | null;
  performanceStartTime: number | null;
  history: PerformanceLog[];
  requests: SongRequest[];
  reactions: AudienceReaction[];
  comments: Comment[];
}

export type AppAction =
  | { type: 'SET_ROLE'; payload: Role }
  | { type: 'ADD_SONG_TO_LIBRARY'; payload: Song }
  | { type: 'ADD_SONGS_TO_LIBRARY'; payload: Song[] }
  | { type: 'UPDATE_SONG_IN_LIBRARY'; payload: Song }
  | { type: 'DELETE_SONG_FROM_LIBRARY'; payload: string }
  | { type: 'SIGN_UP'; payload: { singerName: string; song: Song } }
  | { type: 'SET_NOW_PLAYING'; payload: QueueItem | null }
  | { type: 'STOP_PERFORMANCE' }
  | { type: 'REMOVE_FROM_QUEUE'; payload: string }
  | { type: 'MOVE_QUEUE_ITEM'; payload: { fromIndex: number; toIndex: number } }
  | { type: 'ADD_REQUEST'; payload: Omit<SongRequest, 'id'> }
  | { type: 'ADD_REACTION'; payload: string }
  | { type: 'ADD_COMMENT'; payload: Omit<Comment, 'id'> }
  | { type: 'CLEAR_INTERACTIONS' };
