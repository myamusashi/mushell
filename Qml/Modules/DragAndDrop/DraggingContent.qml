pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool active

    implicitWidth: draggingRowLayout.implicitWidth + 32
    implicitHeight: 44

    RowLayout {
        id: draggingRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        Row {
            spacing: 5

            Repeater {
                model: 3

                delegate: Rectangle {
                    id: dot

                    required property int index
                    property int stagger: index * 90

                    width: 8
                    height: 8
                    radius: width / 2
                    color: Colours.m3Colors.m3Green

                    SequentialAnimation on scale {
                        running: root.active
                        loops: Animation.Infinite
                        PauseAnimation {
                            duration: dot.stagger
                        }
                        NAnim {
                            to: 0.55
                        }
                        NAnim {
                            to: 1
                        }
                    }
                }
            }
        }

        StyledText {
            text: qsTr("Drop files here")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}
