pkg_check_modules(DDCUTIL REQUIRED IMPORTED_TARGET ddcutil)

vast_module(vast-brightness
    URI Vast.Brightness
    SOURCES
        BrightnessManager.hpp
        BrightnessManager.cpp
    LIBRARIES
        PkgConfig::DDCUTIL
)

target_include_directories(vast-brightness SYSTEM PRIVATE ${DDCUTIL_INCLUDE_DIRS})
target_compile_options(vast-brightness PRIVATE ${DDCUTIL_CFLAGS_OTHER})