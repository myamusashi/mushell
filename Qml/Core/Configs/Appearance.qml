pragma Singleton

import Quickshell

// Yoink this from Caelestia
Singleton {
    id: root

    // qmllint disable
    property AppearanceConfig.AnimationsComponent animations: Configs.appearance.animations
    property AppearanceConfig.FontsComponent fonts: Configs.appearance.fonts
    property AppearanceConfig.RoundingComponent rounding: Configs.appearance.rounding
    property AppearanceConfig.MarginComponent margin: Configs.appearance.margin
    property AppearanceConfig.PaddingComponent padding: Configs.appearance.padding
    property AppearanceConfig.SpacingComponent spacing: Configs.appearance.spacing
    // qmllint enable
}
