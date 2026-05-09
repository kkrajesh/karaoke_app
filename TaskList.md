- [] UI Improvements
    - [] Host Screen
        - [x] Need to make this is a single page with no scrolling. Use small cards to stack the content. Reduce the size of all the elements to fit on one page, espcially the video player.
        - [x] Add an option to expand/popup all cards to get more real estate to work in and then close.
        - [x] Move "Live Reactions" to be an overlay on top of the "Now Playing" video player and stack text reactions like playing cards.
        - [x] Update "Debug Metadata" to make paths and URLs clickable.
        - [x] Add ability to re-order the upcoming songs list and move a song up or down the list.
        - [x] Add ability to delete a song from the upcoming songs list.
        - [x] Add ability to call back a past singer to sing again
        - [x] Add ability to undo delete song and call back singer
        - [x] change the timers to 1, 3 , 5 & custom timer with associated small messages.
        - [] ability to add couple of tags to the current song and capture the same in the google sheets. 1. Star to indicate it is good Karaoke 2. Todo indicator to mark the song to the perromance list.
        - [x] Add the option to quicky flip the host screen to other dashboards - audience, singer, display and quick polls dashboard.
    - [] Song Library
        - [x] make the previews open in a popup instead of expanding, but give an option for expanding the popup.
        - [x] for non-loal files give an option to preview it in browser directly


    - [] Public Display
        - [x] Add real-time QR code to join the event that is displayed on the screen.
    - [] Singer Display
        - [x] ability to add a second singer for a duet
        - [x] ability to swap singers for a duet

    - [] audience display
        - [x] make the Audience reaction section a reusable component and make it available in host and singer pages 
        - [x] when requesting song ask for their name as well, prefill it if they already supplied when the started. Make the same info available to the host request queue
    

    - [] Starting Page
        - [x] make two different start up pages - one for the host and other for attendees
        - [x] Make the "Start or connect" section to inside the host dashboard configuration section and remove it from the starting page
        - [x] add a new section to the host configuration section to allow easy startup with custom configuration. This will include event name, QR code for event id etc
        - [x] another start page for the singers and audience with just the Join QR code and the name entry.
        - [x] Give an option to connect to an existing event - either by scanning the QR code or by entering the event id.
        - [x] Capture additional contact information (Phone, Email, Instagram) from singers on the sign-in page.
        - [x] Combine role choice and join party buttons into single action buttons on the home screen.
       

- [] Smule (Blocked by Cloudflare - Requires Headless Browser proxy / Option 3)
    - [] Add smule searching and make available for the singers to select and add to queue
    - [] Add smule to the list of sources for the public display
    - [] Display smule performance on public display and audience display
    - [] ability to preview smule songs before adding to queue
    - [] ability to search smule performances by username   

- [] Settings Page
    - [x] add a settings page to configure the smule API
    - [] add a settings page to configure the mediaMonkey DB path
    - [] add a settings page to configure the Google Sheets API
    - [] add a settings page to configure the Webhook URL
    - [] add a settings page to configure the Public Display
    - [] add a settings page to configure the Audience Display
    - [] add a settings page to configure the Chat Display
    - [] add a settings page to configure the Emoji Reactions
    - [] add a settings page to configure the AI Teleprompter
    - [] add a settings page to configure the AI Song Trivia
    - [] add a settings page to configure the AI Word Cloud 
    - [] add a settings page to configure the AI to generate song trivia and fun facts for current song

- [] Google Sheet Logging
    - [] Add ability to see the last time a song was sung and when it was sung.
    - [] Add ability to see the last time a singer sang and when they sang.
    - [] Log the text reactions received during the performance in a separate tab
    - [] Log the word cloud generated during the performance in a separate tab
    - [] Log the trivia generated during the performance in a separate tab
    - [x] add the right prefix for the youtube link for song URL
    

- Bug Fixes
    - [x] Fix the issue where the public display is not updating when the current song changes
    - [x] Song Library/in general the scrolling is not working with my laptop touchpad two finger scroll. (used to work before.)

    
- [x] Please update all MD files with relevant information
- [x] Please check in all the changes to git with a minor version number update and release notes