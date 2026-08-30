pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Core.Configs
import qs.Components.Base
import qs.Services

Item {
    id: content

    anchors.fill: parent

    property alias wifi: wifi
    property alias ethernet: ethernet
    property alias bluetooth: bluetooth
    readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"
    readonly property string wifiConnectedName: {
        const dev = Networking.devices.values.find(d => d.type === DeviceType.Wifi);
        return dev?.networks.values.find(n => n.connected)?.name ?? "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal

        BrightnessControls {}
        NetworkInfoColumn {}

        RowLayout {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft
            spacing: Appearance.spacing.normal

            StyledText {
                font.pixelSize: Appearance.fonts.size.small
                text: content.isConnected ? `${SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)} used today (${SystemUsage.wiredInterface})` : "Not connected"
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                font.pixelSize: Appearance.fonts.size.small
                text: Networking.wifiEnabled ? `${SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)} used today (${content.wifiConnectedName})` : "Not connected"
                color: Colours.m3Colors.m3OnSurface
            }
        }

        MediaPlayer {}
        Notifications {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
    WifiList {
        id: wifi

        anchors.centerIn: parent
        z: 99
    }

    EthernetList {
        id: ethernet

        anchors.centerIn: parent
        z: 99
    }

    BluetoothList {
        id: bluetooth

        anchors.centerIn: parent
        z: 99
    }

    StyledRect {
        anchors.fill: parent
        visible: wifi.isVisible || ethernet.isVisible || bluetooth.isVisible
        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.7)
        z: 98

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => {
                if (mouse.x < wifi.x || mouse.x > wifi.x + wifi.width || mouse.y < wifi.y || mouse.y > wifi.y + wifi.height) {
                    wifi.isVisible = false;
                }
                if (mouse.x < ethernet.x || mouse.x > ethernet.x + ethernet.width || mouse.y < ethernet.y || mouse.y > ethernet.y + ethernet.height) {
                    ethernet.isVisible = false;
                }
                if (mouse.x < bluetooth.x || mouse.x > bluetooth.x + bluetooth.width || mouse.y < bluetooth.y || mouse.y > bluetooth.y + bluetooth.height) {
                    bluetooth.isVisible = false;
                }
            }
        }
    }
}
