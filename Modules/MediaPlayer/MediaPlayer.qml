pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Scope {
    id: root

    property bool isMediaPlayerOpen: false

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);

        if (hours > 0)
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

        return `${minutes}:${secs.toString().padStart(2, '0')}`;
    }

    property string url: ""

    function getTrackUrl(): void {
        trackUrl.running = true;
    }

    Process {
        id: trackUrl

        command: ["sh", "-c", "playerctl metadata | grep xesam:url | awk '{print $3}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                root.url = res;
            }
        }
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            root.url = "";
            gc();
        }
    }

    LazyLoader {
        active: root.isMediaPlayerOpen
        onActiveChanged: {
            cleanup.start();
        }

        component: PanelWindow {
            anchors {
                top: true
            }
            property real monitorWidth: Hypr.focusedMonitor.width
            implicitWidth: monitorWidth * 0.25
            implicitHeight: container.implicitHeight
            exclusiveZone: 0

            margins.right: (monitorWidth - implicitWidth) / 2

            color: "transparent"

            StyledRect {
                id: container

                implicitWidth: parent.width
                implicitHeight: contentLayout.implicitHeight + 15
                color: Themes.m3Colors.m3Surface
                radius: Appearance.rounding.normal

                RowLayout {
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

                            sourceComponent: Item {
                                anchors.fill: parent
                                Image {
                                    id: coverArt

                                    anchors.fill: parent
                                    source: Mpris.active && Mpris.active.trackArtUrl !== "" ? Mpris.active.trackArtUrl : "root:/Assets/kuru.gif"
                                    fillMode: Image.PreserveAspectCrop
                                    visible: Mpris.active !== null
                                    opacity: 0.5
                                    cache: false
                                    asynchronous: true

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: mask
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    width: 120
                                    text: "Achievement Unlocked: 🏆 Static Image Starer - You expected the kuru spin but trackArtUrl decided to disconnect. GG."
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    color: Themes.m3Colors.m3OnSurface
                                    visible: Mpris.active && Mpris.active.trackArtUrl === ""
                                }

                                AnimatedImage {
                                    id: coverNullArt

                                    anchors.fill: parent
                                    visible: Mpris.active === null
                                    asynchronous: true
                                    cache: false
                                    source: Mpris.active === null ? "root:/Assets/kuru.gif" : ""
                                }

                                Item {
                                    id: mask

                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "white"
                                        radius: Appearance.rounding.small
                                    }
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
                                text: Mpris.active ? Mpris.active.trackTitle : ""
                                color: Themes.m3Colors.m3OnBackground
                                font.pixelSize: Appearance.fonts.large
                                wrapMode: Text.NoWrap
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.preferredWidth: 50

                                StyledText {
                                    Layout.preferredWidth: width
                                    text: Mpris.active ? Mpris.active.trackArtist : ""
                                    color: Themes.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.small
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: Mpris.active ? "•" : ""
                                    color: Themes.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.extraLarge
                                }

                                StyledText {
                                    text: Mpris.active ? "Watched on " : ""
                                    color: Themes.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.small
                                }

                                IconImage {
                                    source: Quickshell.iconPath(Mpris.active.desktopEntry)
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

                                text: Mpris.active == null ? "00:00" : `${root.formatTime(Mpris.active?.position)}:${root.formatTime(Mpris.active?.length)}`
                                font.pixelSize: Appearance.fonts.large
                                color: Themes.m3Colors.m3OnBackground

                                Timer {
                                    running: Mpris.active !== null && Mpris.active.playbackState == MprisPlaybackState.Playing
                                    interval: 1000
                                    repeat: true
                                    onTriggered: Mpris.active.positionChanged()
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            MaterialIcon {
                                id: pauseButton

                                icon: Mpris.active === null ? "pause_circle" : Mpris.active.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                                color: {
                                    if (pauseMArea.pressed)
                                        return Themes.withAlpha(Themes.m3Colors.m3Primary, 0.08);
                                    else if (pauseMArea.containsMouse)
                                        return Themes.withAlpha(Themes.m3Colors.m3Primary, 0.12);
                                    else
                                        return Themes.m3Colors.m3Primary;
                                }
                                font.pointSize: Appearance.fonts.extraLarge * 1.5

                                MArea {
                                    id: pauseMArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Mpris.active ? Mpris.active.togglePlaying() : ""
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            spacing: Appearance.spacing.normal

                            StyledButton {
                                iconButton: "skip_previous"
                                iconSize: 10
                                onClicked: Mpris.active ? Mpris.active.previous() : {}
                            }

                            StyledSlide {
                                id: barSlide

                                value: Mpris.active === null ? 0 : Mpris.active.length > 0 ? Mpris.active.position / Mpris.active.length : 0

                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                valueWidth: 0
                                valueHeight: 0

                                FrameAnimation {
                                    running: Mpris.active && Mpris.active.playbackState == MprisPlaybackState.Playing
                                    onTriggered: Mpris.active.positionChanged()
                                }

                                onMoved: Mpris.active ? Mpris.active.position = value * Mpris.active.length : {}
                            }

                            StyledButton {
                                iconButton: "skip_next"
                                iconSize: 10
                                onClicked: Mpris.active ? Mpris.active.next() : {}
                            }
                        }
                    }
                }
            }
        }
    }
}
