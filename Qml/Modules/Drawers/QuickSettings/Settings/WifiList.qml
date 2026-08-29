pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Vast.Utils

import qs.Components.Base
import qs.Components.Button
import qs.Components.Feedback
import qs.Components.Dialog
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: root

    property bool isVisible: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

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

    WifiPskDialog {
        id: wifiPskDialog
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
                text: qsTr("Internet")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Tap/click a network to connect")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                font.weight: Font.DemiBold
            }

            Progress {
                Layout.fillWidth: true
                condition: GlobalStates.isWifiScannerOpen && root.isVisible
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Wi-Fi")
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledSwitch {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    checked: Networking.wifiEnabled
                    onToggled: Qt.callLater(() => {
                        Networking.wifiEnabled = checked;
                    })
                }
            }

            ListView {
                id: devicesListView

                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                model: Networking.devices
                spacing: Appearance.spacing.small
                clip: true

                delegate: ColumnLayout {
                    id: deviceDelegate

                    required property WifiDevice modelData

                    width: devicesListView.width

                    Connections {
                        target: root

                        function onIsScannerEnabledChanged() {
                            deviceDelegate.modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
                        }
                    }

                    Component.onCompleted: {
                        modelData.scannerEnabled = GlobalStates.isWifiScannerOpen;
                    }

                    Repeater {
                        model: ScriptModel {
                            values: {
                                if (deviceDelegate.modelData.type !== DeviceType.Wifi) // qmllint disable
                                    return [];
                                return [...deviceDelegate.modelData.networks.values].sort((a, b) => {
                                    if (a.connected !== b.connected)
                                        return b.connected - a.connected;
                                    if (a.known !== b.known)
                                        return b.known - a.known;
                                    return b.signalStrength - a.signalStrength;
                                });
                            }
                        }

                        delegate: WrapperRectangle {
                            id: networkDelegate
                            property color target: modelData.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
                            onTargetChanged: {
                                colorBlendAnim.stop();
                                colorFrom = color;
                                colorTo = target;
                                colorBlending = true;
                                colorBlendProgress = 0.0;
                                colorBlendAnim.start();
                            }

                            property color colorFrom
                            property color colorTo
                            property bool colorBlending: false
                            property real colorBlendProgress: 1.0

                            onColorBlendProgressChanged: {
                                if (!colorBlending)
                                    return;
                                if (colorBlendProgress >= 1) {
                                    color = colorTo;
                                    colorBlending = false;
                                } else if (colorBlendProgress > 0) {
                                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                                }
                            }

                            NAnim {
                                id: colorBlendAnim
                                target: networkDelegate
                                property: "colorBlendProgress"
                                from: 0.0
                                to: 1.0
                                duration: Appearance.animations.durations.small
                            }

                            required property var modelData

                            Layout.fillWidth: true
                            radius: Appearance.rounding.large
                            margin: Appearance.margin.small

                            TapHandler {
                                id: networkTap

                                onTapped: networkDelegate.tryConnect()
                            }

                            function tryConnect() {
                                const net = networkDelegate.modelData;
                                if (!net || net.connected)
                                    return;
                                if (net.known || net.security === WifiSecurityType.Open)
                                    net.connect();
                                else
                                    wifiPskDialog.show(net);
                            }

                            Connections {
                                target: networkDelegate.modelData

                                function onConnectionFailed(reason) {
                                    if (reason === ConnectionFailReason.NoSecrets)
                                        wifiPskDialog.show(networkDelegate.modelData);
                                }
                            }

                            RowLayout {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: Appearance.margin.small
                                }
                                spacing: Appearance.spacing.small

                                Item {
                                    implicitWidth: 28
                                    implicitHeight: 28

                                    Icon {
                                        anchors.fill: parent
                                        icon: "signal_wifi_0_bar"
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large * 1.5
                                    }

                                    Icon {
                                        anchors.fill: parent
                                        icon: {
                                            const p = Math.round((networkDelegate.modelData?.signalStrength ?? 0) * 100);
                                            if (p >= 80)
                                                return networkDelegate.modelData && !networkDelegate.modelData.known ? "network_wifi_locked" : "network_wifi";
                                            if (p >= 50)
                                                return networkDelegate.modelData && !networkDelegate.modelData.known ? "network_wifi_3_bar_locked" : "network_wifi_3_bar";
                                            if (p >= 30)
                                                return networkDelegate.modelData && !networkDelegate.modelData.known ? "network_wifi_2_bar_locked" : "network_wifi_2_bar";
                                            if (p >= 15)
                                                return networkDelegate.modelData && !networkDelegate.modelData.known ? "network_wifi_1_bar_locked" : "network_wifi_1_bar";
                                            return "signal_wifi_0_bar";
                                        }
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large * 1.5
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.small * 0.5

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: networkDelegate.modelData?.name ?? ""
                                        elide: Text.ElideRight
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }

                                    StyledText {
                                        text: ConnectionState.toString(networkDelegate.modelData.state)
                                        color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.small
                                    }
                                }

                                FloatingButton {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    backgroundRadius: Appearance.rounding.normal
                                    icon.name: networkDelegate.modelData?.connected ? "link_off" : "wifi_add"
                                    icon.color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                    icon.size: Appearance.fonts.size.large * 1.5
                                    color: "transparent"
                                    onClicked: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.tryConnect()
                                }

                                FloatingButton {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    backgroundRadius: Appearance.rounding.normal
                                    icon.name: "delete"
                                    icon.color: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                    icon.size: Appearance.fonts.size.large * 1.5
                                    color: "transparent"
                                    onClicked: networkDelegate.modelData?.forget()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
