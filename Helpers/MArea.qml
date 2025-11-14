import QtQuick

import qs.Data
import qs.Components

MouseArea {
    id: area

    property real clickOpacity: 0.2
    property real hoverOpacity: 0.08
    property color layerColor: Themes.colors.primary
    property NumberAnimation layerOpacityAnimation: NumbAnim {}
    property int layerRadius: parent?.radius ?? Appearance.rounding.small
    property alias layerRect: layer

    anchors.fill: parent
    hoverEnabled: true

    onContainsMouseChanged: layer.opacity = (area.containsMouse) ? area.hoverOpacity : 0
    onContainsPressChanged: layer.opacity
                            = (area.containsPress) ? area.clickOpacity : area.hoverOpacity

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
