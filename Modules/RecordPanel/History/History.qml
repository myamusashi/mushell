import QtQuick
import QtQuick.Controls

import Quickshell

import qs.Components
import qs.Configs
import qs.Services

StyledRect {
    id: root

    color: "transparent"
    implicitWidth: parent.width
    implicitHeight: 400

    Column {
        anchors.fill: parent
        spacing: Appearance.spacing.normal

        StyledText {
            width: parent.width
            color: Colours.m3Colors.m3OnBackground
            text: "Recent screenshot"
            font.pixelSize: Appearance.fonts.extraLarge
            font.bold: true
        }

        ScrollView {
            width: parent.width
            height: Hypr.focusedMonitor.height * 0.3
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                width: parent.width
                spacing: Appearance.spacing.small

                Repeater {
                    model: ScriptModel {
                        values: [...ScreenCaptureHistory.screenshotFiles]
                    }
                    delegate: Wrapper {}
                }
            }
        }

        Item {
            implicitHeight: parent.height * 0.1
        }

        StyledText {
            width: parent.width
            color: Colours.m3Colors.m3OnBackground
            text: "Recent screen record"
            font.pixelSize: Appearance.fonts.extraLarge
            font.bold: true
        }

        ScrollView {
            width: parent.width
            height: Hypr.focusedMonitor.height * 0.3
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                implicitWidth: parent.width
                spacing: Appearance.spacing.small
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                cacheBuffer: 200
                reuseItems: true

                model: ScriptModel {
                    values: [...ScreenCaptureHistory.screenrecordFiles]
                }

                delegate: Wrapper {}
            }
        }
    }
}
