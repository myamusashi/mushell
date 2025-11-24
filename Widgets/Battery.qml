import QtQuick
import Quickshell.Services.UPower

import qs.Configs
import qs.Components

Item {
    id: root

    readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property real batPercentage: UPower.displayDevice.percentage
    readonly property real batFill: (batteryBody.width - 4) * (batPercentage / 100.0)
    property real chargeFillIndex: 0 // Ubah ke real untuk animasi smooth
    property int widthBattery: 26
    property int heightBattery: 12

    width: widthBattery + 4
    height: heightBattery

    StyledRect {
        id: batteryBody

        width: root.widthBattery
        height: root.heightBattery
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        border {
            width: 2
            color: root.batPercentage <= 0.2 && !root.batCharging ? Themes.m3Colors.m3Error : Themes.withAlpha(Themes.m3Colors.m3Outline, 0.5)
        }
        color: "transparent"
        radius: 6

        StyledRect {
            id: batteryFill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.batCharging ? (parent.width - 4) * (root.chargeFillIndex / 100.0) : (parent.width - 4) * root.batPercentage
            color: {
                if (root.batCharging)
                    return Themes.m3Colors.m3Green;
                if (root.batPercentage <= 0.2)
                    return Themes.m3Colors.m3Red;
                if (root.batPercentage <= 0.5)
                    return Themes.m3Colors.m3Yellow;
                return Themes.m3Colors.m3OnSurface;
            }
            radius: parent.radius

            Behavior on width {
                enabled: !root.batCharging
                NAnim {}
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.batPercentage * 100)
            font.pixelSize: batteryBody.height * 0.65
            font.weight: Font.Bold
            color: root.batPercentage <= 0.5 ? Themes.m3Colors.m3OnBackground : Themes.m3Colors.m3Surface
        }
    }

    StyledRect {
        id: batteryTip

        width: 2
        height: 5
        anchors.left: batteryBody.right
        anchors.leftMargin: 0.5
        anchors.verticalCenter: parent.verticalCenter
        color: root.batPercentage <= 0.2 && !root.batCharging ? Themes.m3Colors.m3Error : Themes.withAlpha(Themes.m3Colors.m3Outline, 0.5)
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
            from: 0
            to: 20
            duration: Appearance.animations.durations.normal
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 20
            to: 40
            duration: Appearance.animations.durations.normal
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 40
            to: 60
            duration: Appearance.animations.durations.normal
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 60
            to: 80
            duration: Appearance.animations.durations.normal
            easing.type: Easing.Linear
        }
        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 80
            to: 100
            duration: Appearance.animations.durations.normal
            easing.type: Easing.Linear
        }

        PauseAnimation {
            duration: Appearance.animations.durations.extraLarge
        }

        NAnim {
            target: root
            property: "chargeFillIndex"
            from: 100
            to: 0
            duration: Appearance.animations.durations.large
            easing.type: Easing.Linear
        }

        onStopped: {
            root.chargeFillIndex = 0;
        }
    }
}
