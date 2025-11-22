pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string sessions: Quickshell.env("KURU_DM_SESSIONS") || "/run/current-system/sw/share/wayland-sessions"
    property string preferred_session: "hyprland"
    property int current_ses_index: 0
    property string current_session: session_execs[current_ses_index] ?? "Hyprland"
    property string current_session_name: session_names[current_ses_index] ?? "Hyprland"
    property list<string> session_execs: []
    property list<string> session_names: []

    function next() {
        if (session_execs.length > 0)
            current_ses_index = (current_ses_index + 1) % session_execs.length;
    }

    function previous() {
        if (session_execs.length > 0)
            current_ses_index = (current_ses_index - 1 + session_execs.length) % session_execs.length;
    }

    Process {
        id: sessions

        command: [Qt.resolvedUrl("../Assets/session.sh"), root.sessions]
        running: true

        stderr: SplitParser {
            onRead: data => console.log("[SESSIONS ERR] " + data)
        }

        stdout: SplitParser {
            onRead: data => {
                const parsedData = data.split(",");
                if (parsedData.length >= 3) {
                    console.log("[SESSIONS] ID: " + parsedData[0] + ", Name: " + parsedData[1] + ", Exec: " + parsedData[2]);

                    if (parsedData[0] == root.preferred_session) {
                        console.log("[INFO] Found preferred session " + root.preferred_session);
                        root.current_ses_index = root.session_names.length;
                    }

                    root.session_names.push(parsedData[1]);
                    root.session_execs.push(parsedData[2]);
                }
            }
        }

        onExited: {
            console.log("[SESSIONS] Loaded " + root.session_execs.length + " sessions");
            if (root.session_execs.length === 0) {
                console.log("[WARN] No sessions found, adding fallback");
                root.session_names.push("Hyprland");
                root.session_execs.push("Hyprland");
            }
        }
    }
}
