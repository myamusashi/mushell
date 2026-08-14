pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components.Feedback
import qs.Components.Base
import qs.Components.Dialog
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    WifiPskDialog {
        id: wifiPskDialog
    }

    readonly property var activeWifiDevice: {
        for (const d of Networking.devices) {
            if (d.type === DeviceType.Wifi)
                return d;
        }
        return null;
    }

    function wifiIcon(strength) {
        if (strength >= 0.8)
            return "network_wifi";
        if (strength >= 0.5)
            return "network_wifi_3_bar";
        if (strength >= 0.3)
            return "network_wifi_2_bar";
        if (strength >= 0.15)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.bottomMargin: Appearance.margin.normal
            text: qsTr("Network & Internet")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn

                width: parent.width
                spacing: Appearance.spacing.normal

                SettingsCard {
                    title: qsTr("Hotspot")

                    Progress {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        condition: Hotspot.status === Hotspot.Status.Starting || Hotspot.status === Hotspot.Status.Stopping
                    }

                    StyledText {
                        visible: Hotspot.errorMessage !== ""
                        text: Hotspot.errorMessage
                        color: Colours.m3Colors.m3Error
                    }

                    SettingRow {
                        label: qsTr("Enable hotspot & sharing internet:")

                        StyledSwitch {
                            Layout.alignment: Qt.AlignRight
                            checked: Hotspot.isActive
                            enabled: Hotspot.status !== Hotspot.Status.Starting && Hotspot.status !== Hotspot.Status.Stopping
                            onToggled: Hotspot.toggle()
                        }
                    }

                    SettingRow {
                        label: qsTr("User hotspot:")

                        StyledTextInput {
                            text: Hotspot.ssid
                            placeHolderText: qsTr("Default: MyHotspot")
                            passwordMode: false
                            toggleButtonVisible: false
                            enabled: !Hotspot.isActive
                            opacity: enabled ? 1.0 : 0.5
                            onTextChanged: Hotspot.ssid = text
                        }
                    }

                    SettingRow {
                        label: qsTr("Password hotspot:")

                        StyledTextInput {
                            text: Hotspot.password
                            placeHolderText: qsTr("Default: password123")
                            passwordMode: true
                            toggleButtonVisible: true
                            enabled: !Hotspot.isActive
                            opacity: enabled ? 1.0 : 0.5
                            onTextChanged: Hotspot.password = text
                        }
                    }

                    SettingRow {
                        label: qsTr("Hotspot interface:")

                        StyledTextInput {
                            text: Hotspot.hotspotInterface
                            placeHolderText: qsTr("Default: %1").arg(Hotspot.hotspotInterface || qsTr("none detected"))
                            passwordMode: false
                            toggleButtonVisible: false
                            enabled: false
                            opacity: 0.7
                        }
                    }

                    SettingRow {
                        label: qsTr("Bandwidth:")

                        DropdownField {
                            implicitWidth: 240
                            currentIndex: Hotspot.band === "a" ? 1 : 0
                            model: [
                                {
                                    display: "bg (2.4 GHz)"
                                },
                                {
                                    display: "a (5 GHz)"
                                }
                            ]
                            onActivated: Hotspot.band = currentIndex === 0 ? "bg" : "a"
                        }
                    }

                    StyledButton {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Apply && Restart")
                        textColor: Colours.m3Colors.m3OnPrimary
                        color: Colours.m3Colors.m3Primary
                        onClicked: {
                            if (Hotspot.isActive) {
                                Hotspot.stop();
                                // Wait briefly then restart with new settings
                                Qt.callLater(function () {
                                    Qt.callLater(Hotspot.start);
                                });
                            } else {
                                Hotspot.start();
                            }
                        }
                    }
                }

                SettingsCard {
                    title: qsTr("Wi-Fi")

                    SettingRow {
                        label: qsTr("Enable Wi-Fi:")

                        StyledSwitch {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 32
                            checked: Networking.wifiEnabled
                            onToggled: Qt.callLater(() => {
                                Networking.wifiEnabled = checked;
                            })
                        }
                    }

                    Progress {
                        Layout.fillWidth: true
                        condition: GlobalStates.isWifiScannerOpen
                    }

                    ListView {
                        id: wifiListView

                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        interactive: false
                        model: Networking.devices
                        spacing: Appearance.spacing.small

                        delegate: ColumnLayout {
                            id: deviceDelegate

                            required property var modelData

                            width: wifiListView.width

                            Repeater {
                                model: ScriptModel {
                                    values: {
                                        if (deviceDelegate.modelData.type !== DeviceType.Wifi)
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
                                    onTargetChanged: {
                                        cAnim.stop();
                                        cFrom = color;
                                        cTo = target;
                                        cActive = true;
                                        cBlend = 0.0;
                                        cAnim.start();
                                    }

                                    required property var modelData

                                    Layout.fillWidth: true
                                    radius: Appearance.rounding.large
                                    margin: Appearance.margin.small

                                    NAnim {
                                        id: cAnim
                                        target: networkDelegate
                                        property: "cBlend"
                                        from: 0.0
                                        to: 1.0
                                        duration: Appearance.animations.durations.small
                                    }

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

                                        NetActionButton {
                                            icon: networkDelegate.modelData?.connected ? "link_off" : "wifi_add"
                                            iconColor: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                            onClicked: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.tryConnect()
                                        }

                                        NetActionButton {
                                            icon: "delete"
                                            iconColor: networkDelegate.modelData?.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                            onClicked: networkDelegate.modelData?.forget()
                                        }

                                        Icon {
                                            visible: networkDelegate.modelData?.known === false
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

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    component NetActionButton: Item {
        id: actionButton

        signal clicked

        required property string icon
        required property color iconColor

        implicitWidth: 28
        implicitHeight: 28

        Icon {
            anchors.fill: parent
            icon: actionButton.icon
            color: actionButton.iconColor
            font.pixelSize: Appearance.fonts.size.large * 1.5
        }

        MArea {
            anchors.fill: parent
            layerColor: Colours.m3Colors.m3OnSurface
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }
    }
}
