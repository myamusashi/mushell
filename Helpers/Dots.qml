import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components
import qs.Configs

RowLayout {
    id: root

    anchors.centerIn: parent

    property alias icon: icon
    property alias text: text
    height: parent.height ? parent.height : 1

    WrapperItem {
        id: iconContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: icon.width
        implicitHeight: icon.height

        StyledText {
            id: icon

            font.family: Appearance.fonts.family.material
            font.pixelSize: Appearance.fonts.size.medium
        }
    }

    WrapperItem {
        id: textContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: text.width
        implicitHeight: text.height

        StyledText {
            id: text

            font.family: Appearance.fonts.family.mono
            font.pixelSize: Appearance.fonts.size.small
        }
    }
}
