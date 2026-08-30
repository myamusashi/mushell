pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

ColumnLayout {
    id: root

    required property bool isVisible

    spacing: Appearance.spacing.small

    Progress {
        Layout.fillWidth: true
        condition: BluetoothServices.isDiscovering && root.isVisible
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: qsTr("Bluetooth")
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 32
            enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
            checked: BluetoothServices.adapterEnabled
            onToggled: BluetoothServices.setEnabled(checked)
        }
    }

    RowLayout {
        visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled
        Layout.fillWidth: true

        StyledText {
            text: qsTr("Discoverable")
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 32
            checked: BluetoothServices.discoverable
            onToggled: BluetoothServices.setDiscoverable(checked)
        }
    }
}
