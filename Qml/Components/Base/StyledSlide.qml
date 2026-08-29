pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import Vast.Utils

Slider {
    id: root

    enum ContainerSize {
        XS = 16,
        S = 24,
        M = 40,
        L = 56,
        XL = 96
    }

    property alias filledRectColor: filledRect.color
    property alias emptyRectColor: emptyRect.color
    property alias handleColor: handle.color
    property alias filledRectOpacity: filledRect.opacity
    property alias emptyRectOpacity: emptyRect.opacity
    property alias handleOpacity: handle.opacity

    readonly property bool popupVisible: showValuePopup && (pressed || (popupOnHoverToo && hovered))

    readonly property bool isHorizontal: orientation === Qt.Horizontal
    readonly property bool isVertical: root.orientation === Qt.Vertical

    readonly property real availableTrackSize: isHorizontal ? availableWidth - handleGap * 2 : availableHeight - handleGap * 2
    readonly property real trackSize: isHorizontal ? height - trackSizeDiff : width - trackSizeDiff
    readonly property real handleSize: pressed ? 2 : 4
    readonly property real invertedVisualPosition: 1 - visualPosition
    readonly property int dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0

    property bool animateChanges: true
    property string icon: ""
    property int iconSize: 0
    property int valueWidth: isHorizontal ? 200 : StyledSlide.ContainerSize.M
    property int valueHeight: isHorizontal ? StyledSlide.ContainerSize.M : 200

    property real trackSizeDiff: 15
    property real handleGap: 6

    property bool snapEnabled: false
    property real snapDotSize: 4
    property color snapDotFilledColor: Colours.m3Colors.m3OnPrimary
    property color snapDotEmptyColor: Colours.m3Colors.m3OnSurfaceVariant // qmllint:ignore

    property bool showValuePopup: true
    property bool popupOnHoverToo: false
    property int popupDecimals: 0
    property var popupValueFormat: v => v.toFixed(root.popupDecimals)

    snapMode: (snapEnabled && stepSize > 0) ? Slider.SnapAlways : Slider.NoSnap
    Layout.alignment: isHorizontal ? Qt.AlignHCenter : Qt.AlignVCenter
    hoverEnabled: true
    implicitWidth: valueWidth
    implicitHeight: valueHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            if (root.isVertical) {
                var pos = 1 - ((mouse.y - root.topPadding) / root.availableHeight);
                pos = Math.max(0, Math.min(1, pos));
                var newValue = root.from + (pos * (root.to - root.from));
                if (root.stepSize > 0)
                    newValue = Math.round(newValue / root.stepSize) * root.stepSize;
                root.value = newValue;
            }
            mouse.accepted = false;
        }
    }

    background: Item {
        implicitWidth: root.valueWidth
        implicitHeight: root.valueHeight
        width: root.availableWidth
        height: root.availableHeight
        x: root.leftPadding
        y: root.topPadding

        Loader {
            id: iconLoader

            readonly property real effectiveIconSize: root.iconSize || Appearance.fonts.size.large
            readonly property real iconSpaceNeeded: effectiveIconSize + 20
            readonly property real freeWidthHorizontal: root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property real freeHeightVertical: root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property bool iconInEmpty: root.isHorizontal ? freeWidthHorizontal > iconSpaceNeeded : freeHeightVertical > iconSpaceNeeded

            active: root.icon !== ""
            z: 10

            // qmllint disable
            states: [
                State {
                    name: "hFilled"
                    when: root.isHorizontal && !iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors {
                            left: parent.left
                            right: undefined
                            top: undefined
                            bottom: undefined
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: undefined
                        }
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.leftMargin: 10
                    }
                },
                State {
                    name: "hEmpty"
                    when: root.isHorizontal && iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors {
                            left: undefined
                            right: parent.right
                            top: undefined
                            bottom: undefined
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: undefined
                        }
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.rightMargin: 10
                    }
                },
                State {
                    name: "vFilled"
                    when: root.isVertical && !iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors {
                            left: undefined
                            right: undefined
                            top: undefined
                            bottom: parent.bottom
                            verticalCenter: undefined
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.bottomMargin: 10
                    }
                },
                State {
                    name: "vEmpty"
                    when: root.isVertical && iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors {
                            left: undefined
                            right: undefined
                            top: parent.top
                            bottom: undefined
                            verticalCenter: undefined
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.topMargin: 10
                    }
                }
            ]
            // qmllint enable

            transitions: Transition {
                enabled: root.animateChanges
                AnchorAnimation {
                    duration: Appearance.animations.durations.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }

            sourceComponent: Icon {
                icon: root.icon
                color: iconLoader.iconInEmpty ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                font.pixelSize: root.iconSize || Appearance.fonts.size.large
            }
        }

        StyledRect {
            id: filledRect

            anchors {
                verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
                left: root.isHorizontal ? parent.left : undefined
                horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                bottom: root.isVertical ? parent.bottom : undefined
            }
            width: root.isHorizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize
            height: root.isHorizontal ? root.trackSize : root.handleGap + (root.invertedVisualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            color: Colours.m3Colors.m3Primary
            radius: Appearance.rounding.small * 0.5
            opacity: 1.0
        }

        StyledRect {
            id: emptyRect

            anchors {
                verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
                right: root.isHorizontal ? parent.right : undefined
                horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                top: root.isVertical ? parent.top : undefined
            }
            width: root.isHorizontal ? root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize
            height: root.isHorizontal ? root.trackSize : root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            color: Colours.m3Colors.m3SurfaceContainerHighest
            radius: Appearance.rounding.small * 0.5
            opacity: 1.0
        }

        Repeater {
            model: (root.snapEnabled && root.stepSize > 0) ? root.dotCount : 0

            delegate: Rectangle {
                id: snapDot

                required property int index

                readonly property real normalPos: root.dotCount > 1 ? index / (root.dotCount - 1) : 0.5
                readonly property bool isFilled: normalPos <= root.visualPosition

                width: root.snapDotSize
                height: root.snapDotSize
                radius: root.snapDotSize / 2
                color: isFilled ? root.snapDotFilledColor : root.snapDotEmptyColor
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

                x: root.isHorizontal ? root.handleGap + (normalPos * root.availableTrackSize) - root.snapDotSize / 2 : (parent.width - root.snapDotSize) / 2
                y: root.isVertical ? root.handleGap + ((1 - normalPos) * root.availableTrackSize) - root.snapDotSize / 2 : (parent.height - root.snapDotSize) / 2
                z: 5

                onIsFilledChanged: {
                    colorBlendAnim.stop();
                    colorFrom = color;
                    colorTo = isFilled ? root.snapDotFilledColor : root.snapDotEmptyColor;
                    colorBlending = true;
                    colorBlendProgress = 0.0;
                    colorBlendAnim.start();
                }

                NAnim {
                    id: colorBlendAnim
                    target: snapDot
                    property: "colorBlendProgress"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    handle: StyledRect {
        id: handle

        width: root.isHorizontal ? root.handleSize : root.width
        height: root.isHorizontal ? root.height : root.handleSize
        x: root.isHorizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - width / 2 : 0
        y: root.isVertical ? root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - height / 2 : 0
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        color: Colours.m3Colors.m3Primary
        opacity: 1.0

        Behavior on width {
            enabled: root.animateChanges
            NAnim {}
        }
        Behavior on height {
            enabled: root.animateChanges
            NAnim {}
        }

        Item {
            id: valuePopupRoot

            x: root.isHorizontal ? (handle.width - valuePopupBubble.width) / 2 : -(valuePopupBubble.width + caret.caretSize + 2)
            y: root.isHorizontal ? -(valuePopupBubble.height + caret.caretSize + 2) : (handle.height - valuePopupBubble.height) / 2

            width: valuePopupBubble.width + (root.isVertical ? caret.caretSize + 2 : 0)
            height: valuePopupBubble.height + (root.isHorizontal ? caret.caretSize + 2 : 0)
            z: 20
            visible: root.popupVisible
            opacity: visible ? 1.0 : 0.0
            scale: visible ? 1.0 : 0.82

            transformOrigin: root.isHorizontal ? Item.Bottom : Item.Right

            Behavior on opacity {
                enabled: root.animateChanges
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on scale {
                enabled: root.animateChanges
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            StyledRect {
                id: valuePopupBubble

                readonly property real horizontalPadding: 10
                readonly property real verticalPadding: 6

                width: valueLabel.implicitWidth + horizontalPadding * 2
                height: valueLabel.implicitHeight + verticalPadding * 2
                x: 0
                y: 0

                color: Colours.m3Colors.m3InverseSurface
                radius: Appearance.rounding.small

                StyledText {
                    id: valueLabel

                    anchors.centerIn: parent
                    text: root.popupValueFormat(root.value) // qmllint disable
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3InverseOnSurface
                }
            }

            Shape {
                id: caret

                anchors {
                    horizontalCenter: root.isHorizontal ? valuePopupBubble.horizontalCenter : undefined
                    top: root.isHorizontal ? valuePopupBubble.bottom : undefined
                    left: root.isVertical ? valuePopupBubble.right : undefined
                    verticalCenter: root.isVertical ? valuePopupBubble.verticalCenter : undefined
                }

                readonly property int caretSize: 6

                width: root.isHorizontal ? caretSize * 2 : caretSize
                height: root.isHorizontal ? caretSize : caretSize * 2
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Colours.m3Colors.m3InverseSurface
                    strokeColor: "transparent"
                    strokeWidth: 0

                    startX: 0
                    startY: 0

                    // Horizontal ▼: (0,0) → (12,0) → (6,6)
                    // Vertical   ▶: (0,0) → (0,12) → (6,6)
                    PathLine {
                        x: root.isHorizontal ? caret.caretSize * 2 : 0
                        y: root.isHorizontal ? 0 : caret.caretSize * 2
                    }
                    PathLine {
                        x: caret.caretSize
                        y: caret.caretSize
                    }
                    PathLine {
                        x: 0
                        y: 0
                    }
                }
            }
        }
    }
}
