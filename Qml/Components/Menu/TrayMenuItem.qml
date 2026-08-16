pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property QsMenuEntry modelData

    signal hovered
    signal activated

    readonly property bool isSeparator: root.modelData?.isSeparator ?? false
    readonly property bool isEnabled: root.modelData?.enabled ?? false

    implicitHeight: root.isSeparator ? 1 : 44
    opacity: root.isSeparator || root.isEnabled ? 1 : 0.4

    StyledRect {
        visible: root.isSeparator
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Appearance.margin.large
        anchors.rightMargin: Appearance.margin.large
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        radius: 0
        color: Colours.m3Colors.m3OutlineVariant
    }

    Row {
        id: contentRow

        visible: !root.isSeparator
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.larger
        anchors.rightMargin: Appearance.margin.larger
        spacing: Appearance.spacing.normal

        IconImage {
            id: leadingIcon

            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.modelData.icon !== ""
            source: root.modelData.icon
            asynchronous: true
            backer.cache: true
        }

        Text {
            id: contentText

            width: {
                let avail = contentRow.width - (leadingIcon.visible ? leadingIcon.width + contentRow.spacing : 0);
                avail -= (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0);
                avail -= (radioIcon.visible ? radioIcon.width + contentRow.spacing : 0);
                avail -= (chevronIcon.visible ? chevronIcon.width + contentRow.spacing : 0);
                return Math.max(avail, 0);
            }
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData.text
            color: Colours.m3Colors.m3OnSurface
            font.family: Appearance.fonts.family.sans
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Icon {
            id: checkIcon

            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.modelData.buttonType === QsMenuButtonType.CheckBox
            icon: root.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            id: radioIcon

            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.modelData.buttonType === QsMenuButtonType.RadioButton
            icon: root.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            id: chevronIcon

            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.modelData.hasChildren
            icon: "chevron_right"
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }
    }

    MArea {
        anchors.fill: parent
        layerRadius: Appearance.rounding.small
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.isSeparator && root.isEnabled

        onEntered: root.hovered()
        onClicked: {
            root.modelData.triggered(); // qmllint disable
            root.activated();
        }
    }
}
