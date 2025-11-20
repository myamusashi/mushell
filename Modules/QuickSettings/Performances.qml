import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

GridLayout {
    anchors.centerIn: parent
    columns: 3
    rowSpacing: Appearance.spacing.large * 2

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            value: Math.round(SystemUsage.memUsed / SystemUsage.memTotal * 100)
            size: 0
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "RAM usage\n" + SystemUsage.memProp.toFixed(0) + " GB"
            color: Themes.m3Colors.m3OnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Appearance.spacing.normal

        Circular {
            Layout.alignment: Qt.AlignHCenter
            value: SystemUsage.cpuPerc
            size: 40
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "CPU usage"
            color: Themes.m3Colors.m3OnSurface
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            value: SystemUsage.diskPercent.toFixed(0)
            text: value + "%"
            size: 0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Disk usage\n" + SystemUsage.diskProp.toFixed(0) + " GB"
            color: Themes.m3Colors.m3OnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [
                {
                    "label": "Wired Download",
                    "value": SystemUsage.formatSpeed(SystemUsage.wiredDownloadSpeed)
                },
                {
                    "label": "Wired Upload",
                    "value": SystemUsage.formatSpeed(SystemUsage.wiredUploadSpeed)
                },
                {
                    "label": "Wireless Download",
                    "value": SystemUsage.formatSpeed(SystemUsage.wirelessDownloadSpeed)
                },
                {
                    "label": "Wireless Upload",
                    "value": SystemUsage.formatSpeed(SystemUsage.wirelessUploadSpeed)
                }
            ]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.m3Colors.m3OnSurface
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [
                {
                    "label": "Wired download usage",
                    "value": SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)
                },
                {
                    "label": "Wired upload usage",
                    "value": SystemUsage.formatUsage(SystemUsage.totalWirelessUploadUsage)
                },
                {
                    "label": "Wireless download usage",
                    "value": SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)
                },
                {
                    "label": "Wireless upload usage",
                    "value": SystemUsage.formatUsage(SystemUsage.totalWirelessUploadUsage)
                }
            ]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.m3Colors.m3OnSurface
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredWidth: 160
        spacing: Appearance.spacing.small

        Repeater {
            model: [
                {
                    "label": "Wired interface",
                    "value": SystemUsage.wiredInterface
                },
                {
                    "label": "Wireless interface",
                    "value": SystemUsage.wirelessInterface
                }
            ]

            StyledText {
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData.label + ":\n" + modelData.value
                color: Themes.m3Colors.m3OnSurface
            }
        }
    }
}
