import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Configs
import qs.Widgets
import qs.Components

StyledRect {
    Layout.preferredHeight: 140
    color: Themes.m3Colors.surfaceContainerLow
    radius: Appearance.rounding.normal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 5

        Battery {
            Layout.alignment: Qt.AlignCenter
            widthBattery: 75
            heightBattery: 36
        }

        BatteryDetailsList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Timer {
        interval: 600
        repeat: true
        running: Battery.charging
        triggeredOnStart: true
        onTriggered: Battery.chargeIconIndex = (Battery.chargeIconIndex % 10) + 1
    }

    component BatteryDetailsList: ColumnLayout {
        spacing: Appearance.spacing.small

        readonly property var details: [
            {
                "label": "Current capacity:",
                "value": UPower.displayDevice.energy.toFixed(2) + " Wh",
                "color": Themes.m3Colors.onBackground
            },
            {
                "label": "Full capacity:",
                "value": UPower.displayDevice.energyCapacity.toFixed(2) + " Wh",
                "color": Themes.m3Colors.onBackground
            },
        ]

        function getHealthColor(health) {
            if (health > 80)
                return Themes.m3Colors.primary;
            if (health > 50)
                return Themes.m3Colors.secondary;
            return Themes.m3Colors.error;
        }

        Repeater {
            model: parent.details

            delegate: RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    text: parent.modelData.label
                    font.weight: Font.DemiBold
                    color: Themes.m3Colors.onBackground
                    font.pixelSize: Appearance.fonts.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: parent.modelData.value
                    color: parent.modelData.color
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.normal
                }
            }
        }
    }
}
