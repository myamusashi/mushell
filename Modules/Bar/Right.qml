pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

import qs.Widgets
import qs.Data
import qs.Components

Loader {
	active: root.isBarOpen
	asynchronous: true

	sourceComponent: StyledRect {
		color: "transparent"
		RowLayout {
			anchors.fill: parent
			anchors.rightMargin: 8
			layoutDirection: Qt.RightToLeft
			spacing: Appearance.spacing.small

			Clock {
				Layout.alignment: Qt.AlignVCenter
				Layout.maximumWidth: implicitWidth
			}
			Tray {
				Layout.alignment: Qt.AlignVCenter
			}
			PowerProfiles {
				Layout.alignment: Qt.AlignVCenter
				Layout.maximumWidth: implicitWidth
			}
			StyledRect {
				Layout.alignment: Qt.AlignVCenter
				Layout.preferredWidth: controlCenterLayout.implicitWidth * 1.1
				Layout.preferredHeight: 25
				color: mArea.containsPress ? Colors.withAlpha(Colors.colors.on_surface, 0.08) : mArea.containsMouse ? Colors.withAlpha(Colors.colors.on_surface, 0.16) : Colors.withAlpha(Colors.colors.on_surface, 0.20)
				radius: Appearance.rounding.normal

				Behavior on color {
					ColAnim {}
				}

				RowLayout {
					id: controlCenterLayout
					anchors.fill: parent
					spacing: Appearance.spacing.small

					Sound {
						Layout.alignment: Qt.AlignVCenter
						Layout.fillHeight: true
					}
					Battery {
						Layout.alignment: Qt.AlignVCenter
						Layout.fillHeight: true
					}
				}

				MouseArea {
					id: mArea

					anchors.fill: parent
					hoverEnabled: true
					onClicked: controlCenterLoader.activeAsync = !controlCenterLoader.activeAsync
				}
			}
		}

		LazyLoader {
			id: controlCenterLoader

			active: false

			component: ControlCenter {
				modelData: bar

				node: Pipewire.defaultAudioSource
			}
		}
	}
}
