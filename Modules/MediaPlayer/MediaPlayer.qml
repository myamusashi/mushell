pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

ClippingRectangle {
    id: root

    property bool isMediaPlayerOpen: GlobalStates.isMediaPlayerOpen
    property string url: ""

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);

        if (hours > 0)
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

        return `${minutes}:${secs.toString().padStart(2, '0')}`;
    }

    implicitWidth: Hypr.focusedMonitor.width * 0.3
    implicitHeight: isMediaPlayerOpen ? contentLoader.implicitHeight + 20 : 0
    color: Themes.m3Colors.m3Surface
    radius: 0
    bottomLeftRadius: Appearance.rounding.normal
    bottomRightRadius: bottomLeftRadius

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: 0
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        active: root.isMediaPlayerOpen
        asynchronous: true
        sourceComponent: RowLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: 10
            spacing: Appearance.spacing.normal

            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                color: "transparent"

                Loader {
                    active: root.isMediaPlayerOpen
                    anchors.centerIn: parent
                    width: 120
                    height: 120

                    sourceComponent: ClippingRectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        Image {
                            id: coverArt

                            anchors.fill: parent
                            source: Players.active && Players.active.trackArtUrl !== "" ? Players.active.trackArtUrl : "root:/Assets/kuru.gif"
                            sourceSize: Qt.size(120, 120)
                            fillMode: Image.PreserveAspectCrop
                            visible: Players.active !== null
                            opacity: 0.5
                            cache: false
                            asynchronous: true
                        }

                        StyledText {
                            anchors.centerIn: parent
                            width: 120
                            text: "Achievement Unlocked: 🏆 Static Image Starer - You expected the kuru spin but trackArtUrl decided to disconnect. GG."
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            color: Themes.m3Colors.m3OnSurface
                            visible: Players.active && Players.active.trackArtUrl === ""
                        }

                        AnimatedImage {
                            id: coverNullArt

                            anchors.fill: parent
                            visible: Players.active === null
                            asynchronous: true
                            cache: true
                            source: Players.active === null ? "root:/Assets/kuru.gif" : ""
                        }
                    }
                }
            }

            ColumnLayout {
                id: controlLayout

                Layout.fillWidth: true

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    spacing: 2

                    StyledLabel {
                        width: parent.width
                        text: Players.active ? Players.active.trackTitle : ""
                        color: Themes.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.large
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.preferredWidth: 50

                        StyledText {
                            Layout.preferredWidth: width
                            text: Players.active ? Players.active.trackArtist : ""
                            color: Themes.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.small
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: Players.active ? "•" : ""
                            color: Themes.m3Colors.m3OnBackground
                            font.pixelSize: Appearance.fonts.extraLarge
                        }

                        StyledText {
                            text: Players.active ? "Watched on " : ""
                            color: Themes.m3Colors.m3OnBackground
                            font.pixelSize: Appearance.fonts.small
                        }

                        IconImage {
                            source: Quickshell.iconPath(Players.active.desktopEntry)
                            asynchronous: true
                            implicitWidth: 20
                            implicitHeight: 20

                            MArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally(root.url)
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 5
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    spacing: 10

                    StyledText {
                        id: timeTrack

                        text: Players.active == null ? "00:00" : `${root.formatTime(Players.active?.position)} / ${root.formatTime(Players.active?.length)}`
                        font.pixelSize: Appearance.fonts.large
                        color: Themes.m3Colors.m3OnBackground

                        Timer {
                            running: root.isMediaPlayerOpen && Players.active !== null && Players.active.playbackState == MprisPlaybackState.Playing
                            interval: 1000
                            repeat: true
                            onTriggered: Players.active.positionChanged()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    MaterialIcon {
                        id: pauseButton

                        icon: Players.active === null ? "pause_circle" : Players.active.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        color: Themes.m3Colors.m3Primary
                        font.pointSize: Appearance.fonts.extraLarge * 1.5

                        MArea {
                            id: pauseMArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active ? Players.active.togglePlaying() : ""
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        iconButton: "skip_previous"
                        iconSize: Appearance.fonts.large * 1.2
                        buttonTextColor: Themes.m3Colors.m3OnPrimary
                        mArea.layerColor: "transparent"
                        onClicked: Players.active ? Players.active.previous() : {}
                    }

                    Wavy {
                        id: barSlide

                        value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        FrameAnimation {
                            running: root.isMediaPlayerOpen && Players.active && Players.active.playbackState == MprisPlaybackState.Playing
                            onTriggered: Players.active.positionChanged()
                        }

                        onMoved: Players.active ? Players.active.position = value * Players.active.length : {}
                    }

                    StyledButton {
                        iconButton: "skip_next"
                        iconSize: Appearance.fonts.large * 1.2
                        buttonTextColor: Themes.m3Colors.m3OnPrimary
                        mArea.layerColor: "transparent"
                        onClicked: Players.active ? Players.active.next() : {}
                    }
                }
            }
        }
    }
}
