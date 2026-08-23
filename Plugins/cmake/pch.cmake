option(VAST_NO_PCH "Disable precompiled headers" OFF)

if(NOT VAST_NO_PCH)
    file(GENERATE
        OUTPUT ${CMAKE_BINARY_DIR}/pchstub.cpp
        CONTENT "// intentionally empty"
    )
endif()

function(vast_pch arg_TARGET)
    if(VAST_NO_PCH)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 arg "" "SET" "")

    if("${arg_SET}" STREQUAL "")
        set(arg_SET "common")
    endif()

    target_precompile_headers(${arg_TARGET} REUSE_FROM "vast-pchset-${arg_SET}")
endfunction()

function(vast_add_pchset arg_SETNAME)
    if(VAST_NO_PCH)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "HEADERS;DEPENDENCIES")

    set(LIBNAME "vast-pchset-${arg_SETNAME}")

    add_library(${LIBNAME} STATIC EXCLUDE_FROM_ALL ${CMAKE_BINARY_DIR}/pchstub.cpp)
    target_link_libraries(${LIBNAME} PRIVATE ${arg_DEPENDENCIES})
    target_precompile_headers(${LIBNAME} PUBLIC ${arg_HEADERS})
endfunction()

set(VAST_COMMON_PCH_SET
    <algorithm>
    <array>
    <cstdint>
    <memory>
    <span>
    <utility>
    <vector>
    <qbytearray.h>
    <qchar.h>
    <qcontainerfwd.h>
    <qdatetime.h>
    <qdebug.h>
    <qhash.h>
    <qlist.h>
    <qlogging.h>
    <qmetatype.h>
    <qnamespace.h>
    <qobject.h>
    <qstring.h>
    <qtmetamacros.h>
    <qtypes.h>
    <qvariant.h>
    <qqmlintegration.h>
)

set(VAST_LARGE_PCH_SET
    ${VAST_COMMON_PCH_SET}
    <qabstractitemmodel.h>
    <qcolor.h>
    <qdir.h>
    <qfile.h>
    <qiodevice.h>
    <qqmlengine.h>
    <qthreadpool.h>
    <qtimer.h>
)

set(VAST_PCHSET_DEPS
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
)

vast_add_pchset(common
    DEPENDENCIES ${VAST_PCHSET_DEPS}
    HEADERS ${VAST_COMMON_PCH_SET}
)

vast_add_pchset(large
    DEPENDENCIES ${VAST_PCHSET_DEPS}
    HEADERS ${VAST_LARGE_PCH_SET}
)

vast_add_pchset(plugin
    DEPENDENCIES Qt::Core Qt::Qml
    HEADERS
        <qobject.h>
        <qstring.h>
        <qtmetamacros.h>
        <qtypes.h>
        <qqmlintegration.h>
)
