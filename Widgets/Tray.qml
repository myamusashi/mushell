pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import qs.Data
import qs.Components

Loader {
	active: root.isBarOpen
	asynchronous: true

	width: parent.width * 0.3

	sourceComponent: Rectangle {
		id: root

		readonly property var parentWindow: bar
		readonly property var parentScreen: bar.modelData
		property real widgetHeight: 25
		readonly property real horizontalPadding: Appearance.spacing.normal

		Layout.preferredWidth: systemTrayRow.width + horizontalPadding * 1.2
		Layout.minimumWidth: visible ? horizontalPadding * 1.2 : 0

		// width: calculatedWidth
		height: widgetHeight
		radius: Appearance.rounding.small
		color: "transparent"
		visible: SystemTray.items.values.length > 0

		Behavior on Layout.preferredWidth {
			NumbAnim {}
		}

		Row {
			id: systemTrayRow
			anchors.centerIn: parent
			spacing: Appearance.spacing.small

			Repeater {
				model: SystemTray.items.values
				delegate: Item {
					id: delegateTray

					required property SystemTrayItem modelData
					property string iconSource: {
						let icon = modelData && modelData.icon;
						if (typeof icon === 'string' || icon instanceof String) {
							if (icon.includes("?path=")) {
								const split = icon.split("?path=");
								if (split.length !== 2)
									return icon;
								const name = split[0];
								const path = split[1];
								const fileName = name.substring(name.lastIndexOf("/") + 1);
								return `file://${path}/${fileName}`;
							}
							return icon;
						}
						return "";
					}

					width: 25
					height: 25

					Rectangle {
						id: bgTrayIcon
						width: 25
						height: 25
						radius: Appearance.rounding.normal
						color: trayItemArea.containsMouse ? Appearance.colors.primary : "transparent"

						Behavior on color {
							ColAnim {}
						}
					}

					IconImage {
						anchors.centerIn: parent
						width: Appearance.fonts.large * 1.2
						height: Appearance.fonts.large * 1.2
						source: parent.iconSource
						asynchronous: true
						smooth: true
						mipmap: true
					}

					MouseArea {
						id: trayItemArea
						anchors.fill: parent
						acceptedButtons: Qt.LeftButton | Qt.RightButton
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor

						onClicked: mouse => {
							if (!delegateTray.modelData)
								return;

							if (mouse.button === Qt.LeftButton && !delegateTray.modelData.onlyMenu) {
								delegateTray.modelData.activate();
								return;
							}

							if (delegateTray.modelData.hasMenu) {
								var validWindow = root.parentWindow;
								if (!validWindow) {
									var item = root.parent;
									while (item && !validWindow) {
										if (item.toString().includes("WlrLayershell")) {
											validWindow = item;
											break;
										}
										item = item.parent;
									}
								}

								if (validWindow) {
									var globalPos = mapToGlobal(0, 0);
									var currentScreen = root.parentScreen || validWindow.screen;
									var screenX = currentScreen ? currentScreen.x : 0;
									var relativeX = globalPos.x - screenX;

									menuAnchor.menu = delegateTray.modelData?.menu;
									menuAnchor.anchor.window = validWindow;
									menuAnchor.anchor.rect = Qt.rect(relativeX, 35 + Appearance.spacing.small, parent.width, 1);
									menuAnchor.open();
								} else {
									console.warn("Cannot find valid Quickshell window for tray menu");
								}
							}
						}
					}
				}
			}
		}

		QsMenuAnchor {
			id: menuAnchor
		}
	}
}
