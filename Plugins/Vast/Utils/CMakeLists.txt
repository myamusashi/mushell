vast_module(vast-utils
    URI Vast.Utils
    PCH_SET large
    SOURCES
        ColorMaterial.hpp
        ColorMaterial.cpp
        ColorUtils.cpp
        ColorUtils.hpp
        PaletteAnimator.cpp
        PaletteAnimator.hpp
        Utils.hpp
        Utils.cpp
    LIBRARIES
        material-color-utilities
        vast-materialcolor
        vast-jobs
)
