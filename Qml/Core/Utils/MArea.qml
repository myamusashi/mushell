import AnotherRipple
import QtQuick

import qs.Core.Configs
import qs.Services
import qs.Components.Base

MouseArea {
    id: area

    anchors.fill: parent

    property alias layerRect: layer
    property alias layerColor: layer.color
    property alias layerRadius: layer.radius

    property real clickOpacity: 0.2
    property real hoverOpacity: 0.08
    property Animation layerOpacityAnimation: SpringAnimation {
        spring: 2
        damping: 0.3
    }

    hoverEnabled: true
    onContainsMouseChanged: layer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
    onContainsPressChanged: layer.opacity = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

    StyledRect {
        id: layer

        anchors.fill: parent
        color: Colours.m3Colors.m3Primary
        opacity: 0
        clip: true

        Behavior on opacity {
            animation: area.layerOpacityAnimation
        }

        SimpleRipple {
            anchors.fill: parent
            acceptEvent: false
            color: Colours.m3Colors.m3OnSurface
            xClipRadius: layer.radius
            yClipRadius: layer.radius
        }
    }

    Component.onCompleted: {
        if (layer.radius === 0)
            layer.radius = Appearance.rounding.small;
    }
}
