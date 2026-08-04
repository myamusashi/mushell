pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    required property var island
    required property bool active

    implicitWidth: doneRowLayout.implicitWidth + 32
    implicitHeight: 44
    spacing: Appearance.spacing.normal

    RowLayout {
        id: doneRowLayout

        spacing: Appearance.spacing.normal
        visible: root.active

        Icon {
            icon: root.island.transferSuccess ? "check_circle" : "error"
            font.pixelSize: Appearance.fonts.size.large
            color: root.island.transferSuccess ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Error
        }

        StyledText {
            text: root.island.transferSuccess ? qsTr("Sent to %1").arg(root.island.selectedDevice?.name ?? "") : qsTr("Transfer cancelled")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
