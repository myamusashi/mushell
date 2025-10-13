pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data
import qs.Components
import "Inbox" as Inbox

Scope {
	id: root

	property bool isDashboardOpen: false
	property int currentIndex: 0
	property int baseWidth: 1366
	property int baseHeight: 768
	property int baseSectionWidth: 455
	property int baseSectionHeight: baseWidth
	property int cpuUsage: 0
	property int ramUsage: 0

	function toggleDashboard(): void {
		isDashboardOpen = !isDashboardOpen;
	}

	LazyLoader {
		id: dashboardLoader

		activeAsync: root.isDashboardOpen

		component: PanelWindow {
			id: dashboard

			property ShellScreen modelData

			anchors {
				top: true
				bottom: true
				right: true
				left: true
			}

			WlrLayershell.namespace: "shell:dashboard"
			visible: true
			focusable: true
			color: Colors.withAlpha(Colors.colors.background, 0.2)
			screen: modelData
			exclusiveZone: -1
			implicitWidth: root.baseWidth
			implicitHeight: root.baseHeight

			StyledRect {
				anchors.fill: parent
				anchors.margins: 20
				color: "transparent"

				Item {
					anchors.fill: parent
					focus: true
					Keys.onEscapePressed: root.toggleDashboard()

					RowLayout {
						anchors.fill: parent
						spacing: Appearance.spacing.large

						ColumnLayout {
							id: notifsAndWeatherLayout
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignTop
							Layout.maximumHeight: parent.height
							Layout.preferredWidth: root.baseWidth / 3
							Layout.minimumWidth: 400

							Loader {
								Layout.fillWidth: true
								Layout.preferredHeight: parent.height * 0.06
								active: root.isDashboardOpen
								asynchronous: true
								sourceComponent: Inbox.Header {}
							}

							Loader {
								Layout.fillWidth: true
								Layout.preferredHeight: parent.height - 70
								active: root.isDashboardOpen
								asynchronous: true
								sourceComponent: Inbox.Notification {}
							}
						}

						ColumnLayout {
							id: performanceLayout

							Layout.fillWidth: true
							Layout.fillHeight: true
							Layout.preferredWidth: root.baseWidth / 3
							Layout.minimumWidth: 400

							Loader {
								id: performanceLoader

								Layout.fillWidth: true
								Layout.preferredHeight: 400
								active: root.isDashboardOpen
								sourceComponent: Performance {}
							}

							Loader {
								id: weatherLoader

								Layout.fillWidth: true
								Layout.preferredHeight: 350
								Layout.topMargin: 8
								active: root.isDashboardOpen
								asynchronous: true
								sourceComponent: WeatherWidget {
									Layout.fillWidth: true
									Layout.preferredHeight: 350
									Layout.topMargin: 8
								}
							}
						}

						ColumnLayout {
							id: mprisLayout

							Layout.fillWidth: true
							Layout.fillHeight: true
							Layout.preferredWidth: root.baseWidth / 3
							Layout.minimumWidth: 400

							Loader {
								id: mediaPlayerLoader

								Layout.fillWidth: true
								Layout.fillHeight: true
								active: root.isDashboardOpen
								asynchronous: true
								sourceComponent: MediaPlayer {}
							}

							Loader {
								id: calendarLoader

								Layout.fillWidth: true
								Layout.preferredHeight: 370
								active: root.isDashboardOpen
								asynchronous: true
								sourceComponent: Calendar {
									Layout.fillWidth: true
									Layout.preferredHeight: 370
								}
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "dashboard"

		function toggle(): void {
			root.toggleDashboard();
		}
	}
}
