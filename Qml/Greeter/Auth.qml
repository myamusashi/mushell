pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

import qs.Core.Utils

Scope {
    id: root

    property string currentText: ""
    property bool showFailure: false
    property bool isUnlock: false
    property bool unlockInProgress: false

    property string currentUser: ""
    property string statusMessage: ""
    property bool messageIsError: false
    property bool echoResponse: false
    property int selectedSessionIndex: -1
    property var users: []
    property ListModel sessions: ListModel {}
    property string lastSessionCommand: ""
    property bool launching: false

    signal launchReady

    readonly property bool available: Greetd.available

    onLastSessionCommandChanged: selectSession(sessionIndexForCommand(lastSessionCommand))

    onCurrentTextChanged: {
        if (showFailure || messageIsError) {
            showFailure = false;
            messageIsError = false;
            statusMessage = "";
        }
    }

    function tryUnlock() {
        if (currentText === "" || currentUser === "")
            return;
        if (Greetd.state !== GreetdState.Inactive)
            return;

        showFailure = false;
        messageIsError = false;
        statusMessage = qsTr("Authenticating…");
        unlockInProgress = true;
        Greetd.createSession(root.currentUser);
    }

    function launch() {
        if (launching || Greetd.state !== GreetdState.ReadyToLaunch)
            return;
        launching = true;
        let index = selectedSessionIndex;
        if (index < 0 || index >= sessions.count)
            index = 0;
        const session = sessions.get(index);
        const rawCommand = session && session.command ? session.command : "bash";
        if (session && session.command)
            saveLastSession(session.command);
        Greetd.launch(rawCommand.split(" ").filter(part => part.length > 0));
    }

    function switchUser(username) {
        if (currentUser === username || unlockInProgress)
            return;

        currentUser = username;
        currentText = "";
        showFailure = false;
        messageIsError = false;
        statusMessage = "";
    }

    function selectSession(index) {
        if (index < 0 || index >= sessions.count)
            return;
        selectedSessionIndex = index;
        const session = sessions.get(index);
        if (session && session.command)
            saveLastSession(session.command);
    }

    function saveLastSession(command) {
        if (lastSessionCommand === command)
            return;
        lastSessionCommand = command;
        Quickshell.execDetached({
            command: [Paths.projectRoot + "/Assets/shell/last-session.sh", command]
        });
    }

    function sessionIndexForCommand(command) {
        if (command === "")
            return -1;
        for (let i = 0; i < sessions.count; i++)
            if (sessions.get(i).command === command)
                return i;

        return -1;
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.statusMessage = message;
            root.messageIsError = error;
            root.echoResponse = echoResponse;

            if (responseRequired) {
                if (root.currentText.length > 0) {
                    Greetd.respond(root.currentText);
                    root.currentText = "";
                } else {
                    root.unlockInProgress = false;
                }
            }
        }

        function onAuthFailure(message) {
            root.showFailure = true;
            root.messageIsError = true;
            root.statusMessage = message;
            root.currentText = "";
            root.unlockInProgress = false;
        }

        function onReadyToLaunch() {
            root.statusMessage = qsTr("Session Start");
            root.launchReady();
        }

        function onError(error) {
            root.launching = false;
            root.showFailure = true;
            root.messageIsError = true;
            root.statusMessage = error;
            root.unlockInProgress = false;
        }
    }

    Process {
        id: usersProcess

        command: ["awk", "-F:", "/\\/home/ { print $1 }", "/etc/passwd"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(line => line.length > 0);
                root.users = lines;
                if (root.currentUser === "" && lines.length > 0)
                    root.currentUser = lines[0];
            }
        }
    }

    Process {
        id: sessionsProcess

        command: [Paths.projectRoot + "/Assets/shell/desktop-session.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(line => line.length > 0);
                for (const line of lines) {
                    const parts = line.split("|||");
                    if (parts.length !== 2)
                        continue;
                    root.sessions.append({
                        display: parts[0],
                        command: parts[1].trim()
                    });
                }
                root.selectSession(root.sessionIndexForCommand(root.lastSessionCommand));
            }
        }
    }

    Process {
        id: lastSessionProcess

        command: [Paths.projectRoot + "/Assets/shell/last-session.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value.length > 0)
                    root.lastSessionCommand = value;
            }
        }
    }
}
