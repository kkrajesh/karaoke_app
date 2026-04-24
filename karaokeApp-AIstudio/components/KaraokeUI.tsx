
import React, { useState, ChangeEvent, useRef, useMemo, useEffect } from 'react';
import { AppState, AppAction, Role, Song, SongSource, QueueItem, PerformanceLog } from '../types';
import { getKaraokeSuggestions, searchYoutubeKaraoke } from '../services/geminiService';
import { EMOJI_REACTIONS, MusicIcon, YoutubeIcon, SparklesIcon, SendIcon, StarIcon, DatabaseIcon } from '../constants';

interface KaraokeUIProps {
  state: AppState;
  dispatch: React.Dispatch<AppAction>;
}

const getYoutubeId = (url: string): string | null => {
    if (!url) return null;

    // Regular expression to find a YouTube video ID from various URL formats.
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    const match = url.match(regExp);

    if (match && match[2].length === 11) {
        return match[2];
    }

    // Also handle if the URL is just the ID itself, in case the regex fails for some reason
    if (url.length === 11 && /^[a-zA-Z0-9_-]+$/.test(url)) {
        return url;
    }

    return null;
};

// Sub-components defined outside the main component to prevent re-rendering issues

const PerformanceTimer: React.FC<{ startTime: number | null }> = ({ startTime }) => {
    const [elapsed, setElapsed] = useState(0);

    useEffect(() => {
        if (!startTime) {
            setElapsed(0);
            return;
        }

        const updateTimer = () => {
            const now = Date.now();
            const diff = Math.floor((now - startTime) / 1000);
            setElapsed(diff >= 0 ? diff : 0);
        };

        // Update immediately then interval
        updateTimer();
        const interval = setInterval(updateTimer, 1000);

        return () => clearInterval(interval);
    }, [startTime]);

    if (!startTime) return null;

    const minutes = Math.floor(elapsed / 60).toString().padStart(2, '0');
    const seconds = (elapsed % 60).toString().padStart(2, '0');

    return (
        <div className="inline-flex items-center space-x-2 bg-black/40 px-3 py-1.5 rounded-lg border border-red-500/30 backdrop-blur-sm shadow-[0_0_15px_rgba(239,68,68,0.2)]">
            <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
            <span className="font-mono text-xl sm:text-2xl font-bold text-white tracking-wider">
                {minutes}:{seconds}
            </span>
        </div>
    );
};

const YoutubePreviewModal: React.FC<{
    title: string;
    youtubeId: string;
    onClose: () => void;
}> = ({ title, youtubeId, onClose }) => {
    const origin = encodeURIComponent(window.location.origin);
    return (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4" onClick={onClose}>
            <div className="bg-gray-800 p-4 rounded-lg max-w-3xl w-full" onClick={e => e.stopPropagation()}>
                <div className="flex justify-between items-center mb-4">
                     <h3 className="text-xl font-bold text-purple-300">{title}</h3>
                     <button onClick={onClose} className="text-gray-400 hover:text-white text-3xl leading-none">&times;</button>
                </div>
                <div className="aspect-video bg-black rounded">
                    <iframe
                        width="100%"
                        height="100%"
                        src={`https://www.youtube.com/embed/${youtubeId}?autoplay=1&origin=${origin}`}
                        title="YouTube video player"
                        frameBorder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                        allowFullScreen
                        className="rounded"
                    ></iframe>
                </div>
                 <div className="mt-4 text-center">
                    <p className="text-sm text-gray-400 mb-2">
                        If the video shows as "unavailable," its owner has disabled embedding on other sites.
                    </p>
                    <a 
                        href={`https://www.youtube.com/watch?v=${youtubeId}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center justify-center bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded transition-colors"
                    >
                        <YoutubeIcon className="w-5 h-5 mr-2" />
                        Watch on YouTube
                    </a>
                </div>
            </div>
        </div>
    );
};


const Player: React.FC<{ item: QueueItem | null }> = ({ item }) => {
    if (!item) {
        return (
            <div className="aspect-video bg-black rounded-lg flex items-center justify-center text-gray-500">
                <MusicIcon className="w-16 h-16" />
                <p className="ml-4 text-xl">Waiting for the next singer...</p>
            </div>
        );
    }

    const renderContent = () => {
        switch (item.song.source) {
            case SongSource.YOUTUBE: {
                 const origin = encodeURIComponent(window.location.origin);
                 return (
                    <div className="relative w-full h-full bg-black group">
                        <iframe
                            width="100%"
                            height="100%"
                            src={`https://www.youtube.com/embed/${item.song.identifier}?autoplay=1&origin=${origin}`}
                            title="YouTube video player"
                            frameBorder="0"
                            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                            allowFullScreen
                            className="rounded-lg"
                        ></iframe>
                        <div className="absolute top-0 left-0 w-full h-full flex flex-col items-center justify-center bg-black bg-opacity-70 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg pointer-events-none">
                             <div className="p-4 bg-gray-900/80 rounded-lg pointer-events-auto text-center">
                                <p className="text-white mb-3">Video not loading?</p>
                                <a 
                                    href={`https://www.youtube.com/watch?v=${item.song.identifier}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center justify-center bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded transition-colors"
                                >
                                    <YoutubeIcon className="w-5 h-5 mr-2" />
                                    Watch on YouTube
                                </a>
                             </div>
                        </div>
                    </div>
                );
            }
            case SongSource.LOCAL:
                return item.song.identifier ? 
                    <video controls autoPlay src={item.song.identifier} className="w-full h-full rounded-lg" /> :
                    <div className="w-full h-full flex items-center justify-center bg-black rounded-lg text-white">Local song selected, but no file is available.</div>;
            case SongSource.SMULE:
                return (
                    <div className="w-full h-full flex flex-col items-center justify-center bg-gray-800 rounded-lg text-white p-4">
                        <p className="text-xl mb-4">Playing from Smule</p>
                        <a href={item.song.identifier} target="_blank" rel="noopener noreferrer" className="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded transition-colors">
                            Open Smule in New Tab
                        </a>
                    </div>
                );
            case SongSource.MEDIAMONKEY:
                return (
                    <div className="w-full h-full flex flex-col items-center justify-center bg-gray-900 border border-yellow-600/30 rounded-lg text-white p-6 text-center">
                        <span title="MediaMonkey Library Track">
                             <DatabaseIcon className="w-16 h-16 text-yellow-500 mb-4" />
                        </span>
                        <h3 className="text-2xl font-bold mb-2 text-yellow-500">MediaMonkey Library Track</h3>
                        <p className="mb-4 text-gray-300">This song is from the host's local MediaMonkey database.</p>
                        <div className="bg-gray-800 p-4 rounded w-full max-w-lg">
                            <p className="text-sm text-gray-400 uppercase tracking-widest mb-1">File Location</p>
                            <code className="block text-green-400 font-mono text-sm break-all select-all">
                                {item.song.identifier}
                            </code>
                        </div>
                        <p className="mt-4 text-sm text-gray-500">The host needs to play this file manually in MediaMonkey.</p>
                    </div>
                );
            default:
                return <div className="w-full h-full flex items-center justify-center bg-black rounded-lg text-white">Unsupported song source.</div>;
        }
    };

    return <div className="aspect-video bg-black rounded-lg overflow-hidden">{renderContent()}</div>;
};

const SongCard: React.FC<{ song: Song; onSelect: (song: Song) => void }> = ({ song, onSelect }) => (
    <div className="bg-gray-800 p-4 rounded-lg flex items-center justify-between hover:bg-gray-700 transition-colors">
        <div>
            <h4 className="font-bold text-lg">{song.title}</h4>
            <p className="text-sm text-gray-400">{song.artist}</p>
            {song.rating && (
                <div className="flex mt-1">
                    {[...Array(5)].map((_, i) => (
                        <StarIcon key={i} className={`w-4 h-4 ${i < (song.rating || 0) ? 'text-yellow-400 fill-current' : 'text-gray-600'}`} />
                    ))}
                </div>
            )}
        </div>
        <div className="flex items-center space-x-4">
            {song.source === SongSource.YOUTUBE && <YoutubeIcon className="w-6 h-6 text-red-500" />}
            {song.source === SongSource.SMULE && <span className="text-green-400 font-bold">S</span>}
            {song.source === SongSource.LOCAL && <MusicIcon className="w-5 h-5 text-blue-400" />}
            {song.source === SongSource.MEDIAMONKEY && (
                <span title="From MediaMonkey">
                    <DatabaseIcon className="w-5 h-5 text-yellow-500" />
                </span>
            )}
            <button onClick={() => onSelect(song)} className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors text-sm">
                Sing
            </button>
        </div>
    </div>
);

const AudienceChat: React.FC<{ state: AppState; dispatch: React.Dispatch<AppAction>}> = ({ state, dispatch }) => {
    const [comment, setComment] = useState('');
    const [author, setAuthor] = useState('');

    const handleSendComment = () => {
        if (comment.trim() && author.trim()) {
            dispatch({ type: 'ADD_COMMENT', payload: { author, text: comment } });
            setComment('');
        }
    };

    return (
        <div className="bg-gray-800/50 backdrop-blur-sm p-4 rounded-lg h-full flex flex-col">
            <h3 className="text-xl font-bold mb-4 text-purple-300">Audience Reactions</h3>
            <div className="flex-grow space-y-2 overflow-y-auto mb-4 h-64 pr-2">
                {state.comments.map(c => (
                    <div key={c.id} className="bg-gray-700 p-2 rounded-md">
                        <span className="font-bold text-pink-400">{c.author}: </span>
                        <span>{c.text}</span>
                    </div>
                ))}
            </div>
            <div className="mt-auto">
                <div className="flex space-x-2 mb-4">
                    {EMOJI_REACTIONS.map(emoji => (
                        <button key={emoji} onClick={() => dispatch({type: 'ADD_REACTION', payload: emoji})} className="text-2xl p-2 bg-gray-700 rounded-full hover:bg-purple-600 transform hover:scale-110 transition-transform">
                            {emoji}
                        </button>
                    ))}
                </div>
                 <div className="flex flex-col sm:flex-row gap-2">
                    <input type="text" value={author} onChange={e => setAuthor(e.target.value)} placeholder="Your Name" className="flex-shrink-0 w-full sm:w-1/3 bg-gray-700 border border-gray-600 rounded px-2 py-1 focus:outline-none focus:ring-2 focus:ring-purple-500" />
                    <input type="text" value={comment} onChange={e => setComment(e.target.value)} placeholder="Say something encouraging..." className="flex-grow bg-gray-700 border border-gray-600 rounded px-2 py-1 focus:outline-none focus:ring-2 focus:ring-purple-500" />
                    <button onClick={handleSendComment} className="p-2 bg-purple-600 rounded hover:bg-purple-700 disabled:opacity-50" disabled={!comment.trim() || !author.trim()}>
                        <SendIcon className="w-5 h-5"/>
                    </button>
                </div>
            </div>
        </div>
    );
};


const AiSuggestions: React.FC<{onSelect: (title: string, artist: string) => void}> = ({ onSelect }) => {
    const [prompt, setPrompt] = useState('');
    const [suggestions, setSuggestions] = useState<{title: string, artist: string, reason: string, link: string}[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [previewingSong, setPreviewingSong] = useState<{title: string, link: string} | null>(null);

    const handleGetSuggestions = async () => {
        if (!prompt.trim()) return;
        setIsLoading(true);
        setError('');
        setSuggestions([]);
        try {
            const resultString = await getKaraokeSuggestions(prompt);
            const result = JSON.parse(resultString);
            if(result.error) {
                 setError(result.error);
            } else {
                setSuggestions(result.suggestions);
            }
        } catch (e) {
            setError('Failed to parse suggestions. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };
    
    const previewVideoId = useMemo(() => {
        if (!previewingSong) return null;
        return getYoutubeId(previewingSong.link);
    }, [previewingSong]);
    
    return (
        <div className="bg-gray-800/50 backdrop-blur-sm p-4 rounded-lg mt-6">
            <h3 className="text-xl font-bold mb-4 text-purple-300 flex items-center"><SparklesIcon className="w-6 h-6 mr-2"/> AI Song Suggestions</h3>
            <div className="flex gap-2">
                <input 
                    type="text"
                    value={prompt}
                    onChange={(e) => setPrompt(e.target.value)}
                    placeholder="e.g., 'an 80s power ballad'"
                    className="flex-grow bg-gray-700 border border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
                <button onClick={handleGetSuggestions} disabled={isLoading} className="bg-pink-600 hover:bg-pink-700 text-white font-bold py-2 px-4 rounded transition-colors disabled:opacity-50">
                    {isLoading ? 'Thinking...' : 'Suggest'}
                </button>
            </div>
            {error && <p className="text-red-400 mt-2">{error}</p>}
            {suggestions.length > 0 && (
                <div className="mt-4 space-y-3">
                    {suggestions.map((s, i) => (
                        <div key={i} className="bg-gray-700 p-3 rounded-md">
                            <div className="flex justify-between items-start">
                                <div>
                                    <p className="font-bold">{s.title} - {s.artist}</p>
                                    <p className="text-sm text-gray-400 italic">"{s.reason}"</p>
                                </div>
                                <div className="flex items-center ml-2 flex-shrink-0">
                                     <button onClick={() => setPreviewingSong({ title: s.title, link: s.link })} className="text-sm bg-blue-600 hover:bg-blue-700 text-white font-semibold py-1 px-2 rounded transition-colors mr-2">
                                        Preview
                                    </button>
                                    <button onClick={() => onSelect(s.title, s.artist)} className="text-sm bg-purple-600 hover:bg-purple-700 text-white font-semibold py-1 px-2 rounded transition-colors">
                                        Search
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
            
            {previewingSong && previewVideoId && (
                <YoutubePreviewModal
                    title={previewingSong.title}
                    youtubeId={previewVideoId}
                    onClose={() => setPreviewingSong(null)}
                />
            )}
        </div>
    );
};

interface YoutubeSearchResult {
    title: string;
    artist: string;
    youtubeId: string;
}

const YoutubeSearch: React.FC<{dispatch: React.Dispatch<AppAction>}> = ({ dispatch }) => {
    const [query, setQuery] = useState('');
    const [results, setResults] = useState<YoutubeSearchResult[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [previewingSong, setPreviewingSong] = useState<YoutubeSearchResult | null>(null);

    const handleSearch = async () => {
        if (!query.trim()) return;
        setIsLoading(true);
        setError('');
        setResults([]);
        try {
            const resultString = await searchYoutubeKaraoke(query);
            const result = JSON.parse(resultString);
            if (result.error) {
                 setError(result.error);
            } else if (result.songs && result.songs.length > 0) {
                setResults(result.songs);
            } else {
                setResults([]);
                setError("No karaoke songs found for your query. Try being more specific!");
            }
        } catch (e) {
            setError('Failed to parse search results. Please try again.');
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };
    
    const handleAddSong = (song: YoutubeSearchResult) => {
        const videoId = getYoutubeId(song.youtubeId);
        if (!videoId) {
            alert(`Could not add "${song.title}". The YouTube link or ID seems invalid.`);
            return;
        }

        const newSong: Song = {
            id: `yt-${videoId}`,
            title: song.title,
            artist: song.artist,
            source: SongSource.YOUTUBE,
            identifier: videoId,
            duration: 'N/A',
        };
        dispatch({ type: 'ADD_SONG_TO_LIBRARY', payload: newSong });
        alert(`'${song.title}' by ${song.artist} has been added to the library!`);
    };
    
    const previewVideoId = useMemo(() => {
        if (!previewingSong) return null;
        return getYoutubeId(previewingSong.youtubeId);
    }, [previewingSong]);

    return (
        <div className="bg-gray-800/50 backdrop-blur-sm p-4 rounded-lg mt-6">
            <h3 className="text-xl font-bold mb-4 text-purple-300 flex items-center"><YoutubeIcon className="w-6 h-6 mr-2"/> Find on YouTube</h3>
            <div className="flex gap-2">
                <input 
                    type="text"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                    placeholder="e.g., 'Queen Bohemian Rhapsody karaoke'"
                    className="flex-grow bg-gray-700 border border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
                <button onClick={handleSearch} disabled={isLoading || !query.trim()} className="bg-pink-600 hover:bg-pink-700 text-white font-bold py-2 px-4 rounded transition-colors disabled:opacity-50">
                    {isLoading ? 'Searching...' : 'Search'}
                </button>
            </div>
            {error && <p className="text-red-400 mt-2">{error}</p>}
            {results.length > 0 && (
                <div className="mt-4 space-y-3 max-h-96 overflow-y-auto pr-2">
                    {results.map((s, i) => (
                        <div key={i} className="bg-gray-700 p-3 rounded-md">
                            <div className="flex justify-between items-center">
                                <div>
                                    <p className="font-bold">{s.title}</p>
                                    <p className="text-sm text-gray-400">{s.artist}</p>
                                </div>
                                <div className="flex items-center ml-2 flex-shrink-0 space-x-2">
                                     <button onClick={() => setPreviewingSong(s)} className="text-sm bg-blue-600 hover:bg-blue-700 text-white font-semibold py-1 px-2 rounded transition-colors">
                                        Preview
                                    </button>
                                    <button onClick={() => handleAddSong(s)} className="text-sm bg-purple-600 hover:bg-purple-700 text-white font-semibold py-1 px-2 rounded transition-colors">
                                        Add to Library
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
            
            {previewingSong && previewVideoId && (
                <YoutubePreviewModal
                    title={previewingSong.title}
                    youtubeId={previewVideoId}
                    onClose={() => setPreviewingSong(null)}
                />
            )}
        </div>
    );
};

const MediaMonkeyImport: React.FC<{dispatch: React.Dispatch<AppAction>}> = ({ dispatch }) => {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [isLoading, setIsLoading] = useState(false);

    const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        setIsLoading(true);

        try {
            // @ts-ignore
            if (typeof window.initSqlJs !== 'function') {
                throw new Error("SQL.js library not loaded. Please refresh the page.");
            }

            const arrayBuffer = await file.arrayBuffer();
            // @ts-ignore
            const SQL = await window.initSqlJs({
                // Locate the WASM file from CDN
                locateFile: (file: string) => `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.10.2/${file}`
            });

            const db = new SQL.Database(new Uint8Array(arrayBuffer));

            // MediaMonkey 4 typical schema:
            // Songs table has SongTitle, Artist (or IDArtist), SongPath, SongLength
            // Artists table has ID, Artist
            const query = `
                SELECT 
                    Songs.SongTitle, 
                    Artists.Artist, 
                    Songs.SongPath, 
                    Songs.SongLength 
                FROM Songs 
                LEFT JOIN Artists ON Songs.IDArtist = Artists.ID 
                WHERE Songs.SongTitle IS NOT NULL
            `;

            const result = db.exec(query);

            if (result.length > 0 && result[0].values) {
                const songs: Song[] = result[0].values.map((row: any[], index: number) => {
                    // row[0] = Title, row[1] = Artist, row[2] = Path, row[3] = Length (ms)
                    const title = row[0] as string || 'Unknown Title';
                    const artist = row[1] as string || 'Unknown Artist';
                    const path = row[2] as string || '';
                    const durationMs = row[3] as number || 0;
                    
                    // Convert duration from ms to mm:ss
                    let duration = "N/A";
                    if (durationMs > 0) {
                        const totalSeconds = Math.floor(durationMs / 1000);
                        const minutes = Math.floor(totalSeconds / 60);
                        const seconds = totalSeconds % 60;
                        duration = `${minutes}:${seconds.toString().padStart(2, '0')}`;
                    }

                    return {
                        id: `mm-db-${Date.now()}-${index}`,
                        title,
                        artist,
                        source: SongSource.MEDIAMONKEY,
                        identifier: path,
                        duration
                    };
                });

                dispatch({ type: 'ADD_SONGS_TO_LIBRARY', payload: songs });
                alert(`Successfully imported ${songs.length} songs from MediaMonkey Database!`);
            } else {
                alert("Could not find songs in the uploaded database file.");
            }
            db.close();

        } catch (err: any) {
            console.error(err);
            alert(`Error reading database: ${err.message}`);
        } finally {
            setIsLoading(false);
            if (fileInputRef.current) fileInputRef.current.value = "";
        }
    };

    return (
        <div className="bg-gray-800/50 p-4 rounded-lg mt-6 border border-yellow-600/30">
            <h4 className="text-lg font-bold text-yellow-500 flex items-center mb-2">
                <span title="Import DB">
                    <DatabaseIcon className="w-5 h-5 mr-2" />
                </span>
                Import MediaMonkey Database
            </h4>
            <p className="text-sm text-gray-400 mb-4">
                Directly upload your MediaMonkey database file (<code>MM.DB</code>). Usually located in <code>AppData/Roaming/MediaMonkey</code>.
            </p>
            <button 
                onClick={() => fileInputRef.current?.click()} 
                disabled={isLoading}
                className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded transition-colors disabled:opacity-50 flex justify-center items-center"
            >
                {isLoading ? (
                    <span className="flex items-center">
                        <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Parsing DB...
                    </span>
                ) : 'Upload MM.DB File'}
            </button>
            <input 
                type="file" 
                ref={fileInputRef} 
                onChange={handleFileChange} 
                accept=".db,.ini,.sqlite"
                className="hidden" 
            />
        </div>
    );
};

const AddOnlineSongForm: React.FC<{dispatch: React.Dispatch<AppAction>}> = ({ dispatch }) => {
    const [title, setTitle] = useState('');
    const [artist, setArtist] = useState('');
    const [identifier, setIdentifier] = useState('');
    const [source, setSource] = useState<SongSource>(SongSource.YOUTUBE);

    const handleAddSong = () => {
        if (!title.trim() || !artist.trim() || !identifier.trim()) {
            alert("Please fill in all fields.");
            return;
        }
        
        let finalIdentifier = identifier;
        if (source === SongSource.YOUTUBE) {
            const videoId = getYoutubeId(identifier);
            if (!videoId) {
                alert("Invalid YouTube URL. Please use the full URL (e.g., https://www.youtube.com/watch?v=...) or just the video ID.");
                return;
            }
            finalIdentifier = videoId;
        }

        const newSong: Song = {
            id: `${source.toLowerCase()}-${new Date().toISOString()}`,
            title,
            artist,
            source,
            identifier: finalIdentifier,
            duration: 'N/A',
        };
        dispatch({ type: 'ADD_SONG_TO_LIBRARY', payload: newSong });

        setTitle('');
        setArtist('');
        setIdentifier('');
    };

    return (
        <div className="space-y-3 pt-4 border-t border-gray-700">
             <h4 className="text-lg font-semibold text-purple-300">Add Online Song Manually</h4>
            <input type="text" value={title} onChange={e => setTitle(e.target.value)} placeholder="Song Title" className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-purple-500"/>
            <input type="text" value={artist} onChange={e => setArtist(e.target.value)} placeholder="Artist" className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-purple-500"/>
            <input type="text" value={identifier} onChange={e => setIdentifier(e.target.value)} placeholder="YouTube or Smule URL" className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-purple-500"/>
            <select value={source} onChange={e => setSource(e.target.value as SongSource)} className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-purple-500">
                <option value={SongSource.YOUTUBE}>YouTube</option>
                <option value={SongSource.SMULE}>Smule</option>
            </select>
            <button onClick={handleAddSong} className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors">Add to Library</button>
        </div>
    );
};

// Library Management Components

const StarRating: React.FC<{
    rating: number;
    onSetRating: (rating: number) => void;
    className?: string;
}> = ({ rating, onSetRating, className = '' }) => {
    return (
        <div className="flex items-center">
            {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} onClick={() => onSetRating(star)} className="p-0 bg-transparent border-none">
                    <StarIcon
                        className={`w-5 h-5 cursor-pointer transition-colors ${
                            star <= rating ? 'text-yellow-400 fill-current' : 'text-gray-600'
                        }`}
                    />
                </button>
            ))}
        </div>
    );
};

const EditSongModal: React.FC<{
    song: Song;
    onSave: (updatedSong: Song) => void;
    onClose: () => void;
}> = ({ song, onSave, onClose }) => {
    const [title, setTitle] = useState(song.title);
    const [artist, setArtist] = useState(song.artist);
    const [rating, setRating] = useState(song.rating ?? 0);

    const handleSave = () => {
        onSave({
            ...song,
            title,
            artist,
            rating: rating > 0 ? rating : undefined,
        });
        onClose();
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4" onClick={onClose}>
            <div className="bg-gray-800 p-6 rounded-lg max-w-md w-full" onClick={e => e.stopPropagation()}>
                <h3 className="text-xl font-bold mb-4 text-purple-300">Edit Song</h3>
                <div className="space-y-4">
                     <input type="text" value={title} onChange={e => setTitle(e.target.value)} placeholder="Song Title" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"/>
                     <input type="text" value={artist} onChange={e => setArtist(e.target.value)} placeholder="Artist" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"/>
                     <div className="flex items-center">
                        <span className="mr-3 text-gray-400">Rating:</span>
                        <StarRating rating={rating} onSetRating={setRating} />
                     </div>
                </div>
                <div className="flex justify-end space-x-4 mt-6">
                    <button onClick={onClose} className="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded transition-colors">Cancel</button>
                    <button onClick={handleSave} className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors">Save</button>
                </div>
            </div>
        </div>
    );
};

const LibraryManagementModal: React.FC<{
    library: Song[];
    dispatch: React.Dispatch<AppAction>;
    onClose: () => void;
}> = ({ library, dispatch, onClose }) => {
    const [searchTerm, setSearchTerm] = useState('');
    const [sourceFilter, setSourceFilter] = useState<string>('ALL');
    const [editingSong, setEditingSong] = useState<Song | null>(null);

    const filteredLibrary = library.filter(song => {
        // Source Filter
        if (sourceFilter !== 'ALL' && song.source !== sourceFilter) return false;

        // Text Search
        const searchTerms = searchTerm.toLowerCase().split(' ').filter(Boolean);
        if (searchTerms.length === 0) return true;
        const songInfo = `${song.title} ${song.artist}`.toLowerCase();
        return searchTerms.every(term => songInfo.includes(term));
    });

    const handleDelete = (songId: string, songTitle: string) => {
        if (window.confirm(`Are you sure you want to delete "${songTitle}"?`)) {
            dispatch({ type: 'DELETE_SONG_FROM_LIBRARY', payload: songId });
        }
    };
    
    const handleUpdate = (updatedSong: Song) => {
        dispatch({ type: 'UPDATE_SONG_IN_LIBRARY', payload: updatedSong });
    };

    const handleRatingUpdate = (song: Song, newRating: number) => {
        handleUpdate({ ...song, rating: newRating });
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-80 flex flex-col z-40 p-4 sm:p-8" onClick={onClose}>
            <div className="bg-gray-800 rounded-lg w-full max-w-4xl mx-auto flex flex-col h-full" onClick={e => e.stopPropagation()}>
                <div className="p-4 border-b border-gray-700 flex justify-between items-center">
                    <h2 className="text-2xl font-bold text-purple-300">Library Management</h2>
                     <button onClick={onClose} className="text-gray-400 hover:text-white text-3xl leading-none">&times;</button>
                </div>
                <div className="p-4 flex flex-col sm:flex-row gap-3">
                     <input
                        type="text"
                        placeholder="Search library..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="flex-grow p-3 bg-gray-700 rounded-lg border border-gray-600 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    />
                     <select
                        value={sourceFilter}
                        onChange={(e) => setSourceFilter(e.target.value)}
                        className="bg-gray-700 text-white p-3 rounded-lg border border-gray-600 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    >
                        <option value="ALL">All Sources</option>
                        <option value={SongSource.YOUTUBE}>YouTube</option>
                        <option value={SongSource.MEDIAMONKEY}>MediaMonkey</option>
                        <option value={SongSource.LOCAL}>Local Files</option>
                        <option value={SongSource.SMULE}>Smule</option>
                    </select>
                </div>
                <div className="flex-grow overflow-y-auto px-4 pb-4">
                    <div className="space-y-3">
                        {filteredLibrary.map(song => (
                             <div key={song.id} className="bg-gray-900/50 p-3 rounded-lg flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                                <div className="flex-grow">
                                    <div className="flex items-center gap-2">
                                        <h4 className="font-bold text-lg">{song.title}</h4>
                                        {song.source === SongSource.MEDIAMONKEY && (
                                            <span title="From MediaMonkey" className="flex items-center">
                                                <DatabaseIcon className="w-4 h-4 text-yellow-500" />
                                            </span>
                                        )}
                                    </div>
                                    <p className="text-sm text-gray-400">{song.artist}</p>
                                </div>
                                <div className="flex items-center gap-4">
                                     <StarRating rating={song.rating ?? 0} onSetRating={(newRating) => handleRatingUpdate(song, newRating)} />
                                     <div className="flex items-center space-x-2">
                                        <button onClick={() => setEditingSong(song)} className="text-sm bg-blue-600 hover:bg-blue-700 text-white font-semibold py-1 px-2 rounded transition-colors">Edit</button>
                                        <button onClick={() => handleDelete(song.id, song.title)} className="text-sm bg-red-600 hover:bg-red-700 text-white font-semibold py-1 px-2 rounded transition-colors">Delete</button>
                                     </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
            {editingSong && (
                <EditSongModal 
                    song={editingSong}
                    onClose={() => setEditingSong(null)}
                    onSave={(updatedSong) => {
                        handleUpdate(updatedSong);
                        setEditingSong(null);
                    }}
                />
            )}
        </div>
    );
};

const PerformanceHistory: React.FC<{ history: PerformanceLog[] }> = ({ history }) => {
    if (history.length === 0) return null;

    return (
        <div className="bg-gray-800/50 p-4 rounded-lg mt-6">
             <h2 className="text-xl font-bold mb-4 text-purple-300">Previous Performances</h2>
             <div className="max-h-60 overflow-y-auto space-y-2 pr-2">
                {history.map((log) => (
                    <div key={log.id} className="bg-gray-700/50 p-2 rounded flex justify-between items-center text-sm">
                        <div>
                            <span className="font-bold text-white">{log.singerName}</span>
                            <span className="text-gray-400"> sang </span>
                            <span className="text-pink-300">{log.songTitle}</span>
                        </div>
                        <div className="text-gray-500 text-xs">
                            {new Date(log.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </div>
                    </div>
                ))}
             </div>
        </div>
    );
};

// Main Role Views

const HostView: React.FC<KaraokeUIProps> = ({ state, dispatch }) => {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [isLibraryModalOpen, setIsLibraryModalOpen] = useState(false);

    const handleNextSinger = () => {
        if (state.queue.length > 0) {
            const nextSinger = state.queue[0];
            dispatch({ type: 'SET_NOW_PLAYING', payload: nextSinger });
            dispatch({ type: 'REMOVE_FROM_QUEUE', payload: nextSinger.id });
            dispatch({ type: 'CLEAR_INTERACTIONS' });
        }
    };

    const handleStopPerformance = () => {
        if (state.nowPlaying) {
            if (window.confirm(`Stop ${state.nowPlaying.singerName}'s performance?`)) {
                 dispatch({ type: 'STOP_PERFORMANCE' });
                 dispatch({ type: 'CLEAR_INTERACTIONS' });
            }
        }
    };
    
    const handleAddLocalFolder = (event: ChangeEvent<HTMLInputElement>) => {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const supportedMimeTypes = ['video/mp4', 'video/webm', 'audio/mpeg', 'video/quicktime'];
        const newSongs: Song[] = [];

        // FIX: Use a standard for-loop to avoid potential issues with `for...of` on FileList in older environments
        // and to ensure correct type inference for `file`.
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            if (supportedMimeTypes.some(type => file.type.startsWith(type.split('/')[0]))) {
                const nameParts = file.name.replace(/\.[^/.]+$/, "").split(' - ');
                const song: Song = {
                    id: `local-${file.name}-${new Date().toISOString()}`,
                    title: nameParts[1]?.trim() || 'Unknown Title',
                    artist: nameParts[0]?.trim() || 'Unknown Artist',
                    source: SongSource.LOCAL,
                    identifier: URL.createObjectURL(file),
                    duration: '',
                };
                newSongs.push(song);
            }
        }

        if (newSongs.length > 0) {
            dispatch({ type: 'ADD_SONGS_TO_LIBRARY', payload: newSongs });
            alert(`Added ${newSongs.length} new song(s) to the library.`);
        }

        if (fileInputRef.current) {
            fileInputRef.current.value = "";
        }
    };

    return (
        <>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-6">
                    <div>
                        <div className="flex justify-between items-center mb-4">
                            <h2 className="text-2xl font-bold text-pink-400">Now Playing: {state.nowPlaying?.singerName || 'Nobody'}</h2>
                            <div className="flex items-center gap-3">
                                 {state.nowPlaying && (
                                    <button 
                                        onClick={handleStopPerformance}
                                        className="bg-red-600 hover:bg-red-700 text-white font-bold py-1.5 px-3 rounded text-sm transition-colors flex items-center"
                                    >
                                        <span className="mr-1">⏹</span> Stop
                                    </button>
                                 )}
                                 <PerformanceTimer startTime={state.performanceStartTime} />
                            </div>
                        </div>
                        <Player item={state.nowPlaying} />
                    </div>
                     <div>
                        <h2 className="text-2xl font-bold mb-4 text-pink-400">Song Requests</h2>
                        <div className="bg-gray-800/50 p-4 rounded-lg max-h-48 overflow-y-auto">
                            {state.requests.length === 0 && <p className="text-gray-400">No requests yet.</p>}
                            <ul className="space-y-2">
                                {state.requests.map(req => (
                                    <li key={req.id} className="text-sm">
                                        <span className="font-bold">{req.songTitle}</span> by {req.artistName} (for {req.forSinger || 'anyone'}) - requested by <span className="text-purple-300">{req.requestedBy}</span>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                    <PerformanceHistory history={state.history} />
                </div>
                <div className="space-y-6">
                    <div>
                        <h2 className="text-2xl font-bold mb-4 text-pink-400">Singer Queue</h2>
                        <div className="bg-gray-800/50 p-4 rounded-lg space-y-3">
                            {state.queue.length === 0 && <p className="text-gray-400">The queue is empty!</p>}
                            {state.queue.map((item, index) => (
                                <div key={item.id} className="bg-gray-700 p-3 rounded-lg flex justify-between items-center">
                                    <div>
                                        <p className="font-bold text-lg">{index + 1}. {item.singerName}</p>
                                        <p className="text-sm text-gray-400">{item.song.title} - {item.song.artist}</p>
                                    </div>
                                    <div className="flex flex-col space-y-1">
                                        <button disabled={index === 0} onClick={() => dispatch({type: 'MOVE_QUEUE_ITEM', payload: {fromIndex: index, toIndex: index - 1}})} className="text-xs p-1 rounded-full bg-gray-600 hover:bg-gray-500 disabled:opacity-50">▲</button>
                                        <button disabled={index === state.queue.length - 1} onClick={() => dispatch({type: 'MOVE_QUEUE_ITEM', payload: {fromIndex: index, toIndex: index + 1}})} className="text-xs p-1 rounded-full bg-gray-600 hover:bg-gray-500 disabled:opacity-50">▼</button>
                                    </div>
                                </div>
                            ))}
                        </div>
                        <button onClick={handleNextSinger} disabled={state.queue.length === 0} className="w-full mt-4 bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-4 rounded transition-colors disabled:opacity-50">
                            Start Next Singer
                        </button>
                    </div>
                    <div className="bg-gray-800/50 p-4 rounded-lg">
                        <h3 className="text-xl font-bold mb-4 text-pink-400">Manage Library</h3>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <button onClick={() => fileInputRef.current?.click()} className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition-colors">
                                Add From Folder
                            </button>
                            <button onClick={() => setIsLibraryModalOpen(true)} className="w-full bg-gray-600 hover:bg-gray-500 text-white font-bold py-2 px-4 rounded transition-colors">
                                View & Edit All
                            </button>
                        </div>
                        <input type="file" ref={fileInputRef} onChange={handleAddLocalFolder} multiple {...({ webkitdirectory: "", directory: "" } as any)} className="hidden" />
                        <p className="text-xs text-gray-400 my-2 text-center">
                            Use "Artist - Title.ext" format for best results.
                        </p>
                        <AddOnlineSongForm dispatch={dispatch} />
                        <MediaMonkeyImport dispatch={dispatch} />
                    </div>
                    <YoutubeSearch dispatch={dispatch} />
                     <AudienceChat state={state} dispatch={dispatch} />
                </div>
            </div>
            {isLibraryModalOpen && (
                <LibraryManagementModal 
                    library={state.library}
                    dispatch={dispatch}
                    onClose={() => setIsLibraryModalOpen(false)}
                />
            )}
        </>
    );
};

const SingerView: React.FC<KaraokeUIProps> = ({ state, dispatch }) => {
    const [searchTerm, setSearchTerm] = useState('');
    const [sourceFilter, setSourceFilter] = useState<string>('ALL');
    const [singerName, setSingerName] = useState('');
    const [selectedSong, setSelectedSong] = useState<Song | null>(null);

    const filteredLibrary = state.library.filter(song => {
        // Source Filter
        if (sourceFilter !== 'ALL' && song.source !== sourceFilter) return false;

        const searchTerms = searchTerm.toLowerCase().split(' ').filter(Boolean);
        if (searchTerms.length === 0) return true;

        const songInfo = `${song.title} ${song.artist}`.toLowerCase();
        return searchTerms.every(term => songInfo.includes(term));
    });

    const handleSignUp = () => {
        if (!singerName.trim() || !selectedSong) {
            alert("Please enter your name and select a song.");
            return;
        }
        dispatch({ type: 'SIGN_UP', payload: { singerName, song: selectedSong } });
        setSingerName('');
        setSelectedSong(null);
        alert("You've been added to the queue!");
    };

    return (
        <div className="space-y-6">
            {/* Now Playing Banner for Singer */}
            {state.nowPlaying && (
                 <div className="bg-purple-900/50 border border-purple-500/30 p-4 rounded-lg flex justify-between items-center animate-pulse">
                    <div>
                        <p className="text-sm text-purple-300 uppercase tracking-wider">Now Performing</p>
                        <p className="text-xl font-bold text-white">{state.nowPlaying.singerName}</p>
                        <p className="text-gray-300">{state.nowPlaying.song.title}</p>
                    </div>
                    <PerformanceTimer startTime={state.performanceStartTime} />
                </div>
            )}

            <div className="bg-gray-800/50 p-4 rounded-lg">
                <h2 className="text-2xl font-bold mb-4 text-purple-300">Sign Up to Sing</h2>
                <div className="flex flex-col md:flex-row gap-4 mb-6">
                    <input 
                        type="text" 
                        value={singerName} 
                        onChange={e => setSingerName(e.target.value)}
                        placeholder="Your Stage Name"
                        className="flex-grow bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500 text-lg"
                    />
                    <div className="flex-grow flex gap-2">
                        {selectedSong ? (
                            <div className="flex-grow flex justify-between items-center bg-purple-700 px-4 py-2 rounded">
                                <span className="font-bold truncate">{selectedSong.title}</span>
                                <button onClick={() => setSelectedSong(null)} className="ml-2 text-gray-300 hover:text-white">&times;</button>
                            </div>
                        ) : (
                            <div className="flex-grow bg-gray-700 border border-gray-600 rounded px-4 py-2 text-gray-400 italic">
                                Select a song below...
                            </div>
                        )}
                    </div>
                    <button 
                        onClick={handleSignUp}
                        disabled={!singerName.trim() || !selectedSong}
                        className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        Join Queue
                    </button>
                </div>
            </div>

            <div className="bg-gray-800/50 p-4 rounded-lg flex flex-col h-[600px]">
                <div className="flex justify-between items-center mb-4">
                     <h3 className="text-xl font-bold text-purple-300">Song Library</h3>
                     <div className="flex gap-2">
                        <select
                            value={sourceFilter}
                            onChange={(e) => setSourceFilter(e.target.value)}
                            className="bg-gray-700 text-white p-2 rounded border border-gray-600 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
                        >
                            <option value="ALL">All Sources</option>
                            <option value={SongSource.YOUTUBE}>YouTube</option>
                            <option value={SongSource.MEDIAMONKEY}>MediaMonkey</option>
                            <option value={SongSource.LOCAL}>Local Files</option>
                            <option value={SongSource.SMULE}>Smule</option>
                        </select>
                         <input
                            type="text"
                            placeholder="Search songs or artists..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
                        />
                     </div>
                </div>
                <div className="flex-grow overflow-y-auto space-y-2 pr-2">
                    {filteredLibrary.map(song => (
                        <SongCard key={song.id} song={song} onSelect={setSelectedSong} />
                    ))}
                    {filteredLibrary.length === 0 && (
                        <p className="text-center text-gray-400 mt-10">No songs found matching your criteria.</p>
                    )}
                </div>
            </div>
             <AiSuggestions onSelect={(t, a) => { setSearchTerm(`${t} ${a}`); }} />
        </div>
    );
};

const AudienceView: React.FC<KaraokeUIProps> = ({ state, dispatch }) => {
    const [requestSong, setRequestSong] = useState('');
    const [requestArtist, setRequestArtist] = useState('');
    const [forSinger, setForSinger] = useState('');
    const [yourName, setYourName] = useState('');

    const handleRequest = () => {
        if (requestSong && requestArtist && yourName) {
            dispatch({
                type: 'ADD_REQUEST',
                payload: {
                    songTitle: requestSong,
                    artistName: requestArtist,
                    requestedBy: yourName,
                    forSinger: forSinger
                }
            });
            setRequestSong('');
            setRequestArtist('');
            setForSinger('');
            alert('Request sent!');
        }
    };

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
                <div className="bg-gray-800/50 p-6 rounded-lg text-center">
                    <h2 className="text-2xl font-bold mb-2 text-pink-400">Currently Performing</h2>
                    {state.nowPlaying ? (
                        <div className="animate-fade-in">
                            <p className="text-4xl font-bold text-white mb-2">{state.nowPlaying.singerName}</p>
                            <p className="text-xl text-purple-300">{state.nowPlaying.song.title} - {state.nowPlaying.song.artist}</p>
                            <div className="mt-4 flex justify-center">
                                 <PerformanceTimer startTime={state.performanceStartTime} />
                            </div>
                        </div>
                    ) : (
                        <p className="text-gray-400 text-xl">The stage is empty!</p>
                    )}
                </div>

                <div className="bg-gray-800/50 p-6 rounded-lg">
                    <h3 className="text-xl font-bold mb-4 text-purple-300">Make a Request</h3>
                    <div className="space-y-3">
                        <input type="text" value={yourName} onChange={e => setYourName(e.target.value)} placeholder="Your Name" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2"/>
                        <input type="text" value={requestSong} onChange={e => setRequestSong(e.target.value)} placeholder="Song Title" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2"/>
                        <input type="text" value={requestArtist} onChange={e => setRequestArtist(e.target.value)} placeholder="Artist" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2"/>
                        <input type="text" value={forSinger} onChange={e => setForSinger(e.target.value)} placeholder="Suggest for a specific singer? (Optional)" className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2"/>
                        <button onClick={handleRequest} disabled={!yourName || !requestSong || !requestArtist} className="w-full bg-pink-600 hover:bg-pink-700 text-white font-bold py-2 px-4 rounded transition-colors disabled:opacity-50">
                            Send Request
                        </button>
                    </div>
                </div>
            </div>
            
            <AudienceChat state={state} dispatch={dispatch} />
        </div>
    );
};

const KaraokeUI: React.FC<KaraokeUIProps> = ({ state, dispatch }) => {
  switch (state.role) {
    case Role.HOST:
      return <HostView state={state} dispatch={dispatch} />;
    case Role.SINGER:
      return <SingerView state={state} dispatch={dispatch} />;
    case Role.AUDIENCE:
      return <AudienceView state={state} dispatch={dispatch} />;
    default:
      return null;
  }
};

export default KaraokeUI;
