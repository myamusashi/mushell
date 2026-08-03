pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.Core.Configs
import qs.Services

Elevation {
    id: elev

    anchors.fill: parent
    color: "transparent"
    blur: 0
    spread: 0
    z: -1
    level: 3

    property color c0From
    property color c0To
    property bool c0Active: false
    property real c0Blend: 1.0

    onC0BlendChanged: {
        if (!c0Active)
            return;
        if (c0Blend >= 1) {
            color = c0To;
            c0Active = false;
        } else if (c0Blend > 0) {
            color = Colours.blendColors(c0From, c0To, c0Blend);
        }
    }

    NAnim {
        id: c0Anim
        target: elev
        property: "c0Blend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.large * 0.8
    }

    property color c1From
    property color c1To
    property bool c1Active: false
    property real c1Blend: 1.0

    onC1BlendChanged: {
        if (!c1Active)
            return;
        if (c1Blend >= 1) {
            color = c1To;
            c1Active = false;
        } else if (c1Blend > 0) {
            color = Colours.blendColors(c1From, c1To, c1Blend);
        }
    }

    NAnim {
        id: c1Anim
        target: elev
        property: "c1Blend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.large
    }

    SequentialAnimation {
        id: chargeFlash

        ParallelAnimation {
            ScriptAction {
                script: {
                    c0Anim.stop();
                    c0From = elev.color;
                    c0To = Colours.m3Colors.m3Green;
                    c0Active = true;
                    c0Blend = 0.0;
                    c0Anim.start();
                }
            }
            NAnim {
                target: elev
                property: "blur"
                to: Configs.generals.chargingGlowSpread
                duration: Appearance.animations.durations.large * 0.8
            }
            NAnim {
                target: elev
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
                    c1Anim.stop();
                    c1From = elev.color;
                    c1To = "transparent";
                    c1Active = true;
                    c1Blend = 0.0;
                    c1Anim.start();
                }
            }
            NAnim {
                target: elev
                property: "blur"
                to: 0
                duration: Appearance.animations.durations.large
            }
            NAnim {
                target: elev
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
                    c0Anim.stop();
                    c0From = elev.color;
                    c0To = Colours.m3Colors.m3Red;
                    c0Active = true;
                    c0Blend = 0.0;
                    c0Anim.start();
                }
            }
            NAnim {
                target: elev
                property: "blur"
                to: 20
                duration: Appearance.animations.durations.large * 0.8
            }
            NAnim {
                target: elev
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
                    c1Anim.stop();
                    c1From = elev.color;
                    c1To = "transparent";
                    c1Active = true;
                    c1Blend = 0.0;
                    c1Anim.start();
                }
            }
            NAnim {
                target: elev
                property: "blur"
                to: 0
                duration: Appearance.animations.durations.large
            }
            NAnim {
                target: elev
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
