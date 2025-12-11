pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

StyledRect {
    id: root

    property int currentIndex: 0
    property var tabs: []
    property real scaleFactor: 0.2
    property int tabSpacing: 15
    property real widthRatio: 0.95
    property int preferredHeight: 60
    property color backgroundColor: Colours.m3Colors.m3Surface
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3OnBackground
    property color indicatorColor: Colours.m3Colors.m3Primary
    property int indicatorHeight: 2
    property int indicatorRadius: Appearance.rounding.large
    property bool showIndicator: true
    radius: 0

    signal tabClicked(int index, var tabData)

    implicitWidth: parent.width
    implicitHeight: preferredHeight
    color: backgroundColor

    RowLayout {
        id: tabLayout

        anchors.centerIn: parent
        spacing: root.tabSpacing
        width: parent.width * root.widthRatio

        Repeater {
            id: tabRepeater

            model: root.tabs

            StyledButton {
                id: tabButton

                required property var modelData
                required property int index

				Layout.fillWidth: true
                buttonTitle: modelData.title || ""
                iconButton: modelData.icon || ""
                iconSize: modelData.iconSize || (Appearance.fonts.size.large * root.scaleFactor)
                buttonTextColor: root.currentIndex === index ? root.activeColor : root.inactiveColor
                buttonColor: root.backgroundColor
                enabled: modelData.enabled !== undefined ? modelData.enabled : true

                onClicked: {
                    root.currentIndex = index;
                    root.tabClicked(index, modelData);
                }
            }
        }
    }

    StyledRect {
        id: indicator

        anchors.bottom: tabLayout.bottom
        implicitWidth: tabRepeater.itemAt(root.currentIndex) ? tabRepeater.itemAt(root.currentIndex).width : 0
        implicitHeight: root.indicatorHeight
        color: root.indicatorColor
        radius: root.indicatorRadius

        x: {
            if (tabRepeater.itemAt(root.currentIndex))
            return tabRepeater.itemAt(root.currentIndex).x + tabLayout.x;
            return 0;
        }

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on width {
            NAnim {
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
        }
    }
}
