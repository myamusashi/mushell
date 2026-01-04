import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

GridLayout {
    anchors.centerIn: parent
    columns: 3
    rows: 2
    rowSpacing: Appearance.spacing.large
    columnSpacing: Appearance.spacing.large

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            Layout.alignment: Qt.AlignHCenter
            value: Math.round(SystemUsage.memUsed / SystemUsage.memTotal * 100)
            size: 0
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "CPU Usage"
            color: Colours.m3Colors.m3OnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            Layout.alignment: Qt.AlignHCenter
            value: SystemUsage.cpuPerc
            size: 40
            text: value + "%"
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "RAM Usage\n" + SystemUsage.memProp.toFixed(0) + " GB"
            color: Colours.m3Colors.m3OnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: Appearance.spacing.normal

        Circular {
            Layout.alignment: Qt.AlignHCenter
            value: SystemUsage.diskPercent.toFixed(0)
            text: value + "%"
            size: 0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Disk Usage\n" + SystemUsage.diskProp.toFixed(0) + " GB"
            color: Colours.m3Colors.m3OnSurface
            horizontalAlignment: Text.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 180
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: "Network Speed"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: [
                {
                    label: "Wired ↓",
                    value: SystemUsage.formatSpeed(SystemUsage.wiredDownloadSpeed)
                },
                {
                    label: "Wired ↑",
                    value: SystemUsage.formatSpeed(SystemUsage.wiredUploadSpeed)
                },
                {
                    label: "Wireless ↓",
                    value: SystemUsage.formatSpeed(SystemUsage.wirelessDownloadSpeed)
                },
                {
                    label: "Wireless ↑",
                    value: SystemUsage.formatSpeed(SystemUsage.wirelessUploadSpeed)
                }
            ]

            RowLayout {
                id: speedDelegate
                required property var modelData
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.preferredWidth: 80
                    text: speedDelegate.modelData.label
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: speedDelegate.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 180
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: "Data Usage"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: [
                {
                    label: "Wired ↓",
                    value: SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)
                },
                {
                    label: "Wired ↑",
                    value: SystemUsage.formatUsage(SystemUsage.totalWiredUploadUsage)
                },
                {
                    label: "Wireless ↓",
                    value: SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)
                },
                {
                    label: "Wireless ↑",
                    value: SystemUsage.formatUsage(SystemUsage.totalWirelessUploadUsage)
                }
            ]

            RowLayout {
                id: totalDelegate

                required property var modelData
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.preferredWidth: 80
                    text: totalDelegate.modelData.label
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: totalDelegate.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 180
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: "Network Interfaces"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.medium
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: [
                {
                    label: "Wired",
                    value: SystemUsage.wiredInterface
                },
                {
                    label: "Wireless",
                    value: SystemUsage.wirelessInterface
                }
            ]

            ColumnLayout {
                id: interfaceDelegate

                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: interfaceDelegate.modelData.label
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: interfaceDelegate.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.family: Appearance.fonts.family.mono
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
