pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Services.ScreenRecorder

Item {
    id: root

    anchors {
        bottom: parent.bottom
        right: parent.right
        rightMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize - 0.05 : 0
        bottomMargin: anchors.rightMargin
    }

    implicitWidth: GlobalStates.isRecordingPanelOpen ? 380 : 0
    implicitHeight: parent.height * 0.25
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    property int currentPage: 0

    property bool isHistoryOpen: false
    onIsHistoryOpenChanged: {
        if (isHistoryOpen)
            ScreenCaptureHistory.reloadFiles();
    }

    function openVideoFile(path) {
        Quickshell.execDetached({
            command: [Configs.generals.apps.videoViewer, path]
        });
    }

    CornerPair {
        location1: Qt.BottomLeftCorner
        location2: Qt.TopRightCorner
        extensionSide1: Qt.Horizontal
        extensionSide2: Qt.Vertical
        active: GlobalStates.isRecordingPanelOpen
    }

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    IpcHandler {
        target: "capture"
        function screen(action: string): void {
            ScreenRecorder.screenshotOutput(Quickshell.screens[0]?.name ?? "", action);
        }
        function region(action: string): void {
            ScreenRecorder.screenshotSelection(action);
        }
        function window(action: string): void {
            ScreenRecorder.screenshotWindow(action);
        }
    }

    IpcHandler {
        target: "recorder"
        function start(): void {
            ScreenRecorder.startRecording("", Quickshell.screens[0]?.name ?? "");
        }
        function stop(): void {
            ScreenRecorder.stopRecording();
        }
        function toggle(): void {
            ScreenRecorder.isRecording ? ScreenRecorder.stopRecording() : ScreenRecorder.startRecording("", Quickshell.screens[0]?.name ?? "");
        }
        function status(): bool {
            return ScreenRecorder.isRecording;
        }
    }

    StyledRect {
        id: panelBg

        anchors.fill: parent
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        color: GlobalStates.drawerColors
        clip: true

        Loader {
            anchors.fill: parent
            active: GlobalStates.isRecordingPanelOpen
            sourceComponent: ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.small
                spacing: Appearance.spacing.small

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.larger

                    RowLayout {
                        anchors.fill: parent
                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: "screen_record"
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: qsTr("Screen Recorder")
                            color: Colours.m3Colors.m3OnSurface
                            font.weight: Font.DemiBold
                            font.pixelSize: Appearance.fonts.size.normal
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                        }

                        FloatingButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 28
                            implicitHeight: 28
                            backgroundRadius: Appearance.rounding.normal
                            icon.name: "close"
                            icon.color: Colours.m3Colors.m3OnSurface
                            icon.size: Appearance.fonts.size.large
                            color: "transparent"
                            onClicked: GlobalStates.isRecordingPanelOpen = false
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                    color: ScreenRecorder.isRecording ? Qt.alpha(Colours.m3Colors.m3Red, 0.15) : Colours.m3Colors.m3SurfaceContainerHighest
                    radius: Appearance.rounding.small
                    visible: ScreenRecorder.isRecording

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Appearance.spacing.small
                            rightMargin: Appearance.spacing.small
                        }
                        spacing: Appearance.spacing.small

                        Rectangle {
                            implicitWidth: Appearance.spacing.small
                            implicitHeight: Appearance.spacing.small
                            radius: Appearance.padding.small
                            color: Colours.m3Colors.m3Red

                            SequentialAnimation on opacity {
                                running: ScreenRecorder.isRecording
                                loops: Animation.Infinite
                                PropertyAnimation {
                                    to: 0.3
                                    duration: 600
                                }
                                PropertyAnimation {
                                    to: 1.0
                                    duration: 600
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Recording")
                            color: Colours.m3Colors.m3Red
                            font.weight: Font.DemiBold
                            font.pixelSize: Appearance.fonts.size.normal
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: {
                                const s = ScreenRecorder.recordingElapsedSeconds;
                                const h = Math.floor(s / 3600);
                                const m = Math.floor((s % 3600) / 60);
                                const sec = s % 60;
                                if (h > 0)
                                    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                                return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
                            }
                            color: Colours.m3Colors.m3OnSurface
                            font.family: Appearance.fonts.family.mono
                            font.bold: true
                            font.pixelSize: Appearance.fonts.size.normal
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentPage

                    PageMain {
                        onOpenAudio: root.currentPage = 1
                        onOpenSettings: root.currentPage = 2
                        onOpenHistory: {
                            root.isHistoryOpen = true;
                            root.currentPage = 3;
                        }
                    }

                    PageAudio {
                        onGoBack: root.currentPage = 0
                    }

                    PageSettings {
                        onGoBack: root.currentPage = 0
                    }

                    PageHistory {
                        onGoBack: root.currentPage = 0
                        onOpenFile: path => root.openVideoFile(path)
                    }
                }
            }
        }
    }
}
