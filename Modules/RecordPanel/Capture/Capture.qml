pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ClippingRectangle {
    id: root

    property bool condition: false
    property int state: 0
    property string icon: Audio.getIcon(root.node)
    property PwNode node: Pipewire.defaultAudioSource
    property bool isExpandSeeMyCaptureOpen: false
    property bool isRecording: false

    PwObjectTracker {
        objects: [root.node]
    }

    implicitWidth: 200
    implicitHeight: columnLayout.implicitHeight
    color: Themes.m3Colors.m3SurfaceContainer
    radius: Appearance.rounding.small

    FileView {
        id: pidStatusRecording

        path: "/tmp/wl-screenrec.pid"
        watchChanges: true
        blockLoading: true
        onFileChanged: {
            reload();
            if (text().trim() != "")
                root.isRecording = true;
            else
                root.isRecording = false;
        }
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
			radius: 0
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

            MaterialIcon {
                icon: "screen_record"
                color: Themes.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.extraLarge
            }

            StyledText {
                text: "Capture"
                color: Themes.m3Colors.m3OnSurface
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.fonts.large * 1.5
            }

            Item {
                Layout.fillWidth: true
            }

            MaterialIcon {
                icon: "close"
                color: Themes.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.extraLarge

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
        color: Themes.m3Colors.m3SurfaceContainerHigh
        radius: 0
        Layout.fillWidth: true
        Layout.preferredHeight: rowLayout.implicitHeight + 30


        RowLayout {
            id: rowLayout

            anchors.centerIn: parent
            spacing: width * 0.2

            Repeater {
                model: [
                    {
                        icon: "photo_camera",
                        label: "Screenshot",
                        action: () => {
                            Quickshell.execDetached({
                                command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenshot-selection"]
							});
                            scope.open = false;
                        }
                    },
                    {
                        icon: "fiber_manual_record",
                        label: "Start",
                        action: () => {
                            Quickshell.execDetached({
                                command: ["sh", "-c", Quickshell.shellDir + "/Assets/screen-capture.sh --screenrecord-selection"]
                            });
                            scope.open = false;
                        },
                        highlight: root.isRecording
                    },
                    {
                        icon: root.icon,
                        label: "Microphone",
                        action: () => Audio.toggleMute(root.node)
                    }
                ]

                delegate: Item {
                    id: controlDelegate

                    required property var modelData
                    required property int index

                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 70

                    StyledRect {
                        anchors.centerIn: parent
                        width: 60
                        height: 60
                        color: controlDelegate.modelData.highlight ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3SurfaceContainerHighest
                        radius: Appearance.rounding.full

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: controlDelegate.modelData.icon
                            color: controlDelegate.modelData.highlight ? Themes.m3Colors.m3OnPrimary : Themes.m3Colors.m3OnSurface
                            font.pixelSize: 24
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: controlDelegate.modelData.action()
                        }
                    }
                }
            }
        }
    }

    component SeeMyCapture: StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: seeMyCaptureLayout.implicitHeight + 30
        color: Themes.m3Colors.m3SurfaceContainerHighest
        radius: 0

        RowLayout {
            id: seeMyCaptureLayout

            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            MaterialIcon {
                icon: "capture"
                color: Themes.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.large
            }

            StyledText {
                text: "See my captures"
                color: Themes.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.large * 1.2
            }
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isExpandSeeMyCaptureOpen = !root.isExpandSeeMyCaptureOpen
        }
    }
}
