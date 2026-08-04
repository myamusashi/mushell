import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Rectangle {
    id: root

    property alias text: textItem.text
    property alias iconName: iconItem.icon
    property int pageIndex: 0
    property bool isActive: pageIndex === settingsLoader.currentPage // qmllint disable

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    radius: height / 2
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

    NumberAnimation {
        id: c0Anim
        target: root
        property: "c0Blend"
        from: 0.0
        to: 1.0
    }

    property color bgTarget: isActive ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    onBgTargetChanged: {
        c0Anim.stop();
        c0From = root.color;
        c0To = bgTarget;
        c0Active = true;
        c0Blend = 0.0;
        c0Anim.start();
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem
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

            NumberAnimation {
                id: c1Anim
                target: iconItem
                property: "c1Blend"
                from: 0.0
                to: 1.0
            }

            font.pixelSize: Appearance.fonts.size.extraLarge
            layer.enabled: true
            layer.smooth: true

            property color iconTarget: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            onIconTargetChanged: {
                c1Anim.stop();
                c1From = iconItem.color;
                c1To = iconTarget;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
            }

            font.variableAxes: {
                "FILL": (area.containsPress || root.isActive) ? 1 : 0
            }

            rotation: area.containsPress ? 25 : area.containsMouse ? 15 : root.isActive ? 20 : 0

            transform: Rotation {
                id: flipRotation

                origin.x: iconItem.width / 2
                origin.y: iconItem.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: 0
            }

            states: State {
                name: "flipped"
                when: area.containsPress
                PropertyChanges {
                    flipRotation.angle: 180
                }
            }

            transitions: Transition {
                NAnim {
                    target: flipRotation
                    property: "angle"
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }

        StyledText {
            id: textItem
            property color c2From
            property color c2To
            property bool c2Active: false
            property real c2Blend: 1.0

            onC2BlendChanged: {
                if (!c2Active)
                    return;
                if (c2Blend >= 1) {
                    color = c2To;
                    c2Active = false;
                } else if (c2Blend > 0) {
                    color = Colours.blendColors(c2From, c2To, c2Blend);
                }
            }

            NumberAnimation {
                id: c2Anim
                target: textItem
                property: "c2Blend"
                from: 0.0
                to: 1.0
            }

            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isActive

            property color textTarget: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            onTextTargetChanged: {
                c2Anim.stop();
                c2From = textItem.color;
                c2To = textTarget;
                c2Active = true;
                c2Blend = 0.0;
                c2Anim.start();
            }
        }
    }

    MArea {
        id: area

        layerColor: "transparent"
        layerRadius: root.radius
        anchors.fill: parent
        onClicked: settingsLoader.currentPage = root.pageIndex // qmllint disable

        Rectangle {
            id: hoverOverlay
            property color c3From
            property color c3To
            property bool c3Active: false
            property real c3Blend: 1.0

            onC3BlendChanged: {
                if (!c3Active)
                    return;
                if (c3Blend >= 1) {
                    color = c3To;
                    c3Active = false;
                } else if (c3Blend > 0) {
                    color = Colours.blendColors(c3From, c3To, c3Blend);
                }
            }

            NumberAnimation {
                id: c3Anim
                target: hoverOverlay
                property: "c3Blend"
                from: 0.0
                to: 1.0
            }

            anchors.fill: parent
            radius: root.radius
            property color hoverTarget: area.containsMouse && !root.isActive ? Qt.rgba(Colours.m3Colors.m3OnSurface.r, Colours.m3Colors.m3OnSurface.g, Colours.m3Colors.m3OnSurface.b, 0.08) : "transparent"

            onHoverTargetChanged: {
                c3Anim.stop();
                c3From = hoverOverlay.color;
                c3To = hoverTarget;
                c3Active = true;
                c3Blend = 0.0;
                c3Anim.start();
            }
        }
    }
}
