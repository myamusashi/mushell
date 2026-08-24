pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

WrapperRectangle {
    id: root

    property bool isVisible: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool isConnected: (wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected
    readonly property var wiredNetwork: wiredDevice?.network ?? null // qmllint disable

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min(loader.implicitHeight + 20 * 2, parent.height * 0.8)
    margin: Appearance.margin.normal
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: loader

        active: true
        asynchronous: true
        sourceComponent: ColumnLayout {
            width: loader.width
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Ethernet")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: root.wiredDevice ? ConnectionState.toString(root.wiredDevice.state) : qsTr("No wired device")
                color: root.isConnected ? Colours.m3Colors.m3Green : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                font.weight: Font.DemiBold
            }

            InfoRow {
                visible: root.wiredDevice
                label: qsTr("Interface")
                value: root.wiredDevice?.name ?? "—"
            }

            InfoRow {
                visible: root.wiredDevice
                label: qsTr("Link speed")
                value: root.wiredDevice?.hasLink ? `${root.wiredDevice.linkSpeed} Mbps` : "—"
            }

            InfoRow {
                visible: root.wiredDevice
                label: qsTr("Hardware address")
                value: root.wiredDevice?.address ?? "—"
            }

            RowLayout {
                visible: root.wiredDevice
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Autoconnect")
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: root.wiredDevice?.autoconnect ?? false
                    onToggled: Qt.callLater(() => {
                        if (root.wiredDevice)
                            root.wiredDevice.autoconnect = checked;
                    })
                }
            }

            RowLayout {
                visible: root.wiredDevice && (root.wiredDevice.hasLink || root.wiredDevice.connected)
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.small * 0.5

                ExtendedFloatingButton {
                    Layout.fillWidth: true
                    visible: !root.isConnected
                    text: qsTr("Connect")
                    color: Colours.m3Colors.m3Primary
                    textColor: Colours.m3Colors.m3OnPrimary
                    onClicked: root.wiredNetwork?.connect()
                }

                ExtendedFloatingButton {
                    Layout.fillWidth: true
                    visible: root.isConnected
                    text: qsTr("Disconnect")
                    color: Colours.m3Colors.m3Primary
                    textColor: Colours.m3Colors.m3OnPrimary
                    onClicked: root.wiredNetwork?.disconnect()
                }
            }
        }
    }

    component InfoRow: RowLayout {
        id: infoRow

        required property string label
        required property string value

        Layout.fillWidth: true

        StyledText {
            text: infoRow.label
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: infoRow.value
            elide: Text.ElideRight
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
        }
    }
}
