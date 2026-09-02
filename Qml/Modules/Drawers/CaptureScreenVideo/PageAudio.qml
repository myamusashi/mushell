pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    signal goBack

    color: "transparent"
    radius: 0
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
            color: "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.small
                }
                spacing: Appearance.spacing.small

                Icon {
                    type: Icon.Material
                    icon: "arrow_back"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                }

                StyledText {
                    text: qsTr("Audio Input")
                    color: Colours.m3Colors.m3OnSurface
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            MArea {
                id: backButtonMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.goBack()
            }
        }

        Flickable {
            id: flickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: columnLayout.implicitHeight

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: columnLayout

                implicitWidth: parent.width
                implicitHeight: Appearance.margin.normal + Appearance.fonts.size.normal
                spacing: Appearance.padding.small

                StyledText {
                    text: qsTr("Microphones")
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    leftPadding: Appearance.margin.smaller
                    topPadding: Appearance.padding.small
                }

                Repeater {
                    model: CaptureScreenVideo.sources()
                    delegate: AudioDeviceItem {
                        required property var modelData

                        audioName: modelData.name
                        audioDescription: modelData.description || modelData.name
                        iconName: "mic"
                        isSelected: modelData.name === CaptureScreenVideo.audioDevice
                        onSelect: name => {
                            CaptureScreenVideo.audioDevice = name;
                            CaptureScreenVideo.audioDeviceDescription = modelData.description || modelData.name;
                            CaptureScreenVideo.includeAudio = true;
                            root.goBack();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.leftMargin: Appearance.margin.smaller
                    Layout.rightMargin: Appearance.margin.smaller
                    color: Qt.alpha(Colours.m3Colors.m3Outline, 0.15)
                }

                StyledText {
                    text: qsTr("Desktop Audio")
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    leftPadding: Appearance.margin.smaller
                    topPadding: Appearance.padding.small
                }

                Repeater {
                    model: CaptureScreenVideo.monitors()
                    delegate: AudioDeviceItem {
                        required property var modelData

                        audioName: modelData.name
                        audioDescription: modelData.description || modelData.name
                        iconName: "speaker"
                        isSelected: modelData.name === CaptureScreenVideo.audioDevice
                        onSelect: name => {
                            CaptureScreenVideo.audioDevice = name;
                            CaptureScreenVideo.audioDeviceDescription = modelData.description || modelData.name;
                            CaptureScreenVideo.includeAudio = true;
                            root.goBack();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.leftMargin: Appearance.margin.smaller
                    Layout.rightMargin: Appearance.margin.smaller
                    color: Qt.alpha(Colours.m3Colors.m3Outline, 0.15)
                }

                AudioDeviceItem {
                    audioName: ""
                    audioDescription: qsTr("No Audio")
                    iconName: "mic_off"
                    isSelected: !CaptureScreenVideo.includeAudio
                    onSelect: {
                        CaptureScreenVideo.audioDevice = "";
                        CaptureScreenVideo.audioDeviceDescription = "";
                        CaptureScreenVideo.includeAudio = false;
                        root.goBack();
                    }
                }
            }
        }
    }
}
