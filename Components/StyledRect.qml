import QtQuick

import qs.Configs

Rectangle {
    color: "transparent"
    radius: Appearance.rounding.normal

    Behavior on color {
        CAnim {}
    }
}
