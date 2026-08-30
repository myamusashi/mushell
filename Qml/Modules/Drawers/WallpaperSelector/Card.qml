pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Vast.ImageCache
import Vast.Utils

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils

Item {
    id: root

    required property var modelData
    required property int index
    required property bool isCurrent
    required property var thumbnailAvailability
    required property real unitWidth
    required property real carouselHeight
    required property var controller

    signal selectRequested(int index)
    signal activateRequested(var modelData)

    onIsCurrentChanged: {
        if (!isCurrent)
            return;
        if (controller.isVideo(modelData))
            controller.ensureThumbnail(modelData);
        else
            ImageCache.preload(modelData, Qt.size(Screen.width, Screen.height));
    }

    implicitWidth: isCurrent ? unitWidth * 2 : unitWidth
    implicitHeight: carouselHeight
    z: isCurrent ? 100 : 1
    opacity: isCurrent ? 1.0 : 0.92

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.normal
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.normal
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    ClippingRectangle {
        id: cardRect

        anchors.centerIn: parent
        implicitWidth: parent.width - (root.isCurrent ? Math.max(20, root.unitWidth * 0.3) : Math.max(12, root.unitWidth * 0.2))
        implicitHeight: parent.height
        radius: root.isCurrent ? Appearance.rounding.large : 20
        color: "transparent"

        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Image {
            anchors.fill: parent
            source: root.controller.isVideo(root.modelData) ? "" : "file://" + root.modelData
            sourceSize: Qt.size(200, 200)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true

            Elevation {
                anchors.fill: parent
                z: -1
                level: 3
            }
        }

        Image {
            id: videoThumbnailCache

            anchors.fill: parent
            source: root.thumbnailAvailability[root.modelData] ? "file://" + root.controller.thumbnailPathFor(root.modelData) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Rectangle {
            id: dimOverlay

            property color target: Qt.rgba(0, 0, 0, root.isCurrent ? 0.0 : 0.22)
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

            anchors.fill: parent
            radius: cardRect.radius

            NAnim {
                id: colorBlendAnim

                target: dimOverlay
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
            }
        }

        MArea {
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!root.isCurrent)
                    root.selectRequested(root.index);
                else
                    root.activateRequested(root.modelData);
            }
        }
    }
}
