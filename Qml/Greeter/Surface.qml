pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell
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

    readonly property string wallpaperPath: Paths.projectRoot + "/Assets/images/wallpaper.png"

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
        ColorGenerator.generateColors(root.wallpaperPath, Configs.colors.scheme);
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
            if (imagePath === root.wallpaperPath)
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
            source: root.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
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
