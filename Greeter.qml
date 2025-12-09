pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd

import qs.Configs
import qs.Helpers
import qs.Greeter
import qs.Components

ShellRoot {
    id: root

    property var sessions: Sessions.sessions

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
        Themes.colorQuantizer.source = sessionLock.wallpaperPath;
        console.log("[INIT] Current session: " + Sessions.current_session);
        console.log("[INIT] Current user: " + Users.current_user);
    }

    WlSessionLock {
        id: sessionLock

        property string inputBuffer: ""
        property string maskedBuffer: ""
        readonly property list<string> maskChars: ["m", "y", "a", "m", "u", "s", "a", "s", "h", "i"]
        property bool showErrorMessage: false
        property bool isAllSelected: false
        property int fakeTypingTimer: 0
        property var lastKeystrokeTime: 0
        readonly property string wallpaperPath: "root:/Assets/wallpaper.png"
        readonly property bool unlocking: Greetd.state == GreetdState.Authenticating

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
                            passwordBuffer.color = Themes.m3GeneratedColors.m3Blue;
                            sessionLock.isAllSelected = true;
                            kevent.accepted = true;
                            return;
                        }

                        if (kevent.key === Qt.Key_Backspace) {
                            if (kevent.modifiers & Qt.ControlModifier) {
                                passwordBuffer.color = Themes.m3GeneratedColors.m3OnBackground;
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                sessionLock.isAllSelected = false;
                                return;
                            }

                            if (sessionLock.isAllSelected) {
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                passwordBuffer.color = Themes.m3GeneratedColors.m3OnSurfaceVariant;
                                sessionLock.isAllSelected = false;
                                return;
                            }

                            sessionLock.inputBuffer = sessionLock.inputBuffer.slice(0, -1);

                            const randomRemove = Math.min(Math.floor(Math.random() * 3) + 1, sessionLock.maskedBuffer.length);
                            sessionLock.maskedBuffer = sessionLock.maskedBuffer.slice(0, -randomRemove);

                            if (sessionLock.maskedBuffer === "")
                                passwordBuffer.color = Themes.m3GeneratedColors.m3OnSurfaceVariant;

                            return;
                        }

                        if (kevent.text) {
                            if (sessionLock.isAllSelected) {
                                sessionLock.inputBuffer = "";
                                sessionLock.maskedBuffer = "";
                                sessionLock.isAllSelected = false;
                            }

                            if (passwordBuffer.color === Themes.m3GeneratedColors.m3Blue || passwordBuffer.color === Themes.m3GeneratedColors.m3OnBackground)
                                passwordBuffer.color = sessionLock.maskedBuffer ? Themes.m3GeneratedColors.m3OnSurface : Themes.m3GeneratedColors.m3OnSurfaceVariant;

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
                    color: Themes.m3GeneratedColors.m3Error
                    font.pointSize: Appearance.fonts.large * 3
                    visible: sessionLock.showErrorMessage
                    z: 10
                }

                StyledLabel {
                    id: passwordBuffer

                    anchors.centerIn: parent
                    text: sessionLock.maskedBuffer
                    color: sessionLock.maskedBuffer ? Themes.m3GeneratedColors.m3OnSurface : Themes.m3GeneratedColors.m3OnSurfaceVariant
                    font.pointSize: Appearance.fonts.extraLarge * 5
                    font.family: Appearance.fonts.familyMono
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
                            const baseFontSize = Appearance.fonts.extraLarge * 5;
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
                    color: Themes.m3GeneratedColors.m3OnSurfaceVariant
                    font.pointSize: Appearance.fonts.small
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

                StyledButton {
                    iconButton: "skip_previous"
                    buttonTitle: ""
                    enabled: true
                    onClicked: {
                        Users.previous();
                        keyHandler.forceActiveFocus();
                    }
                }

                Repeater {
                    model: Users.users_list.length
                    delegate: StyledRect {
                        id: delegateUser

                        required property int index

                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 60
                        visible: Users.current_user_index === index
                        color: Users.current_user_index === index ? Themes.m3GeneratedColors.m3Primary : Themes.m3GeneratedColors.m3SurfaceVariant

                        StyledLabel {
                            anchors.centerIn: parent
                            text: Users.users_list[delegateUser.index] || ""
                            color: Users.current_user_index === delegateUser.index ? Themes.m3GeneratedColors.m3OnPrimary : Themes.m3GeneratedColors.m3OnSurfaceVariant
                        }

                        MArea {
                            anchors.fill: parent
                            onClicked: Users.current_user_index = delegateUser.index
                        }
                    }
                }

                StyledButton {
                    iconButton: "skip_next"
                    buttonTitle: ""
                    enabled: true
                    onClicked: {
                        Users.next();
                        keyHandler.forceActiveFocus();
                    }
                }
            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 20
                spacing: Appearance.spacing.normal

                StyledButton {
                    iconButton: "skip_previous"
                    buttonTitle: ""
                    enabled: true
                    onClicked: {
                        Sessions.previous();
                        keyHandler.forceActiveFocus();
                    }
                }

                Repeater {
                    model: Sessions.session_names.length
                    delegate: StyledRect {
                        id: delegateSession

                        required property int index

                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 60
                        visible: Sessions.current_ses_index === index
                        color: Sessions.current_ses_index === index ? Themes.m3GeneratedColors.m3Primary : Themes.m3GeneratedColors.m3SurfaceVariant

                        StyledLabel {
                            anchors.centerIn: parent
                            text: Sessions.session_names[delegateSession.index] || ""
                            color: Sessions.current_ses_index === delegateSession.index ? Themes.m3GeneratedColors.m3OnPrimary : Themes.m3GeneratedColors.m3OnSurfaceVariant
                        }

                        MArea {
                            anchors.fill: parent
                            onClicked: Sessions.current_ses_index = delegateSession.index
                        }
                    }
                }

                StyledButton {
                    iconButton: "skip_next"
                    buttonTitle: ""
                    enabled: true
                    onClicked: {
                        Sessions.next();
                        keyHandler.forceActiveFocus();
                    }
                }
            }
        }
    }
}
