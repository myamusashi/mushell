import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.ScreenRecorder

import "../Components/Base"

StyledRect {
    id: root

    Layout.alignment: Qt.AlignCenter

    implicitWidth: row.width
    visible: ScreenRecorder.isRecording
    color: "transparent"

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        if (h > 0)
            return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
        return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }

    RowLayout {
        id: row

        anchors.centerIn: parent

        Item {
            id: iconStatus

            property bool isHovering: false

            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Icon {
                id: recordIcon

                anchors.centerIn: parent
                type: Icon.Material
                icon: "screen_record"
                font.pixelSize: Appearance.fonts.size.large * 1.3
                color: Colours.m3Colors.m3OnPrimary
                opacity: iconStatus.isHovering ? 0 : 1
                scale: iconStatus.isHovering ? 0.5 : 1.0

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }

            Icon {
                id: stopIcon

                anchors.centerIn: parent
                type: Icon.Material
                icon: "stop_circle"
                font.pixelSize: Appearance.fonts.size.large * 1.3
                color: Colours.m3Colors.m3OnPrimary
                opacity: iconStatus.isHovering ? 1 : 0
                scale: iconStatus.isHovering ? 1.0 : 0.5

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }

            HoverHandler {
                id: hoverArea

                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered)
                        iconStatus.isHovering = true;
                    else
                        iconStatus.isHovering = false;
                }
            }

            TapHandler {
                id: tapHandler

                onTapped: ScreenRecorder.stopRecording()
            }
        }

        StyledText {
            text: root.formatTime(ScreenRecorder.recordingElapsedSeconds)
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
        }
    }
}
