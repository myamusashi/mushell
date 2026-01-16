pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    property bool isOpen: false
    property string descriptions: ""

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
        path: Qt.resolvedUrl("./Markdown/Visibility.md")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.descriptions = text()
    }

    Loader {
        active: root.isOpen

        sourceComponent: Column {
            spacing: Appearance.spacing.normal

            Header {
                icon: Lucide.icon_eye
                title: "Visibility"
                mouseArea.onClicked: root.isOpen = false
            }

            ClippingRectangle {
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer
                implicitWidth: parent.width
                implicitHeight: parent.height * 0.1

                Item {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    implicitWidth: parent.width

                    MaterialShape {
                        anchors.left: parent.left
                        anchors.leftMargin: -20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.lighter(Colours.m3Colors.m3OnPrimary, 1.1)
                        shape: MaterialShape.Cookie9Sided
                        implicitHeight: parent.height * 2
                        implicitWidth: parent.height * 2
                        z: 3
                    }

                    MaterialShape {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.m3Colors.m3OnPrimary
                        opacity: 0.8
                        shape: MaterialShape.Cookie9Sided
                        implicitHeight: parent.height * 2
                        implicitWidth: parent.height * 2
                        z: 2
                    }

                    MaterialShape {
                        x: 30
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.m3Colors.m3OnPrimary
                        opacity: 0.6
                        shape: MaterialShape.Cookie9Sided
                        implicitHeight: parent.height * 2
                        implicitWidth: parent.height * 2
                        z: 1
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.large

                    StyledText {
                        Layout.alignment: Qt.AlignCenter | Qt.AlignLeft
                        text: "Current conditions"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignCenter | Qt.AlignLeft
                        implicitWidth: parent.width
                        spacing: Appearance.spacing.normal

                        StyledText {
                            text: parseInt(Weather.visibility)
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            font.weight: Font.Bold
                        }

                        StyledText {
                            text: "Km"
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            font.weight: Font.DemiBold
                        }
                    }

                    Item {
                        implicitHeight: parent.height
                    }
                }
            }

            WrapperRectangle {
                border {
                    width: 1
                    color: Colours.m3Colors.m3Outline
                }
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3Surface
                implicitWidth: parent.width
                implicitHeight: description.contentHeight + 15
                margin: 10

                StyledText {
                    id: description

                    text: root.descriptions
                    color: Colours.m3Colors.m3OnSurface
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }
    }
}
