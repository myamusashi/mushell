import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    implicitWidth: timeContainer.width + 15
    implicitHeight: parent.height
    color: "transparent"
    radius: Appearance.rounding.small

    Dots {
        id: timeContainer

        Icon {
            id: icon
            type: Icon.Material

            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pointSize: Appearance.fonts.size.large
            icon: "schedule"
        }

        StyledText {
            id: text

            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.size.medium
            text: Qt.formatDateTime(Time?.date, "h:mm AP")
        }
    }
    MArea {
        id: mArea

        anchors.fill: timeContainer
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.isCalendarOpen = !GlobalStates.isCalendarOpen
    }
}
