pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Switch {
    id: root

    property alias isUseIcon: iconLoader.active
    property string onIcon: "check"
    property string offIcon: "close"

    property string _currentIcon: offIcon
    property color _currentIconColor: Colours.m3Colors.m3SurfaceContainerHighest

    // qmllint disable
    states: [
        State {
            name: "unchecked"
            when: !root.checked && !root.down
            PropertyChanges {
                target: track
                color: Colours.m3Colors.m3SurfaceContainerHighest
                border.color: Colours.m3Colors.m3Outline
            }
            PropertyChanges {
                target: handle
                x: handle.margin
                width: 16
                height: 16
                color: Colours.m3Colors.m3Outline
            }
            PropertyChanges {
                target: root
                _currentIcon: offIcon
                _currentIconColor: Colours.m3Colors.m3SurfaceContainerHighest
            }
        },
        State {
            name: "checked"
            when: root.checked && !root.down
            PropertyChanges {
                target: track
                color: Colours.m3Colors.m3Primary
                border.color: "transparent"
            }
            PropertyChanges {
                target: handle
                x: track.width - 28 - handle.margin
                width: 28
                height: 24
                color: Colours.m3Colors.m3OnPrimary
            }
            PropertyChanges {
                target: root
                _currentIcon: onIcon
                _currentIconColor: Colours.m3Colors.m3OnPrimaryContainer
            }
        },
        State {
            name: "pressedUnchecked"
            when: root.down && !root.checked
            PropertyChanges {
                target: track
                color: Colours.m3Colors.m3SurfaceContainerHighest
                border.color: Colours.m3Colors.m3Outline
            }
            PropertyChanges {
                target: handle
                x: handle.margin
                width: 28
                height: 28
                color: Colours.m3Colors.m3Outline
            }
            PropertyChanges {
                target: root
                _currentIcon: offIcon
                _currentIconColor: Colours.m3Colors.m3SurfaceContainerHighest
            }
        },
        State {
            name: "pressedChecked"
            when: root.down && root.checked
            PropertyChanges {
                target: track
                color: Colours.m3Colors.m3Primary
                border.color: "transparent"
            }
            PropertyChanges {
                target: handle
                x: track.width - 28 - handle.margin
                width: 28
                height: 28
                color: Colours.m3Colors.m3OnPrimary
            }
            PropertyChanges {
                target: root
                _currentIcon: onIcon
                _currentIconColor: Colours.m3Colors.m3OnPrimaryContainer
            }
        }
    ]
    // qmllint enable

    transitions: Transition {
        NAnim {
            properties: "x,width,height"
            easing.bezierCurve: Appearance.animations.curves.emphasized
            duration: Appearance.animations.durations.small
        }
    }

    indicator: StyledRect {
        id: track

        implicitWidth: 52
        implicitHeight: 32
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: Appearance.rounding.full
        border.width: 2

        StyledRect {
            id: handle

            readonly property int margin: 4

            y: (parent.height - height) / 2
            radius: Appearance.rounding.full

            Loader {
                id: iconLoader

                active: true
                anchors.centerIn: parent
                asynchronous: true
                sourceComponent: Icon {
                    icon: root._currentIcon
                    color: root._currentIconColor
                    font.pixelSize: Appearance.fonts.size.medium
                }
            }
        }
    }
}
