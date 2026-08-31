pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool adapterAvailable: adapter !== null
    readonly property bool adapterEnabled: adapter ? adapter.enabled : false
    readonly property bool adapterBlocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false
    readonly property bool isDiscovering: adapter ? adapter.discovering : false
    readonly property bool discoverable: adapter ? adapter.discoverable : false
    readonly property bool pairable: adapter ? adapter.pairable : false

    readonly property bool hasAdapter: adapterAvailable
    readonly property bool isPowered: adapterEnabled

    readonly property int connectedCount: {
        if (!adapter)
            return 0;
        let n = 0;
        for (const d of Bluetooth.devices.values)
            if (d.adapter === adapter && d.connected)
                n++;
        return n;
    }
    readonly property bool hasConnected: connectedCount > 0

    readonly property bool hasPaired: {
        if (!adapter)
            return false;
        for (const d of Bluetooth.devices.values)
            if (d.adapter === adapter && d.paired)
                return true;
        return false;
    }

    readonly property bool hasBlocked: {
        if (!adapter)
            return false;
        for (const d of Bluetooth.devices.values)
            if (d.adapter === adapter && d.blocked)
                return true;
        return false;
    }

    readonly property var pairedDevices: {
        if (!adapter)
            return [];
        const all = [...Bluetooth.devices.values];
        return all.filter(d => d.adapter === adapter && d.paired).sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            return (a.name || a.address).localeCompare(b.name || b.address);
        });
    }

    readonly property var availableDevices: {
        if (!adapter)
            return [];
        const all = [...Bluetooth.devices.values];
        return all.filter(d => d.adapter === adapter && !d.paired).sort((a, b) => {
            const an = a.name || a.deviceName || "";
            const bn = b.name || b.deviceName || "";
            if (!!an !== !!bn)
                return bn ? 1 : -1;
            return (a.name || a.address).localeCompare(b.name || b.address);
        });
    }

    readonly property var blockedDevices: {
        if (!adapter)
            return [];
        const all = [...Bluetooth.devices.values];
        return all.filter(d => d.adapter === adapter && d.blocked);
    }

    readonly property string headerSubtitle: {
        if (!adapterAvailable)
            return qsTr("No Bluetooth adapter found");
        if (adapterBlocked)
            return qsTr("Adapter blocked (rfkill)");
        if (adapter && adapter.state === BluetoothAdapterState.Enabling)
            return qsTr("Enabling…");
        if (adapter && adapter.state === BluetoothAdapterState.Disabling)
            return qsTr("Disabling…");
        if (!adapterEnabled)
            return qsTr("Bluetooth is off");
        return isDiscovering ? qsTr("Scanning…") : qsTr("Tap a device to connect");
    }

    readonly property string cardSubtitle: {
        if (!hasAdapter)
            return qsTr("No adapter");
        if (!isPowered)
            return qsTr("Off");
        if (hasConnected)
            return qsTr("%1 connected").arg(connectedCount);
        if (adapter && adapter.discovering)
            return qsTr("Scanning…");
        return qsTr("On — not connected");
    }

    readonly property string cardIconName: {
        if (!hasAdapter)
            return "bluetooth_disabled";
        if (!isPowered)
            return "bluetooth_disabled";
        if (hasConnected)
            return "bluetooth_connected";
        if (adapter && adapter.discovering)
            return "bluetooth_searching";
        return "bluetooth";
    }

    function setEnabled(checked: bool): void {
        if (adapter)
            adapter.enabled = checked;
    }

    function setDiscoverable(checked: bool): void {
        if (adapter)
            adapter.discoverable = checked;
    }

    function setPairable(checked: bool): void {
        if (adapter)
            adapter.pairable = checked;
    }

    function setDiscovering(checked: bool): void {
        if (adapter)
            adapter.discovering = checked;
    }

    function displayName(device): string {
        if (!device)
            return "";
        return device.name || device.deviceName || device.address || "";
    }

    function stateString(device): string {
        if (!device)
            return "";
        if (device.pairing)
            return qsTr("Pairing…");
        return BluetoothDeviceState.toString(device.state);
    }

    function addressLine(device): string {
        if (!device)
            return "";
        const addr = device.address || "";
        const extra = device.pairing ? " · " + qsTr("Pairing…") : "";
        return addr + extra;
    }
}
