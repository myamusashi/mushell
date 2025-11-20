pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Components

StyledRect {
    id: root

    required property int state
    required property real scaleFactor

    signal tabClicked(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: 60
    bottomLeftRadius: 5
    bottomRightRadius: 5
    color: Themes.m3Colors.m3Surface

    RowLayout {
        id: tabLayout
        anchors.centerIn: parent
        spacing: 15
        width: parent.width * 0.95

        Repeater {
            id: tabRepeater

            model: [{
                    "title": "Settings",
                    "icon": "settings",
                    "index": 0
                }, {
                    "title": "Volumes",
                    "icon": "speaker",
                    "index": 1
                }, {
                    "title": "Performance",
                    "icon": "speed",
                    "index": 2
                }, {
                    "title": "Weather",
                    "icon": "cloud",
                    "index": 3
                }]

            StyledButton {
                id: settingButton

                required property var modelData
                required property int index

                buttonTitle: modelData.title
                Layout.fillWidth: true
                buttonColor: "transparent"
                highlighted: root.state === modelData.index
                flat: root.state !== modelData.index
                onClicked: root.tabClicked(settingButton.index)

                contentItem: RowLayout {
                    id: content

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        icon: settingButton.modelData.icon
                        color: root.state === settingButton.index ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnSurfaceVariant

                        font.pointSize: Appearance.fonts.large * root.scaleFactor
                    }

                    StyledText {
                        text: settingButton.modelData.title
                        color: root.state === settingButton.index ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnSurfaceVariant

                        font.pixelSize: Appearance.fonts.large * root.scaleFactor
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    StyledRect {
        id: indicator

        anchors.bottom: tabLayout.bottom
        width: tabRepeater.itemAt(root.state) ? tabRepeater.itemAt(
                                                    root.state).width : 0
        height: 2
        color: Themes.m3Colors.m3Primary
        radius: Appearance.rounding.large

        x: {
            if (tabRepeater.itemAt(root.state))
            return tabRepeater.itemAt(root.state).x + tabLayout.x

            return 0
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
