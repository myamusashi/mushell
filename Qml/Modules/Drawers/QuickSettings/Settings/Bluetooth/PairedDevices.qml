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
    spacing: Appearance.spacing.small * 0.5
    visible: BluetoothServices.adapterEnabled

    StyledText {
        text: qsTr("Paired devices")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        visible: pairedRepeater.count > 0
    }

    Repeater {
        id: pairedRepeater

        model: BluetoothServices.pairedDevices

        delegate: WrapperRectangle {
            id: pairedDelegate

            required property var modelData

            property color target: modelData.connected ? Colours.m3Colors.m3Primary : tap.pressed ? Colours.m3Colors.m3SurfaceContainerHigh : "transparent"
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
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
                id: colorBlendAnim
                target: pairedDelegate
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            Layout.fillWidth: true
            radius: Appearance.rounding.large
            margin: Appearance.margin.small

            TapHandler {
                id: tap

                onTapped: {
                    if (pairedDelegate.modelData.connected)
                        pairedDelegate.modelData.disconnect();
                    else
                        pairedDelegate.modelData.connect();
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
                    color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

                    Icon {
                        anchors.centerIn: parent
                        icon: pairedDelegate.modelData.connected ? "bluetooth_connected" : "bluetooth"
                        color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: BluetoothServices.displayName(pairedDelegate.modelData)
                        elide: Text.ElideRight
                        color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    StyledText {
                        text: BluetoothServices.stateString(pairedDelegate.modelData)
                        color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                StyledText {
                    visible: pairedDelegate.modelData.batteryAvailable
                    text: Math.round(pairedDelegate.modelData.battery * 100) + "%"
                    color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                }

                FloatingButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: pairedDelegate.modelData.connected ? "link_off" : "link"
                    icon.color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                    color: "transparent"
                    onClicked: pairedDelegate.modelData.connected ? pairedDelegate.modelData.disconnect() : pairedDelegate.modelData.connect()
                }

                FloatingButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: "delete"
                    icon.color: pairedDelegate.modelData.connected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                    color: "transparent"
                    onClicked: pairedDelegate.modelData.forget()
                }
            }
        }
    }

    StyledText {
        visible: pairedRepeater.count === 0
        text: qsTr("No paired devices")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        Layout.alignment: Qt.AlignHCenter
    }
}
