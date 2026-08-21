# The Vast namespace core module. Shared utilities that are used by multiple
# modules live here (e.g. FuzzyMatcher, used by both Vast.Search and
# Vast.Clipboard).

vast_module(vast-core
    URI Vast
    SOURCES
        FuzzyMatcher.hpp
        FuzzyMatcher.cpp
    LIBRARIES
        Qt::Gui
)

add_subdirectory(Audio)
add_subdirectory(Brightness)
add_subdirectory(Clipboard)
add_subdirectory(ImageCache)
add_subdirectory(Keylock)
add_subdirectory(Lyrics)
add_subdirectory(MaterialColor)
add_subdirectory(Search)
add_subdirectory(Translation)
add_subdirectory(Utils)
