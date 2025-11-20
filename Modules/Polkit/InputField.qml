import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Services
import qs.Components

TextField {
    id: passwordInput

    Layout.fillWidth: true
    Layout.preferredHeight: 56

    font.family: Appearance.fonts.familySans
    font.pixelSize: Appearance.fonts.large * 1.2
    echoMode: PolAgent.agent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
    selectByMouse: true
    verticalAlignment: TextInput.AlignVCenter
    leftPadding: 16
    rightPadding: 16
    color: Themes.m3Colors.onSurface

    placeholderText: "Enter password"
    placeholderTextColor: Themes.m3Colors.onSurfaceVariant

    background: Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Appearance.rounding.small

        border.color: {
            if (!passwordInput.enabled)
                return Themes.withAlpha(Themes.m3Colors.outline, 0.38)
            else if (passwordInput.activeFocus)
                return Themes.m3Colors.primary
            else
                return Themes.m3Colors.outline
        }
        border.width: passwordInput.activeFocus ? 2 : 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: {
                if (!passwordInput.enabled)
                    return "transparent"
                else if (passwordInput.activeFocus)
                    return Themes.withAlpha(Themes.m3Colors.primary, 0.08)
                else
                    return "transparent"
            }

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on border.color {
            CAnim {
                duration: Appearance.animations.durations.small
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.width {
            PropertyAnimation {
                duration: Appearance.animations.durations.small
                easing.type: Easing.OutCubic
            }
        }
    }

    selectionColor: Themes.withAlpha(Themes.m3Colors.primary, 0.24)
    selectedTextColor: Themes.m3Colors.onSurface

    onAccepted: okButton.clicked()
}
