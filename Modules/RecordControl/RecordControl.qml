pragma ComponentBehavior: Bound

import QtQuick.Layouts
import QtQuick

import Quickshell.Hyprland
import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

LazyLoader {
    activeAsync: Record.isRecordingControlOpen
    component: FloatingWindow {
        id: root

        title: "Recording Widgets"
        implicitWidth: Hypr.focusedMonitor.width * 0.15
        implicitHeight: Hypr.focusedMonitor.width * 0.12

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
            color: Colours.m3Colors.m3SurfaceContainerHigh
            radius: Appearance.rounding.large
            border.color: Colours.m3Colors.m3Outline
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
                        color: Colours.m3Colors.m3Error

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: Record.isRecordingControlOpen

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
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
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
                        color: "transparent"

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animations.durations.small * 0.8
                            }
                        }

                        MaterialIcon {
                            id: closeIcon

                            anchors.centerIn: parent
                            icon: "close"
                            font.pointSize: Appearance.fonts.size.large
                            color: Colours.m3Colors.m3OnSurfaceVariant
                        }

                        MArea {
                            id: closeButtonMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Record.isRecordingControlOpen = false
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
                        color: Colours.m3Colors.m3SurfaceContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                icon: "schedule"
                                font.pointSize: Appearance.fonts.size.large
                                color: Colours.m3Colors.m3Primary
                            }

                            StyledText {
                                text: root.formatTime(Record.recordingSeconds)
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large * 1.2
                                font.bold: true
                                font.family: Appearance.fonts.family.mono
                            }
                        }
                    }

                    StyledRect {
                        id: stopButton

                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 45
                        radius: Appearance.rounding.normal
                        color: stopButtonMouse.pressed ? Colours.withAlpha(Colours.m3Colors.m3Error, 0.8) : stopButtonMouse.containsMouse ? Colours.m3Colors.m3Error : Colours.withAlpha(Colours.m3Colors.m3Error, 0.9)

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
                                font.pointSize: Appearance.fonts.size.large
                                color: Colours.m3Colors.m3OnError
                            }

                            StyledText {
                                text: "Stop"
                                color: Colours.m3Colors.m3OnError
                                font.pixelSize: Appearance.fonts.size.normal
                                font.bold: true
                            }
                        }

                        MArea {
                            id: stopButtonMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached({
                                                            "command": ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --stop-recording"]
                                                        });

                                Record.recordingTimer.stop();
                                Record.recordingSeconds = 0;
                                Record.isRecordingControlOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
