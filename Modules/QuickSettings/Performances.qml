import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

GridLayout {
    anchors.centerIn: parent
    columns: 3
    rowSpacing: Appearance.spacing.large * 2

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            value: Math.round(SysUsage.memUsed / SysUsage.memTotal * 100)
            size: 0
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "RAM usage\n" + SysUsage.memProp + " GB"
            color: Themes.colors.on_surface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Appearance.spacing.normal

        Circular {
            Layout.alignment: Qt.AlignHCenter
            value: SysUsage.cpuPerc
            size: 40
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "CPU usage"
            color: Themes.colors.on_surface
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            value: Math.round(SysUsage.diskUsed / SysUsage.diskTotal * 100)
            text: value + "%"
            size: 0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Disk usage\n" + SysUsage.diskProp + " GB"
            color: Themes.colors.on_surface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [{
                    "label": "Wired Download",
                    "value": SysUsage.formatSpeed(SysUsage.wiredDownloadSpeed)
                }, {
                    "label": "Wired Upload",
                    "value": SysUsage.formatSpeed(SysUsage.wiredUploadSpeed)
                }, {
                    "label": "Wireless Download",
                    "value": SysUsage.formatSpeed(
                                 SysUsage.wirelessDownloadSpeed)
                }, {
                    "label": "Wireless Upload",
                    "value": SysUsage.formatSpeed(SysUsage.wirelessUploadSpeed)
                }]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.colors.on_surface
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [{
                    "label": "Wired download usage",
                    "value": SysUsage.formatUsage(
                                 SysUsage.totalWiredDownloadUsage)
                }, {
                    "label": "Wired upload usage",
                    "value": SysUsage.formatUsage(
                                 SysUsage.totalWirelessUploadUsage)
                }, {
                    "label": "Wireless download usage",
                    "value": SysUsage.formatUsage(
                                 SysUsage.totalWirelessDownloadUsage)
                }, {
                    "label": "Wireless upload usage",
                    "value": SysUsage.formatUsage(
                                 SysUsage.totalWirelessUploadUsage)
                }]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.colors.on_surface
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [{
                    "label": "Wired interface",
                    "value": SysUsage.wiredInterface
                }, {
                    "label": "Wireless interface",
                    "value": SysUsage.wirelessInterface
                }]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.colors.on_surface
            }
        }
    }
}
