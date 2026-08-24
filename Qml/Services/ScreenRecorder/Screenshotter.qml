pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

import qs.Core.States
import qs.Core.Configs
import qs.Components.Base
import qs.Services
import "shellUtils.js" as Utils

Item {
    id: root

    required property string screenshotDir

    property string pendingAction: ""
    property string frozenImageUrl: ""
    property bool windowPickerOpen: false
    property string pendingWindowAction: ""
    property real regionScale: 1
    property var pickForRecordCallback: null

    property var allScreenPaths: []
    property int captureIndex: 0
    property var captureDoneCallback: null
    property bool isMultiCapturing: false

    signal notify(string summary, string body, string urgency, string icon, string app)

    ScreenshotSaver {
        id: saver

        screenshotDir: root.screenshotDir

        onSaved: path => root.notify("Screenshot Saved", path, "normal", path, "Screenshot")
        onFailed: reason => root.notify("Screenshot Failed", reason, "critical", "dialog-error", "Screenshot")
    }

    Process {
        id: fileCopyProcess

        running: false
        property string destPath: ""
        // qmllint disable
        onExited: (code, status) => {
            // qmllint enable
            if (code === 0 && destPath) {
                root.notify("Screenshot Saved", destPath, "normal", destPath, "Screenshot");
                saver.copyFile(destPath);
            }
            destPath = "";
        }
    }

    LazyLoader {
        id: captureLoader

        property ShellScreen targetScreen: null
        property Toplevel targetToplevel: null
        property int targetWidth: 1
        property int targetHeight: 1

        activeAsync: false

        onActiveChanged: {
            if (!active && root.isMultiCapturing) {
                root.captureNext();
            }
        }

        component: PanelWindow {
            id: captureWin

            visible: true
            color: "transparent"
            screen: captureLoader.targetScreen
            implicitHeight: captureLoader.targetHeight
            implicitWidth: captureLoader.targetWidth
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay

            property bool done: false
            property int grabRetries: 0

            function doGrab() {
                if (scv.width <= 0 || scv.height <= 0) {
                    if (captureWin.grabRetries < 20) {
                        captureWin.grabRetries++;
                        grabRetryTimer.restart();
                    } else {
                        console.log("grabToImage: giving up after retries, closing overlays");
                        root.notify("Screenshot Failed", "Capture timed out, please try again.", "critical", "dialog-error", "Screenshot");
                        root.isMultiCapturing = false;
                        root.selectionOpen = false;
                        root.frozenImageUrl = "";
                        captureLoader.active = false;
                        if (root.captureDoneCallback) {
                            const cb = root.captureDoneCallback;
                            root.captureDoneCallback = null;
                            cb("");
                        }
                    }
                    return;
                }

                if (root.isMultiCapturing) {
                    scv.grabToImage(result => {
                        const screen = captureLoader.targetScreen;
                        const path = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            root.allScreenPaths.push({
                                screen: screen,
                                path: "file://" + path
                            });
                        } else {
                            console.log("multi capture failed for screen", screen?.name);
                        }
                        captureLoader.active = false;
                    });
                } else if (root.pendingAction === "region") {
                    scv.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (!result) {
                            root.notify("Screenshot Failed", "grabToImage returned null.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                            return;
                        }
                        if (result.saveToFile(path)) {
                            root.frozenImageUrl = "file://" + path;
                            captureLoader.active = false;
                            root.selectionOpen = true;
                        } else {
                            root.notify("Screenshot Failed", "Failed to save region preview.", "critical", "dialog-error", "Screenshot");
                            captureLoader.active = false;
                        }
                    });
                } else {
                    console.log("windowCapture: grabbing, source:", captureLoader.targetToplevel ? "toplevel" : "screen", "targetSize:", captureLoader.targetWidth, "x", captureLoader.targetHeight, "scvSize:", scv.width, "x", scv.height);
                    scv.grabToImage(result => {
                        console.log("windowCapture: grabToImage done, result:", !!result, "pendingAction:", root.pendingAction);
                        saver.saveResult(result, root.pendingAction);
                        captureLoader.active = false;
                    });
                }
            }

            Timer {
                id: grabRetryTimer

                interval: 50
                repeat: false
                onTriggered: captureWin.doGrab()
            }

            ScreencopyView {
                id: scv

                anchors.fill: parent
                captureSource: captureLoader.targetToplevel ?? captureLoader.targetScreen
                live: false
                paintCursor: false

                onHasContentChanged: {
                    if (!hasContent || captureWin.done)
                        return;
                    captureWin.done = true;
                    captureWin.doGrab();
                }
            }
        }
    }

    LazyLoader {
        id: compositeLoader

        activeAsync: false

        property string resultPath: ""

        component: PanelWindow {
            visible: true
            color: "transparent"
            screen: Quickshell.screens[0]
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay

            Canvas {
                id: compositeCanvas

                property int imagesToLoad: 0
                property int imagesLoaded: 0

                onImageLoaded: {
                    imagesLoaded++;
                    if (imagesLoaded >= imagesToLoad)
                        requestPaint();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    if (!ctx)
                        return;
                    if (compositeCanvas.width <= 0 || compositeCanvas.height <= 0)
                        return;
                    const screens = root.allScreenPaths;
                    const bounds = Utils.totalBounds(screens.map(e => e.screen));
                    ctx.clearRect(0, 0, bounds.width, bounds.height);
                    for (let i = 0; i < screens.length; i++) {
                        const s = screens[i].screen;
                        ctx.drawImage(screens[i].path, s.x - bounds.x, s.y - bounds.y, s.width, s.height);
                    }
                    grabTimer.restart();
                }
            }

            onVisibleChanged: {
                if (!visible)
                    return;
                const screens = root.allScreenPaths;
                if (screens.length === 0) {
                    compositeLoader.active = false;
                    return;
                }
                const bounds = Utils.totalBounds(screens.map(e => e.screen));
                compositeCanvas.width = bounds.width;
                compositeCanvas.height = bounds.height;
                compositeCanvas.imagesToLoad = screens.length;
                compositeCanvas.imagesLoaded = 0;
                Qt.callLater(() => {
                    for (let i = 0; i < screens.length; i++)
                        compositeCanvas.loadImage(screens[i].path);
                });
            }

            Timer {
                id: grabTimer

                interval: 150
                repeat: false
                onTriggered: {
                    compositeCanvas.grabToImage(result => {
                        const path = Utils.tempCapturePath();
                        if (result && result.saveToFile(path)) {
                            compositeLoader.resultPath = "file://" + path;
                        }
                        compositeLoader.active = false;
                        root.isMultiCapturing = false;
                        if (root.captureDoneCallback) {
                            const cb = root.captureDoneCallback;
                            root.captureDoneCallback = null;
                            cb(compositeLoader.resultPath);
                        }
                    });
                }
            }
        }
    }

    property bool selectionOpen: false

    Binding {
        target: GlobalStates
        property: "isScreenshotSelectionOpen"
        value: root.selectionOpen
    }

    // Shared selection state in virtual desktop logical pixels
    property point selStart: Qt.point(0, 0)
    property point selEnd: Qt.point(0, 0)
    property bool selDragging: false

    // Hidden crop engine — loaded when selection finishes
    LazyLoader {
        id: cropEngine

        activeAsync: false
        component: PanelWindow {
            visible: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            Image {
                id: cropImage

                source: ""
                sourceClipRect: Qt.rect(0, 0, 0, 0)
                width: sourceClipRect.width > 0 ? sourceClipRect.width : 1
                height: sourceClipRect.height > 0 ? sourceClipRect.height : 1
                cache: false

                onStatusChanged: {
                    if (status === Image.Ready && sourceClipRect.width > 0 && sourceClipRect.height > 0)
                        cropGrabTimer.restart();
                }
            }

            Timer {
                id: cropGrabTimer

                interval: 50
                repeat: false
                onTriggered: {
                    cropImage.grabToImage(result => {
                        const path = Utils.screenshotPath(root.screenshotDir);
                        if (result.saveToFile(path)) {
                            saver.copyFile(path);
                            root.notify("Screenshot Saved", path, "normal", path, "Screenshot");
                        } else {
                            root.notify("Screenshot Failed", "Failed to save cropped image.", "critical", "dialog-error", "Screenshot");
                        }
                        cropEngine.active = false;
                        root.selectionOpen = false;
                        root.frozenImageUrl = "";
                    });
                }
            }

            function doCrop(sourceUrl, x, y, w, h) {
                cropImage.sourceClipRect = Qt.rect(x, y, w, h);
                cropImage.source = sourceUrl;
            }
        }
    }

    // Multi-window selection overlay — one PanelWindow per screen
    Instantiator {
        id: selOverlay

        model: Quickshell.screens
        active: root.selectionOpen

        delegate: PanelWindow {
            required property ShellScreen modelData

            visible: true
            color: "transparent"
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:screenshot-overlay"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            readonly property real ox: modelData.x
            readonly property real oy: modelData.y
            readonly property var frozenBounds: Utils.totalBounds(Quickshell.screens)

            Image {
                source: root.frozenImageUrl
                // Composite starts at the virtual desktop's min corner; offset by
                // it so screens left of / above the primary stay aligned
                x: frozenBounds.x - ox
                y: frozenBounds.y - oy
                width: frozenBounds.width
                height: frozenBounds.height
                cache: false
                fillMode: Image.Pad
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
            }

            Rectangle {
                visible: root.selDragging
                x: Math.min(root.selStart.x, root.selEnd.x) - ox
                y: Math.min(root.selStart.y, root.selEnd.y) - oy
                width: Math.abs(root.selEnd.x - root.selStart.x)
                height: Math.abs(root.selEnd.y - root.selStart.y)
                color: "transparent"
                border.color: Colours.m3Colors.m3OnSurface
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.25)
                }
            }

            Item {
                id: focusCatcher

                anchors.fill: parent
                focus: root.selectionOpen

                Keys.onEscapePressed: {
                    root.selectionOpen = false;
                    root.frozenImageUrl = "";
                }
                Component.onCompleted: forceActiveFocus()
            }

            Timer {
                id: overlayWatchdog

                interval: 30000
                repeat: false
                running: root.selectionOpen
                onTriggered: {
                    console.log("selOverlay watchdog: force-closing frozen overlay");
                    root.selectionOpen = false;
                    root.frozenImageUrl = "";
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: e => {
                    if (e.button === Qt.RightButton) {
                        root.selectionOpen = false;
                        root.frozenImageUrl = "";
                        return;
                    }
                    root.selStart = Qt.point(e.x + ox, e.y + oy);
                    root.selEnd = root.selStart;
                    root.selDragging = true;
                }
                onPositionChanged: e => {
                    if (root.selDragging)
                        root.selEnd = Qt.point(e.x + ox, e.y + oy);
                }
                onReleased: e => {
                    if (!root.selDragging)
                        return;
                    root.selDragging = false;

                    const vx = Math.min(root.selStart.x, root.selEnd.x);
                    const vy = Math.min(root.selStart.y, root.selEnd.y);
                    const vw = Math.abs(root.selEnd.x - root.selStart.x);
                    const vh = Math.abs(root.selEnd.y - root.selStart.y);

                    if (vw < 5 || vh < 5) {
                        root.selectionOpen = false;
                        root.frozenImageUrl = "";
                        return;
                    }

                    // Crop coords are relative to the composite's min corner
                    const b = Utils.totalBounds(Quickshell.screens);
                    const s = root.regionScale;
                    const gx = Math.round((vx - b.x) * s);
                    const gy = Math.round((vy - b.y) * s);
                    const gw = Math.round(vw * s);
                    const gh = Math.round(vh * s);

                    cropEngine.active = true;
                    cropEngine.item.doCrop(root.frozenImageUrl, gx, gy, gw, gh);
                }
            }
        }
    }

    Timer {
        id: delayTimer

        repeat: false
        property var pendingFn: null
        onTriggered: {
            if (pendingFn) {
                const fn = pendingFn;
                pendingFn = null;
                fn();
            }
        }
    }

    LazyLoader {
        id: windowPicker

        activeAsync: root.windowPickerOpen

        component: PanelWindow {
            id: pickerWin

            visible: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            color: "transparent"

            Item {
                id: pickerFocus

                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: {
                    root.pickForRecordCallback = null;
                    root.windowPickerOpen = false;
                }
                Component.onCompleted: forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.pickForRecordCallback = null;
                        root.windowPickerOpen = false;
                    }
                }
            }

            property real pickerOriginX: 0
            property real pickerOriginY: 0

            // Scrolling layouts place clients at negative or far-positive global
            // coords; the active-workspace union bounds are fitted into the
            // viewport so every window stays visible and clickable.
            property real pickerScale: 1

            function recalcPickerTransform() {
                let minX = Infinity, minY = Infinity;
                let maxX = -Infinity, maxY = -Infinity;
                const list = Hypr.toplevels;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].workspace?.id !== Hypr.activeWsId)
                        continue;
                    const ipc = list[i].lastIpcObject;
                    const at = ipc?.at;
                    const size = ipc?.size;
                    if (!at || !size || size[0] <= 0 || size[1] <= 0)
                        continue;
                    minX = Math.min(minX, at[0]);
                    minY = Math.min(minY, at[1]);
                    maxX = Math.max(maxX, at[0] + size[0]);
                    maxY = Math.max(maxY, at[1] + size[1]);
                }
                if (minX === Infinity) {
                    pickerOriginX = 0;
                    pickerOriginY = 0;
                    pickerScale = 1;
                    return;
                }
                const margin = Appearance.margin.normal * 2;
                const spanW = Math.max(1, maxX - minX);
                const spanH = Math.max(1, maxY - minY);
                // Never upscale — ordinary layouts keep 1:1 geometry
                pickerScale = Math.min(1, Math.max(1, pickerWin.width - margin * 2) / spanW, Math.max(1, pickerWin.height - margin * 2) / spanH);
                pickerOriginX = minX;
                pickerOriginY = minY;
            }

            Timer {
                id: pickerRefreshTimer

                interval: 400
                repeat: false
                onTriggered: {
                    Hyprland.refreshToplevels();
                    pickerRecalcTimer.restart();
                }
            }

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    const n = event.name;
                    if (["movewindow", "openwindow", "closewindow", "changefloatingmode"].includes(n))
                        pickerRefreshTimer.restart();
                }
            }

            // refreshToplevels() lands over IPC — recalc once fresh geometry arrived
            Timer {
                id: pickerRecalcTimer

                interval: 150
                repeat: false
                onTriggered: recalcPickerTransform()
            }

            Connections {
                target: Hypr

                function onToplevelsChanged() {
                    pickerRecalcTimer.restart();
                }
            }
            Component.onCompleted: {
                recalcPickerTransform();
                pickerRefreshTimer.start();
            }
            Repeater {
                id: pickerRepeater

                model: Hypr.toplevels

                delegate: Rectangle {
                    id: pickerDelegate

                    required property HyprlandToplevel modelData

                    readonly property var ipc: modelData.lastIpcObject

                    x: ((ipc?.at?.[0] ?? 0) - pickerOriginX) * pickerScale
                    y: ((ipc?.at?.[1] ?? 0) - pickerOriginY) * pickerScale
                    width: (ipc?.size?.[0] ?? 0) * pickerScale
                    height: (ipc?.size?.[1] ?? 0) * pickerScale
                    visible: width > 0 && height > 0 && modelData.workspace?.id === Hypr.activeWsId
                    z: modelData.focusHistoryID
                    color: pickerMouse.containsMouse ? Qt.lighter(Colours.m3Colors.m3Primary, 1.4) : Colours.m3Colors.m3Primary
                    opacity: pickerMouse.containsMouse ? 0.55 : 0.25
                    radius: 6
                    border.color: pickerMouse.containsMouse ? Colours.m3Colors.m3OnPrimary : "transparent"
                    border.width: 3

                    Column {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small
                        width: Math.min(parent.width - Appearance.margin.normal * 2, 300)
                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(modelData.lastIpcObject?.class)?.icon, "image-missing")
                            asynchronous: true
                            width: 32
                            height: 32
                            backer.cache: true
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.lastIpcObject?.class ?? modelData.title ?? "?"
                            color: Colours.m3Colors.m3OnPrimary
                            font.pixelSize: Appearance.fonts.size.normal
                            font.bold: true
                            maximumLineCount: 2
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Appearance.spacing.large
                        color: Qt.alpha(Colours.m3Colors.m3Scrim, 0.6)
                        radius: Appearance.rounding.small
                        visible: pickerMouse.containsMouse
                        StyledText {
                            anchors.centerIn: parent
                            text: Math.round(pickerDelegate.x) + "," + Math.round(pickerDelegate.y) + "  " + Math.round(pickerDelegate.width) + "×" + Math.round(pickerDelegate.height)
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                        }
                    }

                    MouseArea {
                        id: pickerMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.pickForRecordCallback) {
                                const appId = modelData.lastIpcObject?.class;
                                const cb = root.pickForRecordCallback;
                                root.pickForRecordCallback = null;
                                root.windowPickerOpen = false;
                                cb(appId);
                                return;
                            }
                            const ipc = modelData.lastIpcObject;
                            const size = ipc?.size ?? [0, 0];
                            const ws = Hypr.focusedWorkspace;
                            const mon = ws?.monitor;
                            const screen = mon ? (Quickshell.screens.find(s => s.name === mon.name) ?? Quickshell.screens[0]) : Quickshell.screens[0];
                            root.pendingAction = root.pendingWindowAction;
                            captureLoader.targetScreen = screen;
                            captureLoader.targetToplevel = modelData.wayland;
                            captureLoader.targetWidth = size[0] || 1;
                            captureLoader.targetHeight = size[1] || 1;
                            captureLoader.active = true;
                            root.windowPickerOpen = false;
                        }
                    }
                }
            }
        }
    }

    function screenshotWindow(action) {
        console.log("screenshotWindow: opening window picker, action:", action);
        root.pickForRecordCallback = null;
        root.pendingWindowAction = action || "save+copy";
        root.windowPickerOpen = true;
    }

    function pickWindowForRecord(callback) {
        console.log("pickWindowForRecord: opening window picker for recording");
        root.pickForRecordCallback = callback;
        root.windowPickerOpen = true;
    }

    function screenshotSelection(action) {
        if (GlobalStates.isSelectionOpen)
            return;
        delayTimer.running = false;
        delayTimer.pendingFn = null;

        if (Quickshell.screens.length <= 1) {
            root.pendingAction = "region";
            const screen = Quickshell.screens[0];
            if (!screen) {
                root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
                return;
            }
            root.regionScale = Hyprland.monitorFor(screen)?.scale ?? 1;
            captureLoader.targetScreen = screen;
            captureLoader.targetWidth = screen.width;
            captureLoader.targetHeight = screen.height;
            delayTimer.interval = 2000;
            delayTimer.pendingFn = () => {
                captureLoader.active = true;
            };
            delayTimer.running = true;
        } else {
            const firstScreen = Quickshell.screens[0];
            root.regionScale = Hyprland.monitorFor(firstScreen)?.scale ?? 1;
            delayTimer.interval = 2000;
            delayTimer.pendingFn = () => {
                root.freezeAllScreens(path => {
                    if (!path) {
                        root.notify("Screenshot Failed", "Failed to capture screens.", "critical", "dialog-error", "Screenshot");
                        return;
                    }
                    root.frozenImageUrl = path;
                    root.selectionOpen = true;
                });
            };
            delayTimer.running = true;
        }
    }

    function screenshotOutput(target, action) {
        delayTimer.running = false;
        delayTimer.pendingFn = null;
        root.pendingAction = action || "save+copy";
        const screen = Quickshell.screens.find(s => s.name === target) ?? Quickshell.screens[0];
        if (!screen) {
            root.notify("Screenshot Failed", "No screen found.", "critical", "dialog-error", "Screenshot");
            return;
        }
        captureLoader.targetScreen = screen;
        captureLoader.targetWidth = screen.width;
        captureLoader.targetHeight = screen.height;
        delayTimer.interval = 2000;
        delayTimer.pendingFn = () => {
            captureLoader.active = true;
        };
        delayTimer.running = true;
    }

    function screenshotAllOutputs(action) {
        delayTimer.running = false;
        delayTimer.pendingFn = null;
        delayTimer.interval = 2000;
        delayTimer.pendingFn = () => {
            root.freezeAllScreens(path => {
                if (!path) {
                    root.notify("Screenshot Failed", "Failed to capture all outputs.", "critical", "dialog-error", "Screenshot");
                    return;
                }
                const srcPath = path.startsWith("file://") ? path.slice(7) : path;
                const outPath = Utils.screenshotPath(root.screenshotDir);
                fileCopyProcess.destPath = outPath;
                fileCopyProcess.command = ["cp", srcPath, outPath];
                fileCopyProcess.running = true;
            });
        };
        delayTimer.running = true;
    }

    function freezeAllScreens(callback) {
        root.allScreenPaths = [];
        root.captureIndex = 0;
        root.captureDoneCallback = callback;
        root.isMultiCapturing = true;
        root.captureNext();
    }

    function captureNext() {
        const screens = Quickshell.screens;
        if (root.captureIndex >= screens.length) {
            root.compositeAllCaptures();
            return;
        }
        const screen = screens[root.captureIndex];
        root.captureIndex++;
        captureLoader.targetScreen = screen;
        captureLoader.targetWidth = screen.width;
        captureLoader.targetHeight = screen.height;
        captureLoader.targetToplevel = null;
        captureLoader.active = true;
    }

    function compositeAllCaptures() {
        if (root.allScreenPaths.length === 0) {
            root.isMultiCapturing = false;
            root.notify("Screenshot Failed", "No screens captured.", "critical", "dialog-error", "Screenshot");
            return;
        }
        compositeLoader.active = true;
    }

    function copyToClipboard(img) {
        saver.copyFile(img);
    }

    function getMonitors(callback) {
        const names = Quickshell.screens.map(s => s.name);
        callback(names);
    }
}
