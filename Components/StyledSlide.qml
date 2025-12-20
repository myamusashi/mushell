pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

Slider {
    id: root

    hoverEnabled: true
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: valueWidth || 200
    implicitHeight: valueHeight

    enum ContainerSize {
        XS = 16,
        S = 24,
        M = 40,
        L = 56,
        XL = 96
    }

    enum HandleSize {
        XS = 44,
        S = 44,
        M = 44,
        L = 68,
        XL = 108
    }

    property bool dotEnd: true
    property real trackHeightDiff: 15
    property real handleGap: 6
    property real trackDotSize: 4
    property bool useAnim: true
    property int valueWidth: 200
    property int valueHeight: StyledSlide.ContainerSize.M
    property string icon
    property int iconSize

    readonly property real availableTrackWidth: availableWidth - handleGap * 2
    readonly property real trackHeight: height - trackHeightDiff
    readonly property real handleWidth: pressed ? 2 : 4
    readonly property int dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0

    component TrackDot: Rectangle {
        required property int index

        readonly property real stepValue: root.from + (index * root.stepSize)
        readonly property real normalizedValue: (stepValue - root.from) / (root.to - root.from)
        readonly property bool isActive: normalizedValue <= root.visualPosition

        anchors.verticalCenter: parent.verticalCenter
        x: root.handleGap + (normalizedValue * root.availableTrackWidth) - root.trackDotSize / 2

        width: root.trackDotSize
        height: root.trackDotSize
        radius: Appearance.rounding.normal
        visible: root.dotEnd && index > 0 && index < root.dotCount - 1
        color: isActive ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSecondaryContainer
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    }

    background: Item {
        implicitWidth: root.valueWidth || 200
        implicitHeight: root.valueHeight
        width: root.availableWidth
        height: root.availableHeight
        x: root.leftPadding
        y: root.topPadding

        Loader {
            active: root.icon !== ""
            z: 10
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            sourceComponent: MaterialIcon {
                icon: root.icon
                color: Colours.m3Colors.m3OnPrimary
                font.pointSize: root.iconSize || Appearance.fonts.size.medium
            }
        }

        StyledRect {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: root.handleGap + (root.visualPosition * root.availableTrackWidth) - (root.handleWidth / 2 + root.handleGap)
            height: root.trackHeight
            color: Colours.m3Colors.m3Primary
            radius: Appearance.rounding.small * 0.5

            topRightRadius: Appearance.rounding.small * 0.5
            bottomRightRadius: Appearance.rounding.small * 0.5
        }

        StyledRect {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: root.handleGap + ((1 - root.visualPosition) * root.availableTrackWidth) - (root.handleWidth / 2 + root.handleGap)
            height: root.trackHeight
            color: Colours.m3Colors.m3SurfaceContainerHighest
            radius: Appearance.rounding.small * 0.5

            topLeftRadius: Appearance.rounding.small * 0.5
            bottomLeftRadius: Appearance.rounding.small * 0.5
        }

        Repeater {
            model: root.dotCount
            TrackDot {
                required property int modelData
                index: modelData
            }
        }
    }

    handle: StyledRect {
        width: root.handleWidth
        height: root.height
        x: root.handleGap + (root.visualPosition * root.availableTrackWidth) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.m3Colors.m3Primary

        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.small
                easing.type: Easing.OutCubic
            }
        }
    }
}
