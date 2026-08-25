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

    readonly property color backgroundColor: root.enabled ? root.color : Qt.alpha(root.color, 0.12)

    property alias backgroundRadius: background.radius
    property string text: ""
    property int textSize: Appearance.fonts.size.normal

    property bool pressed
    property bool hovered
    property bool outlined: false
    property color color: Colours.m3Colors.m3Primary
    property color textColor: Colours.m3Colors.m3OnPrimary
    property color rippleColor: Colours.m3Colors.m3OnPrimary
    property IconComponent icon: IconComponent {}

    readonly property bool keyboardFocused: root.activeFocus

    property bool keyboardFocusable: true

    property int paddingLeft: icon.name !== "" ? 16 : 24
    property int paddingRight: 24
    property int paddingTop: 10
    property int paddingBottom: 10
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

    implicitWidth: contentRow.implicitWidth + paddingLeft + paddingRight
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
            when: root.enabled && root.keyboardFocused
            PropertyChanges {
                target: focusRing
                opacity: 1
            }
        },
        State {
            name: "normal"
            when: root.enabled && !root.hovered && !root.pressed && !root.keyboardFocused
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
        color: root.outlined ? "transparent" : root.backgroundColor
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
                    color = Colours.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NAnim {
                id: iconColorBlendAnim
                target: iconItem
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            visible: root.icon.name !== ""
            icon: root.icon.name
            font.pixelSize: root.icon.size
            property color iconTarget: root.icon.color

            onIconTargetChanged: {
                iconColorBlendAnim.stop();
                colorFrom = iconItem.color;
                colorTo = iconTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                iconColorBlendAnim.start();
            }
        }

        Loader {
            id: styledTextLoader

            active: root.text !== ""
            asynchronous: false
            sourceComponent: StyledText {
                id: styledTextItem
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
                        color = Colours.blendColors(colorFrom, colorTo, colorBlendProgress);
                    }
                }

                NAnim {
                    id: textColorBlendAnim
                    target: styledTextItem
                    property: "colorBlendProgress"
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
                    textColorBlendAnim.stop();
                    colorFrom = styledTextItem.color;
                    colorTo = textTarget;
                    colorBlending = true;
                    colorBlendProgress = 0.0;
                    textColorBlendAnim.start();
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
