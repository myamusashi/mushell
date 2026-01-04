pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// MangoService integrates with MangoWC compositor using mmsg IPC commands
Singleton {
    id: root

    // Direct property exposure (like Hypr.qml)
    readonly property var workspaces: workspacesModel
    readonly property var windows: windowsList
    readonly property int focusedWindowIndex: _focusedWindowIndex
    readonly property bool overviewActive: _overviewActive
    readonly property string currentLayoutSymbol: _currentLayoutSymbol
    readonly property string selectedMonitor: _selectedMonitor
    readonly property var displayScales: _displayScales

    // Signals
    signal workspaceChanged
    signal activeWindowChanged
    signal windowListChanged

    // Internal state (prefixed with _)
    property bool _initialized: false
    property bool _overviewActive: false
    property int _focusedWindowIndex: -1
    property string _currentLayoutSymbol: ""
    property string _selectedMonitor: ""
    property var _displayScales: ({})
    property var _workspaceCache: ({})
    property var _windowCache: ({})
    property var _monitorCache: ({})

    // Internal models
    property ListModel workspacesModel: ListModel {}
    property var windowsList: []

    // Constants
    readonly property var mmsgCommands: ({
            "query": {
                "workspaces": ["mmsg", "-g", "-t"],
                "windows": ["mmsg", "-g", "-c"],
                "layout": ["mmsg", "-g", "-l"],
                "outputs": ["mmsg", "-g", "-A"],
                "monitors": ["mmsg", "-g", "-o"],
                "outputEnum": ["mmsg", "-g", "-O"],
                "eventStream": ["mmsg", "-w"]
            },
            "action": {
                "view": ["mmsg", "-s", "-d", "view"],
                "tag": ["mmsg", "-s", "-t"],
                "focusMaster": ["mmsg", "-s", "-d", "focusmaster"],
                "killClient": ["mmsg", "-s", "-d", "killclient"],
                "toggleOverview": ["mmsg", "-s", "-d", "toggleoverview"],
                "setLayout": ["mmsg", "-s", "-d", "setlayout"],
                "quit": ["mmsg", "-s", "-q"]
            }
        })

    readonly property string overviewLayoutSymbol: "󰃇"
    readonly property int defaultWorkspaceId: 1

    // Debounce timer
    Timer {
        id: updateTimer

        interval: 50
        repeat: false
        onTriggered: root._safeUpdate()
    }

    // Event stream process
    Process {
        id: eventStream

        running: false
        command: root.mmsgCommands.query.eventStream

        stdout: SplitParser {
            onRead: function (line) {
                try {
                    root._handleEvent(line.trim());
                } catch (e) {
                    console.error("MangoService", "Event parsing error:", e, line);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                console.error("MangoService", "Event stream exited, restarting...");
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 1000
        onTriggered: {
            if (root._initialized)
                eventStream.running = true;
        }
    }

    // Workspaces process
    Process {
        id: workspacesProcess

        running: false
        command: root.mmsgCommands.query.workspaces
        property string accumulatedOutput: ""

        stdout: SplitParser {
            onRead: function (line) {
                workspacesProcess.accumulatedOutput += line + "\n";
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0)
                root._parseWorkspaces(accumulatedOutput);
            else
                console.error("MangoService", "Workspaces query failed:", exitCode);

            accumulatedOutput = "";
        }
    }

    // Windows process
    Process {
        id: windowsProcess

        running: false
        command: root.mmsgCommands.query.windows
        property var currentWindow: ({})

        onRunningChanged: {
            if (running)
                windowsProcess.currentWindow = {};
        }

        stdout: SplitParser {
            onRead: function (line) {
                const trimmed = line.trim();
                if (!trimmed)
                    return;
                const parts = trimmed.split(' ');
                if (parts.length >= 3) {
                    const outputName = parts[0];
                    const property = parts[1];
                    const value = parts.slice(2).join(' ');

                    if (!windowsProcess.currentWindow[outputName])
                        windowsProcess.currentWindow[outputName] = {
                            "id": outputName,
                            "output": outputName
                        };

                    switch (property) {
                    case "title":
                        windowsProcess.currentWindow[outputName].title = value;
                        break;
                    case "appid":
                        windowsProcess.currentWindow[outputName].appId = value;
                        windowsProcess.currentWindow[outputName].class = value;
                        break;
                    case "fullscreen":
                        windowsProcess.currentWindow[outputName].fullscreen = (value === "1");
                        break;
                    case "floating":
                        windowsProcess.currentWindow[outputName].floating = (value === "1");
                        break;
                    case "x":
                        windowsProcess.currentWindow[outputName].x = parseInt(value);
                        break;
                    case "y":
                        windowsProcess.currentWindow[outputName].y = parseInt(value);
                        break;
                    case "width":
                        windowsProcess.currentWindow[outputName].width = parseInt(value);
                        break;
                    case "height":
                        windowsProcess.currentWindow[outputName].height = parseInt(value);
                        break;
                    }
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0)
                root._parseWindows(windowsProcess.currentWindow);
            else
                console.error("MangoService", "Windows query failed:", exitCode);

            windowsProcess.currentWindow = {};
        }
    }

    // Layout process
    Process {
        id: layoutProcess

        running: false
        command: root.mmsgCommands.query.layout

        stdout: SplitParser {
            onRead: function (line) {
                try {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 2) {
                        const layoutSymbol = parts.slice(1).join(' ');
                        root._handleLayoutChange(layoutSymbol);
                    }
                } catch (e) {
                    console.error("MangoService", "Layout parsing error:", e, line);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.error("MangoService", "Layout query failed:", exitCode);
        }
    }

    // Outputs process
    Process {
        id: outputsProcess

        running: false
        command: root.mmsgCommands.query.outputs

        stdout: SplitParser {
            onRead: function (line) {
                try {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3 && parts[1] === "scale_factor") {
                        const outputName = parts[0];
                        const scaleFactor = parseFloat(parts[2]);

                        if (!root._monitorCache[outputName])
                            root._monitorCache[outputName] = {};

                        root._monitorCache[outputName].scale = scaleFactor;
                        root._monitorCache[outputName].name = outputName;
                    }
                } catch (e) {
                    console.error("MangoService", "Output parsing error:", e, line);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0)
                root._updateDisplayScales();
            else
                console.error("MangoService", "Outputs query failed:", exitCode);
        }
    }

    // Monitor state process
    Process {
        id: monitorStateProcess

        running: false
        command: root.mmsgCommands.query.monitors

        stdout: SplitParser {
            onRead: function (line) {
                try {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3 && parts[1] === "selmon") {
                        const outputName = parts[0];
                        const isSelected = parts[2] === "1";
                        if (isSelected) {
                            root._selectedMonitor = outputName;
                            console.log("MangoService", `Initial selected monitor: ${outputName}`);
                        }
                    }
                } catch (e) {
                    console.error("MangoService", "Monitor state parsing error:", e, line);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.error("MangoService", "Monitor state query failed:", exitCode);
        }
    }

    // Output enumeration process
    Process {
        id: outputEnumProcess

        running: false
        command: root.mmsgCommands.query.outputEnum

        stdout: SplitParser {
            onRead: function (line) {
                try {
                    const trimmed = line.trim();
                    const outputName = trimmed.replace(/^\+\s*/, '');
                    if (outputName && !root._monitorCache[outputName])
                        root._monitorCache[outputName] = {
                            "name": outputName,
                            "scale": 1.0,
                            "active": false,
                            "focused": false
                        };
                } catch (e) {
                    console.error("MangoService", "Output enumeration error:", e, line);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.error("MangoService", "Output enumeration failed:", exitCode);
        }
    }

    // Public API functions (like Hypr.dispatch)
    function dispatch(action: string): void {
        try {
            const parts = action.split(' ');
            const cmd = parts[0];
            const args = parts.slice(1);

            switch (cmd) {
            case "workspace":
                switchToWorkspace({
                    "idx": parseInt(args[0])
                });
                break;
            case "killactive":
                closeWindow(null);
                break;
            case "toggleoverview":
                toggleOverview();
                break;
            case "exit":
                logout();
                break;
            default:
                console.warn("MangoService", "Unknown dispatch command:", cmd);
            }
        } catch (e) {
            console.error("MangoService", "Dispatch failed:", e);
        }
    }

    function switchToWorkspace(workspace) {
        try {
            const tagId = workspace.idx || workspace.id || defaultWorkspaceId;
            const outputName = workspace.output || _selectedMonitor || "";
            let command = mmsgCommands.action.tag.slice();

            if (outputName && Object.keys(_monitorCache).length > 1)
                command.push("-o", outputName);

            command.push(tagId.toString());

            Quickshell.execDetached(command);
        } catch (e) {
            console.error("MangoService", "Failed to switch workspace:", e);
        }
    }

    function focusWindow(window) {
        try {
            if (window && window.output) {
                let command = mmsgCommands.action.view.slice();
                const isMultiMonitor = Object.keys(_monitorCache).length > 1;

                if (isMultiMonitor)
                    command.push("-o", window.output);

                command.push(window.workspaceId.toString());
                Quickshell.execDetached(command);

                Qt.callLater(() => {
                    let focusCommand = mmsgCommands.action.focusMaster.slice();
                    if (isMultiMonitor)
                        focusCommand.push("-o", window.output);

                    Quickshell.execDetached(focusCommand);
                });
            }
        } catch (e) {
            console.error("MangoService", "Failed to focus window:", e);
        }
    }

    function closeWindow(window) {
        try {
            const command = mmsgCommands.action.killClient.slice();
            if (_selectedMonitor && Object.keys(_monitorCache).length > 1)
                command.push("-o", _selectedMonitor);

            Quickshell.execDetached(command);
        } catch (e) {
            console.error("MangoService", "Failed to close window:", e);
        }
    }

    function toggleOverview() {
        try {
            const command = mmsgCommands.action.toggleOverview.slice();
            if (_selectedMonitor && Object.keys(_monitorCache).length > 1)
                command.push("-o", _selectedMonitor);

            Quickshell.execDetached(command);
        } catch (e) {
            console.error("MangoService", "Failed to toggle overview:", e);
        }
    }

    function setLayout(layoutName) {
        try {
            const command = mmsgCommands.action.setLayout.slice();
            command.push(layoutName);
            Quickshell.execDetached(command);
        } catch (e) {
            console.error("MangoService", "Failed to set layout:", e);
        }
    }

    function logout() {
        try {
            Quickshell.execDetached(mmsgCommands.action.quit);
        } catch (e) {
            console.error("MangoService", "Failed to logout:", e);
        }
    }

    // Initialization
    Component.onCompleted: {
        _initialize();
    }

    // Internal functions (prefixed with _)
    function _initialize() {
        if (_initialized) {
            console.log("MangoService", "Already initialized");
            return;
        }

        try {
            console.log("MangoService", "Service started");

            outputEnumProcess.running = true;
            monitorStateProcess.running = true;
            eventStream.running = true;
            workspacesProcess.running = true;
            windowsProcess.running = true;
            layoutProcess.running = true;
            outputsProcess.running = true;

            _initialized = true;
            console.log("MangoService", "Service initialized successfully");
        } catch (e) {
            console.error("MangoService", "Initialization failed:", e);
            eventStream.running = true;
        }
    }

    function _parseWorkspaces(output) {
        const lines = output.trim().split('\n');
        const workspacesList = [];
        const newWorkspaceCache = {};

        for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed)
                continue;
            const tagMatch = trimmed.match(/^(\S+)\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/);
            if (tagMatch) {
                const outputName = tagMatch[1];
                const tagNum = tagMatch[2];
                const state = tagMatch[3];
                const clients = tagMatch[4];
                const focused = tagMatch[5];
                const tagId = parseInt(tagNum);

                const isActive = (parseInt(state) & 1) !== 0;
                const isUrgent = (parseInt(state) & 2) !== 0;
                const isOccupied = parseInt(clients) > 0;
                const isFocused = isActive && parseInt(focused) === 1;

                const workspaceData = {
                    "id": tagId,
                    "idx": tagId,
                    "name": tagId.toString(),
                    "output": outputName,
                    "isActive": isActive,
                    "isFocused": isFocused || (isActive && (outputName === _selectedMonitor)),
                    "isUrgent": isUrgent,
                    "isOccupied": isOccupied,
                    "clients": parseInt(clients)
                };

                newWorkspaceCache[`${outputName}-${tagId}`] = workspaceData;
                workspacesList.push(workspaceData);
            }

            const tagsMatch = trimmed.match(/^(\S+)\s+tags\s+(\d+)\s+(\d+)\s+(\d+)$/);
            if (tagsMatch) {
                const outputName = tagsMatch[1];
                const occ = tagsMatch[2];
                const seltags = tagsMatch[3];
                const urg = tagsMatch[4];

                const occBits = occ.padStart(9, '0');
                const selBits = seltags.padStart(9, '0');
                const urgBits = urg.padStart(9, '0');

                for (var i = 0; i < 9; i++) {
                    const tagId = i + 1;
                    const isActive = selBits[8 - i] === '1';
                    const isUrgent = urgBits[8 - i] === '1';
                    const isOccupied = occBits[8 - i] === '1';

                    const workspaceData = {
                        "id": tagId,
                        "idx": tagId,
                        "name": tagId.toString(),
                        "output": outputName,
                        "isActive": isActive,
                        "isFocused": false,
                        "isUrgent": isUrgent,
                        "isOccupied": isOccupied,
                        "clients": 0
                    };

                    const key = `${outputName}-${tagId}`;
                    if (!newWorkspaceCache[key]) {
                        newWorkspaceCache[key] = workspaceData;
                        workspacesList.push(workspaceData);
                    }
                }
            }

            const layoutMatch = trimmed.match(/^(\S+)\s+layout\s+(\S+)$/);
            if (layoutMatch) {
                const layoutSymbol = layoutMatch[2];
                root._handleLayoutChange(layoutSymbol);
            }
        }

        if (JSON.stringify(newWorkspaceCache) !== JSON.stringify(_workspaceCache)) {
            _workspaceCache = newWorkspaceCache;

            workspacesList.sort((a, b) => {
                if (a.id !== b.id)
                    return a.id - b.id;
                return a.output.localeCompare(b.output);
            });

            workspacesModel.clear();
            for (var i = 0; i < workspacesList.length; i++)
                workspacesModel.append(workspacesList[i]);

            workspaceChanged();
        }
    }

    function _parseWindows(windowData) {
        const windowsList = [];
        const newWindowCache = {};
        let newFocusedIndex = -1;

        const windowEntries = Object.entries(windowData);
        for (var i = 0; i < windowEntries.length; i++) {
            const outputName = windowEntries[i][0];
            const data = windowEntries[i][1];
            if (data.title || data.appId) {
                const isFocused = (outputName === _selectedMonitor);

                let activeTagId = defaultWorkspaceId;
                const workspaceEntries = Object.entries(_workspaceCache);
                for (var j = 0; j < workspaceEntries.length; j++) {
                    const tagData = workspaceEntries[j][1];
                    if (tagData.output === outputName && tagData.isActive) {
                        activeTagId = tagData.id;
                        break;
                    }
                }

                const windowInfo = {
                    "id": `${outputName}-${data.appId || 'unknown'}`,
                    "title": data.title || "",
                    "appId": data.appId || "",
                    "class": data.appId || "",
                    "workspaceId": activeTagId,
                    "isFocused": isFocused,
                    "output": outputName,
                    "fullscreen": data.fullscreen || false,
                    "floating": data.floating || false,
                    "x": data.x || 0,
                    "y": data.y || 0,
                    "width": data.width || 0,
                    "height": data.height || 0,
                    "geometry": {
                        "x": data.x || 0,
                        "y": data.y || 0,
                        "width": data.width || 0,
                        "height": data.height || 0
                    }
                };

                windowsList.push(windowInfo);
                newWindowCache[windowInfo.id] = windowInfo;

                if (isFocused)
                    newFocusedIndex = windowsList.length - 1;
            }
        }

        if (JSON.stringify(newWindowCache) !== JSON.stringify(_windowCache)) {
            _windowCache = newWindowCache;
            windowsList = windowsList;

            if (newFocusedIndex !== _focusedWindowIndex) {
                _focusedWindowIndex = newFocusedIndex;
                activeWindowChanged();
            }

            windowListChanged();
        }
    }

    function _handleLayoutChange(layoutSymbol) {
        const wasOverview = _overviewActive;
        const isOverview = (layoutSymbol === overviewLayoutSymbol);

        if (wasOverview !== isOverview)
            _overviewActive = isOverview;

        if (layoutSymbol !== _currentLayoutSymbol)
            _currentLayoutSymbol = layoutSymbol;
    }

    function _updateDisplayScales() {
        const scales = {};
        const monitorEntries = Object.entries(_monitorCache);
        for (var i = 0; i < monitorEntries.length; i++) {
            const outputName = monitorEntries[i][0];
            const data = monitorEntries[i][1];
            scales[outputName] = {
                "name": data.name || outputName,
                "scale": data.scale || 1.0,
                "width": data.width || 0,
                "height": data.height || 0,
                "refresh_rate": data.refresh_rate || 0,
                "x": data.x || 0,
                "y": data.y || 0,
                "active": data.active || false,
                "focused": data.focused || false
            };
        }

        _displayScales = scales;
        displayScalesChanged();
    }

    function _handleEvent(eventLine) {
        const parts = eventLine.trim().split(/\s+/);
        if (parts.length < 2)
            return;
        const eventType = parts[1];

        switch (eventType) {
        case "selmon":
            if (parts.length >= 3) {
                const monitorName = parts[0];
                const isSelected = parts[2] === "1";
                if (isSelected)
                    _selectedMonitor = monitorName;
            }
            updateTimer.restart();
            break;
        case "tag":
        case "title":
        case "appid":
        case "fullscreen":
        case "floating":
        case "layout":
        case "scale_factor":
        case "clients":
        case "tags":
            updateTimer.restart();
            break;
        }
    }

    function _safeUpdate() {
        try {
            workspacesProcess.running = true;
            windowsProcess.running = true;
            monitorStateProcess.running = true;
        } catch (e) {
            console.error("MangoService", "Safe update failed:", e);
        }
    }
}
