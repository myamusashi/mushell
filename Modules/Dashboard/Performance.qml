import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Components

Loader {
	active: dashboardLoader.activeAsync
	asynchronous: true

	anchors.centerIn: parent

	sourceComponent: StyledRect {
		id: root

		readonly property int diskProp: SysUsage.diskUsed / 1048576
		readonly property int memProp: SysUsage.memUsed / 1048576

		anchors.centerIn: parent
		radius: Appearance.rounding.normal
		color: Colors.colors.background
		border.color: Colors.colors.outline
		border.width: 2

		GridLayout {
			anchors.centerIn: parent
			columns: 3
			rowSpacing: Appearance.spacing.large * 2

			Item {
				id: memItem

				Layout.alignment: Qt.AlignCenter
				Layout.preferredWidth: childrenRect.width
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.centerIn: parent
					spacing: Appearance.spacing.normal

					Circular {
						id: mem

						value: Math.round(SysUsage.memUsed / SysUsage.memTotal * 100)
						size: 0
						text: value + "%"
					}

					StyledText {
						id: memText

						Layout.alignment: Qt.AlignHCenter
						text: "RAM usage" + "\n" + root.memProp + " GB"
						color: Colors.colors.on_surface
					}
				}
			}

			Item {
				id: cpuItem

				Layout.alignment: Qt.AlignVCenter
				Layout.preferredWidth: childrenRect.width
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.centerIn: parent
					spacing: Appearance.spacing.normal

					Circular {
						id: cpu

						Layout.alignment: Qt.AlignHCenter
						value: SysUsage.cpuPerc
						size: 40
						text: value + "%"
					}

					StyledText {
						id: cpuText

						Layout.alignment: Qt.AlignHCenter
						text: "CPU usage"
						color: Colors.colors.on_surface
					}
				}
			}

			Item {
				Layout.alignment: Qt.AlignCenter
				Layout.preferredWidth: childrenRect.width
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.centerIn: parent
					spacing: Appearance.spacing.normal

					Circular {
						id: disk

						value: Math.round(SysUsage.diskUsed / SysUsage.diskTotal * 100)
						text: value + "%"
						size: 0
					}

					StyledText {
						id: diskText

						Layout.alignment: Qt.AlignHCenter
						text: "Disk usage" + "\n" + root.diskProp + " GB"
						color: Colors.colors.on_surface
					}
				}
			}

			Item {
				Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
				Layout.preferredWidth: 160
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.top: parent.top
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: Appearance.spacing.small
					width: parent.width

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wired Download:\n" + SysUsage.formatSpeed(SysUsage.wiredDownloadSpeed)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wired Upload:\n" + SysUsage.formatSpeed(SysUsage.wiredUploadSpeed)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wireless Download:\n" + SysUsage.formatSpeed(SysUsage.wirelessDownloadSpeed)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wireless Upload:\n" + SysUsage.formatSpeed(SysUsage.wirelessUploadSpeed)
						color: Colors.colors.on_surface
					}
				}
			}

			Item {
				Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
				Layout.preferredWidth: 160
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.top: parent.top
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: Appearance.spacing.small
					width: parent.width

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wired download usage:\n" + SysUsage.formatUsage(SysUsage.totalWiredDownloadUsage)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wired upload usage:\n" + SysUsage.formatUsage(SysUsage.totalWiredUploadUsage)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wireless download usage:\n" + SysUsage.formatUsage(SysUsage.totalWirelessDownloadUsage)
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wireless upload usage:\n" + SysUsage.formatUsage(SysUsage.totalWirelessUploadUsage)
						color: Colors.colors.on_surface
					}
				}
			}

			Item {
				Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
				Layout.preferredWidth: 160
				Layout.preferredHeight: childrenRect.height

				ColumnLayout {
					anchors.top: parent.top
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: Appearance.spacing.small
					width: parent.width

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wired interface:\n" + SysUsage.wiredInterface
						color: Colors.colors.on_surface
					}

					StyledText {
						Layout.alignment: Qt.AlignHCenter
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						text: "Wireless interface:\n" + SysUsage.wirelessInterface
						color: Colors.colors.on_surface
					}
				}
			}
		}
	}
}
