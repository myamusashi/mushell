pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    spacing: Appearance.spacing.small * 0.5
    visible: BluetoothServices.hasBlocked

    StyledText {
        text: qsTr("Blocked devices")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
    }

    Repeater {
        model: BluetoothServices.blockedDevices

        delegate: WrapperRectangle {
            id: blockedDelegate

            required property var modelData

            Layout.fillWidth: true
            radius: Appearance.rounding.large
            margin: Appearance.margin.small
            color: "transparent"

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
                    color: Qt.alpha(Colours.m3Colors.m3Error, 0.12)

                    Icon {
                        anchors.centerIn: parent
                        icon: "block"
                        color: Colours.m3Colors.m3Error
                        font.pixelSize: Appearance.fonts.size.large
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: BluetoothServices.displayName(blockedDelegate.modelData)
                    elide: Text.ElideRight
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                FloatingButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    backgroundRadius: Appearance.rounding.normal
                    icon.name: "block"
                    color: "transparent"
                    onClicked: blockedDelegate.modelData.blocked = false
                }
            }
        }
    }
}
