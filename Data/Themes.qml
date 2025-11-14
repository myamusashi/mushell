pragma ComponentBehavior: Bound

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.Data

Singleton {
    id: root

    readonly property var dark: JSON.parse(colorsFile.text()).colors

    FileView {
        id: colorsFile

        path: Paths.home + "/.config/shell/colors.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
    }

    function parseRGBA(color) {
        const values = color.slice(color.indexOf("(") + 1,
                                   color.indexOf(")")).split(",")

        if (values.length === 4) {
            const r = parseInt(values[0].trim(), 10)
            const g = parseInt(values[1].trim(), 10)
            const b = parseInt(values[2].trim(), 10)
            const a = parseFloat(values[3].trim(), 10)

            return `${r},${g},${b},${a}`
        }

        return null
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    component ColorsComponent: QtObject {
        readonly property color background: root.dark.background
        readonly property color error: root.dark.error
        readonly property color error_container: root.dark.error_container
        readonly property color inverse_on_surface: root.dark.inverse_on_surface
        readonly property color inverse_primary: root.dark.inverse_primary
        readonly property color inverse_surface: root.dark.inverse_surface
        readonly property color on_background: root.dark.on_background
        readonly property color on_error: root.dark.on_error
        readonly property color on_error_container: root.dark.on_error_container
        readonly property color on_primary: root.dark.on_primary
        readonly property color on_primary_container: root.dark.on_primary_container
        readonly property color on_primary_fixed: root.dark.on_primary_fixed
        readonly property color on_primary_fixed_variant: root.dark.on_primary_fixed_variant
        readonly property color on_secondary: root.dark.on_secondary
        readonly property color on_secondary_container: root.dark.on_secondary_container
        readonly property color on_secondary_fixed: root.dark.on_secondary_fixed
        readonly property color on_secondary_fixed_variant: root.dark.on_secondary_fixed_variant
        readonly property color on_surface: root.dark.on_surface
        readonly property color on_surface_variant: root.dark.on_surface_variant
        readonly property color on_tertiary: root.dark.on_tertiary
        readonly property color on_tertiary_container: root.dark.on_tertiary_container
        readonly property color on_tertiary_fixed: root.dark.on_tertiary_fixed
        readonly property color on_tertiary_fixed_variant: root.dark.on_tertiary_fixed_variant
        readonly property color outline: root.dark.outline
        readonly property color outline_variant: root.dark.outline_variant
        readonly property color primary: root.dark.primary
        readonly property color primary_container: root.dark.primary_container
        readonly property color primary_fixed: root.dark.primary_fixed
        readonly property color primary_fixed_dim: root.dark.primary_fixed_dim
        readonly property color scrim: root.dark.scrim
        readonly property color secondary: root.dark.secondary
        readonly property color secondary_container: root.dark.secondary_container
        readonly property color secondary_fixed: root.dark.secondary_fixed
        readonly property color secondary_fixed_dim: root.dark.secondary_fixed_dim
        readonly property color shadow: root.dark.shadow
        readonly property color surface: root.dark.surface
        readonly property color surface_bright: root.dark.surface_bright
        readonly property color surface_container: root.dark.surface_container
        readonly property color surface_container_high: root.dark.surface_container_high
        readonly property color surface_container_highest: root.dark.surface_container_highest
        readonly property color surface_container_low: root.dark.surface_container_low
        readonly property color surface_container_lowest: root.dark.surface_container_lowest
        readonly property color surface_dim: root.dark.surface_dim
        readonly property color surface_tint: root.dark.surface_tint
        readonly property color surface_variant: root.dark.surface_variant
        readonly property color tertiary: root.dark.tertiary
        readonly property color tertiary_container: root.dark.tertiary_container
        readonly property color tertiary_fixed: root.dark.tertiary_fixed
        readonly property color tertiary_fixed_dim: root.dark.tertiary_fixed_dim

        readonly property color red: root.dark.error
        readonly property color green: "#63A002"
        readonly property color blue: "#769CDF"
        readonly property color yellow: "#FFDE3F"
    }

    readonly property ColorsComponent colors: ColorsComponent {}
}
