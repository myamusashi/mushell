import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

RowLayout {
    id: root

    property alias icon: icon
    property alias text: text

    anchors.centerIn: parent
    height: parent.height ? parent.height : 1

    Item {
        id: iconContainer

        Layout.fillHeight: true
        implicitWidth: icon.width

        StyledText {
            id: icon

            anchors.centerIn: parent
            font.family: Appearance.fonts.family_Material
            font.pixelSize: Appearance.fonts.medium
        }
    }

    Item {
        id: textContainer

        Layout.fillHeight: true
        implicitWidth: text.width

        StyledText {
            id: text

            anchors.centerIn: parent
            font.family: Appearance.fonts.family_Mono
            font.pixelSize: Appearance.fonts.small
        }
    }
}
