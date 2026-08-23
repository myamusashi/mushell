# Thin CMake wrapper for the vendored fzy submodule.
# Upstream (github.com/jhawthorn/fzy) builds via autoconf/Makefile and expects
# a generated "config.h"; we provide one on the include path instead of
# configuring the vendored tree, keeping it pristine. Only the scoring core
# (src/match.c + src/bonus.h) is compiled; TTY/CLI parts are excluded.

set(FZY_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../fzy")

add_library(fzy_core STATIC
    "${FZY_ROOT}/src/match.c"
)

# match.h/bonus.h are included by name from src/.
target_include_directories(fzy_core SYSTEM PUBLIC "${FZY_ROOT}/src")

# match.c and bonus.h both include "../config.h", which upstream generates
# from src/config.def.h via autoconf. Mirror that layout in the build dir so
# the quoted "../config.h" resolves against an -I entry without touching the
# source tree: the extra "nested" segment makes "<dir>/../config.h" land on
# gen/config.h.
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/gen/nested")
configure_file("${FZY_ROOT}/src/config.def.h" "${CMAKE_CURRENT_BINARY_DIR}/gen/config.h" COPYONLY)
target_include_directories(fzy_core PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/gen/nested")

target_compile_features(fzy_core PUBLIC c_std_99)

# Vendored code is not held to this project's strict warning flags.
target_compile_options(fzy_core PRIVATE -w)
