pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell.Hyprland
import Quickshell
import QtQuick.Layouts
import QtQuick

import qs.Configs
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

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    LazyLoader {
        active: scope.isRecordingControlOpen
        onActiveChanged: {
            cleanup.start();
        }

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

                if (hours > 0)
                    return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

                return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
            }

            StyledRect {
                anchors.fill: parent
                color: Themes.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.large
                border.color: Themes.m3Colors.m3Outline
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
                            color: Themes.m3Colors.m3Error

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: pidStatusRecording.text().trim() !== ""

                                NAnim {
                                    to: 0.3
                                    duration: Appearance.animations.durations.extraLarge
                                }
                                NAnim {
                                    to: 1.0
                                    duration: Appearance.animations.durations.extraLarge
                                }
                            }
                        }

                        StyledText {
                            id: header

                            text: "Screen Recording"
                            color: Themes.m3Colors.m3OnSurface
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
                            color: closeButtonMouse.pressed ? Themes.m3Colors.m3SecondaryContainer : closeButtonMouse.containsMouse ? Themes.withAlpha(Themes.m3Colors.m3OnSurface, 0.08) : "transparent"

                            Behavior on color {
                                CAnim {
                                    duration: Appearance.animations.durations.small * 0.8
                                }
                            }

                            MaterialIcon {
                                id: closeIcon

                                anchors.centerIn: parent
                                icon: "close"
                                font.pointSize: Appearance.fonts.large
                                color: Themes.m3Colors.m3OnSurfaceVariant
                            }

                            MArea {
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
                            color: Themes.m3Colors.m3SurfaceContainer

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small

                                MaterialIcon {
                                    icon: "schedule"
                                    font.pointSize: Appearance.fonts.large
                                    color: Themes.m3Colors.m3Primary
                                }

                                StyledText {
                                    text: root.formatTime(scope.recordingSeconds)
                                    color: Themes.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.large * 1.2
                                    font.bold: true
                                    font.family: Appearance.fonts.familyMono
                                }
                            }
                        }

                        StyledRect {
                            id: stopButton

                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 45
                            radius: Appearance.rounding.normal
                            color: stopButtonMouse.pressed ? Themes.withAlpha(Themes.m3Colors.m3Error, 0.8) : stopButtonMouse.containsMouse ? Themes.m3Colors.m3Error : Themes.withAlpha(Themes.m3Colors.m3Error, 0.9)

                            Behavior on color {
                                CAnim {
                                    duration: Appearance.animations.durations.small
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }

                            transform: Scale {
                                origin.x: stopButton.width / 2
                                origin.y: stopButton.height / 2
                                xScale: stopButtonMouse.pressed ? 0.95 : 1.0
                                yScale: stopButtonMouse.pressed ? 0.95 : 1.0

                                Behavior on xScale {
                                    NAnim {
                                        duration: 100
                                    }
                                }
                                Behavior on yScale {
                                    NAnim {
                                        duration: 100
                                    }
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small

                                MaterialIcon {
                                    icon: "stop"
                                    font.pointSize: Appearance.fonts.large
                                    color: Themes.m3Colors.onError
                                }

                                StyledText {
                                    text: "Stop"
                                    color: Themes.m3Colors.onError
                                    font.pixelSize: Appearance.fonts.normal
                                    font.bold: true
                                }
                            }

                            MArea {
                                id: stopButtonMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    scope.isRecordingControlOpen = false;
                                    recordingTimer.stop();
                                    scope.recordingSeconds = 0;
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --stop-recording"]
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
