pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Wayland

import qs.Components
import qs.Configs
import qs.Services

StyledRect {
    id: root

    Layout.fillHeight: true
    color: "transparent"
    implicitWidth: windowNameText.contentWidth

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.small
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
    }

    StyledText {
        id: windowNameText

        property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
        readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

        anchors.centerIn: parent
        color: Colours.m3Colors.m3OnBackground
        elide: Text.ElideMiddle
        font.weight: Font.Light
        font.pixelSize: Appearance.fonts.size.large
        horizontalAlignment: Text.AlignHCenter
        text: actWinName.toUpperCase()
    }
}
