import QtQuick
import Quickshell
import Vast

import qs.Core.Configs
import qs.Core.Utils

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

    function load(url) {
        if (url === "" || url === _active().source)
            return;
        if (_busy) {
            _pendingUrl = url;
            _hasPending = true;
            return;
        }
        _startTransition(url);
    }

    function _startTransition(url) {
        _typeResolved = _resolveType();

        if (Configs.wallpaper.transition === "none" || _typeResolved === -1) {
            _inactive().source = url;
            _slot = 1 - _slot;
            _inactive().source = "";
            return;
        }

        const name = _shaderNames[_typeResolved] ?? "fade";
        fx.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        if (_slot === 0) {
            fx.source1 = imgA;
            fx.source2 = imgB;
        } else {
            fx.source1 = imgB;
            fx.source2 = imgA;
        }

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
        fx.progress = 0.0;
        if (Window.window)
            Window.window.requestActivate();
        anim.restart();
    }

    function _commitTransition() {
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

    function _drainPending() {
        if (_hasPending) {
            const url = _pendingUrl;
            _hasPending = false;
            _pendingUrl = "";
            _startTransition(url);
        }
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

        imgA.source = Paths.currentWallpaper;
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

    // Wallpaper change signal
    Connections {
        target: Paths

        function onCurrentWallpaperChanged() {
            root.load((Paths.currentWallpaper));
        }
    }
}
