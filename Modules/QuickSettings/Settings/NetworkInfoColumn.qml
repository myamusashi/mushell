pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

ColumnLayout {

	Layout.alignment: Qt.AlignLeft | Qt.AlignTop
	spacing: Appearance.spacing.normal

	EthernetCard {}
	WiFiCard {}

	component EthernetCard: StyledRect {
		id: ethernetCard

		Layout.fillWidth: true
		Layout.preferredHeight: 65
		color: Themes.colors.surface_container
		radius: Appearance.rounding.normal

		readonly property bool isConnected: SysUsage.statusWiredInterface === "connected"

		RowLayout {
			anchors.fill: parent
			anchors.margins: Appearance.margin.normal
			spacing: Appearance.spacing.normal

			Rectangle {
				Layout.preferredWidth: 50
				Layout.fillHeight: true
				color: ethernetCard.isConnected ? Themes.colors.primary : Themes.withAlpha(
													  Themes.colors.on_surface, 0.1)
				radius: Appearance.rounding.small

				MatIcon {
					anchors.centerIn: parent
					icon: "settings_ethernet"
					color: ethernetCard.isConnected ? Themes.colors.on_primary : Themes.withAlpha(
														  Themes.colors.on_surface, 0.38)
					font.pixelSize: Appearance.fonts.extraLarge
				}
			}

			Column {
				Layout.fillWidth: true
				spacing: 2

				RowLayout {
					spacing: Appearance.spacing.small

					StyledText {
						text: "Ethernet"
						font.pixelSize: Appearance.fonts.large
						font.weight: Font.Medium
						color: Themes.colors.on_surface
					}

					StyledText {
						text: `(${SysUsage.statusVPNInterface})`
						visible: SysUsage.statusVPNInterface !== ""
						font.pixelSize: Appearance.fonts.small
						color: Themes.colors.on_surface
					}
				}

				StyledText {
					text: SysUsage.statusWiredInterface === "connected" ? "Connected" : "Not Connected"
					font.pixelSize: Appearance.fonts.normal
					color: Themes.colors.on_surface_variant
				}
			}
		}
	}

	component WiFiCard: StyledRect {
		id: wifiCard

		Layout.fillWidth: true
		Layout.preferredHeight: 65
		color: Themes.colors.surface_container
		radius: Appearance.rounding.normal

		readonly property var activeNetwork: {
			for (let i = 0; i < NetworkManager.networks.length; i++)
			if (NetworkManager.networks[i].active)
			return NetworkManager.networks[i];

			return null;
		}

		MArea {
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: settings && settings.wifiList.active ? Qt.ArrowCursor : Qt.PointingHandCursor
			enabled: settings && !settings.wifiList.active
			onClicked: {
				if (settings)
				settings.wifiList.active = !settings.wifiList.active;
			}
		}

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

		RowLayout {
			anchors.fill: parent
			anchors.margins: Appearance.margin.normal
			spacing: Appearance.spacing.normal

			Rectangle {
				Layout.preferredWidth: 50
				Layout.preferredHeight: 50
				color: wifiCard.activeNetwork ? Themes.colors.primary : Themes.withAlpha(
													Themes.colors.on_surface, 0.1)
				radius: Appearance.rounding.small

				MatIcon {
					anchors.centerIn: parent
					icon: wifiCard.activeNetwork ? wifiCard.getWiFiIcon(wifiCard.activeNetwork.strength) :
												   "wifi_off"
					color: wifiCard.activeNetwork ? Themes.colors.on_primary : Themes.withAlpha(
														Themes.colors.on_surface, 0.38)
					font.pixelSize: Appearance.fonts.extraLarge
				}
			}

			Column {
				Layout.fillWidth: true
				spacing: 2

				StyledText {
					text: "Internet"
					font.pixelSize: Appearance.fonts.large
					color: Themes.colors.on_surface_variant
				}

				StyledText {
					text: wifiCard.activeNetwork ? wifiCard.activeNetwork.ssid : "WiFi Disconnected"
					font.pixelSize: Appearance.fonts.normal
					font.weight: Font.Medium
					width: parent.width
					elide: Text.ElideRight
					color: Themes.colors.on_surface
				}
			}
		}
	}
}
