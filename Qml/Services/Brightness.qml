pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Brightness

import qs.Services

Singleton {
    id: root

    readonly property bool available: root.primaryId !== ""
    readonly property int maxValue: 100

    property int value: 0
    property string primaryId: ""
    property var displays: []

    function refresh() {
        const list = BrightnessManager.displays();
        root.displays = list;
        if (root.primaryId === "") {
            const internal = list.find(d => d.isInternal);
            root.primaryId = (internal ?? list[0])?.id ?? "";
        }
        const primary = list.find(d => d.id === root.primaryId);
        if (primary)
            root.value = primary.brightness;
    }

    function setBrightness(newValue: int) {
        if (!root.available)
            return;
        BrightnessManager.setBrightness(root.primaryId, newValue);
    }

    function setBrightnessPercent(percent: int) {
        if (!root.available)
            return;
        BrightnessManager.setBrightness(root.primaryId, percent);
    }

    function increaseBrightness(amount: int) {
        if (!root.available)
            return;
        BrightnessManager.setBrightness(root.primaryId, Math.min(100, root.value + Math.round(amount)));
    }

    function decreaseBrightness(amount: int) {
        if (!root.available)
            return;
        BrightnessManager.setBrightness(root.primaryId, Math.max(0, root.value - Math.round(amount)));
    }

    function setBrightnessForDisplay(displayId: string, percent: int) {
        BrightnessManager.setBrightness(displayId, percent);
    }

    function setBrightnessGroup(targets: var) {
        BrightnessManager.setBrightnessGroup(targets);
    }

    function setBrightnessAll(percent: int) {
        BrightnessManager.setBrightnessAll(percent);
    }

    function saveProfile(name: string, targets: var) {
        BrightnessManager.saveProfile(name, targets);
    }

    function applyProfile(name: string) {
        BrightnessManager.applyProfile(name);
    }

    function removeProfile(name: string) {
        BrightnessManager.removeProfile(name);
    }

    function profileNames(): var {
        return BrightnessManager.profileNames();
    }

    Component.onCompleted: Qt.callLater(() => {
        BrightnessManager.initialize();
    })

    Connections {
        target: BrightnessManager

        function onBrightnessChanged(displayId: string, percent: int) {
            root.displays = BrightnessManager.displays();

            if (displayId === root.primaryId)
                root.value = percent;
        }

        function onDisplayListChanged() {
            root.refresh();
        }

        function onInitializationFailed(reason: string) {
            console.warn("BrightnessManager init failed:", reason);
            ToastService.show(qsTr("Brightness unavailable: %1").arg(reason), qsTr("Brightness"), "display-brightness-symbolic", 3000);
        }
    }

    IpcHandler {
        target: "brightness"
        function get(): string {
            return JSON.stringify(BrightnessManager.displays());
        }
        function set(percent: int): void {
            BrightnessManager.setBrightnessAll(percent);
        }
        function change(delta: int): void {
            const targets = {};
            for (const d of BrightnessManager.displays())
                targets[d.id] = Math.max(0, Math.min(100, d.brightness + delta));
            BrightnessManager.setBrightnessGroup(targets);
        }
    }
}
