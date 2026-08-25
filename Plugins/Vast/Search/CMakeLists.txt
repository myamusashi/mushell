vast_module(vast-search
    URI Vast.Search
    PCH_SET large
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
        vast-jobs
        vast-core
)
