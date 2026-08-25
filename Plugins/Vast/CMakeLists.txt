vast_module(vast-core
    URI Vast
    SOURCES
        FuzzyCore.hpp
        FuzzyCore.cpp
        FuzzyMatcher.hpp
        FuzzyMatcher.cpp
    LIBRARIES
        Qt::Gui
        fzy_core
)

add_subdirectory(Jobs)
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
