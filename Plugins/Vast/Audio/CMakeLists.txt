pkg_check_modules(PIPEWIRE REQUIRED IMPORTED_TARGET libpipewire-0.3)

# PkgConfig::PIPEWIRE adds -fno-strict-aliasing/-fno-strict-overflow to this
# target only, which would invalidate reuse of the shared pchsets.
vast_add_pchset(audio
    DEPENDENCIES ${VAST_PCHSET_DEPS} PkgConfig::PIPEWIRE
    HEADERS ${VAST_LARGE_PCH_SET}
)

vast_module(vast-audio
    URI Vast.Audio
    PCH_SET audio
    SOURCES
        AudioProfilesModel.hpp
        AudioProfilesModel.cpp
        AudioProfilesWatcher.hpp
        AudioProfilesWatcher.cpp
        AudioDevicesModel.hpp
        AudioDevicesModel.cpp
        AudioDevicesWatcher.hpp
        AudioDevicesWatcher.cpp
        AudioCard.hpp
        AudioCard.cpp
        AudioCardsModel.hpp
        AudioCardsModel.cpp
    LIBRARIES
        PkgConfig::PIPEWIRE
)

target_include_directories(vast-audio SYSTEM PRIVATE ${PIPEWIRE_INCLUDE_DIRS})
target_compile_options(vast-audio PRIVATE ${PIPEWIRE_CFLAGS_OTHER})
