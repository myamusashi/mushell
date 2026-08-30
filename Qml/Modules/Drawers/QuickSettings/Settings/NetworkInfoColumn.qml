pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

ColumnLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        EthernetCard {}
        WiFiCard {}
    }

    BluetoothCard {}

    component EthernetCard: StyledRect {
        id: ethernetCard

        Layout.fillWidth: true
        implicitHeight: 70
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
        readonly property bool isConnected: (wiredDevice?.state ?? ConnectionState.Disconnected) === ConnectionState.Connected

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: content && content.ethernet.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.ethernet.isVisible // qmllint disable
            onClicked: {
                if (content) // qmllint disable
                    content.ethernet.isVisible = !content.ethernet.isVisible; // qmllint disable
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.fillHeight: true
                color: ethernetCard.isConnected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    icon: "settings_ethernet"
                    color: ethernetCard.isConnected ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Ethernet")
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.Medium
                        color: Colours.m3Colors.m3OnSurface
                    }

                    StyledText {
                        text: `(${SystemUsage.statusVPNInterface})`
                        visible: SystemUsage.statusVPNInterface !== ""
                        font.pixelSize: Appearance.fonts.size.small
                        color: Colours.m3Colors.m3OnSurface
                    }
                }

                StyledText {
                    text: ethernetCard.isConnected ? qsTr("Connected") : qsTr("Not Connected")
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    component WiFiCard: StyledRect {
        id: wifiCard

        Layout.fillWidth: true
        implicitHeight: 70
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        // Pure declarative bindings — no manual update functions needed
        readonly property WifiDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

        readonly property var connectedNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

        readonly property bool isConnected: Networking.wifiEnabled && (connectedNetwork?.connected ?? false)

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: content && content.wifi.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.wifi.isVisible // qmllint disable
            onClicked: {
                if (content) // qmllint disable
                    content.wifi.isVisible = !content.wifi.isVisible; // qmllint disable
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                color: wifiCard.isConnected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    icon: {
                        if (!wifiCard.isConnected)
                            return "wifi_off";
                        const s = wifiCard.connectedNetwork.signalStrength;
                        if (s >= 0.8)
                            return "network_wifi";
                        if (s >= 0.5)
                            return "network_wifi_3_bar";
                        if (s >= 0.3)
                            return "network_wifi_2_bar";
                        if (s >= 0.15)
                            return "network_wifi_1_bar";
                        return "signal_wifi_0_bar";
                    }
                    color: wifiCard.isConnected ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: qsTr("Internet")
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledText {
                    text: wifiCard.isConnected ? wifiCard.connectedNetwork.name : qsTr("WiFi Disconnected")
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colours.m3Colors.m3OnSurface
                }
            }
        }
    }
    component BluetoothCard: StyledRect {
        Layout.fillWidth: true
        implicitHeight: 70
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property string cardIconName: BluetoothServices.cardIconName
        readonly property string cardSubtitle: BluetoothServices.cardSubtitle
        readonly property bool hasConnected: BluetoothServices.hasConnected
        readonly property bool isPowered: BluetoothServices.isPowered

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: content && content.bluetooth.isVisible ? Qt.ArrowCursor : Qt.PointingHandCursor // qmllint disable
            enabled: content && !content.bluetooth.isVisible // qmllint disable
            onClicked: {
                if (content) // qmllint disable
                    content.bluetooth.isVisible = !content.bluetooth.isVisible; // qmllint disable
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                color: hasConnected ? Colours.m3Colors.m3Primary : isPowered ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                Icon {
                    type: Icon.Material
                    anchors.centerIn: parent
                    icon: cardIconName
                    color: hasConnected ? Colours.m3Colors.m3OnPrimary : isPowered ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pixelSize: Appearance.fonts.size.extraLarge
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: qsTr("Bluetooth")
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledText {
                    text: cardSubtitle
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colours.m3Colors.m3OnSurface
                }
            }
        }
    }
}
