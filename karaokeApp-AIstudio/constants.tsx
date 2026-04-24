
import React from 'react';
import { Song, SongSource } from './types';

export const INITIAL_SONGS: Song[] = [
  { id: 'yt1', title: "Bohemian Rhapsody", artist: "Queen", source: SongSource.YOUTUBE, identifier: "fJ9rUzIMcZQ", duration: "5:55", rating: 5 },
  { id: 'yt2', title: "I Will Always Love You", artist: "Whitney Houston", source: SongSource.YOUTUBE, identifier: "3JWTaaS7LdU", duration: "4:31", rating: 5 },
  { id: 'yt3', title: "Don't Stop Believin'", artist: "Journey", source: SongSource.YOUTUBE, identifier: "1k8craCGpgs", duration: "4:11", rating: 4 },
  { id: 'sm1', title: "Shallow", artist: "Lady Gaga & Bradley Cooper", source: SongSource.SMULE, identifier: "https://www.smule.com/recording/lady-gaga-bradley-cooper-shallow/500802773_2721815003", duration: "3:37", rating: 4 },
  { id: 'local1', title: "My Way", artist: "Frank Sinatra", source: SongSource.LOCAL, identifier: "", duration: "4:35" },
];

export const EMOJI_REACTIONS = ['👏', '🔥', '❤️', '🤩', '🎤', '🎉'];

export const MicIcon = (props: React.SVGProps<SVGSVGElement>) => (
  <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"></path><path d="M19 10v2a7 7 0 0 1-14 0v-2"></path><line x1="12" x2="12" y1="19" y2="22"></line></svg>
);

export const MusicIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18V5l12-2v13"></path><circle cx="6" cy="18" r="3"></circle><circle cx="18" cy="16" r="3"></circle></svg>
);

export const UsersIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
);

export const CrownIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7zm3 16h14"></path></svg>
);

export const YoutubeIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} viewBox="0 0 24 24" fill="currentColor"><path d="M12.04,11.02c-1.12,0-2.03,0.91-2.03,2.03s0.91,2.03,2.03,2.03s2.03-0.91,2.03-2.03S13.16,11.02,12.04,11.02z M12.04,14.28 c-0.68,0-1.23-0.55-1.23-1.23s0.55-1.23,1.23-1.23s1.23,0.55,1.23,1.23S12.72,14.28,12.04,14.28z"></path><path d="M21.5,6.2H2.5C1.12,6.2,0,7.32,0,8.7v7.6c0,1.38,1.12,2.5,2.5,2.5h19c1.38,0,2.5-1.12,2.5-2.5V8.7 C24,7.32,22.88,6.2,21.5,6.2z M22.4,16.3c0,0.5-0.4,0.9-0.9,0.9H2.5c-0.5,0-0.9-0.4-0.9-0.9V8.7c0-0.5,0.4-0.9,0.9-0.9h19 c0.5,0,0.9,0.4,0.9,0.9V16.3z"></path><g><path d="M9.37,10.23l-1.46-0.37c-0.12-0.03-0.23,0.05-0.26,0.17L6.2,14.83c-0.03,0.12,0.05,0.23,0.17,0.26l1.46,0.37 c0.12,0.03,0.23-0.05,0.26-0.17l1.46-4.8c0.03-0.12-0.05-0.23-0.17-0.26S9.37,10.23,9.37,10.23z"></path><polygon points="17.93,10.15 15.68,10.15 14.88,12.79 14.88,10.15 13.9,10.15 13.9,15 14.88,15 14.88,12.89 15.82,15 18.07,15  "></polygon></g></svg>
);

export const SendIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg>
);

export const SparklesIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9.94 2.1c-.26.1-.49.26-.69.46l-4.1 4.1c-.39.39-.39 1.02 0 1.41l8.2 8.2c.39.39 1.02.39 1.41 0l4.1-4.1c.2-.2.37-.43.46-.69.25-.72.03-1.54-.53-2.1l-6.1-6.1c-.56-.56-1.38-.78-2.1-.53z"></path><path d="M12.03 7.02 17 11.99"></path><path d="m2.1 14.06 2.1-2.1"></path><path d="m14.06 2.1 2.1 2.1"></path><path d="M18 18.5c.28 0 .5.22.5.5v2c0 .28-.22.5-.5.5s-.5-.22-.5-.5v-2c0-.28.22-.5.5-.5z"></path><path d="M21.89 17.5c.22 0 .4.18.4.4v2c0 .22-.18.4-.4.4s-.4-.18-.4-.4v-2c0-.22.18-.4.4-.4z"></path></svg>
);

export const StarIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
);

export const DatabaseIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><ellipse cx="12" cy="5" rx="9" ry="3"></ellipse><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path></svg>
);