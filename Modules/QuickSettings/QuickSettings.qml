pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Components

import "Settings"

Scope {
	id: scope

	property bool isControlCenterOpen: false
	property int state: 0

	function toggleControlCenter(): void {
		isControlCenterOpen = !isControlCenterOpen;
	}

	GlobalShortcut {
		name: "ControlCenter"
		onPressed: scope.toggleControlCenter()
	}

	LazyLoader {
		active: scope.isControlCenterOpen

		component: PanelWindow {
			id: root

			anchors {
				top: true
				right: true
			}

			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale
			property real scaleFactor: Math.min(1.0, monitorWidth / monitor.width)

			implicitWidth: monitorWidth * 0.3
			implicitHeight: 500
			exclusiveZone: 1
			color: "transparent"

			margins.right: (monitorWidth - implicitWidth) / 5.5

			ColumnLayout {
				anchors.fill: parent
				spacing: 0

				TabRows {
					id: tabBar

					state: scope.state
					scaleFactor: root.scaleFactor

					onTabClicked: index => {
						scope.state = index;
						controlCenterStackView.currentItem.viewIndex = index;
					}
				}

				StyledRect {
					Layout.fillWidth: true
					height: 1
					color: Themes.colors.outline_variant
				}

				StackView {
					id: controlCenterStackView

					Layout.fillWidth: true
					Layout.fillHeight: true

					property Component viewComponent: contentView

					initialItem: viewComponent
					onCurrentItemChanged: {
						if (currentItem)
						currentItem.viewIndex = scope.state;
					}

					Component {
						id: contentView

						StyledRect {
							color: Themes.colors.surface
							topLeftRadius: 5
							topRightRadius: 5
							property int viewIndex: 0

							Loader {
								anchors.fill: parent
								active: parent.viewIndex === 0
								visible: active

								sourceComponent: Settings {}
							}

							Loader {
								anchors.fill: parent
								active: parent.viewIndex === 1
								visible: active

								sourceComponent: VolumeSettings {}
							}

							Loader {
								anchors.fill: parent
								active: parent.viewIndex === 2
								visible: active

								sourceComponent: Performances {}
							}

							Loader {
								anchors.fill: parent
								active: parent.viewIndex === 3
								visible: active

								sourceComponent: Weathers {}
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "controlCenter"
		function toggle(): void {
			scope.toggleControlCenter();
		}
	}
}
