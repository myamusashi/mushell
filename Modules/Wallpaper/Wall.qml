pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

import qs.Configs
import qs.Helpers
import qs.Components

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
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
        layer: WlrLayer.Background
        focusable: false
        exclusiveZone: 1
        exclusionMode: ExclusionMode.Ignore
        surfaceFormat.opaque: false
        namespace: "shell:wallpaper"

        Wallpaper {
            id: img

            anchors.fill: parent
            source: ""

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
                    animatinRect.width = 0;
                });
            }
        }

        Rectangle {
            id: animatinRect

            anchors.right: parent.right
            color: "transparent"
            height: root.screen.height
            width: 0

            NAnim {
                id: walAnimation

                duration: Appearance.animations.durations.expressiveDefaultSpatial * 2
                from: 0
                property: "width"
                target: animatinRect
                to: Math.max(root.screen.width)
            }

            Wallpaper {
                id: animatingWal

                anchors.right: parent.right
                height: root.height
                source: ""
                width: root.width
            }
        }

        IpcHandler {
            target: "img"

            function set(path: string): void {
                Quickshell.execDetached({
                    command: ["sh", "-c", "echo " + path + " >" + Paths.currentWallpaperFile + " && " + `matugen image ${path}`]
                });
            }
            function get(): string {
                return Paths.currentWallpaper;
            }
        }
    }
}
