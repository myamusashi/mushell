pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property string label: ""
    property string leadingIcon: ""
    property string trailingText: ""
    property string disabledLabel: ""
    property bool selected: false

    signal triggered

    implicitHeight: root.leadingIcon === "" ? 48 : 56
    implicitWidth: parent ? parent.width : 200
    opacity: root.enabled ? 1 : 0.38

    readonly property real horizontalInset: Appearance.margin.larger

    Rectangle {
        anchors.fill: parent
        visible: root.selected
        radius: Appearance.rounding.small
        color: Colours.m3Colors.m3SecondaryContainer
    }

    MArea {
        layerRadius: Appearance.rounding.small
        enabled: root.enabled

        onClicked: root.triggered()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.horizontalInset
            anchors.rightMargin: root.horizontalInset
            spacing: Appearance.spacing.normal

            Icon {
                visible: root.leadingIcon !== ""
                icon: root.leadingIcon
                color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.label
                color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
                font.family: Appearance.fonts.family.sans
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                font.letterSpacing: 0.15
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Icon {
                visible: root.selected
                icon: "check"
                color: Colours.m3Colors.m3OnSecondaryContainer
                font.pixelSize: Appearance.fonts.size.large
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                visible: root.trailingText !== ""
                text: root.trailingText
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.family: Appearance.fonts.family.sans
                font.pixelSize: Appearance.fonts.size.normal
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            StyledRect {
                visible: !root.enabled && root.disabledLabel !== ""
                radius: Appearance.rounding.normal
                Layout.preferredHeight: 24
                Layout.preferredWidth: badgeText.implicitWidth + 10
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: badgeText

                    anchors.centerIn: parent
                    text: root.disabledLabel
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3Error
                }
            }
        }
    }
}
