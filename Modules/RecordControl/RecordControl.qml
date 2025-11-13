pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Hyprland
import Quickshell
import QtQuick.Layouts
import QtQuick

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: scope

	property bool isRecordingControlOpen: false
	property int recordingSeconds: 0

	FileView {
		id: pidStatusRecording

		path: "/tmp/wl-screenrec.pid"
		watchChanges: true
		blockLoading: true
		onFileChanged: {
			reload();
			if (text().trim() != "") {
				scope.recordingSeconds = 0;
				scope.isRecordingControlOpen = true;
			} else {
				scope.recordingSeconds = 0;
				scope.isRecordingControlOpen = false;
			}
		}
	}

	Timer {
		id: recordingTimer

		interval: 1000
		repeat: true
		running: scope.isRecordingControlOpen
		onTriggered: scope.recordingSeconds++
	}

	LazyLoader {
		active: scope.isRecordingControlOpen

		component: FloatingWindow {
			id: root

			title: "Recording Widgets"

			visible: true
			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale

			implicitWidth: monitorWidth * 0.15
			implicitHeight: monitorWidth * 0.12

			color: "transparent"

			function formatTime(seconds) {
				const hours = Math.floor(seconds / 3600);
				const minutes = Math.floor((seconds % 3600) / 60);
				const secs = seconds % 60;

				if (hours > 0) {
					return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:
${String(secs).padStart(2, '0')}`;
				}
				return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
			}

			StyledRect {
				anchors.fill: parent
				color: Themes.colors.surface_container_high
				radius: Appearance.rounding.large
				border.color: Themes.colors.outline
				border.width: 1

				ColumnLayout {
					anchors.fill: parent
					anchors.margins: Appearance.spacing.normal
					spacing: Appearance.spacing.small

					RowLayout {
						Layout.fillWidth: true
						spacing: Appearance.spacing.normal

						Rectangle {
							id: recordingDot

							Layout.preferredWidth: 12
							Layout.preferredHeight: 12
							radius: 6
							color: Themes.colors.error

							SequentialAnimation on opacity {
								loops: Animation.Infinite
								running: pidStatusRecording.text().trim() !== ""
								NumberAnimation {
									to: 0.3
									duration: 800
								}
								NumberAnimation {
									to: 1.0
									duration: 800
								}
							}
						}

						StyledText {
							id: header

							text: "Screen Recording"
							color: Themes.colors.on_surface
							font.pixelSize: Appearance.fonts.normal
							font.bold: true
						}

						Item {
							Layout.fillWidth: true
						}

						StyledRect {
							id: closeButton

							Layout.preferredWidth: 28
							Layout.preferredHeight: 28
							radius: Appearance.rounding.large
							color: closeButtonMouse.pressed ? Themes.colors.secondary_container :
															  closeButtonMouse.containsMouse ? Themes.withAlpha(Themes.colors.on_surface, 0.08) :
																							   "transparent"

							Behavior on color {
								ColAnim {
									duration: 100
								}
							}

							MatIcon {
								id: closeIcon

								anchors.centerIn: parent
								icon: "close"
								font.pixelSize: Appearance.fonts.large
								color: Themes.colors.on_surface_variant
							}

							MouseArea {
								id: closeButtonMouse

								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: scope.isRecordingControlOpen = false
							}
						}
					}

					RowLayout {
						Layout.fillWidth: true
						Layout.fillHeight: true
						spacing: Appearance.spacing.large

						StyledRect {
							Layout.fillWidth: true
							Layout.preferredHeight: 45
							radius: Appearance.rounding.normal
							color: Themes.colors.surface_container

							RowLayout {
								anchors.centerIn: parent
								spacing: Appearance.spacing.small

								MatIcon {
									icon: "schedule"
									font.pixelSize: Appearance.fonts.large
									color: Themes.colors.primary
								}

								StyledText {
									text: root.formatTime(scope.recordingSeconds)
									color: Themes.colors.on_surface
									font.pixelSize: Appearance.fonts.large * 1.2
									font.bold: true
									font.family: Appearance.fonts.family_Mono
								}
							}
						}

						StyledRect {
							id: stopButton

							Layout.preferredWidth: 100
							Layout.preferredHeight: 45
							radius: Appearance.rounding.normal
							color: stopButtonMouse.pressed ? Themes.withAlpha(Themes.colors.error, 0.8) : stopButtonMouse.containsMouse
															 ? Themes.colors.error : Themes.withAlpha(Themes.colors.error, 0.9)

							Behavior on color {
								ColAnim {
									duration: 150
									easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
								}
							}

							transform: Scale {
								origin.x: stopButton.width / 2
								origin.y: stopButton.height / 2
								xScale: stopButtonMouse.pressed ? 0.95 : 1.0
								yScale: stopButtonMouse.pressed ? 0.95 : 1.0

								Behavior on xScale {
									NumbAnim {
										duration: 100
									}
								}
								Behavior on yScale {
									NumbAnim {
										duration: 100
									}
								}
							}

							RowLayout {
								anchors.centerIn: parent
								spacing: Appearance.spacing.small

								MatIcon {
									icon: "stop"
									font.pixelSize: Appearance.fonts.large
									color: Themes.colors.on_error
								}

								StyledText {
									text: "Stop"
									color: Themes.colors.on_error
									font.pixelSize: Appearance.fonts.normal
									font.bold: true
								}
							}

							MouseArea {
								id: stopButtonMouse

								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									scope.isRecordingControlOpen = false;
									recordingTimer.stop();
									scope.recordingSeconds = 0;
									Quickshell.execDetached({
																command: ["sh", "-c", Quickshell.shellDir
																	+ "/Assets/screen-capture.sh --stop-recording"]
															});
									scope.isRecordingControlOpen = false;
								}
							}
						}
					}
				}
			}
		}
	}
}
