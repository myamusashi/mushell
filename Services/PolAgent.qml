pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Services.Polkit

Singleton {
    readonly property Agent agent: Agent {}
    component Agent: PolkitAgent {
        id: polkitAgent
    }
}
