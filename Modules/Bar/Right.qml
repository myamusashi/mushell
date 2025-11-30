pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
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
            Layout.alignment: Qt.AlignRight
        }
        Tray {}
        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: quickSettingsLayout.implicitWidth * 1.1
            Layout.preferredHeight: 25
            color: Themes.m3Colors.m3SurfaceContainer
            radius: Appearance.rounding.normal

            Behavior on color {
                CAnim {}
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
