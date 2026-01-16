pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Configs
import qs.Helpers
import qs.Components

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: root

        required property ShellScreen modelData

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: "transparent"
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        surfaceFormat.opaque: true
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "shell:wallpaper"

        Wallpaper {
            id: img

            anchors.fill: parent
            source: ""
            sourceSize: Qt.size(root.modelData.width, root.modelData.height)

            Component.onCompleted: {
                source = Paths.currentWallpaper;

                Paths.currentWallpaperChanged.connect(() => {
                    if (walAnimation.running)
                        walAnimation.complete();
                    animatingWal.source = Paths.currentWallpaper;
                });

                animatingWal.statusChanged.connect(() => {
                    if (animatingWal.status == Image.Ready)
                        walAnimation.start();
                });

                walAnimation.finished.connect(() => {
                    img.source = animatingWal.source;
                    animatingWal.source = "";
                    animatinRect.opacity = 0;
                });
            }
        }

        Rectangle {
            id: animatinRect

            anchors.fill: parent
            color: "transparent"
            opacity: 0
            visible: opacity > 0

            NAnim {
                id: walAnimation

                duration: Appearance.animations.durations.expressiveDefaultSpatial * 2
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                from: 0
                property: "opacity"
                target: animatinRect
                to: 1
            }

            Wallpaper {
                id: animatingWal

                anchors.fill: parent
                source: ""
                sourceSize: Qt.size(root.modelData.width, root.modelData.height)
            }
        }

        IpcHandler {
            target: "img"

            function set(path: string): void {
                Quickshell.execDetached({
                    "command": ["sh", "-c", "echo " + path + " >" + Paths.currentWallpaperFile + " && " + `matugen image ${path}`]
                });
            }
            function get(): string {
                return Paths.currentWallpaper;
            }
        }
    }
}
