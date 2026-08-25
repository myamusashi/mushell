import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    icon: "memory"
    text: qsTr("Memory")
    content: ColumnLayout {
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: qsTr("RAM Size")
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: (SystemUsage.memTotal / 1048576).toFixed(2) + " GB"
                color: Colours.m3Colors.m3Green
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: [
                {
                    text: qsTr("Used"),
                    value: (SystemUsage.memUsed / 1048576).toFixed(2) + " GB"
                },
                {
                    text: qsTr("Free"),
                    value: ((SystemUsage.memTotal - SystemUsage.memUsed) / 1048576).toFixed(2) + " GB"
                }
            ]

            delegate: RowLayout {
                id: row

                required property var modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.small * 0.5

                StyledText {
                    text: row.modelData.text
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.7)
                    font.pixelSize: Appearance.fonts.size.normal
                    Layout.minimumWidth: 60
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: row.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        SliderValues {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            usedValue: SystemUsage.memUsed / 1048576
            totalValue: SystemUsage.memTotal / 1048576
        }
    }

    component SliderValues: Item {
        id: root

        readonly property real usedPercent: totalValue > 0 ? (usedValue / totalValue) : 0
        readonly property real freePercent: 1 - usedPercent

        property real usedValue: 0
        property real totalValue: 100

        implicitHeight: 12

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        Rectangle {
            id: usedBar
            property color target: Colours.m3Colors.m3Green
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0
            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = Colours.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }
            onTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: parent.width * root.usedPercent
            radius: height / 2

            Behavior on implicitWidth {
                SpringAnimation {
                    spring: 2
                    damping: 0.5
                }
            }

            NAnim {
                id: colorBlendAnim
                target: usedBar
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }
        }
    }
}
