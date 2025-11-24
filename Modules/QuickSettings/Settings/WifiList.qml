pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Loader {
    id: loader

    Layout.fillWidth: true
    Layout.fillHeight: true
    active: false

    sourceComponent: WiFi {}

    component WiFi: Item {
        id: root

        StyledRect {
            anchors.fill: parent
            radius: 0
            color: Themes.m3Colors.m3Surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: Appearance.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    Item {
                        implicitWidth: iconBack.width
                        implicitHeight: iconBack.height

                        MaterialIcon {
                            id: iconBack

                            anchors.centerIn: parent
                            icon: "arrow_back"
                            color: Themes.m3Colors.m3OnBackground
                            font.pointSize: Appearance.fonts.extraLarge * 0.8
                        }

                        MArea {
                            id: mIconBackArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loader.active = false
                        }
                    }

                    StyledLabel {
                        text: "Wi-Fi"
                        color: Themes.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.large
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Item {
                        implicitWidth: wifiToggle.width
                        implicitHeight: wifiToggle.height

                        StyledSwitch {
                            id: wifiToggle

                            checked: Network.wifiEnabled
                            onToggled: Network.toggleWifi()
                        }
                    }

                    Item {
                        implicitWidth: iconRefresh.width
                        implicitHeight: iconRefresh.height

                        MaterialIcon {
                            id: iconRefresh

                            anchors.centerIn: parent
                            icon: "refresh"
                            color: Themes.m3Colors.m3OnBackground
                            font.pointSize: Appearance.fonts.extraLarge * 0.8
                            opacity: Network.wifiEnabled ? 1.0 : 0.5
                            antialiasing: true
                            smooth: true

                            layer.enabled: rotation !== 0 || scale !== 1.0
                            layer.smooth: true
                            layer.samples: 16

                            RotationAnimation on rotation {
                                id: refreshAnimation

                                from: 0
                                to: 360
                                duration: 1000
                                running: Network.scanning
                                loops: Animation.Infinite
                            }
                        }

                        MArea {
                            id: mRefreshArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: Network.wifiEnabled && !Network.scanning
                            onClicked: {
                                Network.rescanWifi();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    color: Themes.m3Colors.m3Outline
                    implicitHeight: 1
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: currentNetLayout.implicitHeight + 20
                    color: Themes.m3Colors.m3SurfaceContainerLow
                    radius: Appearance.rounding.normal
                    visible: Network.active !== null

                    RowLayout {
                        id: currentNetLayout

                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            icon: Network.active ? root.getWiFiIcon(Network.active.strength) : "wifi_off"
                            color: Themes.m3Colors.m3Primary
                            font.pointSize: Appearance.fonts.extraLarge
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small

                            StyledLabel {
                                text: Network.active ? Network.active.ssid : "Not connected"
                                color: Themes.m3Colors.m3OnBackground
                                font.pixelSize: Appearance.fonts.medium
                                font.bold: true
                            }

                            StyledLabel {
                                text: Network.active ? "Connected • " + Network.active.frequency + " MHz" : ""
                                color: Themes.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.small
                            }
                        }

                        Item {
                            Layout.alignment: Qt.AlignRight
                            implicitWidth: disconnectBtn.width
                            implicitHeight: disconnectBtn.height

                            MaterialIcon {
                                id: disconnectBtn

                                anchors.centerIn: parent
                                icon: "close"
                                color: disconnectArea.containsPress ? Themes.withAlpha(Themes.m3Colors.m3Error, 0.1) : disconnectArea.containsMouse ? Themes.withAlpha(Themes.m3Colors.m3Error, 0.8) : Themes.m3Colors.m3OnSurfaceVariant
                                font.pointSize: Appearance.fonts.extraLarge * 0.8
                            }

                            MArea {
                                id: disconnectArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.disconnectFromNetwork()
                            }
                        }
                    }
                }

                StyledLabel {
                    text: "Available Networks"
                    color: Themes.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.normal
                    font.bold: true
                    visible: Network.wifiEnabled
                }

                Progress {
                    condition: Network.scanning
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !Network.wifiEnabled

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "wifi_off"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pointSize: Appearance.fonts.extraLarge * 0.8
                        }

                        StyledLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Wi-Fi is turned off"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.large
                        }

                        StyledLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Turn on Wi-Fi to see available networks"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.normal
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: Network.wifiEnabled

                    ListView {
                        id: networkListView

                        model: Network.networks
                        spacing: Appearance.spacing.small

                        delegate: StyledRect {
                            id: delegateWifi

                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: networkLayout.implicitHeight + 20
                            color: Themes.m3Colors.m3SurfaceContainer
                            radius: Appearance.rounding.normal

                            RowLayout {
                                id: networkLayout

                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: Appearance.spacing.normal

                                MaterialIcon {
                                    icon: root.getWiFiIcon(delegateWifi.modelData.strength)
                                    color: delegateWifi.modelData.active ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnSurface
                                    font.pointSize: Appearance.fonts.extraLarge
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.small

                                    RowLayout {
                                        spacing: Appearance.spacing.smaller

                                        StyledLabel {
                                            text: delegateWifi.modelData.ssid || "(Hidden Network)"
                                            color: Themes.m3Colors.m3OnBackground
                                            font.pixelSize: Appearance.fonts.medium
                                            font.bold: delegateWifi.modelData.active
                                        }

                                        MaterialIcon {
                                            icon: "lock"
                                            color: Themes.m3Colors.m3OnSurfaceVariant
                                            font.pointSize: Appearance.fonts.small
                                            visible: delegateWifi.modelData.isSecure
                                        }
                                    }

                                    StyledLabel {
                                        text: {
                                            let details = [];
                                            if (delegateWifi.modelData.active)
                                                details.push("Connected");

                                            if (delegateWifi.modelData.security && delegateWifi.modelData.security !== "--")
                                                details.push(delegateWifi.modelData.security);

                                            details.push(delegateWifi.modelData.frequency + " MHz");
                                            return details.join(" • ");
                                        }
                                        color: Themes.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.small
                                    }
                                }

                                StyledLabel {
                                    text: delegateWifi.modelData.strength + "%"
                                    color: Themes.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.small
                                }

                                MaterialIcon {
                                    icon: "chevron_right"
                                    color: Themes.m3Colors.m3OnSurfaceVariant
                                    font.pointSize: Appearance.fonts.large
                                    visible: !delegateWifi.modelData.active
                                }
                            }

                            MArea {
                                id: mouseArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!delegateWifi.modelData.active)
                                        Network.connectToNetwork(delegateWifi.modelData.ssid, "");
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Network.wifiEnabled && Network.networks.length === 0 && !Network.scanning

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "wifi_off"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pointSize: Appearance.fonts.extraLarge * 0.8
                        }

                        StyledLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No networks found"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.medium
                        }

                        StyledLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Try refreshing the list"
                            color: Themes.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.small
                        }
                    }
                }
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
    }
}
