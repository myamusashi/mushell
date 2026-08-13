pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property Auth auth

    readonly property string initials: root.auth.currentUser.length > 0 ? root.auth.currentUser.charAt(0).toUpperCase() : "?"

    implicitWidth: 380
    implicitHeight: contentColumn.implicitHeight + Appearance.padding.large * 2
    transformOrigin: Item.Center

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Elevation {
        anchors.fill: parent
        level: 3
        radius: Appearance.rounding.large
    }

    StyledRect {
        id: cardSurface

        anchors.fill: parent
        color: Colours.m3Colors.m3SurfaceContainerHigh
        radius: Appearance.rounding.large
        border.color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.4)
        border.width: 1
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 96
            implicitHeight: 96

            StyledRect {
                anchors.fill: parent
                color: Colours.m3Colors.m3PrimaryContainer
                radius: Appearance.rounding.full
            }

            StyledText {
                anchors.centerIn: parent
                text: root.initials
                color: Colours.m3Colors.m3OnPrimaryContainer
                font.pixelSize: Appearance.fonts.size.extraLarge * 1.4
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.auth.currentUser
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Medium
        }

        StyledText {
            id: statusText

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            visible: root.auth.statusMessage !== ""
            text: root.auth.statusMessage
            color: root.auth.messageIsError ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.medium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        StyledTextInput {
            id: passwordInput

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            pam: root.auth
            passwordMode: true
            autoFocus: true
            placeHolderText: qsTr("Password")
        }

        DropdownField {
            id: sessionField

            Layout.fillWidth: true
            implicitWidth: 280
            visible: !root.auth.unlockInProgress
            model: root.auth.sessions
            textRole: "display"
            currentIndex: root.auth.selectedSessionIndex
            placeholderText: qsTr("Session")

            onActivated: index => {
                root.auth.selectedSessionIndex = index;
                passwordInput.forceActiveFocus();
            }
        }

        StyledButton {
            id: loginButton

            Layout.fillWidth: true
            Layout.preferredHeight: 48
            text: qsTr("Sign in")
            icon.name: "login"
            icon.color: Colours.m3Colors.m3OnPrimary
            color: Colours.m3Colors.m3Primary
            textColor: Colours.m3Colors.m3OnPrimary
            rippleColor: Colours.m3Colors.m3OnPrimary
            enabled: !root.auth.unlockInProgress

            onClicked: root.auth.tryUnlock()
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.margin.small
            spacing: Appearance.spacing.small
            visible: root.auth.users.length > 1

            Repeater {
                model: root.auth.users

                delegate: UserSwitcherButton {
                    required property string modelData

                    username: modelData
                    isCurrent: modelData === root.auth.currentUser

                    onClicked: {
                        root.auth.switchUser(modelData);
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    transform: Translate {
        id: shakeTranslate
        x: 0
    }

    Connections {
        target: root.auth

        function onShowFailureChanged() {
            if (root.auth.showFailure)
                shakeAnimation.restart();
        }
    }

    SequentialAnimation {
        id: shakeAnimation

        loops: 1

        NAnim {
            target: shakeTranslate
            property: "x"
            to: 12
            duration: 60
        }
        NAnim {
            target: shakeTranslate
            property: "x"
            to: -12
            duration: 60
        }
        NAnim {
            target: shakeTranslate
            property: "x"
            to: 8
            duration: 60
        }
        NAnim {
            target: shakeTranslate
            property: "x"
            to: -8
            duration: 60
        }
        NAnim {
            target: shakeTranslate
            property: "x"
            to: 4
            duration: 60
        }
        NAnim {
            target: shakeTranslate
            property: "x"
            to: 0
            duration: 60
        }
    }

    component UserSwitcherButton: Item {
        id: button

        required property string username
        required property bool isCurrent

        signal clicked

        implicitWidth: 40
        implicitHeight: 40

        StyledRect {
            anchors.fill: parent
            color: button.isCurrent ? Colours.m3Colors.m3SecondaryContainer : Colours.m3Colors.m3SurfaceContainerHighest
            radius: Appearance.rounding.full
            border.color: button.isCurrent ? Colours.m3Colors.m3Secondary : "transparent"
            border.width: button.isCurrent ? 1 : 0

            Behavior on color {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            text: button.username.charAt(0).toUpperCase()
            color: button.isCurrent ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        MArea {
            layerRadius: Appearance.rounding.full
            onClicked: button.clicked()
        }
    }
}
