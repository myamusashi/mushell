pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    property alias active: loader.active
    width: parent.width
    height: parent.height

    Loader {
        id: loader

        anchors.fill: parent
        active: false
        asynchronous: true
        sourceComponent: WiFi {}
    }

    component WiFi: WrapperItem {
        id: root

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

        StyledRect {
            anchors.fill: parent
            radius: 0
            color: Colours.m3Colors.m3Surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 15
                anchors.bottomMargin: 15
                spacing: Appearance.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: "transparent"
                        radius: Appearance.rounding.full

                        Icon {
                            type: Icon.Material
                            anchors.centerIn: parent
                            icon: "arrow_back"
                            color: Colours.m3Colors.m3OnBackground
                            font.pointSize: Appearance.fonts.size.large
                        }

                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loader.active = false
                        }
                    }

                    StyledLabel {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    StyledSwitch {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 32
                        checked: Network.wifiEnabled
                        onToggled: Network.toggleWifi()
                    }

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: "transparent"
                        radius: Appearance.rounding.full

                        Icon {
                            type: Icon.Material
                            anchors.centerIn: parent
                            icon: "refresh"
                            color: Colours.m3Colors.m3OnBackground
                            font.pointSize: Appearance.fonts.size.large
                            opacity: Network.wifiEnabled ? 1.0 : 0.3

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                running: Network.scanning
                                loops: Animation.Infinite
                            }
                        }

                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: Network.wifiEnabled && !Network.scanning
                            onClicked: Network.rescanWifi()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Colours.m3Colors.m3OutlineVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: Colours.m3Colors.m3SurfaceContainerLow
                    radius: Appearance.rounding.large
                    visible: Network.active !== null

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: Appearance.spacing.normal

                        Icon {
                            type: Icon.Material
                            Layout.alignment: Qt.AlignVCenter
                            icon: Network.active ? root.getWiFiIcon(Network.active.strength) : "wifi_off"
                            color: Colours.m3Colors.m3Primary
                            font.pointSize: Appearance.fonts.size.extraLarge * 1.2
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            StyledLabel {
                                text: Network.active ? Network.active.ssid : "Not connected"
                                color: Colours.m3Colors.m3OnBackground
                                font.pixelSize: Appearance.fonts.size.medium
                                font.bold: true
                            }

                            StyledLabel {
                                text: Network.active ? "Connected • " + Network.active.frequency + " MHz" : ""
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                            }
                        }

                        StyledRect {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignVCenter
                            color: disconnectArea.containsPress ? Colours.withAlpha(Colours.m3Colors.m3Error, 0.2) : disconnectArea.containsMouse ? Colours.withAlpha(Colours.m3Colors.m3Error, 0.1) : "transparent"
                            radius: Appearance.rounding.full

                            Icon {
                                type: Icon.Material
                                anchors.centerIn: parent
                                icon: "close"
                                color: Colours.m3Colors.m3Error
                                font.pointSize: Appearance.fonts.size.large
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
                    Layout.topMargin: 8
                    text: "Available Networks"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.bold: true
                    visible: Network.wifiEnabled
                }

                Progress {
                    Layout.fillWidth: true
                    condition: Network.scanning
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !Network.wifiEnabled

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.large

                        Icon {
                            type: Icon.Material
                            Layout.alignment: Qt.AlignHCenter
                            icon: "wifi_off"
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pointSize: Appearance.fonts.size.extraLarge * 2
                            opacity: 0.6
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Appearance.spacing.small

                            StyledLabel {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Wi-Fi is turned off"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.large
                                font.bold: true
                            }

                            StyledLabel {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Turn on Wi-Fi to see available networks"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                opacity: 0.7
                            }
                        }
                    }
                }

                ListView {
                    id: networksList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Network.wifiEnabled && Network.networks.length > 0
                    clip: true
                    spacing: Appearance.spacing.small
                    model: Network.networks

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: StyledRect {
                        id: networkDelegate

                        required property var modelData
                        required property int index

                        implicitWidth: networksList.width
                        implicitHeight: 72
                        color: Colours.m3Colors.m3SurfaceContainer
                        radius: Appearance.rounding.large

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: Appearance.spacing.normal

                            Icon {
                                type: Icon.Material
                                Layout.alignment: Qt.AlignVCenter
                                icon: root.getWiFiIcon(networkDelegate.modelData.strength)
                                color: networkDelegate.modelData.active ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                font.pointSize: Appearance.fonts.size.extraLarge
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                RowLayout {
                                    spacing: Appearance.spacing.smaller

                                    StyledLabel {
                                        text: networkDelegate.modelData.ssid || "(Hidden Network)"
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.medium
                                        font.bold: networkDelegate.modelData.active
                                    }

                                    Icon {
                                        type: Icon.Material
                                        icon: "lock"
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                        font.pointSize: Appearance.fonts.size.small
                                        visible: networkDelegate.modelData.isSecure
                                    }
                                }

                                StyledLabel {
                                    text: {
                                        let details = [];
                                        if (networkDelegate.modelData.active)
                                            details.push("Connected");
                                        if (networkDelegate.modelData.security && networkDelegate.modelData.security !== "--")
                                            details.push(networkDelegate.modelData.security);
                                        details.push(networkDelegate.modelData.frequency + " MHz");
                                        return details.join(" • ");
                                    }
                                    color: Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.small
                                }
                            }

                            StyledLabel {
                                Layout.alignment: Qt.AlignVCenter
                                text: networkDelegate.modelData.strength + "%"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                font.bold: true
                            }

                            Icon {
                                type: Icon.Material
                                Layout.alignment: Qt.AlignVCenter
                                icon: "chevron_right"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pointSize: Appearance.fonts.size.large
                                visible: !networkDelegate.modelData.active
                                opacity: 0.5
                            }
                        }

                        MArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !networkDelegate.modelData.active
                            onClicked: {
                                if (!networkDelegate.modelData.active)
                                    Network.connectToNetwork(networkDelegate.modelData.ssid, "");
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
                        spacing: Appearance.spacing.large

                        Icon {
                            type: Icon.Material
                            Layout.alignment: Qt.AlignHCenter
                            icon: "wifi_find"
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pointSize: Appearance.fonts.size.extraLarge * 2
                            opacity: 0.6
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Appearance.spacing.small

                            StyledLabel {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No networks found"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.large
                                font.bold: true
                            }

                            StyledLabel {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Try refreshing the list"
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                opacity: 0.7
                            }
                        }
                    }
                }
            }
        }
    }
}
