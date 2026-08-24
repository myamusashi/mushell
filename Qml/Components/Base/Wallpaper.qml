import QtQuick
import QtMultimedia
import Vast.ImageCache

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

// Transition type:
//   "none"     – instant swap, no GPU shader
//   "random"   – random type picked fresh for every transition
//   "fade"     – 0   cross-dissolve
//   "wipeDown" – 1   top-to-bottom soft wipe
//   "circle"   – 2   circle expands from centre
//   "dissolve" – 3   per-pixel noise dissolve
//   "splitH"   – 4   horizontal split from centre
//   "slideUp"  – 5   old image slides upward
//   "pixelate" – 6   pixelation blur peak at mid
//   "diagonal" – 7   diagonal band top-left → bottom-right
//   "box"      – 8   rectangle expands from centre
//   "roll"     – 9   page-roll from right edge
//   "hexTile"  - 10  hex tile from right edge too top left edge

Item {
    id: root

    readonly property string effectiveSource: GlobalStates.previewWallpaper !== "" ? GlobalStates.previewWallpaper : Paths.currentWallpaper

    readonly property var _shaderNames: ["fade", "wipeDown", "circleExpand", "dissolve", "splitHorizontal", "slideUp", "pixelate", "diagonalWipe", "boxExpand", "roll", "hexTile"]
    readonly property var _typeMap: ({
            "fade": 0,
            "wipeDown": 1,
            "circle": 2,
            "dissolve": 3,
            "splitH": 4,
            "slideUp": 5,
            "pixelate": 6,
            "diagonal": 7,
            "box": 8,
            "roll": 9,
            "hexTile": 10
        })

    // Which slot is the "active" (currently shown)
    // 0 = imgA, 1 = imgB
    property int _slot: 0
    property bool _busy: false
    property int _typeResolved: 0
    property url _pendingUrl: ""
    property bool _hasPending: false
    property var _toImg: null
    property bool _isVideoWallpaper: false
    property bool _targetVideo: false
    property int _videoSlot: 0
    property var _toVideo: null
    property bool _sourceVideo: false
    property bool _transitionStarted: false
    readonly property bool _pauseVideo: {
        const toplevels = Hypr.focusedWorkspace?.toplevels?.values ?? [];
        return toplevels.some(toplevel => toplevel.wayland?.activated && (toplevel.wayland?.fullscreen || !toplevel.lastIpcObject?.floating) && !GlobalStates.isLockscreenOpen);
    }

    function isVideo(url) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(url.toString());
    }

    function updateVideoPlayback() {
        if (_pauseVideo) {
            videoPlayerA.pause();
            videoPlayerB.pause();
        } else {
            if (videoPlayerA.source !== "")
                videoPlayerA.play();
            if (videoPlayerB.source !== "")
                videoPlayerB.play();
        }
    }

    function playVideo(player) {
        if (_pauseVideo)
            player.pause();
        else
            player.play();
    }

    on_PauseVideoChanged: updateVideoPlayback()

    // Returns -1 when lowPerfMode is on; _startTransition intercepts it.
    function _resolveType() {
        if (Configs.wallpaper.transitionLowPerfMode)
            return -1;
        const t = Configs.wallpaper.transition;
        if (t === "random")
            return Math.floor(Math.random() * 10);
        const v = _typeMap[t];
        return (v !== undefined) ? v : 0;
    }

    function _active() {
        return _slot === 0 ? imgA : imgB;
    }
    function _inactive() {
        return _slot === 0 ? imgB : imgA;
    }

    function _activeVideoOutput() {
        return _videoSlot === 0 ? videoOutputA : videoOutputB;
    }

    function _inactiveVideoPlayer() {
        return _videoSlot === 0 ? videoPlayerB : videoPlayerA;
    }

    function _inactiveVideoOutput() {
        return _videoSlot === 0 ? videoOutputB : videoOutputA;
    }

    function load(url) {
        if (isVideo(url)) {
            if (_isVideoWallpaper)
                _startVideoTransition(url);
            else {
                videoPlayerA.source = Qt.resolvedUrl(url);
                playVideo(videoPlayerA);
                _isVideoWallpaper = true;
            }
            return;
        }

        if (_isVideoWallpaper && url === "") {
            videoPlayerA.stop();
            videoPlayerA.source = "";
            videoPlayerB.stop();
            videoPlayerB.source = "";
            _isVideoWallpaper = false;
            _sourceVideo = false;
            _targetVideo = false;
            _toVideo = null;
            _busy = false;
            anim.stop();
            return;
        }

        if (url === "" || url === _active().source)
            return;
        if (_busy) {
            _pendingUrl = url;
            _hasPending = true;
            return;
        }
        _startTransition(url);
    }

    function _startVideoTransition(url) {
        if (_busy) {
            _pendingUrl = url;
            _hasPending = true;
            return;
        }

        _typeResolved = _resolveType();
        if (Configs.wallpaper.transition === "none" || _typeResolved === -1) {
            videoPlayerA.stop();
            videoPlayerB.stop();
            videoPlayerA.source = "";
            videoPlayerB.source = "";
            const player = _inactiveVideoPlayer();
            player.source = Qt.resolvedUrl(url);
            playVideo(player);
            _videoSlot = 1 - _videoSlot;
            return;
        }

        const name = _shaderNames[_typeResolved] ?? "fade";
        fx.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        fx.source1 = _isVideoWallpaper ? _activeVideoOutput() : _active();
        fx.source2 = _inactiveVideoOutput();
        videoOutputA.layer.enabled = true;
        videoOutputB.layer.enabled = true;

        _targetVideo = true;
        _busy = true;
        _transitionStarted = false;

        const player = _inactiveVideoPlayer();
        _toVideo = player;
        player.source = Qt.resolvedUrl(url);
        playVideo(player);
    }

    function _startTransition(url) {
        _typeResolved = _resolveType();
        _sourceVideo = _isVideoWallpaper;

        if (Configs.wallpaper.transition === "none" || _typeResolved === -1) {
            if (_sourceVideo) {
                videoPlayerA.stop();
                videoPlayerA.source = "";
                videoPlayerB.stop();
                videoPlayerB.source = "";
                _isVideoWallpaper = false;
                _sourceVideo = false;
            }
            _inactive().source = url;
            _slot = 1 - _slot;
            _inactive().source = "";
            return;
        }

        const name = _shaderNames[_typeResolved] ?? "fade";
        fx.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        if (_sourceVideo) {
            fx.source1 = _activeVideoOutput();
            fx.source2 = _inactive();
            _activeVideoOutput().layer.enabled = true;
        } else if (_slot === 0) {
            fx.source1 = imgA;
            fx.source2 = imgB;
        } else {
            fx.source1 = imgB;
            fx.source2 = imgA;
        }

        _targetVideo = false;
        _transitionStarted = false;
        _toImg = _inactive();
        _busy = true;
        _toImg.source = url;

        if (_toImg.status === Image.Ready) {
            _beginAnim();
        } else if (_toImg.status === Image.Error) {
            console.warn("[Wallpaper] Immediate error loading:", url);
            _busy = false;
            _toImg = null;
        }
    }

    function _onImgStatus(img) {
        if (!_busy || img !== _toImg)
            return;
        if (img.status === Image.Ready) {
            _beginAnim();
        } else if (img.status === Image.Error) {
            console.warn("[Wallpaper] Failed to load:", img.source);
            img.source = "";
            _busy = false;
            _toImg = null;
            _drainPending();
        }
    }

    function _beginAnim() {
        if (_transitionStarted)
            return;
        _transitionStarted = true;
        fx.progress = 0.0;
        if (Window.window)
            Window.window.requestActivate();
        anim.restart();
    }

    function _commitTransition() {
        if (!_busy)
            return;
        if (_targetVideo) {
            const oldPlayer = _videoSlot === 0 ? videoPlayerA : videoPlayerB;
            oldPlayer.stop();
            oldPlayer.source = "";
            _videoSlot = 1 - _videoSlot;
            videoOutputA.layer.enabled = false;
            videoOutputB.layer.enabled = false;
            _isVideoWallpaper = true;
            _busy = false;
            fx.progress = 0.0;
            _toVideo = null;
            _drainPending();
            return;
        }

        if (_sourceVideo) {
            videoPlayerA.stop();
            videoPlayerA.source = "";
            videoPlayerB.stop();
            videoPlayerB.source = "";
            _isVideoWallpaper = false;
            _sourceVideo = false;
            videoOutputA.layer.enabled = false;
            videoOutputB.layer.enabled = false;
        }

        const newSlot = 1 - _slot;
        const oldImg = (newSlot === 0) ? imgB : imgA;
        const oldPath = oldImg.source.toString().replace("file://", "");

        _busy = false;
        _slot = newSlot;
        oldImg.source = "";
        fx.progress = 0.0;
        _toImg = null;

        ImageCache.evict(oldPath);

        _drainPending();
    }

    function _maybeBeginVideoTransition() {
        if (_toVideo === null)
            return;
        if (_toVideo.mediaStatus !== MediaPlayer.LoadedMedia && _toVideo.mediaStatus !== MediaPlayer.BufferedMedia)
            return;
        _beginAnim();
    }

    function _drainPending() {
        if (_hasPending) {
            const url = _pendingUrl;
            _hasPending = false;
            _pendingUrl = "";
            if (isVideo(url))
                _startVideoTransition(url);
            else
                _startTransition(url);
        }
    }

    function _onVideoError(player) {
        if (!_busy || _transitionStarted || _toVideo !== player)
            return;
        player.stop();
        player.source = "";
        _toVideo = null;
        _targetVideo = false;
        _busy = false;
        videoOutputA.layer.enabled = false;
        videoOutputB.layer.enabled = false;
    }

    // Resolution helper (call whenever viewport resizes and shader is idle)
    function _updateResolution() {
        if (!_busy) {
            const w = root.width;
            const h = root.height;
            fx.resolution = Qt.vector2d(w, h);
            fx.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);
        }
    }

    Component.onCompleted: {
        imgA.sourceSize = Qt.size(root.width, root.height);
        imgB.sourceSize = Qt.size(root.width, root.height);

        const w = root.width;
        const h = root.height;
        fx.resolution = Qt.vector2d(w, h);
        fx.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);

        if (root.isVideo(root.effectiveSource)) {
            videoPlayerA.source = Qt.resolvedUrl(root.effectiveSource);
            playVideo(videoPlayerA);
            _isVideoWallpaper = true;
        } else {
            imgA.source = root.effectiveSource;
        }
    }

    MediaPlayer {
        id: videoPlayerA

        loops: MediaPlayer.Infinite
        videoOutput: videoOutputA
        onErrorOccurred: (error, errorString) => {
            console.warn("[Wallpaper] Video error:", errorString);
            root._onVideoError(videoPlayerA);
        }
    }

    Connections {
        target: videoPlayerA

        function onMediaStatusChanged() {
            root._maybeBeginVideoTransition();
        }
    }

    VideoOutput {
        id: videoOutputA

        anchors.fill: parent
        z: 1
        fillMode: VideoOutput.PreserveAspectCrop
        visible: videoPlayerA.source !== ""
    }

    MediaPlayer {
        id: videoPlayerB

        loops: MediaPlayer.Infinite
        videoOutput: videoOutputB
        onErrorOccurred: (error, errorString) => {
            console.warn("[Wallpaper] Video error:", errorString);
            root._onVideoError(videoPlayerB);
        }
    }

    Connections {
        target: videoPlayerB

        function onMediaStatusChanged() {
            root._maybeBeginVideoTransition();
        }
    }

    VideoOutput {
        id: videoOutputB

        anchors.fill: parent
        z: 1
        fillMode: VideoOutput.PreserveAspectCrop
        visible: videoPlayerB.source !== ""
    }

    Image {
        id: imgA

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        visible: !root._busy && root._slot === 0
        onStatusChanged: root._onImgStatus(imgA)
    }

    Image {
        id: imgB

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        visible: !root._busy && root._slot === 1
        onStatusChanged: root._onImgStatus(imgB)
    }

    ShaderEffect {
        id: fx

        anchors.fill: parent
        z: 2

        property var source1: imgA
        property var source2: imgB

        property real progress: 0.0
        property real smoothAmount: 0.05
        property real aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d resolution: Qt.vector2d(720, 720)
        property vector2d invResolution: Qt.vector2d(1.0 / 720, 1.0 / 720.0)

        vertexShader: Paths.projectRoot + "/Assets/shaders/ImageTransition.vert.qsb"
        fragmentShader: Paths.projectRoot + "/Assets/shaders/transitions/fade.frag.qsb"
        visible: root._busy
        blending: false
        layer.enabled: false
    }

    NumberAnimation {
        id: anim

        target: fx
        property: "progress"
        from: 0.0
        to: 1.0
        duration: Configs.wallpaper.transitionDuration
        easing.type: Easing.Linear
        onStopped: root._commitTransition()
    }

    onEffectiveSourceChanged: root.load(root.effectiveSource)
}
