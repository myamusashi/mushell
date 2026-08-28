pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    required property var monthNames
    required property int currentMonth
    required property int currentYear
    signal prevClicked
    signal nextClicked
    signal titleClicked

    spacing: Appearance.spacing.normal
    Layout.fillWidth: true
    Layout.preferredHeight: 48

    StyledRect {
        id: prevButton

        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: Appearance.rounding.full
        color: "transparent"

        Icon {
            anchors.centerIn: parent
            icon: "chevron_left"
            font.pixelSize: Appearance.fonts.size.large * 2
            color: Colours.m3Colors.m3OnPrimaryContainer
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.prevClicked()
        }
    }

    StyledText {
        id: headerLabel

        Layout.fillWidth: true
        text: root.monthNames[root.currentMonth] + " " + root.currentYear
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.weight: 600
        color: Colours.m3Colors.m3OnBackground
        font.pixelSize: Appearance.fonts.size.large

        MArea {
            width: headerLabel.contentWidth
            height: headerLabel.contentHeight
            anchors.centerIn: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.titleClicked()
        }
    }

    StyledRect {
        id: nextButton

        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: Appearance.rounding.full
        color: "transparent"

        Icon {
            anchors.centerIn: parent
            icon: "chevron_right"
            font.pixelSize: Appearance.fonts.size.large * 2
            color: Colours.m3Colors.m3Primary
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.nextClicked()
        }
    }
}
