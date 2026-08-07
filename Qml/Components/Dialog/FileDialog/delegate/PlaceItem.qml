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
            property color c0From
            property color c0To
            property bool c0Active: false
            property real c0Blend: 1.0

            onC0BlendChanged: {
                if (!c0Active)
                    return;
                if (c0Blend >= 1) {
                    color = c0To;
                    c0Active = false;
                } else if (c0Blend > 0) {
                    color = Colours.blendColors(c0From, c0To, c0Blend);
                }
            }

            NAnim {
                id: c0Anim
                target: iconItem
                property: "c0Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                c0Anim.stop();
                c0From = iconItem.color;
                c0To = target;
                c0Active = true;
                c0Blend = 0.0;
                c0Anim.start();
            }

            icon: root.icon
            font.pixelSize: Appearance.fonts.size.large
        }

        StyledText {
            id: label
            property color c1From
            property color c1To
            property bool c1Active: false
            property real c1Blend: 1.0

            onC1BlendChanged: {
                if (!c1Active)
                    return;
                if (c1Blend >= 1) {
                    color = c1To;
                    c1Active = false;
                } else if (c1Blend > 0) {
                    color = Colours.blendColors(c1From, c1To, c1Blend);
                }
            }

            NAnim {
                id: c1Anim
                target: label
                property: "c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            onTargetChanged: {
                c1Anim.stop();
                c1From = label.color;
                c1To = target;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
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
