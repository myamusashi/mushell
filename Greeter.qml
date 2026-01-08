pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

import qs.Components
import qs.Configs
import qs.Greeter
import qs.Helpers
import qs.Services

ShellRoot {
    id: root

    property var sessions: Sessions.sessions

    function authenticate() {
        console.log("[AUTH START] User: " + Users.current_user);
        console.log("[AUTH START] Session: " + Sessions.current_session);

        if (!Users.current_user) {
            console.log("[ERROR] No user selected!");
            return;
        }

        Greetd.createSession(Users.current_user);
    }

    Component.onCompleted: {
        console.log("[INIT] Current session: " + Sessions.current_session);
        console.log("[INIT] Current user: " + Users.current_user);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            console.log("[MSG] " + message);
            console.log("[ERR] " + error);
            console.log("[RESREQ] " + responseRequired);
            console.log("[ECHO] " + echoResponse);

            if (responseRequired) {
                Greetd.respond(sessionLock.inputBuffer);
                sessionLock.inputBuffer = "";
                sessionLock.maskedBuffer = "";
            }

            if (error) {
                console.log("[AUTH ERROR] " + error);
                sessionLock.showErrorMessage = true;
                sessionLock.inputBuffer = "";
                sessionLock.maskedBuffer = "";
            }
        }

        function onReadyToLaunch() {
            console.log("[READY TO LAUNCH]");
            console.log("[SESSION] " + Sessions.current_session);
            sessionLock.locked = false;

            const sessionCmd = Sessions.current_session.split(" ");
            console.log("[LAUNCHING] " + JSON.stringify(sessionCmd));
            Greetd.launch(sessionCmd);
        }

        function onAuthFailure(message) {
            sessionLock.showErrorMessage = true;
        }
    }

    WlSessionLock {
        id: sessionLock

        readonly property list<string> maskChars: ["m", "y", "a", "m", "u", "s", "a", "s", "h", "i"]
        readonly property string wallpaperPath: "root:/Assets/wallpaper.png"
        readonly property bool unlocking: Greetd.state == GreetdState.Authenticating
        property string inputBuffer: ""
        property string maskedBuffer: ""
        property bool showErrorMessage: false
        property bool isAllSelected: false
        property int fakeTypingTimer: 0
        property var lastKeystrokeTime: 0

        locked: true

        WlSessionLockSurface {
            id: lockSurface

            Wallpaper {
                id: img

                anchors.fill: parent
                source: ""

                Component.onCompleted: {
                    source = sessionLock.wallpaperPath;

                    Paths.currentWallpaperChanged.connect(() => {
                        if (walAnimation.running)
                            walAnimation.complete();
                        animatingWal.source = sessionLock.wallpaperPath;
                    });
                    animatingWal.statusChanged.connect(() => {
                        if (animatingWal.status == Image.Ready)
                            walAnimation.start();
                    });

                    walAnimation.finished.connect(() => {
                        img.source = animatingWal.source;
                        animatingWal.source = "";
                        animatinRect.width = 0;
                    });
                }
            }

            Rectangle {
                id: animatinRect

                anchors.right: parent.right
                color: "transparent"
                height: lockSurface.height
                width: 0

                NAnim {
                    id: walAnimation

                    duration: Appearance.animations.durations.expressiveDefaultSpatial * 2
                    from: 0
                    property: "width"
                    target: animatinRect
                    to: Math.max(lockSurface.width)
                }

                Wallpaper {
                    id: animatingWal

                    anchors.right: parent.right
                    height: lockSurface.height
                    source: ""
                    width: lockSurface.width
                }
            }

            Keys.onTabPressed: keyHandler.forceActiveFocus()

            FocusScope {
                id: inputFocus

                anchors.fill: parent
                focus: true

                Item {
                    id: keyHandler

                    focus: true
                    Keys.onPressed: kevent => {
                        if (sessionLock.showErrorMessage && kevent.text)
                            sessionLock.showErrorMessage = false;

                        if (kevent.key === Qt.Key_Enter || kevent.key === Qt.Key_Return) {
                            if (sessionLock.inputBuffer.length > 0) {
                                console.log("[ENTER] Authenticating...");
                                root.authenticate();
                            }
                            return;
                        }

                        if (Greetd.state === GreetdState.Authenticating) {
                            console.log("[BLOCKED] Input blocked during authentication");
                            return;
                        }

                        if (kevent.key === Qt.Key_A && (kevent.modifiers & Qt.ControlModifier)) {
                            passwordBuffer.color = Colours.m3GeneratedColors.m3Blue;
                            sessionLock.isAllSelected = true;
                            kevent.accepted = true;
                            return;
                        }

                        if (kevent.key === Qt.Key_Backspace) {
                            if (kevent.modifiers & Qt.ControlModifier) {
                                passwordBuffer.color = Colours.m3GeneratedColors.m3OnBackground;
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                sessionLock.isAllSelected = false;
                                return;
                            }

                            if (sessionLock.isAllSelected) {
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                passwordBuffer.color = Colours.m3GeneratedColors.m3OnSurfaceVariant;
                                sessionLock.isAllSelected = false;
                                return;
                            }

                            sessionLock.inputBuffer = sessionLock.inputBuffer.slice(0, -1);

                            const randomRemove = Math.min(Math.floor(Math.random() * 3) + 1, sessionLock.maskedBuffer.length);
                            sessionLock.maskedBuffer = sessionLock.maskedBuffer.slice(0, -randomRemove);

                            if (sessionLock.maskedBuffer === "")
                                passwordBuffer.color = Colours.m3GeneratedColors.m3OnSurfaceVariant;

                            return;
                        }

                        if (kevent.text) {
                            if (sessionLock.isAllSelected) {
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                sessionLock.isAllSelected = false;
                            }

                            if (passwordBuffer.color === Colours.m3GeneratedColors.m3Blue || passwordBuffer.color === Colours.m3GeneratedColors.m3OnBackground)
                                passwordBuffer.color = sessionLock.maskedBuffer ? Colours.m3GeneratedColors.m3OnSurface : Colours.m3GeneratedColors.m3OnSurfaceVariant;

                            sessionLock.inputBuffer += kevent.text;

                            const randomLength = Math.floor(Math.random() * 3) + 1;
                            for (var i = 0; i < randomLength; i++)
                                sessionLock.maskedBuffer += sessionLock.maskChars[Math.floor(Math.random() * sessionLock.maskChars.length)];

                            const currentTime = Date.now();
                            if (sessionLock.lastKeystrokeTime > 0) {
                                const timeDelta = currentTime - sessionLock.lastKeystrokeTime;
                                if (timeDelta < 50) {
                                    fakeDelayTimer.interval = Math.random() * 30 + 10;
                                    fakeDelayTimer.restart();
                                }
                            }
                            sessionLock.lastKeystrokeTime = currentTime;

                            typingAnimation.restart();
                        }
                    }
                }

                Timer {
                    id: fakeDelayTimer

                    interval: 20
                    repeat: false
                    onTriggered: {
                        passwordBuffer.opacity = 0.99;
                        passwordBuffer.opacity = 1.0;
                    }
                }

                Timer {
                    id: fakeTypingTimer

                    interval: Math.random() * 3000 + 2000
                    repeat: true
                    running: sessionLock.locked && sessionLock.maskedBuffer.length > 0

                    onTriggered: {
                        if (Math.random() > 0.5 && sessionLock.maskedBuffer.length < 50)
                            sessionLock.maskedBuffer += sessionLock.maskChars[Math.floor(Math.random() * sessionLock.maskChars.length)];
                        else if (sessionLock.maskedBuffer.length > sessionLock.inputBuffer.length * 3)
                            sessionLock.maskedBuffer = sessionLock.maskedBuffer.slice(0, -1);

                        interval = Math.random() * 3000 + 2000;
                    }
                }

                StyledLabel {
                    id: errorLabel

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -80
                    text: "WRONG PASSWORD"
                    color: Colours.m3GeneratedColors.m3Error
                    font.pointSize: Appearance.fonts.size.large * 3
                    visible: sessionLock.showErrorMessage
                    z: 10
                }

                StyledLabel {
                    id: passwordBuffer

                    anchors.centerIn: parent
                    text: sessionLock.maskedBuffer
                    color: sessionLock.maskedBuffer ? Colours.m3GeneratedColors.m3OnSurface : Colours.m3GeneratedColors.m3OnSurfaceVariant
                    font.pointSize: Appearance.fonts.size.extraLarge * 5
                    font.family: Appearance.fonts.family.mono
                    z: 5

                    property real randomXOffset: 0
                    property real randomYOffset: 0

                    transform: Translate {
                        x: passwordBuffer.randomXOffset
                        y: passwordBuffer.randomYOffset
                    }

                    Timer {
                        interval: 100
                        repeat: true
                        running: sessionLock.locked && sessionLock.maskedBuffer.length > 0
                        onTriggered: {
                            passwordBuffer.randomXOffset = (Math.random() - 0.5) * 4;
                            passwordBuffer.randomYOffset = (Math.random() - 0.5) * 4;
                        }
                    }

                    Timer {
                        interval: 200
                        repeat: true
                        running: sessionLock.locked && sessionLock.maskedBuffer.length > 0
                        onTriggered: {
                            const baseFontSize = Appearance.fonts.size.extraLarge * 5;
                            passwordBuffer.font.pointSize = baseFontSize * (0.95 + Math.random() * 0.1);
                        }
                    }

                    SequentialAnimation {
                        id: typingAnimation

                        ParallelAnimation {
                            NAnim {
                                target: passwordBuffer
                                property: "scale"
                                from: 0.9
                                to: 1.0
                                duration: Appearance.animations.durations.small
                                easing.type: Easing.Linear
                                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                            }
                            NAnim {
                                target: passwordBuffer
                                property: "opacity"
                                from: 0.5
                                to: 1.0
                                duration: Appearance.animations.durations.small
                                easing.type: Easing.Linear
                                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                            }
                        }
                    }
                }

                StyledLabel {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 60
                    text: "Type password and press Enter"
                    color: Colours.m3GeneratedColors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    opacity: sessionLock.maskedBuffer.length === 0 ? 0.6 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                }
            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 20
                spacing: Appearance.spacing.normal

                StyledLabel {
                    text: "User:"
                    color: Colours.m3GeneratedColors.m3OnSurface
                }

                ComboBox {
                    Layout.preferredWidth: 200
                    model: ScriptModel {
                        values: [...Users.users_list]
                    }
                    currentIndex: Users.current_user_index
                    onCurrentIndexChanged: {
                        if (currentIndex !== Users.current_user_index) {
                            Users.current_user_index = currentIndex;
                            keyHandler.forceActiveFocus();
                        }
                    }
                }
            }

            StyledButton {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 20
                iconButton: "keyboard"
                buttonTitle: "Get yo ass back"
                visible: !keyHandler.activeFocus
                onClicked: {
                    keyHandler.forceActiveFocus();
                }

                opacity: keyHandler.activeFocus ? 0 : 1
                Behavior on opacity {
                    NAnim {}
                }
            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 20
                spacing: Appearance.spacing.normal

                StyledLabel {
                    text: "Session:"
                    color: Colours.m3GeneratedColors.m3OnSurface
                }

                ComboBox {
                    Layout.preferredWidth: 250
                    model: ScriptModel {
                        values: [...Sessions.session_names]
                    }
                    currentIndex: Sessions.current_ses_index
                    onCurrentIndexChanged: {
                        if (currentIndex !== Sessions.current_ses_index) {
                            Sessions.current_ses_index = currentIndex;
                            keyHandler.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
