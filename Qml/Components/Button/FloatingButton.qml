pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property string size: "medium"

    readonly property int actionButtonSize: root.size === "small" ? 32 : root.size === "regular" ? 40 : root.size === "large" ? 96 : 56
    readonly property int actionButtonRadius: root.size === "small" ? 12 : root.size === "regular" ? 12 : root.size === "large" ? 28 : 16
    readonly property int actionButtonIconSize: root.size === "small" ? 16 : root.size === "large" ? 36 : 24

    readonly property color backgroundColor: root.enabled || root.color.a === 0 ? root.color : Qt.alpha(root.color, 0.12)

    property alias backgroundRadius: background.radius
    property bool pressed
    property bool hovered
    property color color: Colours.m3Colors.m3PrimaryContainer
    property IconComponent icon: IconComponent {}

    readonly property bool keyboardFocused: root.activeFocus

    property bool keyboardFocusable: true
    property bool spinning: false

    onSpinningChanged: if (!spinning)
        iconItem.rotation = 0

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

    implicitWidth: root.actionButtonSize
    implicitHeight: root.actionButtonSize

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

    Elevation {
        visible: root.backgroundColor.a > 0 && root.enabled
        radius: background.radius
        level: root.hovered && !root.pressed ? 4 : 3
    }

    StyledRect {
        id: background

        anchors.fill: parent
        radius: root.enabled && root.pressed ? height * 0.5 : root.actionButtonRadius
        color: root.backgroundColor

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

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
        color: root.icon.color
        opacity: (root.enabled ? (root.pressed ? 0.10 : root.hovered ? 0.08 : 0.0) : 0.0)

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

    Icon {
        id: iconItem

        anchors.centerIn: parent
        icon: root.icon.name
        color: root.icon.color
        font.pixelSize: root.icon.size

        RotationAnimator on rotation {
            running: root.spinning
            loops: Animation.Infinite
            duration: Appearance.animations.durations.extraLarge
            easing.type: Easing.Linear
            from: 0
            to: 360
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
        property color color: Colours.m3Colors.m3OnPrimaryContainer
        property string name: ""
        property int size: root.actionButtonIconSize
    }
}
