pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "TextInputComponents/" as TI

Item {
    id: root

    property alias toggleButtonVisible: toggleButton.visible
    property alias text: passwordInput.text
    readonly property alias isFocused: passwordInput.activeFocus

    readonly property bool hasSelection: passwordInput.selectionStart !== passwordInput.selectionEnd
    readonly property bool selectedAll: passwordInput.selectionStart === 0 && passwordInput.selectionEnd === passwordInput.text.length && passwordInput.text.length > 0
    readonly property int selectionStart: passwordInput.selectionStart
    readonly property int selectionEnd: passwordInput.selectionEnd

    readonly property bool isUnlocked: root.pam ? root.pam.isUnlock : false
    readonly property bool unlockInProgress: root.pam ? root.pam.unlockInProgress : false
    readonly property bool showFailure: root.pam ? root.pam.showFailure : false

    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]
    readonly property int dotStep: 24
    readonly property bool hasText: passwordInput.text.length > 0

    property bool keyboardFocusable: true
    property bool autoFocus: true

    property string placeHolderText: ""
    property var pam: null
    property bool passwordMode: false

    function requestKeyboardFocus() {
        passwordInput.forceActiveFocus();
    }

    function forceActiveFocus() {
        passwordInput.forceActiveFocus();
    }

    signal accepted
    signal editingFinished
    signal keyPressed(var event)

    implicitWidth: 240
    implicitHeight: 44

    TextInput {
        id: passwordInput

        width: 0
        height: 0

        echoMode: TextInput.Password
        passwordMaskDelay: 0
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        enabled: !root.unlockInProgress
        text: (root.pam && root.pam.isUnlock) ? root.pam.currentText : ""
        clip: true

        onTextChanged: {
            if (root.pam)
                root.pam.currentText = text;

            const len = text.length;
            while (dotsModel.count < len)
                dotsModel.append({});
            while (dotsModel.count > len)
                dotsModel.remove(dotsModel.count - 1);
        }

        Keys.onReturnPressed: {
            if (root.pam && text.length > 0)
                root.pam.tryUnlock();
            root.accepted();
        }

        Keys.onEscapePressed: event => {
            root.keyPressed(event);
            if (event.accepted)
                return;

            if (root.hasSelection) {
                passwordInput.cursorPosition = passwordInput.selectionEnd;
                passwordInput.deselect();
                event.accepted = true;
            }
        }

        Keys.onPressed: event => {
            // Let consumers (e.g. the clipboard vim keybinds) intercept and
            // accept the key before it becomes text input.
            root.keyPressed(event);
            if (event.accepted)
                return;

            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                passwordInput.selectAll();
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            if (root.autoFocus)
                forceActiveFocus();
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onCurrentTextChanged() {
            if (passwordInput.text !== root.pam.currentText)
                passwordInput.text = root.pam.currentText;
        }
    }

    ListModel {
        id: dotsModel
    }

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: height / 2
        color: Colours.m3Colors.m3SurfaceVariant
        opacity: 0.4
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border {
            color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            width: root.isFocused ? 2 : 0
        }
        opacity: root.isFocused ? 1 : 0
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    Loader {

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: Appearance.margin.large
        }
        active: !root.hasText
        sourceComponent: placeHolderComponent
    }

    Component {
        id: placeHolderComponent

        StyledText {
            text: root.placeHolderText !== "" ? root.placeHolderText : (root.showFailure ? qsTr("Password invalid") : qsTr("Enter password"))
            color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
        }
    }

    Loader {
        id: passwordModeLoader

        anchors.fill: parent
        active: root.passwordMode
        sourceComponent: passwordModeComponent
    }

    Component {
        id: passwordModeComponent

        TI.PasswordInput {
            isFocused: root.isFocused
            isUnlocked: root.isUnlocked
            unlockInProgress: root.unlockInProgress
            hasSelection: root.hasSelection
            passwordInput: passwordInput
            toggleButton: toggleButton
            selectionStart: root.selectionStart
            selectionEnd: root.selectionEnd
            dotsModel: dotsModel
        }
    }

    Loader {
        id: visibleModeLoader

        anchors.fill: parent
        active: !root.passwordMode && root.hasText
        sourceComponent: visibleModeComponent
    }

    Component {
        id: visibleModeComponent

        TI.VisibleInput {
            isFocused: root.isFocused
            unlockInProgress: root.unlockInProgress
            hasSelection: root.hasSelection
            passwordInput: passwordInput
            toggleButton: toggleButton
            selectionStart: root.selectionStart
            selectionEnd: root.selectionEnd
        }
    }

    Item {
        id: toggleButton

        anchors {
            right: parent.right
            rightMargin: Appearance.margin.normal
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: 32
        implicitHeight: 32
        z: 1

        Icon {
            icon: "visibility_off"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            opacity: root.passwordMode ? 1.0 : 0.0
            scale: root.passwordMode ? 1.0 : 0.5
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
        }

        Icon {
            icon: "visibility"
            color: Colours.m3Colors.m3Secondary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            opacity: root.passwordMode ? 0.0 : 1.0
            scale: root.passwordMode ? 0.5 : 1.0
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
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            z: 1
            onClicked: {
                if (root.toggleButtonVisible) {
                    root.passwordMode = !root.passwordMode;
                    passwordInput.forceActiveFocus();
                }
            }
        }
    }

    MArea {
        layerRadius: bg.radius
        z: 0
        propagateComposedEvents: true
        onClicked: passwordInput.forceActiveFocus()
    }
}
