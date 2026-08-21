add_library(vast-materialcolor STATIC
    MaterialRoles.hpp
    MaterialRoles.cpp
    MaterialPalette.hpp
    MaterialTemperatureCache.hpp
    MaterialTemperatureCache.cpp
    ImageQuantizer.hpp
    ImageQuantizer.cpp
    PaletteBuilder.hpp
    PaletteBuilder.cpp
    PaletteValidation.hpp
    PaletteValidation.cpp
)

target_include_directories(vast-materialcolor PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(vast-materialcolor PUBLIC
    material-color-utilities
    Qt6::Core
    Qt6::Gui
)
