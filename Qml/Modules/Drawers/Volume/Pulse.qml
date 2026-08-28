pragma ComponentBehavior: Bound

import QtQuick

import qs.Services

Item {
    id: root

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
        const barConfig = barConfigs[index];
        const phase = (progress + barConfig.phaseOffset) % 1.0;
        const sinValue = Math.max(0, Math.sin(phase * Math.PI * 2));
        return barConfig.minHeight + (barConfig.maxHeight - barConfig.minHeight) * sinValue;
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
            property real currentBarHeight: root.barHeight(modelData.index)

            x: modelData.x - width / 2.1
            y: 10 - currentBarHeight
            width: 3
            height: currentBarHeight * 2
            radius: 3
            color: Colours.m3Colors.m3Primary

            Behavior on currentBarHeight {
                enabled: !root.isActive

                NumberAnimation {
                    duration: 900
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    SequentialAnimation on progress {
        running: root.isActive
        loops: Animation.Infinite

        NumberAnimation {
            from: 0.0
            to: 1.0
            duration: 1000
        }
    }
}
