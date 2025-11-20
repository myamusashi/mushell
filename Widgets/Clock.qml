import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Components
import qs.Modules.Calendar

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    // color: Themes.colors.withAlpha(Themes.m3Colors.background, 0.79)
    implicitWidth: timeContainer.width + 15
    radius: Appearance.rounding.small

    Dots {
        id: timeContainer

        MaterialIcon {
            id: icon

            color: Themes.m3Colors.onBackground
            font.bold: true
            font.pointSize: Appearance.fonts.large
            icon: "schedule"
        }

        StyledText {
            id: text

            color: Themes.m3Colors.onBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.medium
            text: Qt.formatDateTime(Time?.date, "h:mm AP")
        }
    }
    MArea {
        id: mArea

        anchors.fill: timeContainer
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cal.isCalendarShow = !cal.isCalendarShow
    }

    Calendar {
        id: cal
    }
}
