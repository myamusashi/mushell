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
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        radius: Appearance.rounding.full
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)

        IconImage {
            anchors.centerIn: parent
            width: 28
            height: 28
            asynchronous: true
            source: PolAgent.agent?.flow?.iconName ? Quickshell.iconPath(PolAgent.agent.flow.iconName) : "" // qmllint disable
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Authentication Is Required")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.size.larger
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.fillWidth: true
            text: PolAgent.agent?.flow?.message || qsTr("<no message>") // qmllint disable
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
