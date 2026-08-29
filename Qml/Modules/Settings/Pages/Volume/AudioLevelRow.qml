pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import Vast.Utils

ColumnLayout {
    id: root

    required property PwNode node
    property bool selectable: false
    property bool isCurrent: false
    readonly property real vol: node.audio.volume
    readonly property real peak: peakMonitor.peak

    signal defaultRequested

    function dbText(v) {
        if (v <= 0.00001)
            return "-∞ dB";
        const db = 20 * Math.log10(v);
        return (db >= 0 ? "+" : "") + db.toFixed(1) + " dB";
    }

    PwObjectTracker {
        id: objectTracker
        objects: [root.node]
    }

    PwNodePeakMonitor {
        id: peakMonitor
        node: root.node
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledRect {
            id: defaultIndicator

            visible: root.selectable
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            property color target: root.isCurrent ? Colours.m3Colors.m3Primary : "transparent"
            property color colorFrom
            property color colorTo
            property bool colorBlending: false
            property real colorBlendProgress: 1.0

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }
            onTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = target;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            radius: width / 2
            border.width: 2
            border.color: Colours.m3Colors.m3Primary
            color: "transparent"

            NAnim {
                id: colorBlendAnim
                target: defaultIndicator
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            TapHandler {
                onTapped: root.defaultRequested()
            }
        }

        StyledRect {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            radius: Appearance.rounding.full

            Icon {
                anchors.centerIn: parent
                icon: Audio.getIcon(root.node)
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }

            MArea {
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        Audio.toggleMute(root.node);
                }
                onWheel: mouse => Audio.wheelAction(mouse, root.node)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.node.description || root.node.nickname || root.node.name
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                id: percentText

                Layout.fillWidth: true
                text: Math.round(root.vol * 100) + "% · " + root.dbText(root.vol)
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
            }
        }
    }

    StyledSlide {
        id: volumeSlider

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        from: 0
        to: 1.5
        stepSize: 0.01
        value: root.vol
        popupValueFormat: v => Math.round(v * 100) + "%"
        onMoved: root.node.audio.volume = value
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        radius: height / 2
        color: Colours.m3Colors.m3SurfaceContainerHighest

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: parent.radius
            color: root.peak > 0.98 ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            opacity: root.node.audio.muted ? 0.25 : 1.0
            width: parent.width * Math.min(root.peak, 1.0)
        }
    }
}
