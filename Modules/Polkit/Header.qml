import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Services

RowLayout {
    implicitWidth: parent.width
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        Layout.topMargin: 8
        radius: Appearance.rounding.full
        color: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.12)

        IconImage {
            id: appIcon

            anchors.centerIn: parent
            width: 40
            height: 40
            asynchronous: true
            source: Quickshell.iconPath(PolAgent.agent?.flow?.iconName) || ""
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledLabel {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: "Authentication Is Required"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.extraLarge
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledLabel {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: PolAgent.agent?.flow?.message || "<no message>"
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fonts.large
            font.weight: Font.Normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
