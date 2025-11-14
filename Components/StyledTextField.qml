import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.Data
import qs.Components

Scope {
    id: root

    property color colorTextField: Themes.colors.on_surface
    property color backgroundColorTextField: Themes.colors.surface_container_high
    property int backgroundRadius: Appearance.rounding.large
    property color backgroundBorderColor: Themes.colors.outline
    property int backgroundBorderWidth
    property real backgroundOpacity
    property bool selectByMouse: false
    property var echoMode: TextInput.Normal

    signal accepted

    TextField {
        id: textFieldBox

        focus: true

        color: root.colorTextField
        font.family: Appearance.fonts.family_Sans
        font.pixelSize: Appearance.fonts.large

        echoMode: root.echoMode
        selectByMouse: root.selectByMouse

        onAccepted: root.accepted()

        background: StyledRect {
            anchors.fill: parent

            color: root.backgroundColorTextField

            border.color: {
                if (!textFieldBox.enabled)
                    return Themes.withAlpha(Themes.colors.outline, 0.12)
                else if (textFieldBox.activeFocus)
                    return Themes.colors.primary
                else
                    return Themes.colors.outline
            }

            border.width: textFieldBox.activeFocus ? 2 : 1
            radius: root.backgroundRadius

            opacity: textFieldBox.enabled ? 1 : 0.38

            Behavior on border.color {
                ColorAnimation {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }

            Behavior on border.width {
                PropertyAnimation {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }

            Behavior on opacity {
                PropertyAnimation {
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }
        }

        implicitWidth: 320
        implicitHeight: 56

        leftPadding: Appearance.padding.large
        rightPadding: Appearance.padding.large
        topPadding: Appearance.padding.large
        bottomPadding: Appearance.padding.large

        selectionColor: Themes.withAlpha(Themes.colors.on_surface, 0.16)
        selectedTextColor: Themes.colors.on_primary

        Layout.alignment: Qt.AlignVCenter

        transform: Scale {
            id: focusScale
            origin.x: textFieldBox.width / 2
            origin.y: textFieldBox.height / 2
            xScale: textFieldBox.activeFocus ? 1.02 : 1.0
            yScale: textFieldBox.activeFocus ? 1.02 : 1.0

            Behavior on xScale {
                PropertyAnimation {
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                }
            }

            Behavior on yScale {
                PropertyAnimation {
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                }
            }
        }

        StyledRect {
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.large
            anchors.verticalCenter: parent.verticalCenter

            width: 20
            height: 20
            radius: 10
            color: Themes.colors.primary
            visible: root.pam.unlockInProgress
            opacity: visible ? 1 : 0

            SequentialAnimation on color {
                ColAnim {
                    to: Themes.colors.primary
                }
                ColAnim {
                    to: Themes.colors.secondary
                }
                ColAnim {
                    to: Themes.colors.tertiary
                }
                loops: Animation.Infinite
            }

            Behavior on opacity {
                PropertyAnimation {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }
        }
    }
}
