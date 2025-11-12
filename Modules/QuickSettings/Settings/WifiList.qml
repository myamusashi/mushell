import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers
import qs.Components

Loader {
	id: loader

	anchors.fill: parent
	active: false

	sourceComponent: WiFi {}

	component WiFi: Item {
		id: root

		StyledRect {
			anchors.fill: parent
			color: Colors.colors.surface_container

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 15
				spacing: Appearance.spacing.normal

				RowLayout {
					Layout.fillWidth: true
					spacing: Appearance.spacing.normal

					Item {
						width: iconBack.width
						height: iconBack.height

						MatIcon {
							id: iconBack

							anchors.centerIn: parent
							icon: "arrow_back"
							color: mIconBackArea.containsPressed ? Colors.withAlpha(Colors.colors.on_background, 0.1) : mIconBackArea.containsMouse ? Colors.withAlpha(Colors.colors.on_background, 0.08) : Colors.colors.on_background
							font.pixelSize: Appearance.fonts.extraLarge
						}

						MouseArea {
							id: mIconBackArea

							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								loader.active = false;
							}
						}
					}

					StyledLabel {
						text: "Wi-Fi"
						color: Colors.colors.on_background
						font.pixelSize: Appearance.fonts.large
						font.bold: true
					}

					Item {
						Layout.fillWidth: true
					}

					Item {
						width: wifiToggle.width
						height: wifiToggle.height

						StyledSwitch {
							id: wifiToggle

							checked: NetworkManager.wifiEnabled
							onToggled: {
								NetworkManager.toggleWifi();
							}
						}
					}

					Item {
						width: iconRefresh.width
						height: iconRefresh.height

						MatIcon {
							id: iconRefresh

							anchors.centerIn: parent
							icon: "refresh"
							color: mRefreshArea.containsPressed ? Colors.withAlpha(Colors.colors.on_background, 0.1) : mRefreshArea.containsMouse ? Colors.withAlpha(Colors.colors.on_background, 0.08) : Colors.colors.on_background
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

						MouseArea {
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
					color: Colors.colors.outline
					height: 1
				}

				StyledRect {
					Layout.fillWidth: true
					implicitHeight: currentNetLayout.implicitHeight + 20
					color: Colors.colors.surface_container_low
					radius: Appearance.rounding.normal
					visible: NetworkManager.active !== null

					RowLayout {
						id: currentNetLayout
						
						anchors.fill: parent
						anchors.margins: 10
						spacing: Appearance.spacing.normal

						MatIcon {
							icon: NetworkManager.active ? getWiFiIcon(NetworkManager.active.strength) : "wifi_off"
							color: Colors.colors.primary
							font.pixelSize: Appearance.fonts.extraLarge
						}

						ColumnLayout {
							spacing: Appearnce.spacing.small

							StyledLabel {
								text: NetworkManager.active ? NetworkManager.active.ssid : "Not connected"
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.medium
								font.bold: true
							}

							StyledLabel {
								text: NetworkManager.active ? "Connected • " + NetworkManager.active.frequency + " MHz" : ""
								color: Colors.colors.on_surface_variant
								font.pixelSize: Appearance.fonts.small
							}
						}

						Item {
							anchors.right: parent.right
							width: disconnectBtn.width
							height: disconnectBtn.height

							MatIcon {
								id: disconnectBtn
								
								anchors.centerIn: parent
								icon: "close"
								color: disconnectArea.containsPressed ? Colors.withAlpha(Colors.colors.error, 0.1) : disconnectArea.containsMouse ? Colors.withAlpha(Colors.colors.error, 0.8) : Colors.colors.on_surface_variant
								font.pixelSize: Appearance.fonts.large * 1.5
							}

							MouseArea {
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
					color: Colors.colors.on_surface_variant
					font.pixelSize: Appearance.fonts.normal
					font.bold: true
					visible: NetworkManager.wifiEnabled
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
							color: Colors.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.extraLarge
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Wi-Fi is turned off"
							color: Colors.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.large
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Turn on Wi-Fi to see available networks"
							color: Colors.colors.on_surface_variant
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
						spacing: Appearnce.spacing.small

						delegate: StyledRect {
							id: delegateWifi
							
							required property var modelData
							required property int index

							width: ListView.view.width
							implicitHeight: networkLayout.implicitHeight + 20
							color: mouseArea.containsPressed ? Colors.withAlpha(Colors.colors.primary, 0.12) : mouseArea.containsMouse ? Colors.withAlpha(Colors.colors.on_surface, 0.08) : modelData.active ? Colors.withAlpha(Colors.colors.primary, 0.08) : Colors.colors.surface_container
							radius: Appearance.rounding.normal

							RowLayout {
								id: networkLayout
								
								anchors.fill: parent
								anchors.margins: 10
								spacing: Appearance.spacing.normal

								MatIcon {
									icon: getWiFiIcon(modelData.strength)
									color: modelData.active ? Colors.colors.primary : Colors.colors.on_surface
									font.pixelSize: Appearance.fonts.extraLarge
								}

								ColumnLayout {
									Layout.fillWidth: true
									spacing: 2

									RowLayout {
										spacing: 6

										StyledLabel {
											text: modelData.ssid || "(Hidden Network)"
											color: Colors.colors.on_background
											font.pixelSize: Appearance.fonts.medium
											font.bold: modelData.active
										}

										MatIcon {
											icon: "lock"
											color: Colors.colors.on_surface_variant
											font.pixelSize: Appearance.fonts.small
											visible: modelData.isSecure
										}
									}

									StyledLabel {
										text: {
											let details = [];
											if (modelData.active) {
												details.push("Connected");
											}
											if (modelData.security && modelData.security !== "--") {
												details.push(modelData.security);
											}
											details.push(modelData.frequency + " MHz");
											return details.join(" • ");
										}
										color: Colors.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.small
									}
								}

								StyledLabel {
									text: modelData.strength + "%"
									color: Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.small
								}

								MatIcon {
									icon: "chevron_right"
									color: Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.medium
									visible: !modelData.active
								}
							}

							MouseArea {
								id: mouseArea
								
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									if (!modelData.active) {
										NetworkManager.connectToNetwork(modelData.ssid, "");
									}
								}
							}
						}
					}
				}

				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true
					visible: NetworkManager.wifiEnabled && NetworkManager.networks.length === 0 && !NetworkManager.scanning

					ColumnLayout {
						anchors.centerIn: parent
						spacing: Appearance.spacing.normal

						MatIcon {
							Layout.alignment: Qt.AlignHCenter
							icon: "wifi_off"
							color: Colors.colors.on_surface_variant
							font.pixelSize: 48
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "No networks found"
							color: Colors.colors.on_surface_variant
							font.pixelSize: Appearance.fonts.medium
						}

						StyledLabel {
							Layout.alignment: Qt.AlignHCenter
							text: "Try refreshing the list"
							color: Colors.colors.on_surface_variant
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
							color: Colors.colors.primary
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
							color: Colors.colors.on_surface_variant
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
