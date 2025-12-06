pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Components

import "Capture" as Cap
import "History"

Scope {
    id: scope

    GlobalShortcut {
        name: "recordPanel"
        onPressed: GlobalStates.isRecordPanelOpen = !GlobalStates.isRecordPanelOpen
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: root

            required property ShellScreen modelData

            anchors {
                right: true
                left: true
                bottom: true
                top: true
            }

            screen: modelData
            color: "transparent"

            WlrLayershell.namespace: "shell:bar"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Normal
            focusable: true
            exclusiveZone: 0
            surfaceFormat.opaque: false
            visible: GlobalStates.isRecordPanelOpen

            StyledRect {
                anchors.fill: parent
                color: Themes.withAlpha(Themes.m3Colors.m3Surface, 0.3)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    ColumnLayout {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        Layout.topMargin: 15
                        Layout.leftMargin: 15
                        spacing: Appearance.spacing.large
                        Loader {
                            id: captureLoader

                            active: GlobalStates.isRecordPanelOpen
                            asynchronous: true
                            Layout.preferredWidth: item ? item.implicitWidth + 50 : 200
                            Layout.preferredHeight: item ? item.implicitHeight : 0
                            sourceComponent: Cap.Capture {
                                condition: GlobalStates.isRecordPanelOpen
                            }
                        }
                        Loader {
                            id: performanceLoader

                            active: GlobalStates.isRecordPanelOpen
                            asynchronous: true
                            Layout.preferredWidth: item ? item.implicitWidth : 200
                            Layout.preferredHeight: item ? item.implicitHeight : 0
                            sourceComponent: Performance {}
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        spacing: Appearance.spacing.large
                        // Loader {
                        //     id: controlBarLoader
                        //
                        //     active: GlobalStates.isRecordPanelOpen
                        //     asynchronous: true
                        //     Layout.alignment: Qt.AlignHCenter
                        //     Layout.preferredHeight: 80
                        //     Layout.preferredWidth: parent.width
                        //     sourceComponent: ControlBar {}
                        // }
                        Loader {
                            id: historyLoader

                            active: GlobalStates.isRecordPanelOpen
                            asynchronous: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 80
                            Layout.preferredWidth: parent.width
                            sourceComponent: History {}
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        Layout.rightMargin: 15
                        spacing: Appearance.spacing.large
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 100
                            color: "transparent"
                            border.color: Themes.m3Colors.m3Primary
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "WIP"
                                color: Themes.m3Colors.m3OnSurface
                            }
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
