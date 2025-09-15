pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: root

	// Memory and disk
	property real memTotal
	property real memUsed
	property real diskUsed
	property real diskTotal

	// Networking
	property string wiredInterface
	property string wirelessInterface

	property var previousData: ({})
	property var lastUpdateTime: 0

	// Wireless
	property real wirelessUploadSpeed
	property real wirelessDownloadSpeed

	property real totalWirelessDownloadUsage
	property real totalWirelessUploadUsage

	// Wired
	property real wiredUploadSpeed
	property real wiredDownloadSpeed

	property real totalWiredDownloadUsage
	property real totalWiredUploadUsage

	// CPU
	property real cpuPerc: 0
	property real lastCpuIdle: 0
	property real lastCpuTotal: 0
	property bool initialized: false

	FileView {
		id: networkInfo

		path: "/proc/net/dev"
		onLoaded: {
			const data = text();
			root.calculateNetworkStats(data);
		}
	}

	Process {
		id: networkWiredInterfacesState

		command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device status | grep ':ethernet:' | head -1"]
		stdout: StdioCollector {
			onStreamFinished: {
				const data = text.trim();
				root.wiredInterface = root.parseInterfaceState(data, "ethernet");
			}
		}
	}

	Process {
		id: networkWirelessInterfacesState

		command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device status | grep ':wifi:' | head -1"]
		stdout: StdioCollector {
			onStreamFinished: {
				const data = text.trim();
				root.wirelessInterface = root.parseInterfaceState(data, "wifi");
			}
		}
	}

	function parseInterfaceState(data, expectedType) {
		if (!data) {
			return `No ${expectedType} interface found`;
		}

		const [device, type, state] = data.split(':');

		if (type !== expectedType) {
			return `No ${expectedType} interface found`;
		}

		const status = (state === "connected") ? "ONLINE" : "OFFLINE";
		return `${device} [${status}]`;
	}

	function parseNetworkData(data) {
		const lines = data.split('\n');
		const interfaces = {};

		for (let i = 2; i < lines.length; i++) {
			const line = lines[i].trim();
			if (line === '')
				continue;

			const parts = line.split(/\s+/);
			if (parts.length < 17)
				continue;

			const interfaceName = parts[0].replace(':', '');

			interfaces[interfaceName] = {
				rxBytes: parseInt(parts[1]) || 0,
				rxPackets: parseInt(parts[2]) || 0,
				txBytes: parseInt(parts[9]) || 0,
				txPackets: parseInt(parts[10]) || 0
			};
		}

		return interfaces;
	}

	// Thx claude
	function calculateNetworkStats(data) {
		const currentTime = Date.now();
		const currentData = parseNetworkData(data);

		if (currentData[wirelessInterface]) {
			totalWirelessDownloadUsage = currentData[wirelessInterface].rxBytes / (1024 * 1024);
			totalWirelessUploadUsage = currentData[wirelessInterface].txBytes / (1024 * 1024);
		}

		if (currentData[wiredInterface]) {
			totalWiredDownloadUsage = currentData[wiredInterface].rxBytes / (1024 * 1024);
			totalWiredUploadUsage = currentData[wiredInterface].txBytes / (1024 * 1024);
		}

		if (previousData && Object.keys(previousData).length > 0 && lastUpdateTime > 0) {
			const timeDiff = (currentTime - lastUpdateTime) / 1000;

			if (timeDiff > 0) {
				if (currentData[wirelessInterface] && previousData[wirelessInterface]) {
					const wirelessRxDiff = currentData[wirelessInterface].rxBytes - previousData[wirelessInterface].rxBytes;
					const wirelessTxDiff = currentData[wirelessInterface].txBytes - previousData[wirelessInterface].txBytes;

					wirelessDownloadSpeed = Math.max(0, wirelessRxDiff / (1024 * 1024) / timeDiff);
					wirelessUploadSpeed = Math.max(0, wirelessTxDiff / (1024 * 1024) / timeDiff);
				}

				if (currentData[wiredInterface] && previousData[wiredInterface]) {
					const wiredRxDiff = currentData[wiredInterface].rxBytes - previousData[wiredInterface].rxBytes;
					const wiredTxDiff = currentData[wiredInterface].txBytes - previousData[wiredInterface].txBytes;

					wiredDownloadSpeed = Math.max(0, wiredRxDiff / (1024 * 1024) / timeDiff);
					wiredUploadSpeed = Math.max(0, wiredTxDiff / (1024 * 1024) / timeDiff);
				}
			}
		}

		previousData = JSON.parse(JSON.stringify(currentData));
		lastUpdateTime = currentTime;
	}

	function formatSpeed(speedMBps) {
		if (speedMBps < 0.01)
			return "0.00 MB/s";
		if (speedMBps < 1)
			return (speedMBps * 1024).toFixed(2) + " KB/s";
		return speedMBps.toFixed(2) + " MB/s";
	}

	function formatUsage(usageMB) {
		if (usageMB < 1024)
			return usageMB.toFixed(2) + " MB";
		return (usageMB / 1024).toFixed(2) + " GB";
	}

	FileView {
		id: meminfo

		path: "/proc/meminfo"
		onLoaded: {
			const data = text();
			const memTotalMatch = data.match(/MemTotal:\s+(\d+)/);
			const memAvailableMatch = data.match(/MemAvailable:\s+(\d+)/);
			if (memTotalMatch && memAvailableMatch) {
				root.memTotal = parseInt(memTotalMatch[1], 10);
				root.memUsed = root.memTotal - parseInt(memAvailableMatch[1], 10);
			}
		}
	}

	// Thx caelestia
	Process {
		id: diskinfo

		command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
		stdout: StdioCollector {
			onStreamFinished: {
				const deviceMap = new Map();

				for (const line of text.trim().split("\n")) {
					if (line.trim() === "")
						continue;

					const parts = line.trim().split(/\s+/);
					if (parts.length >= 3) {
						const device = parts[0];
						const used = parseInt(parts[1], 10) || 0;
						const avail = parseInt(parts[2], 10) || 0;

						// Only keep the entry with the largest total space for each device
						if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
							deviceMap.set(device, {
								used: used,
								avail: avail
							});
						}
					}
				}

				let totalUsed = 0;
				let totalAvail = 0;

				for (const [device, stats] of deviceMap) {
					totalUsed += stats.used;
					totalAvail += stats.avail;
				}

				root.diskUsed = totalUsed;
				root.diskTotal = totalUsed + totalAvail;
			}
		}
	}

	FileView {
		id: stat

		path: "/proc/stat"
		onLoaded: {
			const data = text();
			const match = data.match(/^cpu\s+(\d+)(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?(?:\s+(\d+))?/m);

			if (match) {
				const stats = match.slice(1).filter(val => val !== undefined).map(n => parseInt(n, 10));

				if (stats.length >= 4) {
					const total = stats.reduce((a, b) => a + b, 0);
					const idle = stats[3] + (stats[4] || 0);

					if (!root.initialized) {
						root.lastCpuTotal = total;
						root.lastCpuIdle = idle;
						root.initialized = true;
					} else {
						const totalDiff = total - root.lastCpuTotal;
						const idleDiff = idle - root.lastCpuIdle;

						if (totalDiff > 0) {
							const cpuUsage = Math.max(0, Math.min(1, (totalDiff - idleDiff) / totalDiff));
							root.cpuPerc = Math.round(cpuUsage * 100);
						}

						root.lastCpuTotal = total;
						root.lastCpuIdle = idle;
					}
				}
			}
		}
	}

	Timer {
		running: true
		interval: 1000
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			stat.reload();
			meminfo.reload();
			networkInfo.reload();
			diskinfo.running = true;
			networkWiredInterfacesState.running = true;
			networkWirelessInterfacesState.running = true;
		}
	}
}
