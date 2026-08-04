pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Feedback
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
                                    return b.signalStrength - a.signalStrength;
                                });
                            }
                        }

                        delegate: WrapperRectangle {
                            id: networkDelegate
                            property color target: modelData.connected ? Colours.m3Colors.m3Primary : networkTap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
                            onTargetChanged: {
                                cAnim.stop();
                                cFrom = color;
                                cTo = target;
                                cActive = true;
                                cBlend = 0.0;
                                cAnim.start();
                            }

                            property color cFrom
                            property color cTo
                            property bool cActive: false
                            property real cBlend: 1.0

                            onCBlendChanged: {
                                if (!cActive)
                                    return;
                                if (cBlend >= 1) {
                                    color = cTo;
                                    cActive = false;
                                } else if (cBlend > 0) {
                                    color = Colours.blendColors(cFrom, cTo, cBlend);
                                }
                            }

                            NAnim {
                                id: cAnim
                                target: networkDelegate
                                property: "cBlend"
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

                                onTapped: {
                                    if (networkDelegate.modelData && !networkDelegate.modelData.connected)
                                        networkDelegate.modelData.connect();
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: contextMenu.popup()
                            }

                            StyledMenu {
                                id: contextMenu

                                StyledMenuItem {
                                    text: networkDelegate.modelData?.connected ? qsTr("Disconnect") : qsTr("Connect")
                                    onTriggered: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.modelData?.connect()
                                }

                                StyledMenuItem {
                                    text: qsTr("Forget Network")
                                    onTriggered: networkDelegate.modelData?.forget()
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
                                                return "network_wifi";
                                            if (p >= 50)
                                                return "network_wifi_3_bar";
                                            if (p >= 30)
                                                return "network_wifi_2_bar";
                                            if (p >= 15)
                                                return "network_wifi_1_bar";
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

                                Icon {
                                    visible: networkDelegate.modelData && !networkDelegate.modelData.known
                                    icon: "lock"
                                    color: networkDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
