import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Components

RowLayout {
    id: root

    property alias icon: icon
    property alias text: text
    anchors.centerIn: parent
    height: parent.height ? parent.height : 1

    Item {
        id: iconContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: icon.width
        implicitHeight: icon.height

        StyledText {
            id: icon

            anchors.centerIn: parent
            font.family: Appearance.fonts.familyMaterial
            font.pixelSize: Appearance.fonts.medium
        }
    }

    Item {
        id: textContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: text.width
        implicitHeight: text.height

        StyledText {
            id: text

            anchors.centerIn: parent
            font.family: Appearance.fonts.familyMono
            font.pixelSize: Appearance.fonts.small
        }
    }
}
