pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	id: loader

	Layout.fillWidth: true
	Layout.fillHeight: true
	active: false

	sourceComponent: WiFi {}

	component WiFi: Item {
		id: root

		StyledRect {
			anchors.fill: parent
			radius: 0
			color: Themes.colors.surface

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 15
				spacing: Appearance.spacing.normal

				RowLayout {
					Layout.fillWidth: true
					spacing: Appearance.spacing.normal

					Item {
						implicitWidth: iconBack.width
						implicitHeight: iconBack.height

						MatIcon {
							id: iconBack

							anchors.centerIn: parent
							icon: "arrow_back"
							color: mIconBackArea.containsPress ? Themes.withAlpha(Themes.colors.on_background, 0.1) :
																 mIconBackArea.containsMouse ? Themes.withAlpha(Themes.colors.on_background, 0.08) :
																							   Themes.colors.on_background
							font.pixelSize: Appearance.fonts.extraLarge
						}

						MArea {
							id: mIconBackArea

							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: loader.active = false
						}
					}

					StyledLabel {
						text: "Wi-Fi"
						color: Themes.colors.on_background
						font.pixelSize: Appearance.fonts.large
						font.bold: true
					}

					Item {
						Layout.fillWidth: true
					}

					Item {
						implicitWidth: wifiToggle.width
						implicitHeight: wifiToggle.height

						StyledSwitch {
							id: wifiToggle

							checked: NetworkManager.wifiEnabled
							onToggled: NetworkManager.toggleWifi()
						}
					}

					Item {
						implicitWidth: iconRefresh.width
						implicitHeight: iconRefresh.height

						MatIcon {
							id: iconRefresh

							anchors.centerIn: parent
							icon: "refresh"
							color: mRefreshArea.containsPress ? Themes.withAlpha(Themes.colors.on_background, 0.1) :
																mRefreshArea.containsMouse ? Themes.withAlpha(Themes.colors.on_background, 0.08) :
																							 Themes.colors.on_background
							font.pixelSize: Appearance.fonts.extraLarge
							opacity: NetworkManager.wifiEnabled ? 1.0 : 0.5

							RotationAnimation on rotation {
								id: refreshAnimation

								from: 0
								to: 360
								duration: 1000
								running: NetworkManager.scanning
								loops: Animation.Infinite
							}
						}

						MArea {
							id: mRefreshArea

							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							enabled: NetworkManager.wifiEnabled && !NetworkManager.scanning
							onClicked: {
								NetworkManager.rescanWifi();
							}
						}
					}
				}

				StyledRect {
					Layout.fillWidth: true
					color: Themes.colors.outline
					implicitHeight: 1
				}

				StyledRect {
					Layout.fillWidth: true
					implicitHeight: currentNetLayout.implicitHeight + 20
					color: Themes.colors.surface_container_low
					radius: Appearance.rounding.normal
					visible: NetworkManager.active !== null

					RowLayout {
						id: currentNetLayout

						anchors.fill: parent
						anchors.margins: 10
						spacing: Appearance.spacing.normal

						MatIcon {
							icon: NetworkManager.active ? root.getWiFiIcon(NetworkManager.active.strength) : "wifi_off"
							color: Themes.colors.primary
							font.pixelSize: Appearance.fonts.extraLarge
						}

						ColumnLayout {
							spacing: Appearance.spacing.small

							StyledLabel {
								text: NetworkManager.active ? NetworkManager.active.ssid : "Not connected"
								color: Themes.colors.on_background
								font.pixelSize: Appearance.fonts.medium
								font.bold: true
							}

							StyledLabel {
								text: NetworkManager.active ? "Connected • " + NetworkManager.active.frequency + " MHz" : ""
								color: Themes.colors.on_surface_variant
								font.pixelSize: Appearance.fonts.small
							}
						}

						Item {
							Layout.alignment: Qt.AlignRight
							implicitWidth: disconnectBtn.width
							implicitHeight: disconnectBtn.height

							MatIcon {
								id: disconnectBtn

								anchors.centerIn: parent
								icon: "close"
								color: disconnectArea.containsPress ? Themes.withAlpha(Themes.colors.error, 0.1) :
																	  disconnectArea.containsMouse ? Themes.withAlpha(Themes.colors.error, 0.8) :
																									 Themes.colors.on_surface_variant
								font.pixelSize: Appearance.fonts.large * 1.5
							}

							MArea {
								id: disconnectArea

								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									NetworkManager.disconnectFromNetwork();
								}
							}
						}
					}
				}

				StyledLabel {
					text: "Available Networks"
					color: Themes.colors.on_surface_variant
					font.pixelSize: Appearance.fonts.normal
					font.bold: true
					visible: NetworkManager.wifiEnabled
				}

				Progress {
					condition: NetworkManager.scanning
				}

				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true
					visible: !NetworkManager.wifiEnabled

					ColumnLayout {
						anchors.centerIn: parent
						spacing: Appearance.spacing.normal

						MatIcon {
							Layout.alignment: Qt.AlignHCenter
							icon: "wifi_off"
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.extraLarge
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Wi-Fi is turned off"
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.large
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Turn on Wi-Fi to see available networks"
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.normal
						}
					}
				}

				ScrollView {
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					visible: NetworkManager.wifiEnabled

					ListView {
						id: networkListView

						model: NetworkManager.networks
						spacing: Appearance.spacing.small

						delegate: StyledRect {
							id: delegateWifi

							required property var modelData
							required property int index

							width: ListView.view.width
							implicitHeight: networkLayout.implicitHeight + 20
							color: mouseArea.containsPress ? Themes.withAlpha(Themes.colors.surface_container, 0.12) :
															 mouseArea.containsMouse ? Themes.withAlpha(Themes.colors.surface_container, 0.08) :
																					   modelData.active ? Themes.withAlpha(Themes.colors.surface_container, 0.08) :
																										  Themes.colors.surface_container
							radius: Appearance.rounding.normal

							RowLayout {
								id: networkLayout

								anchors.fill: parent
								anchors.margins: 10
								spacing: Appearance.spacing.normal

								MatIcon {
									icon: root.getWiFiIcon(delegateWifi.modelData.strength)
									color: delegateWifi.modelData.active ? Themes.colors.primary : Themes.colors.on_surface
									font.pixelSize: Appearance.fonts.extraLarge
								}

								ColumnLayout {
									Layout.fillWidth: true
									spacing: Appearance.spacing.small

									RowLayout {
										spacing: Appearance.spacing.smaller

										StyledLabel {
											text: delegateWifi.modelData.ssid || "(Hidden Network)"
											color: Themes.colors.on_background
											font.pixelSize: Appearance.fonts.medium
											font.bold: delegateWifi.modelData.active
										}

										MatIcon {
											icon: "lock"
											color: Themes.colors.on_surface_variant
											font.pixelSize: Appearance.fonts.small
											visible: delegateWifi.modelData.isSecure
										}
									}

									StyledLabel {
										text: {
											let details = [];
											if (delegateWifi.modelData.active) {
												details.push("Connected");
											}
											if (delegateWifi.modelData.security && delegateWifi.modelData.security !== "--") {
												details.push(delegateWifi.modelData.security);
											}
											details.push(delegateWifi.modelData.frequency + " MHz");
											return details.join(" • ");
										}
										color: Themes.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.small
									}
								}

								StyledLabel {
									text: delegateWifi.modelData.strength + "%"
									color: Themes.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.small
								}

								MatIcon {
									icon: "chevron_right"
									color: Themes.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.medium
									visible: !delegateWifi.modelData.active
								}
							}

							MArea {
								id: mouseArea

								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									if (!delegateWifi.modelData.active) {
										NetworkManager.connectToNetwork(delegateWifi.modelData.ssid, "");
									}
								}
							}
						}
					}
				}

				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true
					visible: NetworkManager.wifiEnabled && NetworkManager.networks.length === 0 &&
							 !NetworkManager.scanning

					ColumnLayout {
						anchors.centerIn: parent
						spacing: Appearance.spacing.normal

						MatIcon {
							Layout.alignment: Qt.AlignHCenter
							icon: "wifi_off"
							color: Themes.colors.on_surface_variant
							font.pixelSize: 48
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "No networks found"
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.medium
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Try refreshing the list"
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.small
						}
					}
				}

				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true
					visible: NetworkManager.scanning

					ColumnLayout {
						anchors.centerIn: parent
						spacing: Appearance.spacing.normal

						MatIcon {
							Layout.alignment: Qt.AlignHCenter
							icon: "wifi_find"
							color: Themes.colors.primary
							font.pixelSize: 48

							SequentialAnimation on opacity {
								running: NetworkManager.scanning
								loops: Animation.Infinite
								NumberAnimation {
									from: 1.0
									to: 0.3
									duration: 600
								}
								NumberAnimation {
									from: 0.3
									to: 1.0
									duration: 600
								}
							}
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Scanning for networks..."
							color: Themes.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.medium
						}
					}
				}
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
	}
}
