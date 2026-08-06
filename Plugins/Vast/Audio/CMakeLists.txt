pkg_check_modules(PIPEWIRE REQUIRED IMPORTED_TARGET libpipewire-0.3)

vast_module(vast-audio
    URI Vast.Audio
    SOURCES
        AudioProfilesModel.hpp
        AudioProfilesModel.cpp
        AudioProfilesWatcher.hpp
        AudioProfilesWatcher.cpp
        AudioDevicesModel.hpp
        AudioDevicesModel.cpp
        AudioDevicesWatcher.hpp
        AudioDevicesWatcher.cpp
    LIBRARIES
        PkgConfig::PIPEWIRE
)

target_include_directories(vast-audio SYSTEM PRIVATE ${PIPEWIRE_INCLUDE_DIRS})
target_compile_options(vast-audio PRIVATE ${PIPEWIRE_CFLAGS_OTHER})