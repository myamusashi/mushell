pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Scope {
    id: root

    property bool isVolumeOSDShow: false
    property bool isCapsLockOSDShow: false
    property bool isNumLockOSDShow: false

    property var osdTimers: ({
            "capslock": null,
            "numlock": null,
            "volume": null
        })

    function startOSDTimer(osdName) {
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 2000; repeat: false; }', root, "dynamicTimer");

        timer.triggered.connect(function () {
            closeOSD(osdName);
            timer.destroy();
            osdTimers[osdName] = null;

            checkAndClosePanelWindow();
        });

        if (osdTimers[osdName]) {
            osdTimers[osdName].stop();
            osdTimers[osdName].destroy();
        }

        osdTimers[osdName] = timer;
        timer.start();
    }

    function closeOSD(osdName) {
        if (osdName === "capslock")
            root.isCapsLockOSDShow = false;
        else if (osdName === "numlock")
            root.isNumLockOSDShow = false;
        else if (osdName === "volume")
            root.isVolumeOSDShow = false;
    }

    function checkAndClosePanelWindow() {
        if (!root.isVolumeOSDShow && !root.isCapsLockOSDShow && !root.isNumLockOSDShow)
            cleanup.start();
    }

    Connections {
        target: KeyLockState.state

        function onCapsLockChanged() {
            root.isCapsLockOSDShow = true;
            root.startOSDTimer("capslock");
        }
        function onNumLockChanged() {
            root.isNumLockOSDShow = true;
            root.startOSDTimer("numlock");
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            root.isVolumeOSDShow = true;
            root.startOSDTimer("volume");
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: {
            gc();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: OuterShapeItem {
            id: panelWindow

            content: mainRect

            StyledRect {
                id: mainRect

                anchors {
					right: parent.right
                    bottom: parent.bottom
				}

				width: root.isVolumeOSDShow || root.isNumLockOSDShow || root.isCapsLockOSDShow ? 250 : 0
                height: root.isVolumeOSDShow || root.isNumLockOSDShow || root.isCapsLockOSDShow ? calculateHeight() : 0
				radius: 0
				topLeftRadius: Appearance.rounding.normal
                color: Themes.m3Colors.m3Background
                clip: true

				Behavior on width {
					NAnim {
						duration: Appearance.animations.durations.small
                    }
				}

                Behavior on height  {
					NAnim {
						duration: Appearance.animations.durations.small
                    }
                }

                function calculateHeight() {
                    var totalHeight = 0;
                    var spacing = 10;
                    var padding = 10;

                    if (root.isCapsLockOSDShow)
                        totalHeight += 50;
                    if (root.isNumLockOSDShow)
                        totalHeight += 50;
                    if (root.isVolumeOSDShow)
                        totalHeight += 80;

                    var activeCount = 0;
                    if (root.isCapsLockOSDShow)
                        activeCount++;
                    if (root.isNumLockOSDShow)
                        activeCount++;
                    if (root.isVolumeOSDShow)
                        activeCount++;

                    if (activeCount > 1)
                        totalHeight += (activeCount - 1) * spacing;

                    return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
				}

                Column {
					id: osdColumn

                    anchors {
                        fill: parent
                        margins: 15
                    }
                    spacing: Appearance.spacing.normal

                    CapsLockWidget {
                        id: capsLockOSD
                        isCapsLockOSDShow: root.isCapsLockOSDShow
                    }

                    NumLockWidget {
                        id: numLockOSD
                        isNumLockOSDShow: root.isNumLockOSDShow
                    }

                    Volumes {
                        id: volumeOSD

                        isVolumeOSDShow: root.isVolumeOSDShow
                    }
                }
            }
        }
    }
}
