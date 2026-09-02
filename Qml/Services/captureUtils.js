.pragma library

let tempCaptureCounter = 0;

function pad(n) {
    return String(n).padStart(2, "0");
}

function generateTimestamp() {
    const d = new Date();
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
}

function screenshotPath(screenshotDir) {
    return screenshotDir + "/" + generateTimestamp() + ".png";
}

function tempCapturePath() {
    tempCaptureCounter = (tempCaptureCounter + 1) % 1000000;
    return "/tmp/quickshell-capture-" + Date.now() + "-" + tempCaptureCounter + "-" + Math.floor(Math.random() * 100000) + ".png";
}

function videoPath(videoDir) {
    return videoDir + "/" + generateTimestamp() + ".mp4";
}

function intersectRect(a, b) {
    var x = Math.max(a.x, b.x);
    var y = Math.max(a.y, b.y);
    var x2 = Math.min(a.x + a.width, b.x + b.width);
    var y2 = Math.min(a.y + a.height, b.y + b.height);
    if (x2 <= x || y2 <= y) return null;
    return { x: x, y: y, width: x2 - x, height: y2 - y };
}

function totalBounds(screens) {
    var minX = Infinity, minY = Infinity;
    var maxX = -Infinity, maxY = -Infinity;
    for (var i = 0; i < screens.length; i++) {
        var s = screens[i];
        if (s.x < minX) minX = s.x;
        if (s.y < minY) minY = s.y;
        var right = s.x + s.width;
        var bottom = s.y + s.height;
        if (right > maxX) maxX = right;
        if (bottom > maxY) maxY = bottom;
    }
    if (minX === Infinity)
        return { x: 0, y: 0, width: 0, height: 0 };
    // Origin of the virtual desktop bounding box — screens left of / above the
    // primary output produce negative coordinates that callers must normalize by.
    return { x: minX, y: minY, width: maxX - minX, height: maxY - minY };
}

function buildWlScreenrecArgs(cfg, geometry, output, toplevelFilter) {
    const args = ["wl-screenrec", "--capture-backend", "ext-image-copy-capture"];
    if (cfg.videoCodec && cfg.videoCodec !== "auto")
        args.push("--codec", cfg.videoCodec);
    if (cfg.audioCodec && cfg.audioCodec !== "auto")
        args.push("--audio-codec", cfg.audioCodec);
    if (cfg.encodeResolution)
        args.push("--encode-resolution", cfg.encodeResolution);
    if (cfg.driDevice)
        args.push("--dri-device", cfg.driDevice);
    if (cfg.lowPower && cfg.lowPower !== "auto")
        args.push("--low-power", cfg.lowPower);
    args.push("--max-fps", String(cfg.maxFps));
    args.push("--bitrate", cfg.bitrate);
    if (!cfg.showCursor)
        args.push("--no-cursor");
    if (cfg.historyMode)
        args.push("--history", "30");
    if (cfg.includeAudio) {
        args.push("--audio");
        if (cfg.audioDevice)
            args.push("--audio-device", cfg.audioDevice);
    }
    if (toplevelFilter)
        args.push("--toplevel", toplevelFilter);
    else if (geometry)
        args.push("-g", geometry);
    else if (output)
        args.push("-o", output);
    return args;
}
