pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    // Segment labels: plain strings or { icon, label } objects.
    property var model: []
    property int currentIndex: 0

    property color selectedColor: Colours.m3Colors.m3SecondaryContainer
    property color unselectedColor: Colours.m3Colors.m3SurfaceContainerHigh
    property color selectedContentColor: Colours.m3Colors.m3OnSecondaryContainer
    property color unselectedContentColor: Colours.m3Colors.m3OnSurfaceVariant

    property int textSize: Appearance.fonts.size.normal
    property var reportedSegmentWidths: []

    signal clicked(int index)

    function reportSegmentWidth(index, width) {
        const widths = reportedSegmentWidths.slice();
        if (widths[index] === width)
            return;
        widths[index] = width;
        reportedSegmentWidths = widths;
    }

    readonly property real segmentWidth: {
        let maxWidth = 0;
        for (let i = 0; i < reportedSegmentWidths.length; ++i)
            maxWidth = Math.max(maxWidth, reportedSegmentWidths[i]);
        return maxWidth;
    }

    implicitWidth: segmentRow.implicitWidth
    implicitHeight: 40
    opacity: enabled ? 1 : 0.38

    Row {
        id: segmentRow

        spacing: 2

        Repeater {
            id: segmentRepeater

            model: root.model

            delegate: Segment {}
        }
    }

    component Segment: Item {
        id: segment

        required property int index
        required property var modelData

        readonly property bool isSelected: root.currentIndex === segment.index
        readonly property bool isFirst: segment.index === 0
        readonly property bool isLast: segment.index === root.model.length - 1
        readonly property string label: typeof segment.modelData === "string" ? segment.modelData : (segment.modelData.label ?? "")
        readonly property string segmentIconName: typeof segment.modelData === "string" ? "" : (segment.modelData.icon ?? "")
        readonly property color contentColor: segment.isSelected ? root.selectedContentColor : root.unselectedContentColor
        property bool pressed
        property bool hovered

        readonly property real preferredWidth: contentRow.implicitWidth + 32

        Component.onCompleted: root.reportSegmentWidth(segment.index, segment.preferredWidth)

        onPreferredWidthChanged: root.reportSegmentWidth(segment.index, segment.preferredWidth)

        Component.onDestruction: root.reportSegmentWidth(segment.index, 0)

        width: root.segmentWidth
        height: root.height
        activeFocusOnTab: root.enabled

        function select() {
            if (!root.enabled)
                return;
            root.clicked(segment.index);
        }

        function moveFocus(delta) {
            const target = segmentRepeater.itemAt(segment.index + delta);
            if (target)
                target.forceActiveFocus();
        }

        Keys.onReturnPressed: event => {
            segment.select();
            event.accepted = true;
        }

        Keys.onSpacePressed: event => {
            segment.select();
            event.accepted = true;
        }

        Keys.onLeftPressed: event => {
            segment.moveFocus(-1);
            event.accepted = true;
        }

        Keys.onRightPressed: event => {
            segment.moveFocus(1);
            event.accepted = true;
        }

        // qmllint disable
        states: [
            State {
                name: "pressed"
                when: segment.pressed
                PropertyChanges {
                    target: segmentBackground
                    scale: 0.98
                }
            },
            State {
                name: "focused"
                when: segment.activeFocus
                PropertyChanges {
                    target: focusRing
                    opacity: 1
                }
            }
        ]
        // qmllint enable

        transitions: [
            Transition {
                from: "*"
                to: "*"
                NAnim {
                    properties: "scale,opacity"
                    duration: Appearance.animations.durations.small
                }
            }
        ]

        StyledRect {
            id: segmentBackground

            anchors.fill: parent
            topLeftRadius: segment.isFirst ? Appearance.rounding.full : 8
            bottomLeftRadius: segment.isFirst ? Appearance.rounding.full : 8
            topRightRadius: segment.isLast ? Appearance.rounding.full : 8
            bottomRightRadius: segment.isLast ? Appearance.rounding.full : 8
            color: segment.isSelected ? root.selectedColor : root.unselectedColor
            transformOrigin: Item.Center

            Behavior on color {
                CAnim {}
            }
        }

        StyledRect {
            id: stateOverlay

            anchors.fill: parent
            topLeftRadius: segmentBackground.topLeftRadius
            bottomLeftRadius: segmentBackground.bottomLeftRadius
            topRightRadius: segmentBackground.topRightRadius
            bottomRightRadius: segmentBackground.bottomRightRadius
            color: segment.contentColor
            opacity: segment.hovered || segment.pressed ? (segment.pressed ? 0.12 : 0.08) : 0

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        Rectangle {
            id: focusRing

            anchors.fill: parent
            topLeftRadius: segmentBackground.topLeftRadius
            bottomLeftRadius: segmentBackground.bottomLeftRadius
            topRightRadius: segmentBackground.topRightRadius
            bottomRightRadius: segmentBackground.bottomRightRadius
            color: "transparent"
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            opacity: 0

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        RowLayout {
            id: contentRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                visible: segment.segmentIconName !== ""
                icon: segment.segmentIconName
                color: segment.contentColor
                font.pixelSize: Appearance.fonts.size.large * 1.2

                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                text: segment.label
                color: segment.contentColor
                font.pixelSize: root.textSize
                font.weight: segment.isSelected ? Font.DemiBold : Font.Medium

                Behavior on color {
                    CAnim {}
                }
            }
        }
        HoverHandler {
            id: segmentHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            id: segmentTapHandler

            enabled: root.enabled
            onTapped: segment.select()
        }

        pressed: segmentTapHandler.pressed
        hovered: segmentHoverHandler.hovered
    }
}
