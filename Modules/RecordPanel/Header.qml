import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    required property string icon
    required property string text
    required property bool condition

    Layout.fillWidth: true
    Layout.preferredHeight: 50

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        MaterialIcon {
            icon: root.icon
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
        }

        StyledText {
            text: root.text
            color: Colours.m3Colors.m3OnSurface
            font.weight: Font.DemiBold
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        Item {
            Layout.fillWidth: true
        }

        MaterialIcon {
            icon: "close"
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge

            MArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: Qt.PointingHandCursor
                onClicked: root.condition = !root.condition
            }
        }
    }
}
