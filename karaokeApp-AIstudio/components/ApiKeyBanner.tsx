import React from 'react';

const ApiKeyBanner = () => {
  // process.env.API_KEY is checked. If it's undefined, null, or an empty string, the banner will show.
  if (process.env.API_KEY) {
    return null;
  }

  return (
    <div className="bg-yellow-500 border-l-4 border-yellow-700 text-yellow-900 p-4 rounded-md my-6" role="alert">
      <p className="font-bold">Configuration Notice: API Key Missing</p>
      <p className="mt-1">
        To enable AI-powered features like song suggestions and YouTube search, a Google Gemini API key is required.
      </p>
      <p className="mt-2 text-sm">
        Please add your API key as a secret named <code className="bg-yellow-200 text-yellow-900 font-mono py-0.5 px-1 rounded">API_KEY</code> in your environment settings.
      </p>
    </div>
  );
};

export default ApiKeyBanner;
