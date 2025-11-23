pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int memTotal: 0
    property int memUsed: 0
    property int diskUsed: 0
    property int diskTotal: 0

    readonly property real diskProp: diskUsed / 1048576
    readonly property real memProp: memUsed / 1048576
    readonly property real diskPercent: diskTotal > 0 ? (diskUsed / diskTotal) * 100 : 0
    readonly property real memPercent: memTotal > 0 ? (memUsed / memTotal) * 100 : 0

    property string wiredInterface: ""
    property string wirelessInterface: ""
    property string statusWiredInterface: ""
    property string statusVPNInterface: ""

    property double wirelessUploadSpeed: 0
    property double wirelessDownloadSpeed: 0
    property double totalWirelessDownloadUsage: 0
    property double totalWirelessUploadUsage: 0

    property double wiredUploadSpeed: 0
    property double wiredDownloadSpeed: 0
    property double totalWiredDownloadUsage: 0
    property double totalWiredUploadUsage: 0

    property int cpuPerc: 0

    property int gpuUsage: 0
    property int vramUsed: 0
    property string gpuPower: "0.00"
    property int gpuFreqActual: 0
    property int gpuFreqRequested: 0
    property string gpuRc6: "0.0"
    property int gpuMemBandwidthRead: 0
    property int gpuMemBandwidthWrite: 0

    readonly property string gpuPowerText: gpuPower + " W"
    readonly property string gpuFreqText: gpuFreqActual + " MHz"
    readonly property string gpuRc6Text: gpuRc6 + "%"
	readonly property string gpuBandwidthText: `R: ${gpuMemBandwidthRead} MiB/s W: ${gpuMemBandwidthWrite} MiB/s`

    property var previousData: null
    property double lastUpdateTime: 0
    property int lastCpuIdle: 0
    property int lastCpuTotal: 0
    property bool initialized: false

    FileView {
        id: netDevFileView

        path: "/proc/net/dev"
        onLoaded: root.calculateNetworkStats(text())
    }

    Process {
        id: networkInfoProc

        command: ["sh", "-c", `
            nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '
            /ethernet/ && !eth_found {
                print "WIRED_DEV:" $1;
                print "WIRED_STATE:" $3;
                eth_found=1
            }
            /wifi/ && !wifi_found {
                print "WIFI_DEV:" $1;
                wifi_found=1
            }
            /^(wg0|CloudflareWARP):/ {
                print "VPN_DEV:" $1
            }
            '
            `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                for (const line of lines) {
                    if (line.startsWith("WIRED_DEV:"))
                        root.wiredInterface = line.substring(10).trim();
                    else if (line.startsWith("WIRED_STATE:"))
                        root.statusWiredInterface = line.substring(12).replace(" (externally)", "").trim();
                    else if (line.startsWith("WIFI_DEV:"))
                        root.wirelessInterface = line.substring(9).trim();
                    else if (line.startsWith("VPN_DEV:"))
                        root.statusVPNInterface = line.substring(8).trim();
                }
            }
        }
    }

    Process {
        id: intelGpuProc

        command: ["sh", "-c", "timeout 1 intel_gpu_top -J -s 500"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const jsonText = text.trim();
                    const cleanedJson = jsonText.endsWith(',') ? jsonText.slice(0, -1) + ']' : jsonText + ']';
                    const dataArray = JSON.parse(cleanedJson);

                    // Get the last sample (most recent data)
                    if (dataArray.length === 0)
                        return;
                    const data = dataArray[dataArray.length - 1];

                    // Get GPU usage from render/3d engine
                    if (data.engines && data.engines["Render/3D"])
                        root.gpuUsage = Math.round(data.engines["Render/3D"].busy || 0);

                    // Get power consumption
                    if (data.power && data.power.GPU)
                        root.gpuPower = data.power.GPU.toFixed(2);

                    let totalVramUsed = 0;
                    if (data.clients)
                        for (const clientId in data.clients) {
                            const client = data.clients[clientId];
                            if (client.memory && client.memory.system)
                                totalVramUsed += parseInt(client.memory.system.resident) || 0;
                        }

                    // Convert bytes to MB
                    root.vramUsed = Math.round(totalVramUsed / 1048576);

                    // Get frequency info
                    if (data.frequency) {
                        root.gpuFreqActual = Math.round(data.frequency.actual || 0);
                        root.gpuFreqRequested = Math.round(data.frequency.requested || 0);
                    }

                    // RC6 (power saving state)
                    if (data.rc6)
                        root.gpuRc6 = data.rc6.value.toFixed(1);

                    // Get memory bandwidth
                    if (data["imc-bandwidth"]) {
                        root.gpuMemBandwidthRead = Math.round(data["imc-bandwidth"].reads || 0);
                        root.gpuMemBandwidthWrite = Math.round(data["imc-bandwidth"].writes || 0);
                    }
                } catch (e) {
                    console.log("Failed to parse intel_gpu_top output:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    console.log("intel_gpu_top error:", text.trim());
                }
            }
        }
    }

    // Fallback
    Process {
        id: intelGpuSysfsProc

        command: ["sh", "-c", `
            cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo "0"
            cat /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || echo "1"

            cat /sys/kernel/debug/dri/0/i915_gem_objects 2>/dev/null | awk '/bytes total/ {print $1}'
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                if (lines.length >= 3) {
                    const curFreq = parseInt(lines[0]) || 0;
                    const maxFreq = parseInt(lines[1]) || 1;
                    const vramBytes = parseInt(lines[2]) || 0;

                    // Estimate usage from frequency
                    root.gpuUsage = Math.round((curFreq / maxFreq) * 100);

                    if (vramBytes > 0)
                        root.vramUsed = Math.round(vramBytes / 1048576);
                }
            }
        }
    }

    function parseNetworkData(data) {
        const lines = data.split('\n');
        const interfaces = {};

        for (var i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;
            const parts = line.split(/\s+/);
            if (parts.length < 17)
                continue;
            const ifaceName = parts[0].replace(':', '');

            if (ifaceName !== root.wirelessInterface && ifaceName !== root.wiredInterface)
                continue;

            interfaces[ifaceName] = {
                "rxBytes": parseInt(parts[1]) || 0,
                "txBytes": parseInt(parts[9]) || 0
            };
        }

        return interfaces;
    }

    function calculateNetworkStats(data) {
        const currentTime = Date.now();
        const currentData = parseNetworkData(data);

        const wirelessData = currentData[wirelessInterface];
        const wiredData = currentData[wiredInterface];

        if (wirelessData) {
            totalWirelessDownloadUsage = wirelessData.rxBytes / 1048576;
            totalWirelessUploadUsage = wirelessData.txBytes / 1048576;
        }

        if (wiredData) {
            totalWiredDownloadUsage = wiredData.rxBytes / 1048576;
            totalWiredUploadUsage = wiredData.txBytes / 1048576;
        }

        if (previousData && lastUpdateTime > 0) {
            const timeDiffSec = (currentTime - lastUpdateTime) / 1000;

            if (timeDiffSec > 0.1) {
                const prevWireless = previousData[wirelessInterface];
                const prevWired = previousData[wiredInterface];

                if (wirelessData && prevWireless) {
                    const rxDiff = wirelessData.rxBytes - prevWireless.rxBytes;
                    const txDiff = wirelessData.txBytes - prevWireless.txBytes;

                    wirelessDownloadSpeed = Math.max(0, rxDiff / 1048576 / timeDiffSec);
                    wirelessUploadSpeed = Math.max(0, txDiff / 1048576 / timeDiffSec);
                }

                if (wiredData && prevWired) {
                    const rxDiff = wiredData.rxBytes - prevWired.rxBytes;
                    const txDiff = wiredData.txBytes - prevWired.txBytes;

                    wiredDownloadSpeed = Math.max(0, rxDiff / 1048576 / timeDiffSec);
                    wiredUploadSpeed = Math.max(0, txDiff / 1048576 / timeDiffSec);
                }
            }
        }

        previousData = currentData;
        lastUpdateTime = currentTime;
    }

    readonly property var speedThresholds: [
        {
            "limit": 0.01,
            "format": () => "0.00 MB/s"
        },
        {
            "limit": 1,
            "format": s => (s * 1024).toFixed(2) + " KB/s"
        },
        {
            "limit": Infinity,
            "format": s => s.toFixed(2) + " MB/s"
        }
    ]

    function formatSpeed(speedMBps) {
        for (const threshold of speedThresholds)
            if (speedMBps < threshold.limit)
                return threshold.format(speedMBps);
    }

    function formatUsage(usageMB) {
        return usageMB < 1024 ? usageMB.toFixed(2) + " MB" : (usageMB / 1024).toFixed(2) + " GB";
    }

    FileView {
        id: meminfoFileView

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const memMatch = data.match(/MemTotal:\s+(\d+)[\s\S]*?MemAvailable:\s+(\d+)/);
            if (memMatch) {
                root.memTotal = parseInt(memMatch[1], 10);
                root.memUsed = root.memTotal - parseInt(memMatch[2], 10);
            }
        }
    }

    Process {
        id: diskDfProc

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

                        if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                            deviceMap.set(device, {
                                "used": used,
                                "avail": avail
                            });
                        }
                    }
                }

                let totalUsed = 0;
                let totalAvail = 0;

                for (const stats of deviceMap.values()) {
                    totalUsed += stats.used;
                    totalAvail += stats.avail;
                }

                root.diskUsed = totalUsed;
                root.diskTotal = totalUsed + totalAvail;
            }
        }
    }

    FileView {
        id: cpuStatFileView

        path: "/proc/stat"
        onLoaded: {
            const data = text();
            const match = data.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/m);

            if (!match)
                return;

            const user = parseInt(match[1], 10);
            const nice = parseInt(match[2], 10);
            const system = parseInt(match[3], 10);
            const idle = parseInt(match[4], 10);
            const iowait = parseInt(match[5], 10) || 0;

            const total = user + nice + system + idle + iowait;
            const idleTotal = idle + iowait;

            if (!root.initialized) {
                root.lastCpuTotal = total;
                root.lastCpuIdle = idleTotal;
                root.initialized = true;
                return;
            }

            const totalDiff = total - root.lastCpuTotal;
            const idleDiff = idleTotal - root.lastCpuIdle;

            if (totalDiff > 0) {
                const usage = (totalDiff - idleDiff) / totalDiff;
                root.cpuPerc = Math.round(Math.max(0, Math.min(1, usage)) * 100);
            }

            root.lastCpuTotal = total;
            root.lastCpuIdle = idleTotal;
        }
    }

    Timer {
        id: mainTimer

        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true

        property int updateCycle: 0

        onTriggered: {
            cpuStatFileView.reload();
            meminfoFileView.reload();
            netDevFileView.reload();

            updateCycle = (updateCycle + 1) % 4;

            switch (updateCycle) {
            case 0:
                networkInfoProc.running = true;
                break;
            case 1:
                diskDfProc.running = true;
                break;
            case 2:
                intelGpuProc.running = true;
                break;
            case 3:
                intelGpuSysfsProc.running = true;
                break;
            }
        }
    }

    Component.onDestruction: {
        previousData = null;
    }
}
