pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Components
import qs.Configs
import qs.Services

ClippingRectangle {
    id: root

    required property int state
    signal tabClicked(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: columnContent.implicitHeight
    color: Colours.m3Colors.m3SurfaceContainerHigh

    ColumnLayout {
        id: columnContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Header {
            id: tabLayout
        }

		StyledRect {
			Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.m3Colors.m3OutlineVariant
        }

        View {
            id: audioCaptureStackView
        }
    }

    component Header: TabRow {
        state: root.state
        scaleFactor: Math.min(1.0, root.width / root.width)
        visible: true
        backgroundColor: "transparent"
        Layout.fillWidth: true
        tabs: [
            {
                "title": "Mix",
            },
            {
                "title": "Voice",
            }
        ]
        onTabClicked: root.tabClicked(root.state)
    }

    component View: StackView {
        property Component viewComponent: contentView

        Layout.fillWidth: true
        Layout.preferredHeight: 250

        initialItem: viewComponent
        onCurrentItemChanged: {
            if (currentItem)
                currentItem.viewIndex = root.state;
        }

        Component {
            id: contentView

            StyledRect {
                implicitHeight: 250
                property int viewIndex: 0

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 0
                    visible: active

                    sourceComponent: Mix {}
                }

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 1
                    visible: active

                    sourceComponent: Voice {}
                }
            }
        }
    }

    component Mix: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.rightMargin: 10
        anchors.leftMargin: 10
        spacing: Appearance.spacing.normal
        StyledLabel {
            text: "LINUX DEFAULT OUTPUT"
            font.pixelSize: Appearance.fonts.large
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            implicitHeight: contentLayout.implicitHeight
            clip: true

            RowLayout {
                id: contentLayout

                anchors.fill: parent
                Layout.margins: 15
                spacing: 20

                ColumnLayout {
                    Layout.margins: 10
                    Layout.alignment: Qt.AlignTop

                    PwNodeLinkTracker {
                        id: linkTracker

                        node: Pipewire.defaultAudioSink
                    }

                    CustomMixerEntry {
                        useCustomProperties: false
                        node: Pipewire.defaultAudioSink
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3Outline
                        implicitHeight: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        Repeater {
                            model: linkTracker.linkGroups

                            delegate: Item {
                                id: delegateTracker

                                required property PwLinkGroup modelData
                                Layout.fillWidth: true
                                implicitHeight: rowLayout.implicitHeight

                                RowLayout {
                                    id: rowLayout

                                    anchors.fill: parent
                                    spacing: 10

                                    IconImage {
                                        source: Quickshell.iconPath(Players.active.desktopEntry)
                                        asynchronous: true
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    CustomMixerEntry {
                                        Layout.fillWidth: true
                                        useCustomProperties: false
                                        node: delegateTracker.modelData.source
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
    component Voice: ColumnLayout {}
}
