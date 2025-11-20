pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ColumnLayout {

    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    spacing: Appearance.spacing.normal

    EthernetCard {}
    WiFiCard {}

    component EthernetCard: StyledRect {
        id: ethernetCard

        Layout.fillWidth: true
        Layout.preferredHeight: 65
        color: Themes.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 50
                Layout.fillHeight: true
                color: ethernetCard.isConnected ? Themes.m3Colors.m3Primary : Themes.withAlpha(Themes.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: "settings_ethernet"
                    color: ethernetCard.isConnected ? Themes.m3Colors.m3OnPrimary : Themes.withAlpha(Themes.m3Colors.m3OnSurface, 0.38)
                    font.pointSize: Appearance.fonts.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: "Ethernet"
                        font.pixelSize: Appearance.fonts.large
                        font.weight: Font.Medium
                        color: Themes.m3Colors.m3OnSurface
                    }

                    StyledText {
                        text: `(${SystemUsage.statusVPNInterface})`
                        visible: SystemUsage.statusVPNInterface !== ""
                        font.pixelSize: Appearance.fonts.small
                        color: Themes.m3Colors.m3OnSurface
                    }
                }

                StyledText {
                    text: SystemUsage.statusWiredInterface === "connected" ? "Connected" : "Not Connected"
                    font.pixelSize: Appearance.fonts.normal
                    color: Themes.m3Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    component WiFiCard: StyledRect {
        id: wifiCard

        Layout.fillWidth: true
        Layout.preferredHeight: 65
        color: Themes.m3Colors.m3SurfaceContainer
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
                color: wifiCard.activeNetwork ? Themes.m3Colors.m3Primary : Themes.withAlpha(Themes.m3Colors.m3OnSurface, 0.1)
                radius: Appearance.rounding.small

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: wifiCard.activeNetwork ? wifiCard.getWiFiIcon(wifiCard.activeNetwork.strength) : "wifi_off"
                    color: wifiCard.activeNetwork ? Themes.m3Colors.m3OnPrimary : Themes.withAlpha(Themes.m3Colors.m3OnSurface, 0.38)
                    font.pointSize: Appearance.fonts.extraLarge * 0.8
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    text: "Internet"
                    font.pixelSize: Appearance.fonts.large
                    color: Themes.m3Colors.m3OnSurfaceVariant
                }

                StyledText {
                    text: wifiCard.activeNetwork ? wifiCard.activeNetwork.ssid : "WiFi Disconnected"
                    font.pixelSize: Appearance.fonts.normal
                    font.weight: Font.Medium
                    width: parent.width
                    elide: Text.ElideRight
                    color: Themes.m3Colors.m3OnSurface
                }
            }
        }
    }
}
