pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking

import qs.Components.Feedback
import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import Vast.Utils

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    WifiPskDialog {
        id: wifiPskDialog
    }

    readonly property var activeWifiDevice: {
        for (const device of Networking.devices) {
            if (device.type === DeviceType.Wifi)
                return device;
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

    CardRevealer {
        id: cardRevealer

        container: contentColumn
        target: pageFlickable
    }

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
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
            id: pageFlickable
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

                        SplitButton {
                            readonly property int selectedIndex: Hotspot.band === "a" ? 1 : 0

                            model: [
                                {
                                    display: "bg (2.4 GHz)"
                                },
                                {
                                    display: "a (5 GHz)"
                                }
                            ]
                            textRole: "display"
                            currentIndex: selectedIndex
                            text: model[selectedIndex]?.display ?? "bg (2.4 GHz)"
                            icon.name: "graphic_eq"

                            onMenuItemActivated: index => Hotspot.band = index === 0 ? "bg" : "a"
                        }
                    }

                    ExtendedFloatingButton {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Apply && Restart")
                        textColor: Colours.m3Colors.m3OnPrimary
                        color: Colours.m3Colors.m3Primary
                        onClicked: {
                            if (Hotspot.isActive) {
                                Hotspot.stop();
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
                                    onTargetChanged: {
                                        colorBlendAnim.stop();
                                        colorFrom = color;
                                        colorTo = target;
                                        colorBlending = true;
                                        colorBlendProgress = 0.0;
                                        colorBlendAnim.start();
                                    }

                                    required property var modelData

                                    Layout.fillWidth: true
                                    radius: Appearance.rounding.large
                                    margin: Appearance.margin.small

                                    NAnim {
                                        id: colorBlendAnim
                                        target: networkDelegate
                                        property: "colorBlendProgress"
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
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            onClicked: networkDelegate.modelData?.connected ? networkDelegate.modelData.disconnect() : networkDelegate.tryConnect()
                                        }

                                        FloatingButton {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            backgroundRadius: Appearance.rounding.normal
                                            icon.name: "delete"
                                            icon.color: Colours.m3Colors.m3SurfaceVariant
                                            icon.size: Appearance.fonts.size.large * 1.5
                                            onClicked: networkDelegate.modelData?.forget()
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
}
