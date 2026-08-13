pragma ComponentBehavior: Bound

import QtQuick

import Quickshell

import qs.Components.Base
import qs.Core.Configs

PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"

    WallpaperView {
        id: wallpaper

        anchors.fill: parent
    }

    Component.onCompleted: {
        entranceSequence.start();
    }

    SequentialAnimation {
        id: entranceSequence

        ParallelAnimation {
            NAnim {
                target: wallpaper
                property: "wallpaperOpacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }
}
