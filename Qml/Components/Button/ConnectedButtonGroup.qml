pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property var model: []
    property int currentIndex: 0

    property color selectedColor: Colours.m3Colors.m3SecondaryContainer
    property color unselectedColor: Colours.m3Colors.m3SurfaceContainerHigh
    property color selectedContentColor: Colours.m3Colors.m3OnSecondaryContainer
    property color unselectedContentColor: Colours.m3Colors.m3OnSurfaceVariant

    property int textSize: Appearance.fonts.size.normal

    property bool fillWidth: false

    readonly property real distributedSegmentWidth: model.length > 0 ? (width - (model.length - 1) * 2) / model.length : 0
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

        readonly property bool isSelected: root.currentIndex === index
        readonly property bool isFirst: index === 0
        readonly property bool isLast: index === root.model.length - 1
        readonly property string label: typeof modelData === "string" ? modelData : (modelData.label ?? "")
        readonly property string segmentIconName: typeof modelData === "string" ? "" : (modelData.icon ?? "")
        readonly property color contentColor: isSelected ? root.selectedContentColor : root.unselectedContentColor
        property bool pressed
        property bool hovered

        readonly property real targetInnerRadius: isSelected ? height * 0.5 : pressed ? 4 : 8
        readonly property real preferredWidth: contentRow.implicitWidth + 32

        onPreferredWidthChanged: root.reportSegmentWidth(index, preferredWidth)

        width: root.fillWidth ? root.distributedSegmentWidth : root.segmentWidth
        height: root.height
        activeFocusOnTab: root.enabled
        pressed: segmentTapHandler.pressed
        hovered: segmentHoverHandler.hovered

        Component.onCompleted: root.reportSegmentWidth(index, preferredWidth)
        Component.onDestruction: root.reportSegmentWidth(index, 0)

        function select() {
            if (!root.enabled)
                return;
            root.clicked(index);
        }

        function moveFocus(delta) {
            const target = segmentRepeater.itemAt(index + delta);
            if (target)
                target.forceActiveFocus();
        }

        Keys.onReturnPressed: event => {
            select();
            event.accepted = true;
        }

        Keys.onSpacePressed: event => {
            select();
            event.accepted = true;
        }

        Keys.onLeftPressed: event => {
            moveFocus(-1);
            event.accepted = true;
        }

        Keys.onRightPressed: event => {
            moveFocus(1);
            event.accepted = true;
        }

        StyledRect {
            id: segmentBackground

            anchors.fill: parent
            topLeftRadius: segment.isFirst ? Appearance.rounding.full : segment.targetInnerRadius
            bottomLeftRadius: segment.isFirst ? Appearance.rounding.full : segment.targetInnerRadius
            topRightRadius: segment.isLast ? Appearance.rounding.full : segment.targetInnerRadius
            bottomRightRadius: segment.isLast ? Appearance.rounding.full : segment.targetInnerRadius
            color: segment.isSelected ? root.selectedColor : root.unselectedColor

            Behavior on topLeftRadius {
                NAnim {}
            }

            Behavior on bottomLeftRadius {
                NAnim {}
            }

            Behavior on topRightRadius {
                NAnim {}
            }

            Behavior on bottomRightRadius {
                NAnim {}
            }

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
            opacity: segment.activeFocus ? 1 : 0
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
    }
}
