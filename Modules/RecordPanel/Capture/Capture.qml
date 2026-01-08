pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ClippingRectangle {
    id: root

    property bool condition: false
    property int state: 0
    property string icon: Audio.getIcon(root.node)
    property PwNode node: Pipewire.defaultAudioSource
    property bool isExpandSeeMyCaptureOpen: false
    property bool isRecording: false

    implicitWidth: 350
    implicitHeight: columnLayout.implicitHeight
    color: Colours.m3Colors.m3SurfaceContainer
    radius: Appearance.rounding.small

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;

        if (hours > 0)
            return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

        return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }

    PwObjectTracker {
        objects: [root.node]
    }

    Process {
        id: pidStatusRecording

        command: ["sh", "-c", "cat /tmp/wl-screenrec.pid"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim();
                if (data !== "")
                    root.isRecording = true;
                else
                    root.isRecording = false;
            }
        }
    }

    Timer {
        id: pidCheckTimer

        interval: 2000
        repeat: true
        running: true
        onTriggered: pidStatusRecording.running = true
    }

    ColumnLayout {
        id: columnLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Header {}
        Control {}
        SeeMyCapture {}

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 15
            visible: root.isExpandSeeMyCaptureOpen
        }

        AudioCapture {
            visible: root.isExpandSeeMyCaptureOpen
            state: root.state
            onTabClicked: index => root.state = index
        }
    }

    component Header: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                type: Icon.Material
                icon: "screen_record"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
            }

            StyledText {
                text: "Capture"
                color: Colours.m3Colors.m3OnSurface
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.fonts.size.large * 1.5
            }

            Item {
                Layout.fillWidth: true
            }

            Icon {
                type: Icon.Material
                icon: "close"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge

                MArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = !root.visible
                }
            }
        }
    }

    component Control: StyledRect {
        color: Colours.m3Colors.m3SurfaceContainerHigh
        radius: 0
        Layout.fillWidth: true
        Layout.preferredHeight: rowLayout.implicitHeight + 70

        RowLayout {
            id: rowLayout

            anchors.centerIn: parent
            spacing: width * 0.2

            Repeater {
                model: [
                    {
                        "icon": "photo_camera",
                        "label": "Screenshot",
                        "action": () => {
                            Quickshell.execDetached({
                                "command": ["sh", "-c", Paths.rootDir + "/Assets/screen-capture.sh --screenshot-selection"]
                            });
                            root.open = false;
                        }
                    },
                    {
                        "icon": "fiber_manual_record",
                        "label": "Start",
                        "action": () => {
                            Quickshell.execDetached({
                                "command": ["sh", "-c", Paths.rootDir + "/Assets/screen-capture.sh --screenrecord-selection"]
                            });
                            root.open = root.isRecording ? false : true;
                        },
                        "highlight": root.isRecording,
                        "showRecordTime": Record.recordingSeconds
                    },
                    {
                        "icon": root.icon,
                        "label": "Microphone",
                        "action": () => Audio.toggleMute(root.node)
                    }
                ]

                delegate: Item {
                    id: controlDelegate

                    required property var modelData
                    required property int index

                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 70

                    StyledRect {
                        id: iconRect

                        anchors.centerIn: parent
                        implicitWidth: 60
                        implicitHeight: 60
                        color: controlDelegate.modelData.highlight ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainerHighest
                        radius: Appearance.rounding.full

                        Icon {
                            id: iconItem

                            anchors.centerIn: parent
                            icon: controlDelegate.modelData.icon
                            color: controlDelegate.modelData.highlight ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: 24
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: controlDelegate.modelData.action()
                        }
                    }

                    StyledText {
                        visible: controlDelegate.modelData.showRecordTime !== undefined && root.isRecording
                        anchors {
                            top: iconRect.bottom
                            topMargin: 2
                            horizontalCenter: iconRect.horizontalCenter
                        }
                        text: root.formatTime(Record.recordingSeconds)
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large
                        font.bold: true
                        font.family: Appearance.fonts.family.mono
                    }
                }
            }
        }
    }

    component SeeMyCapture: StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: seeMyCaptureLayout.implicitHeight + 30
        color: Colours.m3Colors.m3SurfaceContainerHighest
        radius: 0

        RowLayout {
            id: seeMyCaptureLayout

            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Icon {
                type: Icon.Material
                icon: "capture"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }

            StyledText {
                text: "See my captures"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.2
            }
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isExpandSeeMyCaptureOpen = !root.isExpandSeeMyCaptureOpen
        }
    }
}
