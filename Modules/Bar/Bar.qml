// Thx Rexiel for your Bar PR on quickshell-mirror
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Configs
import qs.Components

Scope {
    id: root

    property bool isBarOpen: true

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: bar

            required property ShellScreen modelData
            property real cornerRadius: 12

            anchors {
                left: true
                right: true
                top: true
            }
            color: "transparent"
            WlrLayershell.namespace: "shell:bar"
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            implicitHeight: 40
            exclusiveZone: 1
            surfaceFormat.opaque: false
            visible: root.isBarOpen

			Cornery {
				screen: bar.screen
                visible: bar.visible
                exclusiveZone: -1
                barColor: Themes.m3Colors.m3Background
                exclusionMode: ExclusionMode.Ignore
            }

            Item {
                anchors.fill: parent

                StyledRect {
                    id: base

                    color: "transparent"
                    anchors.fill: parent
                    radius: 0

                    RowLayout {
                        width: parent.width
                        anchors {
                            leftMargin: 5
                            rightMargin: 5
                        }
                        anchors.fill: parent
                        Left {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width / 6
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                            onActiveChanged: {
                                cleanup.start();
                            }
                        }
                        Middle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width / 6
							Layout.alignment: Qt.AlignCenter

							onActiveChanged: {
                                cleanup.start();
                            }
                        }
                        Right {
                            Layout.fillHeight: true
                            Layout.preferredWidth: parent.width / 6
							Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

							onActiveChanged: {
                                cleanup.start();
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "layerShell"
        function toggle(): void {
            root.isBarOpen = !root.isBarOpen;
        }
    }
}
