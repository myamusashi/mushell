import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: bottomWrapperRect

    property alias lockIcon: lockIcon
    property alias contentLayout: contentLayout
    required property var mediaLayout
    required property bool showErrorMessage

    Layout.fillHeight: true
    implicitHeight: mediaLayout.implicitHeight + Appearance.margin.small * 2
    color: GlobalStates.drawerColors
    clip: true
    radius: Appearance.rounding.normal
    leftMargin: Appearance.margin.normal
    rightMargin: Appearance.margin.normal

    FontMetrics {
        id: lockIconMetrics
        font: lockIcon.font
    }

    RowLayout {
        id: contentLayout

        spacing: Appearance.spacing.normal
        opacity: 0

        ClippingWrapperRectangle {
            implicitWidth: 48
            implicitHeight: 48
            radius: Appearance.rounding.full
            color: "transparent"
            z: -1

            IconImage {
                id: avatar

                source: Qt.resolvedUrl(`${Paths.home}/.face`)
                z: 1
                backer.cache: true
                asynchronous: true
            }
        }

        Icon {
            id: lockIcon

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
                    color = Colours.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }

            NAnim {
                id: colorBlendAnim
                target: lockIcon
                property: "colorBlendProgress"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }

            Layout.alignment: Qt.AlignCenter
            icon: "lock"
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            transformOrigin: Item.Bottom

            SequentialAnimation {
                id: shakeAnim
                running: bottomWrapperRect.showErrorMessage

                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: 18
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: -18
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: 12
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: -12
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: 6
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: -6
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                NAnim {
                    target: lockIcon
                    property: "rotation"
                    to: 0
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
                ScriptAction {
                    script: {
                        colorBlendAnim.stop();
                        lockIcon.colorFrom = lockIcon.color;
                        lockIcon.colorTo = Colours.m3Colors.m3Red;
                        lockIcon.colorBlending = true;
                        lockIcon.colorBlendProgress = 0.0;
                        colorBlendAnim.start();
                    }
                }
            }
        }

        StyledText {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            text: "WRONG"
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.medium
            font.bold: true
            opacity: bottomWrapperRect.showErrorMessage ? 1 : 0
            visible: bottomWrapperRect.showErrorMessage

            Behavior on opacity {
                NAnim {
                    duration: 200
                }
            }
        }

        Clock {
            id: clockItem
            Layout.alignment: Qt.AlignCenter
        }
    }
}
