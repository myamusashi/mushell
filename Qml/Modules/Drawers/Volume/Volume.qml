pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
        rightMargin: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
    }

    readonly property real sliderHeight: 250 - 30 - 40 - 2 * Appearance.spacing.normal
    readonly property int itemSize: 40
    readonly property int itemSpacing: Appearance.spacing.large

    property bool openPerappVolume: false

    implicitWidth: GlobalStates.isOSDVisible("volume") ? wrapper.implicitWidth : 0
    implicitHeight: 280

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopRightCorner
        location2: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        active: GlobalStates.isOSDVisible("volume")
    }

    PwNodeLinkTracker {
        id: linkTracker

        node: Pipewire.defaultAudioSink
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            GlobalStates.showOSD("volume");
        }
    }

    IpcHandler {
        target: "volume"
        function systemGet(): string {
            return JSON.stringify({
                volume: Pipewire.defaultAudioSink.audio.volume,
                muted: Pipewire.defaultAudioSink.audio.muted
            });
        }
        function systemSet(percent: int): void {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }
        function systemChange(delta: int): void {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume + delta / 100));
        }
        function systemMute(): void {
            Pipewire.defaultAudioSink.audio.muted = true;
        }
        function systemUnmute(): void {
            Pipewire.defaultAudioSink.audio.muted = false;
        }
        function systemToggleMute(): void {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
        function appList(): string {
            const streams = Pipewire.nodes.values.filter(n => n.isStream);
            const r = [];
            for (const s of streams)
                r.push({
                    id: s.id,
                    name: s.name,
                    appName: s.properties["application.name"] ?? s.description ?? s.name,
                    mediaName: s.properties["media.name"] ?? "",
                    volume: s.audio.volume,
                    muted: s.audio.muted
                });
            return JSON.stringify(r);
        }
        function appSet(id: int, percent: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.volume = Math.max(0.0, Math.min(1.0, percent / 100));
        }
        function appChange(id: int, delta: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.volume = Math.max(0.0, Math.min(1.0, s.audio.volume + delta / 100));
        }
        function appMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = true;
        }
        function appUnmute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = false;
        }
        function appToggleMute(id: int): void {
            const s = Pipewire.nodes.values.filter(n => n.isStream).find(n => n.id === id);
            if (s)
                s.audio.muted = !s.audio.muted;
        }
    }

    WrapperRectangle {
        id: wrapper

        anchors.fill: parent
        implicitWidth: 60 + (root.openPerappVolume && loader.item ? loader.item.perappWidth + root.itemSpacing : 0) // qmllint disable
        color: GlobalStates.drawerColors
        clip: true
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: topLeftRadius

        Loader {
            id: loader

            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isOSDVisible("volume") // qmllint disable
            asynchronous: true
            onActiveChanged: {
                if (!active)
                    root.openPerappVolume = false;
            }

            sourceComponent: Item {
                anchors.fill: parent

                readonly property real perappWidth: repeater.count * root.itemSize + Math.max(0, repeater.count - 1) * root.itemSpacing

                Row {
                    id: perappContainer

                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    width: root.openPerappVolume ? parent.perappWidth : 0
                    height: mainVolumeColumn.height
                    spacing: root.itemSpacing
                    clip: true

                    Behavior on width {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    Repeater {
                        id: repeater

                        model: linkTracker.linkGroups
                        delegate: Mixer {
                            required property PwLinkGroup modelData

                            width: root.itemSize
                            height: perappContainer.height
                            node: modelData.source
                        }
                    }
                }

                ColumnLayout {
                    id: mainVolumeColumn

                    anchors {
                        right: parent.right
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    property bool showVolume: false

                    implicitWidth: 50
                    implicitHeight: 250
                    spacing: Appearance.spacing.normal

                    Item {
                        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                        implicitWidth: 30
                        implicitHeight: 30

                        Icon {
                            id: volumeIcon

                            anchors.centerIn: parent
                            type: Icon.Material
                            icon: Audio.getIcon(Pipewire.defaultAudioSink)
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            opacity: mainVolumeColumn.showVolume ? 0 : 1
                            scale: mainVolumeColumn.showVolume ? 0.5 : 1

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                            Behavior on scale {
                                NAnim {
                                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: volumeIcon
                            text: (Pipewire.defaultAudioSink.audio.volume * 100).toFixed(0)
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            font.weight: Font.DemiBold
                            opacity: mainVolumeColumn.showVolume ? 1 : 0
                            scale: mainVolumeColumn.showVolume ? 1 : 0.5

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }
                            Behavior on scale {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mevent => {
                                if (mevent.button === Qt.LeftButton)
                                    Audio.toggleMute(Pipewire.defaultAudioSink);
                            }
                        }
                    }

                    Timer {
                        id: volumeHideTimer

                        interval: 500
                        onTriggered: mainVolumeColumn.showVolume = false
                    }

                    StyledSlide {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.sliderHeight
                        orientation: Qt.Vertical
                        popupValueFormat: v => Math.round(v * 100)
                        value: Pipewire.defaultAudioSink.audio.volume
                        onMoved: Pipewire.defaultAudioSink.audio.volume = value
                        onValueChanged: {
                            mainVolumeColumn.showVolume = true;
                            if (!pressed)
                                volumeHideTimer.restart();
                        }
                        onPressedChanged: {
                            if (pressed) {
                                GlobalStates.pauseOSD("volume");
                                volumeHideTimer.stop();
                                mainVolumeColumn.showVolume = true;
                            } else {
                                GlobalStates.resumeOSD("volume");
                                volumeHideTimer.restart();
                            }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 15
                        implicitHeight: 15

                        Pulse {
                            anchors.centerIn: parent
                            isActive: Players.active.playbackState === MprisPlaybackState.Playing && GlobalStates.isOSDVisible("volume")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onEntered: GlobalStates.pauseOSD("volume")
                            onExited: GlobalStates.resumeOSD("volume")
                            onClicked: root.openPerappVolume = !root.openPerappVolume
                        }
                    }
                }
            }
        }
    }

    component Mixer: Column {
        id: mixer

        required property PwNode node
        property bool showVolume: false

        spacing: Appearance.spacing.normal

        PwObjectTracker {
            objects: [mixer.node]
        }

        Item {
            implicitWidth: root.itemSize
            implicitHeight: 30

            IconImage {
                id: appIcon

                anchors.centerIn: parent
                implicitWidth: 30
                implicitHeight: 30
                opacity: mixer.showVolume ? 0 : 1
                scale: mixer.showVolume ? 0.5 : 1
                source: IconUtils.guessIconPath(mixer.node)

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            StyledText {
                anchors.centerIn: appIcon
                text: (mixer.node.audio.volume * 100).toFixed(0)
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                opacity: mixer.showVolume ? 1 : 0
                scale: mixer.showVolume ? 1 : 0.5

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }

            Timer {
                id: appVolumeHideTimer

                interval: 500
                onTriggered: mixer.showVolume = false
            }
        }

        StyledSlide {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: root.itemSize
            implicitHeight: root.sliderHeight
            orientation: Qt.Vertical
            popupValueFormat: v => Math.round(v * 100)
            value: mixer.node.audio.volume
            onMoved: mixer.node.audio.volume = value
            onValueChanged: {
                mixer.showVolume = true;
                if (!pressed)
                    appVolumeHideTimer.restart();
            }
            onPressedChanged: {
                if (pressed) {
                    GlobalStates.pauseOSD("volume");
                    appVolumeHideTimer.stop();
                    mixer.showVolume = true;
                } else {
                    GlobalStates.resumeOSD("volume");
                    appVolumeHideTimer.restart();
                }
            }
        }
    }

    component Pulse: Item {
        id: pulse

        readonly property real baseBarHeight: 1.5
        property bool isActive: false
        property real progress: 0.0

        implicitWidth: 20
        implicitHeight: 20

        readonly property list<var> barConfigs: [
            {
                minHeight: 2,
                maxHeight: 4,
                phaseOffset: 0.70
            },
            {
                minHeight: 3,
                maxHeight: 6,
                phaseOffset: 0.45
            },
            {
                minHeight: 5,
                maxHeight: 8,
                phaseOffset: 0.20
            },
            {
                minHeight: 8,
                maxHeight: 11,
                phaseOffset: 0.15
            },
            {
                minHeight: 7,
                maxHeight: 6,
                phaseOffset: 0.00
            }
        ]

        function barHeight(index: int): real {
            if (!isActive)
                return baseBarHeight;
            const cfg = barConfigs[index];
            const phase = (progress + cfg.phaseOffset) % 1.0;
            const sinValue = Math.max(0, Math.sin(phase * Math.PI * 2));
            return cfg.minHeight + (cfg.maxHeight - cfg.minHeight) * sinValue;
        }

        Repeater {
            model: [
                {
                    x: 2,
                    index: 0
                },
                {
                    x: 6,
                    index: 1
                },
                {
                    x: 10,
                    index: 2
                },
                {
                    x: 14,
                    index: 3
                },
                {
                    x: 18,
                    index: 4
                }
            ]

            delegate: Rectangle {
                required property var modelData
                property real currentBarHeight: pulse.barHeight(modelData.index)

                x: modelData.x - width / 2.1
                y: 10 - currentBarHeight
                width: 3
                height: currentBarHeight * 2
                radius: 3
                color: Colours.m3Colors.m3Primary

                Behavior on currentBarHeight {
                    enabled: !pulse.isActive

                    NumberAnimation {
                        duration: 900
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        SequentialAnimation on progress {
            running: pulse.isActive
            loops: Animation.Infinite

            NumberAnimation {
                from: 0.0
                to: 1.0
                duration: 1000
            }
        }
    }
}
