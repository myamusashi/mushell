pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Services
import qs.Components

Item {
    id: root

    property int maxColumns: {
        const w = Hypr.focusedMonitor.width / Hypr.focusedMonitor.scale;
        return Math.max(1, Math.min(5, Math.floor(w / 512) + 1));
    }
    property int maxRows: 3
    property int itemSpacing: Appearance.spacing.normal
    property int pageSpacing: 20
    property var widgetsList: Configs.widgets.lists
    readonly property int itemsPerPage: maxColumns * maxRows
    readonly property int totalPages: Math.ceil(widgetsList.length / itemsPerPage)
    readonly property int currentPageIndex: Math.floor(swipeView.contentX / swipeView.width)

    implicitWidth: parent.width
    implicitHeight: 220

    Flickable {
        id: swipeView

        anchors.fill: parent
        contentWidth: root.totalPages * width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 5000
        maximumFlickVelocity: 2500

        onMovementEnded: {
            var targetPage = Math.round(contentX / width);
            snapAnimation.to = targetPage * width;
            snapAnimation.start();
        }

        onFlickEnded: {
            var targetPage = Math.round(contentX / width);
            snapAnimation.to = targetPage * width;
            snapAnimation.start();
        }

        NAnim {
            id: snapAnimation

            target: swipeView
            property: "contentX"
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }

        Row {
            id: pagesContainer

            spacing: root.pageSpacing
            height: parent.height

            Repeater {
                model: root.totalPages

                delegate: Item {
                    id: pageItem

                    width: swipeView.width
                    height: swipeView.height

                    required property int index
                    readonly property int startIndex: index * root.itemsPerPage
                    readonly property int endIndex: Math.min(startIndex + root.itemsPerPage, root.widgetsList.length)
                    readonly property var pageWidgets: root.widgetsList.slice(startIndex, endIndex)

                    GridLayout {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        columns: root.maxColumns
                        rowSpacing: root.itemSpacing
                        columnSpacing: root.itemSpacing

                        Repeater {
                            model: pageItem.pageWidgets

                            delegate: StyledButton {
                                id: button

                                required property var modelData
                                required property int index

                                textSize: Appearance.fonts.size.normal
                                fontFamily: Appearance.fonts.family.mono
                                iconBackgroundColor: Colours.m3Colors.m3Primary
                                buttonHeight: 50
                                buttonWidth: 165
                                iconBackgroundSize: height - 10
                                iconBackgroundRadius: Appearance.rounding.small
                                showIconBackground: true
                                useLayoutWidth: true
                                iconButton: modelData.icon
                                buttonTitle: modelData.title
                                buttonColor: Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.1)
                                buttonTextColor: Colours.m3Colors.m3OnSurface
                                enabled: modelData.condition
                                mArea.layerColor: "transparent"

                                onClicked: Quickshell.execDetached({
                                    command: ["sh", "-c", modelData.action]
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 12
        spacing: 8

        Repeater {
            model: root.totalPages

            delegate: Rectangle {
                required property int index

                width: root.currentPageIndex === index ? 24 : 8
                height: 8
                radius: Appearance.rounding.small

                color: root.currentPageIndex === index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                opacity: root.currentPageIndex === index ? 1.0 : 0.5

                Behavior on width {
                    NAnim {
                        duration: Appearance.animations.durations.emphasized
                        easing.bezierCurve: Appearance.animations.curves.emphasized
                    }
                }

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.emphasized
                        easing.bezierCurve: Appearance.animations.curves.emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        property real startX: 0
        property real startContentX: 0

        onPressed: function (mouse) {
            startX = mouse.x;
            startContentX = swipeView.contentX;
            mouse.accepted = false;
        }

        onPositionChanged: function (mouse) {
            if (pressed) {
                var delta = startX - mouse.x;
                swipeView.contentX = startContentX + delta;
            }
            mouse.accepted = false;
        }
    }
}
