find_program(WAYLAND_SCANNER_EXECUTABLE NAMES wayland-scanner REQUIRED)
pkg_check_modules(WAYLAND_CLIENT REQUIRED IMPORTED_TARGET wayland-client)

set(WAYLAND_PROTOCOL_XML ${CMAKE_CURRENT_SOURCE_DIR}/protocols/ext-data-control-v1.xml)
set(WAYLAND_PROTOCOL_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated/wayland)
file(MAKE_DIRECTORY ${WAYLAND_PROTOCOL_GEN_DIR})

add_custom_command(
    OUTPUT ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-protocol.c
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} private-code
            ${WAYLAND_PROTOCOL_XML}
            ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-protocol.c
    DEPENDS ${WAYLAND_PROTOCOL_XML}
    COMMENT "Generating ext-data-control-v1 protocol source"
)

add_custom_command(
    OUTPUT ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-client-protocol.h
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} client-header
            ${WAYLAND_PROTOCOL_XML}
            ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-client-protocol.h
    DEPENDS ${WAYLAND_PROTOCOL_XML}
    COMMENT "Generating ext-data-control-v1 client header"
)

add_library(wayland-ext-data-control STATIC
    ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-protocol.c
    ${WAYLAND_PROTOCOL_GEN_DIR}/ext-data-control-v1-client-protocol.h
)
target_include_directories(wayland-ext-data-control PUBLIC ${WAYLAND_PROTOCOL_GEN_DIR})
target_link_libraries(wayland-ext-data-control PUBLIC PkgConfig::WAYLAND_CLIENT)

vast_module(vast-clipboard
    URI Vast.Clipboard
    PCH_SET large
    SOURCES
        ClipboardEntry.hpp
        ClipboardContentClassifier.hpp
        ClipboardContentClassifier.cpp
        ClipboardPreviewCache.hpp
        ClipboardPreviewCache.cpp
        ClipboardDatabase.hpp
        ClipboardDatabase.cpp
        ClipboardModel.hpp
        ClipboardModel.cpp
        ClipboardManager.hpp
        ClipboardManager.cpp
        LoopbackGuard.hpp
        LoopbackGuard.cpp
        WaylandDataControl.hpp
        WaylandDataControl.cpp
    LIBRARIES
        Qt::Sql
        wayland-ext-data-control
        vast-core
)
