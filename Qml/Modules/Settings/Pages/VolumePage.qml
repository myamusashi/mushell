pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Button
import "../Components"
import "./Volume"

SettingsPageBase {
    id: root

    pageTitle: qsTr("Volume")

    property int currentTab: 0

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Appearance.margin.large
        spacing: Appearance.spacing.large

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Item {
                Layout.fillWidth: true
            }

            ConnectedButtonGroup {
                id: tabBar

                Layout.alignment: Qt.AlignHCenter
                fillWidth: true
                Layout.fillWidth: true

                model: [
                    {
                        icon: "graphic_eq",
                        label: qsTr("Playback")
                    },
                    {
                        icon: "speaker",
                        label: qsTr("Output Devices")
                    },
                    {
                        icon: "mic",
                        label: qsTr("Input Devices")
                    },
                    {
                        icon: "tune",
                        label: qsTr("Configuration")
                    }
                ]
                currentIndex: root.currentTab
                onClicked: idx => root.currentTab = idx
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentTab === 0
            visible: root.currentTab === 0
            sourceComponent: PlaybackTab {}
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentTab === 1
            visible: root.currentTab === 1
            sourceComponent: OutputDevicesTab {}
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentTab === 2
            visible: root.currentTab === 2
            sourceComponent: InputDevicesTab {}
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.currentTab === 3
            visible: root.currentTab === 3
            sourceComponent: ConfigurationTab {}
        }
    }
}
