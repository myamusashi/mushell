pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Item {
    id: root

    readonly property color bgColor: root.enabled ? root.color : Qt.alpha(root.color, 0.12)

    property alias bgRadius: background.radius
    property string text: ""
    property int textSize: Appearance.fonts.size.normal

    property bool pressed
    property bool hovered
    property bool outlined: false
    property color color: Colours.m3Colors.m3Primary
    property color textColor: Colours.m3Colors.m3OnPrimary
    property color rippleColor: Colours.m3Colors.m3OnPrimary
    property IconComponent icon: IconComponent {}

    readonly property bool kbFocused: root.activeFocus

    property bool keyboardFocusable: true

    property int leftPad: icon.name !== "" ? 16 : 24
    property int rightPad: 24
    property int topPad: 10
    property int bottomPad: 10
    property int spacing: 8

    signal clicked

    Keys.onReturnPressed: event => {
        if (root.enabled) {
            root.clicked();
            event.accepted = true;
        }
    }

    Keys.onSpacePressed: event => {
        if (root.enabled) {
            root.clicked();
            event.accepted = true;
        }
    }

    implicitWidth: contentRow.implicitWidth + leftPad + rightPad
    implicitHeight: 40

    // qmllint disable
    states: [
        State {
            name: "disabled"
            when: !root.enabled
            PropertyChanges {
                target: root
                opacity: 0.38
            }
        },
        State {
            name: "pressed"
            when: root.enabled && root.pressed
            PropertyChanges {
                target: background
                scale: 0.98
            }
        },
        State {
            name: "focused"
            when: root.enabled && root.kbFocused
            PropertyChanges {
                target: focusRing
                opacity: 1
            }
        },
        State {
            name: "normal"
            when: root.enabled && !root.hovered && !root.pressed && !root.kbFocused
        }
    ]
    // qmllint enable

    transitions: [
        Transition {
            from: "*"
            to: "*"
            NAnim {
                properties: "scale,opacity"
                duration: Appearance.animations.durations.small
            }
        }
    ]

    StyledRect {
        id: background

        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.outlined ? "transparent" : root.bgColor
        border.width: root.outlined ? 1 : 0
        border.color: root.outlined ? Qt.alpha(Colours.m3Colors.m3OnSurface, root.enabled ? 1.0 : 0.38) : "transparent"
        transformOrigin: Item.Center

        SimpleRipple {
            anchors.fill: parent
            xClipRadius: background.radius
            yClipRadius: background.radius
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    StyledRect {
        id: stateOverlay

        anchors.fill: parent
        radius: background.radius
        color: root.textColor
        opacity: (root.enabled ? (root.pressed ? 0.12 : root.hovered ? 0.08 : 0.0) : 0.0)

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    Rectangle {
        id: focusRing

        anchors.fill: parent
        radius: background.radius
        color: "transparent"
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        opacity: 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: root.spacing

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

            visible: root.icon.name !== ""
            icon: root.icon.name
            font.pixelSize: root.icon.size
            property color iconTarget: root.icon.color

            onIconTargetChanged: {
                c0Anim.stop();
                c0From = iconItem.color;
                c0To = iconTarget;
                c0Active = true;
                c0Blend = 0.0;
                c0Anim.start();
            }
        }

        Loader {
            id: styledTextLoader

            active: root.text !== ""
            asynchronous: false
            sourceComponent: StyledText {
                id: styledTextItem
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
                    target: styledTextItem
                    property: "c1Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                }

                text: root.text
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                font.letterSpacing: 0.1
                property color textTarget: root.textColor

                onTextTargetChanged: {
                    c1Anim.stop();
                    c1From = styledTextItem.color;
                    c1To = textTarget;
                    c1Active = true;
                    c1Blend = 0.0;
                    c1Anim.start();
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    hovered: hoverHandler.hovered

    TapHandler {
        id: tapHandler

        enabled: root.enabled
        onTapped: root.clicked()
    }

    pressed: tapHandler.pressed

    component IconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSurface
        property string name: ""
        property int size: Appearance.fonts.size.large * 1.2
    }
}
