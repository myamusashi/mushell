pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    spacing: Appearance.spacing.small

    StyledText {
        Layout.alignment: Qt.AlignCenter
        text: qsTr("Bluetooth")
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large * 1.5
        font.weight: Font.DemiBold
    }

    StyledText {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: BluetoothServices.headerSubtitle
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
    }
}
