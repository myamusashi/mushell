import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Widgets
import qs.Components

StyledRect {
    Layout.preferredHeight: 140
    color: Themes.colors.surface_container_low
    radius: Appearance.rounding.normal

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 5

        Item {
            Layout.preferredWidth: 80
            Layout.fillHeight: true

            Battery {
                anchors.centerIn: parent
                widthBattery: 75
                heightBattery: 36
            }
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

        readonly property var details: [{
                "label": "Battery found:",
                "value": Battery.foundBattery,
                "color": Themes.colors.on_background
            }, {
                "label": "Current capacity:",
                "value": UPower.displayDevice.energy.toFixed(2) + " Wh",
                "color": Themes.colors.on_background
            }, {
                "label": "Full capacity:",
                "value": UPower.displayDevice.energyCapacity.toFixed(2) + " Wh",
                "color": Themes.colors.on_background
            }, {
                "label": "Battery Health:",
                "value": Battery.overallBatteryHealth + "%",
                "color": getHealthColor(Battery.overallBatteryHealth)
            }]

        function getHealthColor(health) {
            if (health > 80)
                return Themes.colors.primary
            if (health > 50)
                return Themes.colors.secondary
            return Themes.colors.error
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
                    color: Themes.colors.on_background
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
