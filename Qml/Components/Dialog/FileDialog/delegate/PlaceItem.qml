import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "../../../Base"

StyledRect {
    id: root

    required property string icon
    required property string label
    required property bool isSelected

    signal clicked

    property bool keyboardFocusable: true

    function requestKeyboardFocus() {
        root.forceActiveFocus();
    }

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }

    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }

    implicitHeight: 48
    radius: Appearance.rounding.small
    clip: true
    color: isSelected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.normal
            rightMargin: Appearance.margin.small
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem
            property color iconColorFrom
            property color iconColorTo
            property bool iconColorBlending: false
            property real iconColorBlendProgress: 1.0

            onIconColorBlendProgressChanged: {
                if (!iconColorBlending)
                    return;
                if (iconColorBlendProgress >= 1) {
                    color = iconColorTo;
                    iconColorBlending = false;
                } else if (iconColorBlendProgress > 0) {
                    color = Colours.blendColors(iconColorFrom, iconColorTo, iconColorBlendProgress);
                }
            }

            NAnim {
                id: iconColorAnim
                target: iconItem
                property: "iconColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                iconColorAnim.stop();
                iconColorFrom = iconItem.color;
                iconColorTo = target;
                iconColorBlending = true;
                iconColorBlendProgress = 0.0;
                iconColorAnim.start();
            }

            icon: root.icon
            font.pixelSize: Appearance.fonts.size.large
        }

        StyledText {
            id: label
            property color labelColorFrom
            property color labelColorTo
            property bool labelColorBlending: false
            property real labelColorBlendProgress: 1.0

            onLabelColorBlendProgressChanged: {
                if (!labelColorBlending)
                    return;
                if (labelColorBlendProgress >= 1) {
                    color = labelColorTo;
                    labelColorBlending = false;
                } else if (labelColorBlendProgress > 0) {
                    color = Colours.blendColors(labelColorFrom, labelColorTo, labelColorBlendProgress);
                }
            }

            NAnim {
                id: labelColorAnim
                target: label
                property: "labelColorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                labelColorAnim.stop();
                labelColorFrom = label.color;
                labelColorTo = target;
                labelColorBlending = true;
                labelColorBlendProgress = 0.0;
                labelColorAnim.start();
            }

            text: root.label
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isSelected
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    MArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        visible: root.activeFocus
    }
}
