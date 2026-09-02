pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    property int sourceMode: 0
    property string selectedMonitor: Quickshell.screens[0]?.name ?? ""

    property string audioLabel: qsTr("No Audio")

    function updateAudioLabel() {
        if (!CaptureScreenVideo.includeAudio) {
            audioLabel = qsTr("No Audio");
        } else if (CaptureScreenVideo.audioDeviceDescription) {
            audioLabel = CaptureScreenVideo.audioDeviceDescription;
        } else {
            audioLabel = qsTr("Choose an audio source...");
        }
    }

    Connections {
        target: CaptureScreenVideo

        function onIncludeAudioChanged() {
            root.updateAudioLabel();
        }
        function onAudioDeviceChanged() {
            root.updateAudioLabel();
        }
    }

    Component.onCompleted: root.updateAudioLabel()

    signal openAudio
    signal openSettings
    signal openHistory

    color: "transparent"
    radius: 0
    clip: true

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: columnLayout.implicitHeight

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: columnLayout

            width: flickable.width
            spacing: Appearance.spacing.small

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: innerColumn.implicitHeight + Appearance.margin.small * 2
                color: Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small

                ColumnLayout {
                    id: innerColumn

                    anchors {
                        fill: parent
                        margins: Appearance.margin.small
                    }
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Source")
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        spacing: Appearance.spacing.small

                        Repeater {
                            model: [
                                {
                                    name: qsTr("Full Screen"),
                                    icon: "monitor"
                                },
                                {
                                    name: qsTr("Region"),
                                    icon: "select"
                                },
                                {
                                    name: qsTr("Window"),
                                    icon: "select_window_2"
                                }
                            ]

                            delegate: StyledRect {
                                id: mainDelegate

                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                Layout.margins: Appearance.margin.normal
                                color: index === root.sourceMode ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (sourceButtonMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                                radius: Appearance.rounding.small
                                border.color: index === root.sourceMode ? Qt.alpha(Colours.m3Colors.m3Primary, 0.4) : "transparent"
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Appearance.padding.small

                                    Icon {
                                        type: Icon.Material
                                        icon: mainDelegate.modelData.icon
                                        color: mainDelegate.index === root.sourceMode ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.large
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    StyledText {
                                        text: mainDelegate.modelData.name
                                        color: mainDelegate.index === root.sourceMode ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: mainDelegate.index === root.sourceMode ? Font.DemiBold : Font.Normal
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MArea {
                                    id: sourceButtonMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.sourceMode = mainDelegate.index
                                }
                            }
                        }
                    }

                    Loader {
                        active: root.sourceMode === 0
                        Layout.preferredHeight: active ? implicitHeight : 0
                        Layout.fillHeight: true

                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Monitor:")
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                            }

                            Repeater {
                                model: Quickshell.screens

                                delegate: StyledRect {
                                    id: screensDelegate
                                    required property ShellScreen modelData
                                    required property int index

                                    Layout.preferredHeight: Appearance.spacing.small + Appearance.fonts.size.medium
                                    implicitWidth: monitorLabel.implicitWidth + Appearance.margin.smaller
									// qmlformat off
									color: modelData.name === root.selectedMonitor
										? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : (monitorButtonMouseArea.containsMouse
										? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
									// qmlformat on
                                    radius: Appearance.rounding.small

                                    StyledText {
                                        id: monitorLabel
                                        anchors.centerIn: parent
                                        text: screensDelegate.modelData.name
                                        color: screensDelegate.modelData.name === root.selectedMonitor ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: screensDelegate.modelData.name === root.selectedMonitor ? Font.DemiBold : Font.Normal
                                    }

                                    MArea {
                                        id: monitorButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedMonitor = screensDelegate.modelData.name
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: audioRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.margin.smaller
                    anchors.rightMargin: Appearance.margin.smaller
                    spacing: Appearance.spacing.small

                    Icon {
                        type: Icon.Material
                        icon: CaptureScreenVideo.includeAudio ? "mic" : "mic_off"
                        color: CaptureScreenVideo.includeAudio ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }

                    StyledText {
                        text: root.audioLabel
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Icon {
                        type: Icon.Material
                        icon: "chevron_right"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }
                }

                MArea {
                    id: audioRowMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openAudio()
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: settingsRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.margin.smaller
                        rightMargin: Appearance.margin.smaller
                    }
                    spacing: Appearance.spacing.small

                    Icon {
                        type: Icon.Material
                        icon: "tune"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }

                    StyledText {
                        text: qsTr("Settings")
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        Layout.fillWidth: true
                    }

                    Icon {
                        type: Icon.Material
                        icon: "chevron_right"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }
                }

                MArea {
                    id: settingsRowMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openSettings()
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                color: historyRowMouseArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.05) : "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.margin.smaller
                        rightMargin: Appearance.margin.smaller
                    }
                    spacing: Appearance.spacing.small

                    Icon {
                        type: Icon.Material
                        icon: "history"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }

                    StyledText {
                        text: qsTr("Recordings")
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        Layout.fillWidth: true
                    }

                    Icon {
                        type: Icon.Material
                        icon: "chevron_right"
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                    }
                }

                MArea {
                    id: historyRowMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.openHistory()
                }
            }

            Item {
                Layout.fillHeight: true
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.larger
                Layout.bottomMargin: Appearance.margin.large
                color: "transparent"
                radius: Appearance.rounding.small

                RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.smaller

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        Layout.preferredHeight: Appearance.spacing.normal + Appearance.spacing.large
                        implicitWidth: buttonLabel.implicitWidth + Appearance.margin.large + 15
						// qmlformat off
						color: CaptureScreenVideo.isRecording
							? (recordButtonMouseArea.containsMouse
								? Qt.alpha(Colours.m3Colors.m3Error, 0.3)
								: Qt.alpha(Colours.m3Colors.m3Error, 0.2))
							: (recordButtonMouseArea.containsMouse
								? Qt.alpha(Colours.m3Colors.m3Red, 0.3)
								: Qt.alpha(Colours.m3Colors.m3Red, 0.2))
						// qmlformat on
                        radius: Appearance.rounding.full
                        border.color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                        border.width: 2

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Appearance.padding.small

                            Rectangle {
                                implicitWidth: Appearance.margin.smaller
                                implicitHeight: Appearance.margin.smaller
                                radius: CaptureScreenVideo.isRecording ? Appearance.padding.small : Appearance.margin.small
                                color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                                Behavior on radius {
                                    NAnim {
                                        duration: Appearance.animations.durations.small
                                    }
                                }
                            }

                            StyledText {
                                id: buttonLabel
                                text: CaptureScreenVideo.isRecording ? qsTr("Stop") : qsTr("Start Recording")
                                color: CaptureScreenVideo.isRecording ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Red
                                font.weight: Font.DemiBold
                                font.pixelSize: Appearance.fonts.size.normal
                            }
                        }

                        MArea {
                            id: recordButtonMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (CaptureScreenVideo.isRecording) {
                                    CaptureScreenVideo.stopRecording();
                                } else {
                                    switch (root.sourceMode) {
                                    case 0:
                                        CaptureScreenVideo.startRecording("", root.selectedMonitor);
                                        GlobalStates.isRecordingPanelOpen = false;
                                        break;
                                    case 1:
                                        GlobalStates.isRecordingPanelOpen = false;
                                        ScreenCapture.openRegionSelector();
                                        break;
                                    case 2:
                                        ScreenCapture.recordWindow();
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
