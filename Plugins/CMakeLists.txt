cmake_minimum_required(VERSION 3.22)
project(VastPlugins VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

find_package(Qt6 6.3 REQUIRED COMPONENTS Core Gui Qml Quick Network Sql Concurrent)
qt_policy(SET QTP0001 NEW)
find_package(PkgConfig REQUIRED)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture)
endif()

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

if(NOT DEFINED INSTALL_QMLDIR)
    execute_process(
        COMMAND ${QT_QMAKE_EXECUTABLE} -query QML2_IMPORT_PATH
        OUTPUT_VARIABLE QT_QML_IMPORT_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(QT_QML_IMPORT_PATH)
        file(RELATIVE_PATH QML_REL_PATH "/" "${QT_QML_IMPORT_PATH}")
        set(INSTALL_QMLDIR "${QML_REL_PATH}")
    else()
        set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml")
    endif()
endif()
message(STATUS "QML install dir: ${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}")

include(cmake/qml-module.cmake)

add_subdirectory(third_party/mcu)
add_subdirectory(third_party/fzy-wrapper)
add_subdirectory(Vast)