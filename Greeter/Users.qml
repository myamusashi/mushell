pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string preferred_user: "myamusashi"
    property string current_user: users_list[current_user_index] ?? ""
    property int current_user_index: 0
    property list<string> users_list: []

    function next() {
        current_user_index = (current_user_index + 1) % users_list.length;
    }

    function previous() {
        current_user_index = (current_user_index - 1 + users_list.length) % users_list.length;
    }

    Process {
        id: users

        command: ["awk", `BEGIN { FS = ":"} /\\/home/ { print $1 }`, "/etc/passwd"]
        running: true

        stderr: SplitParser {
            onRead: data => console.log("[ERR] " + data)
        }
        stdout: SplitParser {
            onRead: data => {
                console.log("[USERS] " + data);
                if (data == root.preferred_user) {
                    console.log("[INFO] Found preferred user " + root.preferred_user);
                    root.current_user_index = root.users_list.length;
                }
                root.users_list.push(data);
            }
        }
    }
}
