pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property real contentHeight: 44

    implicitWidth: doneRowLayout.implicitWidth
    implicitHeight: contentHeight

    RowLayout {
        id: doneRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        ExtendedFloatingButton {
            text: root.island.transferSuccess ? qsTr("Sent to %1").arg(root.island.selectedDevice?.name ?? "") : qsTr("Transfer cancelled")
            icon.name: root.island.transferSuccess ? "check_circle" : "error"
            icon.color: root.island.transferSuccess ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Error
            icon.size: Appearance.fonts.size.extraLarge
            textColor: Colours.m3Colors.m3OnSurface
            color: "transparent"
            onClicked: {}
        }
    }
}
