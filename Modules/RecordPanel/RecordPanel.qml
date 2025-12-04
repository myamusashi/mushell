pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Services
import qs.Components

import "Capture" as Cap

Scope {
    id: scope

    property bool open: false

    GlobalShortcut {
        name: "recordPanel"
        onPressed: scope.open = !scope.open
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
            visible: scope.open

            StyledRect {
                anchors.fill: parent
                color: Themes.withAlpha(Themes.m3Colors.m3Surface, 0.3)

                RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.large

                    ColumnLayout {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        Layout.topMargin: 15
                        Layout.leftMargin: 15
                        spacing: Appearance.spacing.large

                        Loader {
                            id: captureLoader

                            active: scope.open
                            asynchronous: true
                            Layout.preferredWidth: item ? item.implicitWidth + 50 : 200
                            Layout.preferredHeight: item ? item.implicitHeight : 0
                            sourceComponent: Cap.Capture {
                                condition: scope.open
                            }
                        }

                        Loader {
                            id: performanceLoader

                            active: scope.open
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
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        spacing: Appearance.spacing.large

                        //                  Loader {
                        // id: controlBarLoader
                        //                      active: scope.open
                        //                      asynchronous: true
                        //                      Layout.fillWidth: true
                        //                      Layout.preferredHeight: 80
                        //                      sourceComponent: ControlBar {}
                        //                  }
                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width / 3
                        Layout.rightMargin: 15
                        spacing: Appearance.spacing.large

                        Rectangle {
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
