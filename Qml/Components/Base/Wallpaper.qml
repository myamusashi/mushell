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

    readonly property var transitionShaderNames: ["fade", "wipeDown", "circleExpand", "dissolve", "splitHorizontal", "slideUp", "pixelate", "diagonalWipe", "boxExpand", "roll", "hexTile"]
    readonly property var transitionTypeMap: ({
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
    // 0 = imageA, 1 = imageB
    property int activeImageSlot: 0
    property bool transitionBusy: false
    property int resolvedTransitionType: 0
    property url pendingUrl: ""
    property bool hasPendingUrl: false
    property var incomingImage: null
    property bool isVideoWallpaper: false
    property bool targetIsVideo: false
    property int activeVideoSlot: 0
    property var incomingPlayer: null
    property bool sourceIsVideo: false
    property bool transitionStarted: false
    readonly property bool pauseVideo: {
        const toplevels = Hypr.focusedWorkspace?.toplevels?.values ?? [];
        return toplevels.some(toplevel => toplevel.wayland?.activated && (toplevel.wayland?.fullscreen || !toplevel.lastIpcObject?.floating) && !GlobalStates.isLockscreenOpen);
    }

    function isVideo(url) {
        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(url.toString());
    }

    function updateVideoPlayback() {
        if (pauseVideo) {
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
        if (pauseVideo)
            player.pause();
        else
            player.play();
    }

    onPauseVideoChanged: updateVideoPlayback()

    // Returns -1 when lowPerfMode is on; startImageTransition intercepts it.
    function resolveTransitionType() {
        if (Configs.wallpaper.transitionLowPerfMode)
            return -1;
        const t = Configs.wallpaper.transition;
        if (t === "random")
            return Math.floor(Math.random() * 10);
        const v = transitionTypeMap[t];
        return (v !== undefined) ? v : 0;
    }

    function activeImage() {
        return activeImageSlot === 0 ? imageA : imageB;
    }
    function inactiveImage() {
        return activeImageSlot === 0 ? imageB : imageA;
    }

    function activeVideoOutput() {
        return activeVideoSlot === 0 ? videoOutputA : videoOutputB;
    }

    function inactiveVideoPlayer() {
        return activeVideoSlot === 0 ? videoPlayerB : videoPlayerA;
    }

    function inactiveVideoOutput() {
        return activeVideoSlot === 0 ? videoOutputB : videoOutputA;
    }

    function load(url) {
        if (isVideo(url)) {
            if (isVideoWallpaper)
                startVideoTransition(url);
            else {
                videoPlayerA.source = Qt.resolvedUrl(url);
                playVideo(videoPlayerA);
                isVideoWallpaper = true;
            }
            return;
        }

        if (isVideoWallpaper && url === "") {
            videoPlayerA.stop();
            videoPlayerA.source = "";
            videoPlayerB.stop();
            videoPlayerB.source = "";
            isVideoWallpaper = false;
            sourceIsVideo = false;
            targetIsVideo = false;
            incomingPlayer = null;
            transitionBusy = false;
            progressAnimation.stop();
            return;
        }

        if (url === "" || url === activeImage().source)
            return;
        if (transitionBusy) {
            pendingUrl = url;
            hasPendingUrl = true;
            return;
        }
        startImageTransition(url);
    }

    function startVideoTransition(url) {
        if (transitionBusy) {
            pendingUrl = url;
            hasPendingUrl = true;
            return;
        }

        resolvedTransitionType = resolveTransitionType();
        if (Configs.wallpaper.transition === "none" || resolvedTransitionType === -1) {
            videoPlayerA.stop();
            videoPlayerB.stop();
            videoPlayerA.source = "";
            videoPlayerB.source = "";
            const player = inactiveVideoPlayer();
            player.source = Qt.resolvedUrl(url);
            playVideo(player);
            activeVideoSlot = 1 - activeVideoSlot;
            return;
        }

        const name = transitionShaderNames[resolvedTransitionType] ?? "fade";
        transitionEffect.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        transitionEffect.source1 = isVideoWallpaper ? activeVideoOutput() : activeImage();
        transitionEffect.source2 = inactiveVideoOutput();
        videoOutputA.layer.enabled = true;
        videoOutputB.layer.enabled = true;

        targetIsVideo = true;
        transitionBusy = true;
        transitionStarted = false;

        const player = inactiveVideoPlayer();
        incomingPlayer = player;
        player.source = Qt.resolvedUrl(url);
        playVideo(player);
    }

    function startImageTransition(url) {
        resolvedTransitionType = resolveTransitionType();
        sourceIsVideo = isVideoWallpaper;

        if (Configs.wallpaper.transition === "none" || resolvedTransitionType === -1) {
            if (sourceIsVideo) {
                videoPlayerA.stop();
                videoPlayerA.source = "";
                videoPlayerB.stop();
                videoPlayerB.source = "";
                isVideoWallpaper = false;
                sourceIsVideo = false;
            }
            inactiveImage().source = url;
            activeImageSlot = 1 - activeImageSlot;
            inactiveImage().source = "";
            return;
        }

        const name = transitionShaderNames[resolvedTransitionType] ?? "fade";
        transitionEffect.fragmentShader = `${Paths.projectRoot}/Assets/shaders/transitions/${name}.frag.qsb`;

        if (sourceIsVideo) {
            transitionEffect.source1 = activeVideoOutput();
            transitionEffect.source2 = inactiveImage();
            activeVideoOutput().layer.enabled = true;
        } else if (activeImageSlot === 0) {
            transitionEffect.source1 = imageA;
            transitionEffect.source2 = imageB;
        } else {
            transitionEffect.source1 = imageB;
            transitionEffect.source2 = imageA;
        }

        targetIsVideo = false;
        transitionStarted = false;
        incomingImage = inactiveImage();
        transitionBusy = true;
        incomingImage.source = url;

        if (incomingImage.status === Image.Ready) {
            beginTransition();
        } else if (incomingImage.status === Image.Error) {
            console.warn("[Wallpaper] Immediate error loading:", url);
            transitionBusy = false;
            incomingImage = null;
        }
    }

    function handleImageStatus(img) {
        if (!transitionBusy || img !== incomingImage)
            return;
        if (img.status === Image.Ready) {
            beginTransition();
        } else if (img.status === Image.Error) {
            console.warn("[Wallpaper] Failed to load:", img.source);
            img.source = "";
            transitionBusy = false;
            incomingImage = null;
            loadPendingUrl();
        }
    }

    function beginTransition() {
        if (transitionStarted)
            return;
        transitionStarted = true;
        transitionEffect.progress = 0.0;
        if (Window.window)
            Window.window.requestActivate();
        progressAnimation.restart();
    }

    function commitTransition() {
        if (!transitionBusy)
            return;
        if (targetIsVideo) {
            const oldPlayer = activeVideoSlot === 0 ? videoPlayerA : videoPlayerB;
            oldPlayer.stop();
            oldPlayer.source = "";
            activeVideoSlot = 1 - activeVideoSlot;
            videoOutputA.layer.enabled = false;
            videoOutputB.layer.enabled = false;
            isVideoWallpaper = true;
            transitionBusy = false;
            transitionEffect.progress = 0.0;
            incomingPlayer = null;
            loadPendingUrl();
            return;
        }

        if (sourceIsVideo) {
            videoPlayerA.stop();
            videoPlayerA.source = "";
            videoPlayerB.stop();
            videoPlayerB.source = "";
            isVideoWallpaper = false;
            sourceIsVideo = false;
            videoOutputA.layer.enabled = false;
            videoOutputB.layer.enabled = false;
        }

        const newSlot = 1 - activeImageSlot;
        const oldImg = (newSlot === 0) ? imageB : imageA;
        const oldPath = oldImg.source.toString().replace("file://", "");

        transitionBusy = false;
        activeImageSlot = newSlot;
        oldImg.source = "";
        transitionEffect.progress = 0.0;
        incomingImage = null;

        ImageCache.evict(oldPath);

        loadPendingUrl();
    }

    function tryBeginVideoTransition() {
        if (incomingPlayer === null)
            return;
        if (incomingPlayer.mediaStatus !== MediaPlayer.LoadedMedia && incomingPlayer.mediaStatus !== MediaPlayer.BufferedMedia)
            return;
        beginTransition();
    }

    function loadPendingUrl() {
        if (hasPendingUrl) {
            const url = pendingUrl;
            hasPendingUrl = false;
            pendingUrl = "";
            if (isVideo(url))
                startVideoTransition(url);
            else
                startImageTransition(url);
        }
    }

    function handleVideoError(player) {
        if (!transitionBusy || transitionStarted || incomingPlayer !== player)
            return;
        player.stop();
        player.source = "";
        incomingPlayer = null;
        targetIsVideo = false;
        transitionBusy = false;
        videoOutputA.layer.enabled = false;
        videoOutputB.layer.enabled = false;
    }

    // Resolution helper (call whenever viewport resizes and shader is idle)
    function updateResolution() {
        if (!transitionBusy) {
            const w = root.width;
            const h = root.height;
            transitionEffect.resolution = Qt.vector2d(w, h);
            transitionEffect.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);
        }
    }

    Component.onCompleted: {
        imageA.sourceSize = Qt.size(root.width, root.height);
        imageB.sourceSize = Qt.size(root.width, root.height);

        const w = root.width;
        const h = root.height;
        transitionEffect.resolution = Qt.vector2d(w, h);
        transitionEffect.invResolution = Qt.vector2d(1.0 / w, 1.0 / h);

        if (root.isVideo(root.effectiveSource)) {
            videoPlayerA.source = Qt.resolvedUrl(root.effectiveSource);
            playVideo(videoPlayerA);
            isVideoWallpaper = true;
        } else {
            imageA.source = root.effectiveSource;
        }
    }

    MediaPlayer {
        id: videoPlayerA

        loops: MediaPlayer.Infinite
        videoOutput: videoOutputA
        onErrorOccurred: (error, errorString) => {
            console.warn("[Wallpaper] Video error:", errorString);
            root.handleVideoError(videoPlayerA);
        }
    }

    Connections {
        target: videoPlayerA

        function onMediaStatusChanged() {
            root.tryBeginVideoTransition();
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
            root.handleVideoError(videoPlayerB);
        }
    }

    Connections {
        target: videoPlayerB

        function onMediaStatusChanged() {
            root.tryBeginVideoTransition();
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
        id: imageA

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        visible: !root.transitionBusy && root.activeImageSlot === 0
        onStatusChanged: root.handleImageStatus(imageA)
    }

    Image {
        id: imageB

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        visible: !root.transitionBusy && root.activeImageSlot === 1
        onStatusChanged: root.handleImageStatus(imageB)
    }

    ShaderEffect {
        id: transitionEffect

        anchors.fill: parent
        z: 2

        property var source1: imageA
        property var source2: imageB

        property real progress: 0.0
        property real smoothAmount: 0.05
        property real aspect: root.height > 0.0 ? root.height / root.width : 1.0
        property vector2d resolution: Qt.vector2d(720, 720)
        property vector2d invResolution: Qt.vector2d(1.0 / 720, 1.0 / 720.0)

        vertexShader: Paths.projectRoot + "/Assets/shaders/ImageTransition.vert.qsb"
        fragmentShader: Paths.projectRoot + "/Assets/shaders/transitions/fade.frag.qsb"
        visible: root.transitionBusy
        blending: false
        layer.enabled: false
    }

    NumberAnimation {
        id: progressAnimation

        target: transitionEffect
        property: "progress"
        from: 0.0
        to: 1.0
        duration: Configs.wallpaper.transitionDuration
        easing.type: Easing.Linear
        onStopped: root.commitTransition()
    }

    onEffectiveSourceChanged: root.load(root.effectiveSource)
}
