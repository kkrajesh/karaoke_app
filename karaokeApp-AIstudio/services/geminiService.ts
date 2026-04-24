import { GoogleGenAI, Type } from "@google/genai";

export async function getKaraokeSuggestions(prompt: string): Promise<string> {
  if (!process.env.API_KEY) {
    console.error("API_KEY is not set in environment variables.");
    return JSON.stringify({ error: "API key not configured. Please set it up to use AI features." });
  }

  try {
    const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
    const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `Based on the following request, suggest 3 karaoke songs. For each song, provide the title, artist, a creative reason for the suggestion, and a direct link to a karaoke version on YouTube. Request: "${prompt}"`,
        config: {
            responseMimeType: "application/json",
            responseSchema: {
                type: Type.OBJECT,
                properties: {
                    suggestions: {
                        type: Type.ARRAY,
                        items: {
                            type: Type.OBJECT,
                            properties: {
                                title: { type: Type.STRING },
                                artist: { type: Type.STRING },
                                reason: { type: Type.STRING },
                                link: { type: Type.STRING, description: "A URL to a karaoke version on YouTube." }
                            },
                             required: ["title", "artist", "reason", "link"]
                        }
                    }
                },
                required: ["suggestions"]
            }
        }
    });

    return response.text;
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    if (error instanceof Error) {
        return JSON.stringify({ error: `An error occurred: ${error.message}. Please ensure your API key is valid.` });
    }
    return JSON.stringify({ error: "An unknown error occurred while fetching suggestions. Ensure your API key is valid." });
  }
}

export async function searchYoutubeKaraoke(query: string): Promise<string> {
  const apiKey = process.env.API_KEY;
  if (!apiKey) {
    console.error("API_KEY is not set in environment variables.");
    return JSON.stringify({ error: "API key not configured. Please set it up to use YouTube search." });
  }

  try {
    // We add 'karaoke' to the search term to ensure the results are relevant to the app's purpose.
    const searchQuery = encodeURIComponent(`${query} karaoke`);
    // Requesting 10 results to provide a good variety
    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=10&q=${searchQuery}&type=video&videoEmbeddable=true&key=${apiKey}`;
    
    const response = await fetch(url);
    
    if (!response.ok) {
        const errorBody = await response.json();
        const errorMessage = errorBody.error?.message || `HTTP error! status: ${response.status}`;
        throw new Error(errorMessage);
    }
    
    const data = await response.json();
    
    if (!data.items || data.items.length === 0) {
        return JSON.stringify({ songs: [] });
    }

    const songs = data.items.map((item: any) => {
        const rawTitle = item.snippet.title;
        // Basic decoding of common HTML entities found in YouTube titles
        const decodedTitle = rawTitle
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>');

        // Heuristic to split common "Artist - Title" formats
        const separators = [" - ", " – ", " — ", " : ", " | "];
        let artist = "YouTube Artist";
        let title = decodedTitle;

        for (const sep of separators) {
            if (decodedTitle.includes(sep)) {
                const parts = decodedTitle.split(sep);
                artist = parts[0].trim();
                title = parts.slice(1).join(sep).trim();
                break;
            }
        }

        // Cleanup: remove common suffixes that clutter the library display
        title = title.replace(/\(?(Karaoke Version|Karaoke|Lower Key|Higher Key|With Lyrics|Lyrics|Instrumental|Official Video|HD|HQ)\)?/gi, "").trim();

        return {
            title: title || decodedTitle,
            artist: artist,
            youtubeId: item.id.videoId
        };
    });

    return JSON.stringify({ songs });
  } catch (error) {
    console.error("Error calling YouTube Search API:", error);
    const message = error instanceof Error ? error.message : "An unknown error occurred.";
    // Providing specific feedback if the API key isn't configured for YouTube
    return JSON.stringify({ error: `YouTube search failed: ${message}. Ensure the YouTube Data API v3 is enabled in your Google Cloud project for this key.` });
  }
}
