pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    RowLayout {
        visible: !root.isSeparator
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.larger
        anchors.rightMargin: Appearance.margin.larger
        spacing: Appearance.spacing.normal

        IconImage {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            visible: root.modelData.icon !== ""
            source: root.modelData.icon
            asynchronous: true
            backer.cache: true
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.modelData.text
            color: Colours.m3Colors.m3OnSurface
            font.family: Appearance.fonts.family.sans
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            visible: root.modelData.buttonType === QsMenuButtonType.CheckBox
            icon: root.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            visible: root.modelData.buttonType === QsMenuButtonType.RadioButton
            icon: root.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
            color: root.modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
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
