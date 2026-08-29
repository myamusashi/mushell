pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.Core.Configs
import qs.Services
import Vast.Utils

Elevation {
    id: elevation

    anchors.fill: parent
    color: "transparent"
    blur: 0
    spread: 0
    z: -1
    level: 3

    property color flashInFrom
    property color flashInTo
    property bool flashInActive: false
    property real flashInBlend: 1.0

    onFlashInBlendChanged: {
        if (!flashInActive)
            return;
        if (flashInBlend >= 1) {
            color = flashInTo;
            flashInActive = false;
        } else if (flashInBlend > 0) {
            color = ColorUtils.blendColors(flashInFrom, flashInTo, flashInBlend);
        }
    }

    NAnim {
        id: flashInAnim
        target: elevation
        property: "flashInBlend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.large * 0.8
    }

    property color flashOutFrom
    property color flashOutTo
    property bool flashOutActive: false
    property real flashOutBlend: 1.0

    onFlashOutBlendChanged: {
        if (!flashOutActive)
            return;
        if (flashOutBlend >= 1) {
            color = flashOutTo;
            flashOutActive = false;
        } else if (flashOutBlend > 0) {
            color = ColorUtils.blendColors(flashOutFrom, flashOutTo, flashOutBlend);
        }
    }

    NAnim {
        id: flashOutAnim
        target: elevation
        property: "flashOutBlend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.large
    }

    SequentialAnimation {
        id: chargeFlash

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashInAnim.stop();
                    flashInFrom = elevation.color;
                    flashInTo = Colours.m3Colors.m3Green;
                    flashInActive = true;
                    flashInBlend = 0.0;
                    flashInAnim.start();
                }
            }
            NAnim {
                target: elevation
                property: "blur"
                to: Configs.generals.chargingGlowSpread
                duration: Appearance.animations.durations.large * 0.8
            }
            NAnim {
                target: elevation
                property: "spread"
                to: Configs.generals.chargingGlowSpread
                duration: Appearance.animations.durations.large * 0.8
            }
        }

        PauseAnimation {
            duration: 800
        }

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashOutAnim.stop();
                    flashOutFrom = elevation.color;
                    flashOutTo = "transparent";
                    flashOutActive = true;
                    flashOutBlend = 0.0;
                    flashOutAnim.start();
                }
            }
            NAnim {
                target: elevation
                property: "blur"
                to: 0
                duration: Appearance.animations.durations.large
            }
            NAnim {
                target: elevation
                property: "spread"
                to: 0
                duration: Appearance.animations.durations.large
            }
        }
    }

    SequentialAnimation {
        id: lowFlash

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashInAnim.stop();
                    flashInFrom = elevation.color;
                    flashInTo = Colours.m3Colors.m3Red;
                    flashInActive = true;
                    flashInBlend = 0.0;
                    flashInAnim.start();
                }
            }
            NAnim {
                target: elevation
                property: "blur"
                to: 20
                duration: Appearance.animations.durations.large * 0.8
            }
            NAnim {
                target: elevation
                property: "spread"
                to: 20
                duration: Appearance.animations.durations.large * 0.8
            }
        }

        PauseAnimation {
            duration: 800
        }

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashOutAnim.stop();
                    flashOutFrom = elevation.color;
                    flashOutTo = "transparent";
                    flashOutActive = true;
                    flashOutBlend = 0.0;
                    flashOutAnim.start();
                }
            }
            NAnim {
                target: elevation
                property: "blur"
                to: 0
                duration: Appearance.animations.durations.large
            }
            NAnim {
                target: elevation
                property: "spread"
                to: 0
                duration: Appearance.animations.durations.large
            }
        }
    }

    Connections {
        target: UPower.displayDevice

        function onStateChanged() {
            if (UPower.displayDevice.state === UPowerDeviceState.Charging)
                chargeFlash.restart();
        }
        function onPercentageChanged() {
            const percentage = Math.round(UPower.displayDevice.percentage * 100);
            const levels = Configs.generals.battery.warnLevels;
            const warn = levels.find(e => e.level === percentage);

            if (warn) {
                lowFlash.restart();
                Quickshell.execDetached({
                    command: ["notify-send", "-a", "vast-shell", "-i", warn.icon, warn.title, warn.message, "-u", warn.level === percentage ? warn.urgency : "normal"]
                });
            }
        }
    }
}
