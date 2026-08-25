pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import QtQml.Models

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool isFocused
    required property bool isUnlocked
    required property bool unlockInProgress
    required property bool hasSelection
    required property TextInput passwordInput
    required property Item toggleButton
    required property int selectionStart
    required property int selectionEnd
    required property ListModel dotsModel

    readonly property int dotStep: 24
    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]

    Item {
        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large - 4
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
        implicitHeight: 28
        clip: true

        Rectangle {
            id: passwordRectSelected

            anchors.verticalCenter: parent.verticalCenter
            x: root.selectionStart * root.dotStep
            implicitWidth: (root.selectionEnd - root.selectionStart) * root.dotStep + radius
            implicitHeight: 28
            radius: 2
            color: Colours.m3Colors.m3Primary
            opacity: 0.0

            states: [
                State {
                    name: "selection"
                    when: root.hasSelection
                    PropertyChanges {
                        target: passwordRectSelected // qmllint disable
                        opacity: 0.25 // qmllint disable
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "*"
                    to: "*"
                    NAnim {
                        properties: "opacity"
                        duration: Appearance.animations.durations.small
                    }
                }
            ]

            Behavior on implicitWidth {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    ListView {
        id: dotsView

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
        orientation: ListView.Horizontal
        spacing: 4
        model: root.dotsModel
        clip: true
        implicitWidth: Math.min(contentWidth, parent.width - root.toggleButton.width - 20)
        implicitHeight: 20

        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        delegate: MaterialShape {
            id: shapeDelegate
            required property int index

            implicitWidth: 20
            implicitHeight: 20
            shape: MaterialShape.Circle
            animationDuration: 350
            property color shapeTarget: root.unlockInProgress ? Colours.m3Colors.m3OnSurfaceVariant : root.isUnlocked ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Primary
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

            onShapeTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = shapeTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            Component.onCompleted: {
                shape = root.shapeList[index % root.shapeList.length];

                colorBlendAnim.stop();
                color = "white";
                colorFrom = "white";
                colorTo = shapeTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            Connections {
                target: root
                function onIsUnlockedChanged() {
                    if (root.isUnlocked)
                        shapeDelegate.shape = MaterialShape.Circle;
                }
            }

            NAnim {
                id: colorBlendAnim
                target: shapeDelegate
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }
        }

        add: Transition {
            ParallelAnimation {
                NAnim {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Appearance.animations.durations.small
                }
                SpringAnimation {
                    property: "scale"
                    from: 0.5
                    to: 1
                    spring: 3.0
                    damping: 0.4
                    mass: 1.0
                }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NAnim {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Appearance.animations.durations.small
                }
                SpringAnimation {
                    property: "scale"
                    from: 1
                    to: 0.5
                    spring: 4.0
                    damping: 0.6
                    mass: 1.0
                }
            }
        }
        displaced: Transition {
            SpringAnimation {
                properties: "x"
                spring: 3.0
                damping: 0.4
                mass: 1.0
            }
        }
    }

    Connections {
        target: root.passwordInput

        function onCursorPositionChanged() {
            root.scrollToCursor();
        }

        function onTextChanged() {
            root.scrollToCursor();
        }
    }

    function scrollToCursor() {
        if (root.dotsModel.count > 0)
            dotsView.positionViewAtIndex(Math.min(root.passwordInput.cursorPosition, root.dotsModel.count - 1), ListView.Contain);
    }

    Item {
        id: caretArea

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
        implicitHeight: 28
        clip: true

        Rectangle {
            id: dotsCaret

            anchors.verticalCenter: parent.verticalCenter
            x: root.passwordInput.cursorPosition * root.dotStep - dotsView.contentX
            implicitWidth: 2
            implicitHeight: 20
            radius: 1
            color: Colours.m3Colors.m3Primary
            visible: root.isFocused && !root.unlockInProgress && !root.hasSelection

            onVisibleChanged: {
                if (visible)
                    opacity = 1;
            }

            Behavior on x {
                NAnim {
                    duration: 50
                }
            }

            SequentialAnimation on opacity {
                running: dotsCaret.visible
                loops: Animation.Infinite
                NAnim {
                    to: 1
                    duration: 0
                }
                PauseAnimation {
                    duration: 530
                }
                NAnim {
                    to: 0
                    duration: 0
                }
                PauseAnimation {
                    duration: 530
                }
            }
        }
    }
}
