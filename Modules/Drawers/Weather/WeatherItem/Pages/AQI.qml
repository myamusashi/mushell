pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    property bool isOpen: false

    margin: Appearance.margin.normal
    visible: opacity > 0
    color: Colours.m3Colors.m3Surface
    scale: isOpen ? 1.0 : 0.5
    opacity: isOpen ? 1.0 : 0.0
    transformOrigin: Item.Center

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Component {
        id: loadingIndicator

        LoadingIndicator {
            implicitWidth: 120
            implicitHeight: 120
            status: !Loader.Ready
        }
    }

    FileView {
        id: aqiUSAFileDescription

        path: Qt.resolvedUrl("./Markdown/USAQI.md")
        watchChanges: true
    }

    FileView {
        id: aqiEuroFileDescription

        path: Qt.resolvedUrl("./Markdown/EuroAQI.md")
        watchChanges: true
    }

    Loader {
        active: root.isOpen

        sourceComponent: Column {
            id: column

            property string description: tabGroup.currentIndex === 0 ? aqiUSAFileDescription.text() : aqiEuroFileDescription.text()

            spacing: Appearance.spacing.normal

            Header {
                icon: Lucide.icon_waves
                title: "Air quality"
                mouseArea.onClicked: root.isOpen = false
            }

            WrapperRectangle {
                anchors.margins: Appearance.margin.normal
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.25
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer

                ColumnLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: "Current conditions"
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large * 1.5
                    }

                    RowLayout {
                        spacing: Appearance.spacing.small
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft

                        StyledText {
                            text: Weather.europeanAQI
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        StyledText {
                            text: Weather.europeanAQICategory
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.normal
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        Layout.bottomMargin: 8

                        StyledRect {
                            implicitWidth: parent.width
                            implicitHeight: 5
                            radius: Appearance.rounding.small
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: "#4CAF50"
                                }
                                GradientStop {
                                    position: 0.2
                                    color: "#FFEB3B"
                                }
                                GradientStop {
                                    position: 0.4
                                    color: "#FF9800"
                                }
                                GradientStop {
                                    position: 0.6
                                    color: "#F44336"
                                }
                                GradientStop {
                                    position: 0.8
                                    color: "#9C27B0"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#8B0000"
                                }
                            }
                        }

                        StyledRect {
                            implicitWidth: 15
                            implicitHeight: 15
                            radius: implicitWidth / 2
                            color: Colours.m3Colors.m3Surface
                            border.width: 2
                            border.color: Colours.m3Colors.m3OnSurface
                            x: {
                                var position = 0;
                                var value = Weather.usAQI;

                                if (value <= 50) {
                                    position = (value / 50) * 0.2; // 0-20% of gradient
                                } else if (value <= 100) {
                                    position = 0.2 + ((value - 50) / 50) * 0.2; // 20-40%
                                } else if (value <= 150) {
                                    position = 0.4 + ((value - 100) / 50) * 0.2; // 40-60%
                                } else if (value <= 200) {
                                    position = 0.6 + ((value - 150) / 50) * 0.2; // 60-80%
                                } else if (value <= 300) {
                                    position = 0.8 + ((value - 200) / 100) * 0.2; // 80-100%
                                } else {
                                    position = Math.min(1.0, 0.8 + ((value - 300) / 200) * 0.2);
                                }

                                return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                            }
                            y: parent.height / 2 - height / 2
                            Behavior on x {
                                NAnim {}
                            }
                        }
                    }

                    Repeater {
                        model: [
                            {
                                text: "United States AQI:",
                                value: Weather.usAQI
                            },
                            {
                                text: "European AQi:",
                                value: Weather.europeanAQI
                            }
                        ]

                        delegate: RowLayout {
                            id: aqiDelegate

                            required property var modelData

                            StyledText {
                                text: aqiDelegate.modelData.text
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledRect {
                                implicitWidth: aqiTextValue.contentWidth + 20
                                implicitHeight: aqiTextValue.contentHeight + 5
                                radius: Appearance.rounding.full
                                color: Colours.m3Colors.m3Primary

                                StyledText {
                                    id: aqiTextValue

                                    anchors.centerIn: parent
                                    text: aqiDelegate.modelData.value
                                    color: Colours.m3Colors.m3OnPrimary
                                    font.pixelSize: Appearance.fonts.size.large
                                }
                            }
                        }
                    }

                    TabBar {
                        id: tabGroup

                        implicitWidth: parent.width
                        implicitHeight: 35

                        Repeater {
                            model: ["United States AQI", "European AQI"]
                            delegate: TabButton {
                                id: buttonDelegate

                                required property var modelData
                                required property int index
                                implicitHeight: parent.height
                                text: modelData
                                contentItem: StyledText {
                                    text: buttonDelegate.modelData
                                    font.pixelSize: Appearance.fonts.size.large
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: tabGroup.currentIndex === buttonDelegate.index ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Primary
                                }
                                background: Rectangle {
                                    property real animatedRadius: tabGroup.currentIndex === buttonDelegate.index ? Appearance.rounding.full : 3

                                    color: tabGroup.currentIndex === buttonDelegate.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                                    topLeftRadius: (buttonDelegate.index === 0 || tabGroup.currentIndex === buttonDelegate.index) ? animatedRadius : 3
                                    bottomLeftRadius: (buttonDelegate.index === 0 || tabGroup.currentIndex === buttonDelegate.index) ? animatedRadius : 3
                                    topRightRadius: (buttonDelegate.index === 1 || tabGroup.currentIndex === buttonDelegate.index) ? animatedRadius : 3
                                    bottomRightRadius: (buttonDelegate.index === 1 || tabGroup.currentIndex === buttonDelegate.index) ? animatedRadius : 3

                                    Behavior on animatedRadius {
                                        NAnim {}
                                    }
                                }
                            }
                        }
                    }
                }
            }

            WrapperRectangle {
                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }
                margin: 20
                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3Surface
                implicitWidth: parent.width
                implicitHeight: aqiDescription.contentHeight + 20

                StyledText {
                    id: aqiDescription

                    text: column.description
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    font.weight: Font.DemiBold
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }
    }
}
