import QtQuick
import QtQuick.Layouts

import Vast.Utils

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    property var optionData
    property int optionIndex
    property bool isSelected
    property int maxIndex

    signal executed
    signal indexModel(int newIndex)
    signal closed

    focus: root.isSelected

    function executeAction() {
        root.forceActiveFocus();
        root.optionData.action();
        root.executed();
    }

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.executeAction();
            GlobalStates.isScreenCapturePanelOpen = false;
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            root.closed();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            if (root.optionIndex > 0)
                root.indexModel(root.optionIndex - 1);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (root.optionIndex < root.maxIndex)
                root.indexModel(root.optionIndex + 1);
            event.accepted = true;
            break;
        }
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            leftMargin: Appearance.spacing.small
            rightMargin: Appearance.spacing.small
        }
        spacing: Appearance.spacing.normal
        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.isSelected ? 1.03 : 1.0
            yScale: root.isSelected ? 1.03 : 1.0

            Behavior on xScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on yScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        Icon {
            id: captureIcon
            property color target: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
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
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
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

            type: Icon.Material
            icon: root.optionData.icon
            font.pixelSize: Appearance.fonts.size.large
            Layout.alignment: Qt.AlignVCenter

            NAnim {
                id: colorBlendAnim
                target: captureIcon
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        StyledText {
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            text: root.optionData.name
            Layout.fillWidth: true
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.executeAction();
            GlobalStates.isScreenCapturePanelOpen = false;
        }
        onEntered: root.forceActiveFocus()
    }
}
