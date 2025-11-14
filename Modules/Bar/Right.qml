pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Widgets
import qs.Helpers
import qs.Components
import qs.Modules.QuickSettings

Loader {
    active: true
    asynchronous: true

    sourceComponent: RowLayout {
        Layout.alignment: Qt.AlignLeft | Qt.AlignCenter
        layoutDirection: Qt.RightToLeft
        spacing: Appearance.spacing.small

        Clock {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: implicitWidth
        }
        NotificationDots {
            Layout.alignment: Qt.AlignVCenter
        }
        Tray {}
        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: quickSettingsLayout.implicitWidth * 1.1
            Layout.preferredHeight: 25
            color: mArea.containsPress ? Themes.withAlpha(
                                             Themes.colors.surface_container_highest,
                                             0.08) : mArea.containsMouse ? Themes.withAlpha(Themes.colors.surface_container_highest, 0.1) : Themes.colors.surface_container
            radius: Appearance.rounding.normal

            Behavior on color {
                ColAnim {}
            }

            RowLayout {
                id: quickSettingsLayout

                anchors.fill: parent
                spacing: Appearance.spacing.small

                Sound {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                }
                Battery {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                    widthBattery: 33
                    heightBattery: 18
                }
            }

            MArea {
                id: mArea

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor
                onClicked: quickSettings.isControlCenterOpen = !quickSettings.isControlCenterOpen
            }
        }
    }

    QuickSettings {
        id: quickSettings
    }
}
