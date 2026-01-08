import QtQuick

import qs.Components
import qs.Configs
import qs.Services

MouseArea {
    id: area

    anchors.fill: parent

    property alias layerRect: layer

    property real clickOpacity: 0.2
    property real hoverOpacity: 0.08
    property color layerColor: Colours.m3Colors.m3Primary
    property NumberAnimation layerOpacityAnimation: NAnim {}
    property int layerRadius: parent?.radius ?? Appearance.rounding.small

    hoverEnabled: true
    onContainsMouseChanged: layer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
    onContainsPressChanged: layer.opacity = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

    StyledRect {
        id: layer

        anchors.fill: parent
        color: area.layerColor
        opacity: 0
        radius: area.layerRadius

        Behavior on opacity {
            animation: area.layerOpacityAnimation
        }
    }
}
