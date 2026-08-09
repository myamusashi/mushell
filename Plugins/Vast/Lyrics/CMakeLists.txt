vast_module(vast-lyrics
    URI Vast.Lyrics
    SOURCES
        LyricsProvider.hpp
        LyricsProvider.cpp
        LrcParser.hpp
        LrcParser.cpp
        LyricsCache.hpp
        LyricsCache.cpp
        LyricsScheduler.hpp
        LyricsScheduler.cpp
    LIBRARIES
        Qt::Gui
        Qt::Network
)