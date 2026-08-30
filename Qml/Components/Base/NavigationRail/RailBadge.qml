import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    property string text: ""
    property bool dot: false

    readonly property bool hasBadge: text !== "" || dot

    visible: hasBadge
    implicitWidth: text !== "" ? Math.max(16, badgeText.implicitWidth + 8) : 8
    implicitHeight: text !== "" ? 16 : 8

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
