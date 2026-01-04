import QtQuick
import Quickshell.Services.UPower

import qs.Components
import qs.Configs
import qs.Services

Item {
    id: root

    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batPercentage: UPower.displayDevice.percentage
    readonly property real batFill: batteryBody.width * (batPercentage / 100.0)
    property real chargeFillIndex: 0
    property int widthBattery: 26
    property int heightBattery: 12

    implicitWidth: widthBattery + 4
    implicitHeight: heightBattery

    onBatChargingChanged: {
        if (root.batCharging)
            root.chargeFillIndex = root.batPercentage * 100;
    }

    StyledRect {
        id: batteryBody

        implicitWidth: root.widthBattery
        implicitHeight: root.heightBattery
        clip: true
        color: "transparent"
        radius: Appearance.rounding.small * 0.5

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        border {
            width: 2
            color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Colours.withAlpha(Colours.m3Colors.m3Outline, 0.5)
        }

        StyledRect {
            id: batteryFill

            anchors {
                left: parent.left
                leftMargin: 2
                top: parent.top
                topMargin: 2
                bottom: parent.bottom
                bottomMargin: 2
            }
            implicitWidth: root.batCharging ? (parent.width - 4) * (root.chargeFillIndex / 100.0) : (parent.width - 4) * root.batPercentage
            color: {
                if (root.batCharging)
                    return Colours.m3Colors.m3Green;
                if (root.batPercentage <= 0.2)
                    return Colours.m3Colors.m3Red;
                if (root.batPercentage <= 0.5)
                    return Colours.m3Colors.m3Yellow;
                return Colours.m3Colors.m3OnSurface;
            }
            radius: parent.radius - 2

            Behavior on width {
                enabled: !root.batCharging
                NAnim {}
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.batPercentage * 100)
            font {
                pixelSize: batteryBody.height * 0.65
                weight: Font.Bold
            }
            color: root.batPercentage <= 0.5 ? Colours.m3Colors.m3OnBackground : Colours.m3Colors.m3Surface
        }
    }

    StyledRect {
        id: batteryTip

        implicitWidth: 2
        implicitHeight: 5
        anchors {
            left: batteryBody.right
            leftMargin: 0.5
            verticalCenter: parent.verticalCenter
        }
        color: root.batPercentage <= 0.2 && !root.batCharging ? Colours.m3Colors.m3Error : Colours.withAlpha(Colours.m3Colors.m3Outline, 0.5)
        topRightRadius: 1
        bottomRightRadius: 1
    }

    SequentialAnimation {
        running: root.batCharging
        loops: Animation.Infinite

        PauseAnimation {
            duration: Appearance.animations.durations.normal
        }

        NAnim {
            target: root
            property: "chargeFillIndex"
            from: root.batPercentage * 100
            to: Math.min(root.batPercentage * 100 + 20, 100)
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: Math.min(root.batPercentage * 100 + 20, 100)
            to: Math.min(root.batPercentage * 100 + 40, 100)
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: Math.min(root.batPercentage * 100 + 40, 100)
            to: Math.min(root.batPercentage * 100 + 60, 100)
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: Math.min(root.batPercentage * 100 + 60, 100)
            to: Math.min(root.batPercentage * 100 + 80, 100)
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: Math.min(root.batPercentage * 100 + 80, 100)
            to: 100
            easing.type: Easing.Linear
        }

        PauseAnimation {
            duration: Appearance.animations.durations.extraLarge
        }

        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 100
            to: root.batPercentage * 100
            duration: Appearance.animations.durations.large
            easing.type: Easing.Linear
        }

        onStopped: {
            root.chargeFillIndex = root.batPercentage * 100;
        }
    }
}
