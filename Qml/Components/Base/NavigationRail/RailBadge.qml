import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

// Numeric/short-text badge (e.g. "3") or a plain unread dot.
// text takes priority over dot if both are set. Renders nothing if neither is set.
Item {
    id: root

    property string text: ""
    property bool dot: false

    readonly property bool hasBadge: root.text !== "" || root.dot

    visible: root.hasBadge
    implicitWidth: root.text !== "" ? Math.max(16, badgeText.implicitWidth + 8) : 8
    implicitHeight: root.text !== "" ? 16 : 8

    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: Colours.m3Colors.m3Error

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            visible: root.text !== ""
            text: root.text
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnError
        }
    }
}
