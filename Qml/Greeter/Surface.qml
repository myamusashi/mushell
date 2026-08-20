pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import Vast.Utils

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Auth auth

    readonly property bool useVideoWallpaper: configLoaded ? configUseVideo : false
    readonly property string wallpaperPath: useVideoWallpaper ? (configLoaded ? configVideoPath : "/etc/vast-shell/wallpaper.mp4") : (configLoaded ? configStaticPath : "/etc/vast-shell/wallpaper.png")
    property bool configLoaded: false
    property bool configUseVideo: false
    property string configStaticPath: ""
    property string configVideoPath: ""
    readonly property string assetWallpaper: Paths.projectRoot + "/Assets/images/wallpaper.png"
    property string greeterThumbnailJob: ""
    function greeterThumbnailPath() {
        return `${Paths.cacheDir}/vast-shell/greeter-wallpaper-${Qt.md5(root.greeterThumbnailJob)}.png`;
    }
    property url effectiveWallpaper: useVideoWallpaper ? "file://" + wallpaperPath : wallpaperPath
    property bool effectiveIsVideo: useVideoWallpaper

    FileView {
        path: "/etc/vast-shell/greeter.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const json = JSON.parse(text());
                root.configUseVideo = json.useVideoWallpaper === true;
                if (json.staticWallpaper)
                    root.configStaticPath = json.staticWallpaper;
                if (json.videoWallpaper)
                    root.configVideoPath = json.videoWallpaper;
                root.configLoaded = true;
            } catch (error) {}
        }
    }

    readonly property var fallbackColors: ({
            scrim: Colours.m3Colors.m3Scrim,
            onBackground: Colours.m3Colors.m3OnBackground,
            onSurface: Colours.m3Colors.m3OnSurface,
            onSurfaceVariant: Colours.m3Colors.m3OnSurfaceVariant,
            surfaceContainerHigh: Colours.m3Colors.m3SurfaceContainerHigh,
            surfaceContainerHighest: Colours.m3Colors.m3SurfaceContainerHighest,
            outlineVariant: Colours.m3Colors.m3OutlineVariant,
            primaryContainer: Colours.m3Colors.m3PrimaryContainer,
            onPrimaryContainer: Colours.m3Colors.m3OnPrimaryContainer,
            primary: Colours.m3Colors.m3Primary,
            onPrimary: Colours.m3Colors.m3OnPrimary,
            error: Colours.m3Colors.m3Error,
            secondary: Colours.m3Colors.m3Secondary,
            secondaryContainer: Colours.m3Colors.m3SecondaryContainer,
            onSecondaryContainer: Colours.m3Colors.m3OnSecondaryContainer
        })
    property var dynColors: root.fallbackColors

    color: "transparent"

    Component.onCompleted: {
        if (!root.effectiveIsVideo)
            ColorGenerator.generateColors(root.effectiveWallpaper.toString().replace(/^file:\/\//, ""), Configs.colors.scheme);
        root.playEntrance();
    }

    function playEntrance() {
        background.opacity = 0;
        background.blurRadius = 0;
        entranceSequence.restart();
    }

    function playExit() {
        exitSequence.start();
    }

    Connections {
        target: root.lock

        function onLockedChanged() {
            if (root.lock.locked)
                root.playEntrance();
        }
    }

    Connections {
        target: root.auth

        function onLaunchReady() {
            root.playExit();
        }
    }

    Connections {
        target: ColorGenerator

        function onColorsReady(imagePath, colors) {
            if (imagePath === root.effectiveWallpaper.toString().replace(/^file:\/\//, ""))
                root.dynColors = colors;
        }
    }

    Item {
        id: background

        anchors.fill: parent
        opacity: 0
        scale: 1.0
        transformOrigin: Item.Center
        property real blurRadius: 0
        layer.enabled: true
        layer.effect: FastBlur {
            source: background
            radius: background.blurRadius
            transparentBorder: false
        }

        Image {
            anchors.fill: parent
            source: root.effectiveIsVideo ? "" : root.effectiveWallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        Image {
            id: staticProbe

            source: root.useVideoWallpaper ? "" : "file://" + root.wallpaperPath
            visible: false
            onStatusChanged: {
                if (status === Image.Ready) {
                    root.effectiveWallpaper = "file://" + root.wallpaperPath;
                    root.effectiveIsVideo = false;
                    ColorGenerator.generateColors(root.wallpaperPath, Configs.colors.scheme);
                } else if (status === Image.Error) {
                    root.effectiveWallpaper = root.assetWallpaper;
                    root.effectiveIsVideo = false;
                    ColorGenerator.generateColors(root.assetWallpaper.replace(/^file:\/\//, ""), Configs.colors.scheme);
                }
            }
        }

        MediaPlayer {
            id: videoPlayer

            source: root.useVideoWallpaper ? "file://" + root.wallpaperPath : ""
            loops: MediaPlayer.Infinite
            videoOutput: videoOutput
            onMediaStatusChanged: {
                if (!root.useVideoWallpaper)
                    return;
                if (mediaStatus === MediaPlayer.LoadedMedia) {
                    root.effectiveWallpaper = "file://" + root.wallpaperPath;
                    root.effectiveIsVideo = true;
                    play();
                    root.greeterThumbnailJob = root.wallpaperPath;
                    greeterThumbnailExtractor.running = true;
                } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                    root.effectiveWallpaper = root.assetWallpaper;
                    root.effectiveIsVideo = false;
                    ColorGenerator.generateColors(root.assetWallpaper.replace(/^file:\/\//, ""), Configs.colors.scheme);
                }
            }
        }

        Process {
            id: greeterThumbnailExtractor

            command: ["sh", "-c", `test -s ${JSON.stringify(root.greeterThumbnailPath())} || ffmpeg -y -loglevel error -i ${JSON.stringify(root.greeterThumbnailJob)} -frames:v 1 ${JSON.stringify(root.greeterThumbnailPath())}`]
            running: root.greeterThumbnailJob !== ""
            onExited: function (exitCode, exitStatus) { // qmllint disable signal-handler-parameters
                root.greeterThumbnailJob = "";
                ColorGenerator.generateColors(root.greeterThumbnailPath(), Configs.colors.scheme);
            }
        }

        VideoOutput {
            id: videoOutput

            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            visible: root.useVideoWallpaper
        }

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on blurRadius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Column {
        id: clockColumn

        anchors {
            top: parent.top
            topMargin: Appearance.margin.large * 4
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Appearance.spacing.smaller

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Time.date, "HH:mm")
            color: root.dynColors.onBackground
            font.pixelSize: 72
            font.weight: Font.Medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(Time.date, "dddd, d MMMM")
            color: root.dynColors.onSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
        }
    }

    UserCard {
        id: userCard

        anchors.centerIn: parent
        auth: root.auth
        colors: root.dynColors
        opacity: 0
        scale: 0.9
    }

    Item {
        id: powerControls

        anchors {
            bottom: parent.bottom
            bottomMargin: Appearance.margin.large * 2
            right: parent.right
            rightMargin: Appearance.margin.large * 2
        }
        implicitWidth: powerRow.implicitWidth
        implicitHeight: powerRow.implicitHeight
        opacity: 0

        RowLayout {
            id: powerRow

            spacing: Appearance.spacing.small

            StyledButton {
                icon.name: "restart_alt"
                icon.color: root.dynColors.onSurface
                color: Qt.alpha(root.dynColors.surfaceContainerHighest, 0.8)
                leftPad: 12
                rightPad: 12

                onClicked: Quickshell.execDetached({
                    command: ["systemctl", "reboot"]
                })
            }

            StyledButton {
                icon.name: "power_settings_new"
                icon.color: root.dynColors.onSurface
                color: Qt.alpha(root.dynColors.surfaceContainerHighest, 0.8)
                leftPad: 12
                rightPad: 12

                onClicked: Quickshell.execDetached({
                    command: ["systemctl", "poweroff"]
                })
            }
        }
    }

    ParallelAnimation {
        id: entranceSequence

        NAnim {
            target: background
            property: "opacity"
            to: 1
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }

        NAnim {
            target: background
            property: "blurRadius"
            to: 12
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }

        NAnim {
            target: powerControls
            property: "opacity"
            to: 1
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }

        NAnim {
            target: userCard
            property: "opacity"
            to: 1
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }

        NAnim {
            target: userCard
            property: "scale"
            to: 1
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    SequentialAnimation {
        id: exitSequence

        ParallelAnimation {
            NAnim {
                target: background
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: background
                property: "blurRadius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: background
                property: "scale"
                to: 1.15
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: powerControls
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: userCard
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: userCard
                property: "scale"
                to: 0.9
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: root.lock.locked = false
        }
    }
}
