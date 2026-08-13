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
    property bool launched: false
    property var users: []
    property ListModel sessions: ListModel {}

    signal authenticated

    readonly property bool available: Greetd.available

    onCurrentTextChanged: {
        if (root.showFailure || root.messageIsError) {
            root.showFailure = false;
            root.messageIsError = false;
            root.statusMessage = "";
        }
    }

    function tryUnlock() {
        if (root.currentText === "" || root.currentUser === "")
            return;
        if (Greetd.state !== GreetdState.Inactive)
            return;

        root.showFailure = false;
        root.messageIsError = false;
        root.statusMessage = qsTr("Authenticating…");
        root.unlockInProgress = true;
        Greetd.createSession(root.currentUser);
    }

    function switchUser(username) {
        if (root.currentUser === username || root.unlockInProgress)
            return;

        root.currentUser = username;
        root.currentText = "";
        root.showFailure = false;
        root.messageIsError = false;
        root.statusMessage = "";
    }

    function launch() {
        if (root.launched)
            return;
        root.launched = true;
        let index = root.selectedSessionIndex;
        if (index < 0 || index >= root.sessions.count)
            index = 0;
        const session = root.sessions.get(index);
        const rawCommand = session && session.command ? session.command : "bash";
        Greetd.launch(rawCommand.split(" ").filter(part => part.length > 0));
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
            root.statusMessage = qsTr("Launching session…");
            root.authenticated();
        }

        function onError(error) {
            root.showFailure = true;
            root.messageIsError = true;
            root.statusMessage = error;
            root.unlockInProgress = false;
        }

        function onLaunched() {
            Quickshell.execDetached({
                command: ["pkill", "-TERM", "-x", "mango"]
            });
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
            }
        }
    }
}
