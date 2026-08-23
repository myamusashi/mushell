vast_module(vast-search
    URI Vast.Search
    SOURCES
        DirectoryWalker.hpp
        DirectoryWalker.cpp
        FileSearchModel.hpp
        FileSearchModel.cpp
        LaunchHistoryStore.hpp
        LaunchHistoryStore.cpp
        SearchEngine.hpp
        SearchEngine.cpp
    LIBRARIES
        Qt::Gui
        Qt6::Concurrent
        vast-core
)
