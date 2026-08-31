pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell.Widgets
import Quickshell.Bluetooth

import qs.Components.Base
import qs.Components.Button
import qs.Components.Feedback
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    pageTitle: qsTr("Bluetooth")

    SettingsCard {
        title: qsTr("Adapter")

        StyledText {
            visible: !BluetoothServices.adapterAvailable
            text: qsTr("No Bluetooth adapter found. Ensure Bluetooth hardware is present and BlueZ is running.")
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.normal
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        SettingRow {
            visible: BluetoothServices.adapterAvailable
            label: qsTr("Enable Bluetooth:")
            description: qsTr("Turn the Bluetooth adapter on or off.")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
                checked: BluetoothServices.adapterEnabled
                onToggled: BluetoothServices.setEnabled(checked)
            }
        }

        StyledText {
            visible: BluetoothServices.adapterBlocked
            text: qsTr("Adapter is blocked by rfkill. Unblock it with: rfkill unblock bluetooth")
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.normal
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        StyledText {
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapter && BluetoothServices.adapter.state === BluetoothAdapterState.Enabling // qmllint disable
            text: qsTr("Enabling…")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        StyledText {
            visible: BluetoothServices.adapterAvailable && BluetoothServices.adapter && BluetoothServices.adapter.state === BluetoothAdapterState.Disabling // qmllint disable
            text: qsTr("Disabling…")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        GridLayout {
            columns: 2
            columnSpacing: Appearance.spacing.normal

            SettingRow {
                visible: BluetoothServices.adapterAvailable
                label: qsTr("Adapter")
                description: qsTr("Local Bluetooth adapter.")

                StyledText {
                    text: {
                        if (!BluetoothServices.adapter)
                            return "—";
                        const id = BluetoothServices.adapter.adapterId || "";
                        const name = BluetoothServices.adapter.name || "";
                        if (name && id)
                            return `${name} (${id})`;
                        return name || id || "—";
                    }
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    elide: Text.ElideRight
                    Layout.maximumWidth: 320
                }
            }

            SettingRow {
                visible: BluetoothServices.adapterAvailable
                label: qsTr("Address")
                description: qsTr("Bluetooth device address.")

                StyledText {
                    text: BluetoothServices.adapter ? BluetoothServices.adapter.dbusPath : "—"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: 320
                }
            }

            SettingRow {
                visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled
                label: qsTr("Discoverable:")
                description: qsTr("Allow nearby devices to discover this machine.")

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: BluetoothServices.discoverable
                    onToggled: BluetoothServices.setDiscoverable(checked)
                }
            }

            SettingRow {
                visible: BluetoothServices.adapterAvailable && BluetoothServices.adapterEnabled
                label: qsTr("Pairable:")
                description: qsTr("Allow nearby devices to request pairing.")

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: BluetoothServices.pairable
                    onToggled: BluetoothServices.setPairable(checked)
                }
            }
        }

        Progress {
            Layout.fillWidth: true
            condition: BluetoothServices.isDiscovering
        }
    }

    SettingsCard {
        title: qsTr("Paired devices")
        visible: BluetoothServices.adapterEnabled

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                visible: pairedRepeater.count === 0
                text: qsTr("No paired devices")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                id: pairedRepeater

                model: BluetoothServices.pairedDevices

                delegate: WrapperRectangle {
                    id: pairedDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    radius: Appearance.rounding.large
                    margin: Appearance.margin.small
                    color: modelData.connected ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                    border.width: modelData.connected ? 1 : 0
                    border.color: Colours.m3Colors.m3OutlineVariant

                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Appearance.margin.small
                        }
                        spacing: Appearance.spacing.small

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: Appearance.rounding.small
                            color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

                            Icon {
                                anchors.centerIn: parent
                                icon: pairedDelegate.modelData.connected ? "bluetooth_connected" : "bluetooth"
                                color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: BluetoothServices.displayName(pairedDelegate.modelData)
                                elide: Text.ElideRight
                                color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: BluetoothServices.stateString(pairedDelegate.modelData)
                                color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                            }

                            StyledText {
                                visible: pairedDelegate.modelData.address !== ""
                                text: pairedDelegate.modelData.address + (pairedDelegate.modelData.batteryAvailable ? ` · ${Math.round(pairedDelegate.modelData.battery * 100)}%` : "") + (pairedDelegate.modelData.blocked ? " · " + qsTr("blocked") : "")
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        FloatingButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: pairedDelegate.modelData.connected ? "link_off" : "link"
                            color: "transparent"
                            onClicked: pairedDelegate.modelData.connected ? pairedDelegate.modelData.disconnect() : pairedDelegate.modelData.connect()
                        }

                        FloatingButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: "block"
                            icon.color: pairedDelegate.modelData.blocked ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
                            color: "transparent"
                            onClicked: pairedDelegate.modelData.blocked = !pairedDelegate.modelData.blocked
                        }

                        FloatingButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: "delete"
                            color: "transparent"
                            onClicked: pairedDelegate.modelData.forget()
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: ""
        visible: BluetoothServices.adapterEnabled

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Available devices")
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }

            FloatingButton {
                implicitWidth: 32
                implicitHeight: 32
                backgroundRadius: Appearance.rounding.small
                enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
                spinning: BluetoothServices.isDiscovering
                icon.name: "refresh"
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                color: "transparent"
                onClicked: {
                    if (BluetoothServices.isDiscovering)
                        BluetoothServices.setDiscovering(false);
                    else
                        BluetoothServices.setDiscovering(true);
                }
            }
        }

        ColumnLayout {

            StyledText {
                visible: availableRepeater.count === 0 && !BluetoothServices.isDiscovering
                text: qsTr("No devices found — turn on scanning to discover nearby devices.")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            StyledText {
                visible: availableRepeater.count === 0 && BluetoothServices.isDiscovering
                text: qsTr("Searching for devices…")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                id: availableRepeater

                model: BluetoothServices.availableDevices

                delegate: WrapperRectangle {
                    id: availDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    radius: Appearance.rounding.large
                    margin: Appearance.margin.small
                    color: availDelegate.modelData.pairing ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                    border.width: availDelegate.modelData.pairing ? 1 : 0
                    border.color: Colours.m3Colors.m3OutlineVariant

                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: Appearance.margin.small
                        }
                        spacing: Appearance.spacing.small

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: Appearance.rounding.small
                            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

                            Icon {
                                anchors.centerIn: parent
                                icon: availDelegate.modelData.pairing ? "bluetooth_searching" : "bluetooth"
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: BluetoothServices.displayName(availDelegate.modelData)
                                elide: Text.ElideRight
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: BluetoothServices.addressLine(availDelegate.modelData)
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        FloatingButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: "bluetooth"
                            color: "transparent"
                            enabled: !availDelegate.modelData.pairing
                            onClicked: availDelegate.modelData.pair()
                        }

                        FloatingButton {
                            visible: availDelegate.modelData.pairing
                            implicitWidth: 32
                            implicitHeight: 32
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: "close"
                            color: "transparent"
                            onClicked: availDelegate.modelData.cancelPair()
                        }
                    }
                }
            }
        }
    }
}
