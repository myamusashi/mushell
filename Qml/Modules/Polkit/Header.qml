import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    implicitWidth: parent.width
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        Layout.topMargin: 8
        radius: Appearance.rounding.full
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)

        IconImage {
            id: appIcon

            anchors.centerIn: parent
            width: 40
            height: 40
            asynchronous: true
            source: Quickshell.iconPath(PolAgent.agent?.flow?.iconName) || "" // qmllint disable
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: qsTr("Authentication Is Required")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: PolAgent.agent?.flow?.message || qsTr("<no message>") // qmllint disable
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
