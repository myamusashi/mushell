pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ColumnLayout {

    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    spacing: Appearance.spacing.normal

    EthernetCard {}
    WiFiCard {}

    component EthernetCard: StyledRect {
        id: ethernetCard

        Layout.fillWidth: true
        Layout.preferredHeight: 65
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.fillHeight: true
                color: ethernetCard.isConnected ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "settings_ethernet"
                    color: ethernetCard.isConnected ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pointSize: Appearance.fonts.size.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: "Ethernet"
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
                    text: SystemUsage.statusWiredInterface === "connected" ? "Connected" : "Not Connected"
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    component WiFiCard: StyledRect {
        id: wifiCard

        Layout.fillWidth: true
        Layout.preferredHeight: 65
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property var activeNetwork: {
            for (var i = 0; i < Network.networks.length; i++)
            if (Network.networks[i].active)
            return Network.networks[i];

            return null;
        }

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: settings && settings.wifiList.active ? Qt.ArrowCursor : Qt.PointingHandCursor
            enabled: settings && !settings.wifiList.active
            onClicked: {
                if (settings)
                settings.wifiList.active = !settings.wifiList.active;
            }
        }

        function getWiFiIcon(strength) {
            if (strength >= 80)
                return "network_wifi";
            if (strength >= 50)
                return "network_wifi_3_bar";
            if (strength >= 30)
                return "network_wifi_2_bar";
            if (strength >= 15)
                return "network_wifi_1_bar";
            return "signal_wifi_0_bar";
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                color: wifiCard.activeNetwork ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: wifiCard.activeNetwork ? wifiCard.getWiFiIcon(wifiCard.activeNetwork.strength) : "wifi_off"
                    color: wifiCard.activeNetwork ? Colours.m3Colors.m3OnPrimary : Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
                    font.pointSize: Appearance.fonts.size.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Internet"
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledText {
                    text: wifiCard.activeNetwork ? wifiCard.activeNetwork.ssid : "WiFi Disconnected"
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
