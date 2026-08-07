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

    readonly property real caretRawX: visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.passwordInput.cursorPosition))
    readonly property real scrollOffset: Math.max(0, caretRawX - (visibleArea.width - 4))

    Item {
        id: visibleArea

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.spacing.small
            verticalCenter: parent.verticalCenter
        }
        implicitHeight: visibleInput.font.pixelSize + Appearance.spacing.normal
        clip: true

        Rectangle {
            id: visibleRectSelected

            anchors.verticalCenter: parent.verticalCenter
            x: visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.selectionStart)) - root.scrollOffset
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

        TextInput {
            id: visibleInput

            anchors {
                verticalCenter: parent.verticalCenter
            }
            x: -root.scrollOffset
            readOnly: true
            text: root.passwordInput.text
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            echoMode: TextInput.Normal
            clip: true

            Keys.onReturnPressed: root.editingFinished()
        }

        Rectangle {
            id: textCaret

            anchors.verticalCenter: parent.verticalCenter
            x: root.caretRawX - root.scrollOffset
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

    FontMetrics {
        id: visibleInputMetrics

        font: visibleInput.font
    }
}
