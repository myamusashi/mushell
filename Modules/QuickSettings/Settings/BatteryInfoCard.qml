import QtQuick
import QtQuick.Layouts

import Quickshell.Services.UPower

import qs.Components
import qs.Configs
import qs.Services
import qs.Widgets

StyledRect {
    Layout.preferredHeight: 140
    color: Colours.m3Colors.m3SurfaceContainerLow
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
                "color": Colours.m3Colors.m3OnBackground
            },
            {
                "label": "Full capacity:",
                "value": UPower.displayDevice.energyCapacity.toFixed(2) + " Wh",
                "color": Colours.m3Colors.m3OnBackground
            }
        ]

        function getHealthColor(health) {
            if (health > 80)
                return Colours.m3Colors.m3Primary;
            if (health > 50)
                return Colours.m3Colors.m3Secondary;
            return Colours.m3Colors.m3Error;
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
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: parent.modelData.value
                    color: parent.modelData.color
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }
    }
}
