pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import Vast.Utils

ColumnLayout {
    visible: BluetoothServices.adapterEnabled
    spacing: Appearance.spacing.small * 0.5

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Available devices")
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
        }

        FloatingButton {
            implicitWidth: 28
            implicitHeight: 28
            backgroundRadius: Appearance.rounding.small
            enabled: BluetoothServices.adapterAvailable && !BluetoothServices.adapterBlocked
            spinning: BluetoothServices.isDiscovering
            icon.name: "refresh"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            color: "transparent"
            onClicked: {
                if (BluetoothServices.isDiscovering)
                    BluetoothServices.setDiscovering(false);
                else
                    BluetoothServices.setDiscovering(true);
            }
        }
    }

    Repeater {
        id: availableRepeater

        model: BluetoothServices.availableDevices

        delegate: WrapperRectangle {
            id: availDelegate

            required property var modelData

            property color target: modelData.pairing ? Colours.m3Colors.m3Primary : tap2.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onTargetChanged: {
                colorBlendAnim2.stop();
                colorFrom = color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim2.start();
            }

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NAnim {
                id: colorBlendAnim2
                target: availDelegate
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            Layout.fillWidth: true
            radius: Appearance.rounding.large
            margin: Appearance.margin.small

            TapHandler {
                id: tap2

                onTapped: {
                    if (!availDelegate.modelData.paired && !availDelegate.modelData.pairing)
                        availDelegate.modelData.pair();
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: Appearance.margin.small
                }
                spacing: Appearance.spacing.small

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Appearance.rounding.small
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

                    Icon {
                        anchors.centerIn: parent
                        icon: "bluetooth_searching"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: BluetoothServices.displayName(availDelegate.modelData)
                        elide: Text.ElideRight
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    StyledText {
                        text: BluetoothServices.addressLine(availDelegate.modelData)
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                FloatingButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: availDelegate.modelData.pairing ? "close" : "bluetooth"
                    icon.color: Colours.m3Colors.m3OnSurfaceVariant
                    color: "transparent"
                    enabled: !availDelegate.modelData.pairing
                    onClicked: availDelegate.modelData.pair()
                }

                FloatingButton {
                    visible: availDelegate.modelData.pairing
                    implicitWidth: 28
                    implicitHeight: 28
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: "close"
                    color: "transparent"
                    onClicked: availDelegate.modelData.cancelPair()
                }
            }
        }
    }

    StyledText {
        visible: availableRepeater.count === 0 && BluetoothServices.isDiscovering
        text: qsTr("Searching for devices…")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }

    StyledText {
        visible: availableRepeater.count === 0 && !BluetoothServices.isDiscovering && BluetoothServices.hasPaired
        text: qsTr("No new devices — turn on scanning")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }
}
