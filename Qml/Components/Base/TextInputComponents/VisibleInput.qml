import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool isFocused
    required property bool unlockInProgress
    required property bool hasSelection
    required property TextInput passwordInput
    required property Item toggleButton
    required property int selectionStart
    required property int selectionEnd

    signal editingFinished

    Item {
        anchors {
            left: parent.left
            leftMargin: 8
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.spacing.small
            verticalCenter: parent.verticalCenter
        }
        implicitHeight: visibleInput.font.pixelSize + Appearance.spacing.normal
        clip: true

        Rectangle {
            id: visibleRectSelected

            anchors.verticalCenter: parent.verticalCenter
            x: visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.selectionStart))
            implicitWidth: visibleInputMetrics.advanceWidth(visibleInput.text.substring(root.selectionStart, root.selectionEnd)) + Appearance.spacing.small
            implicitHeight: visibleInput.font.pixelSize + Appearance.spacing.normal
            radius: 2
            color: Colours.m3Colors.m3Primary
            opacity: 0.0

            states: [
                State {
                    name: "selection"
                    when: root.hasSelection
                    // qmllint disable
                    PropertyChanges {
                        target: visibleRectSelected
                        opacity: 0.25
                    }
                    // qmllint enable
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

    TextInput {
        id: visibleInput

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.spacing.small
            verticalCenter: parent.verticalCenter
        }
        readOnly: true
        text: root.passwordInput.text
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        echoMode: TextInput.Normal
        clip: true

        Keys.onReturnPressed: root.editingFinished()
    }

    FontMetrics {
        id: visibleInputMetrics

        font: visibleInput.font
    }

    Rectangle {
        id: textCaret

        x: Math.min(visibleInput.x + visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.passwordInput.cursorPosition)), root.toggleButton.x - 8)
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 2
        implicitHeight: visibleInput.font.pixelSize + 2
        radius: 1
        color: Colours.m3Colors.m3Primary
        visible: root.isFocused && !root.unlockInProgress && !root.hasSelection

        onVisibleChanged: {
            if (visible)
                opacity = 1;
        }

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        SequentialAnimation on opacity {
            running: textCaret.visible
            loops: Animation.Infinite
            NAnim {
                to: 1
                duration: 0
            }
            PauseAnimation {
                duration: Appearance.animations.durations.large
            }
            NAnim {
                to: 0
                duration: 0
            }
            PauseAnimation {
                duration: Appearance.animations.durations.large
            }
        }
    }
}
