pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Widgets
import qs.Components

ClippingRectangle {
    id: root

    required property int state
    signal tabClicked(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: columnContent.implicitHeight
    color: Themes.m3Colors.m3SurfaceContainerHigh

    ColumnLayout {
        id: columnContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
		spacing: 0

        Header {
            id: tabLayout
        }

        View {
            id: audioCaptureStackView
        }
    }

    component Header: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        RowLayout {
            id: tabRowLayout

            anchors.fill: parent
            anchors.margins: 5
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: Appearance.spacing.large

            Repeater {
                id: tabRepeater

                model: [
                    {
                        "title": "Mix",
                        "index": 0
                    },
                    {
                        "title": "Voice",
                        "index": 1
                    }
                ]

                StyledButton {
                    id: audioTabButton

                    required property var modelData
                    required property int index
                    buttonTitle: modelData.title
                    Layout.preferredWidth: implicitWidth
                    buttonColor: "transparent"
                    highlighted: root.state === index
                    flat: root.state !== index
                    onClicked: root.tabClicked(index)

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: audioTabButton.modelData.title
                        color: root.state === audioTabButton.index ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.large * 1.5
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Themes.m3Colors.m3OutlineVariant
        }

        StyledRect {
            id: indicator

            anchors.bottom: parent.bottom
            width: tabRepeater.itemAt(root.state) ? tabRepeater.itemAt(root.state).width : 0
            height: 5
            color: Themes.m3Colors.m3Primary
            radius: Appearance.rounding.large
            x: {
                var item = tabRepeater.itemAt(root.state);
                if (item)
                    return item.x + tabRowLayout.anchors.leftMargin;
                return 0;
            }
            visible: tabRepeater.itemAt(root.state) !== null

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
                        useCustomProperties: true
                        node: Pipewire.defaultAudioSink

                        customProperty: audioProfilesComboBox
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: Themes.m3Colors.m3Outline
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

                    Component {
                        id: audioProfilesComboBox

                        ComboBox {
                            id: profilesComboBox

                            model: Audio.models
                            textRole: "readable"
                            implicitWidth: 250
                            currentIndex: {
                                for (var i = 0; i < Audio.models.length; i++)
                                    if (Audio.models[i].index === Audio.activeProfileIndex)
                                        return i;

                                return -1;
                            }
                            height: contentItem.implicitHeight * 3

                            MArea {
                                id: mArea

                                layerColor: "transparent"
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                z: -1
                            }

                            background: StyledRect {
                                implicitWidth: 250
                                radius: 4

                                Rectangle {
                                    x: 12
                                    y: 0
                                    height: 40
                                    color: Themes.m3Colors.m3OnBackground
                                    visible: true
                                }
                            }

                            contentItem: StyledText {
                                leftPadding: Appearance.padding.normal
                                rightPadding: profilesComboBox.indicator.width + profilesComboBox.spacing
                                text: profilesComboBox.displayText
                                font.weight: Font.DemiBold
                                font.pixelSize: Appearance.fonts.large
                                color: Themes.m3Colors.m3OnBackground
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            delegate: ItemDelegate {
                                id: itemDelegate

                                required property var modelData
                                required property int index
                                width: profilesComboBox.width
                                padding: Appearance.padding.normal

                                background: StyledRect {
                                    color: itemDelegate.highlighted ? Themes.m3Colors.m3Primary : itemDelegate.hovered ? itemDelegate.modelData.available !== "yes" ? "transparent" : Themes.withAlpha(Themes.m3Colors.m3Primary, 0.1) : "transparent"
                                }

                                contentItem: StyledText {
                                    text: itemDelegate.modelData.readable
                                    color: itemDelegate.modelData.available !== "yes" ? Themes.m3Colors.m3OutlineVariant : Themes.m3Colors.m3OnBackground
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                enabled: modelData.available === "yes"
                            }

                            indicator: Item {
                                x: profilesComboBox.width - width - 12
                                y: profilesComboBox.topPadding + (profilesComboBox.availableHeight - height) / 2
                                width: 24
                                height: 24

                                Canvas {
                                    id: canvas

                                    anchors.centerIn: parent
                                    width: 10
                                    height: 5
                                    contextType: "2d"

                                    Connections {
                                        target: profilesComboBox
                                        function onPressedChanged() {
                                            canvas.requestPaint();
                                        }
                                    }

                                    Component.onCompleted: requestPaint()

                                    onPaint: {
                                        context.reset();
                                        context.moveTo(0, 0);
                                        context.lineTo(width, 0);
                                        context.lineTo(width / 2, height);
                                        context.closePath();
                                        context.fillStyle = Themes.m3Colors.m3OnBackground;
                                        context.fill();
                                    }
                                }

                                StyledRect {
                                    anchors.centerIn: parent
                                    width: 40
                                    height: 40
                                    radius: Appearance.rounding.large
                                    color: "transparent"
                                    opacity: profilesComboBox.pressed ? 0.12 : profilesComboBox.hovered ? 0.08 : 0

                                    Behavior on opacity {
                                        NAnim {}
                                    }
                                }
                            }

                            popup: Popup {
                                y: profilesComboBox.height
                                width: profilesComboBox.width
                                implicitHeight: contentItem.implicitHeight
                                height: Math.min(implicitHeight, 250)
                                padding: Appearance.padding.normal

                                background: StyledRect {
                                    color: Themes.m3Colors.m3SurfaceContainerLow
                                    radius: Appearance.rounding.small
                                }

                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight - 5
                                    model: profilesComboBox.popup.visible ? profilesComboBox.delegateModel : null
                                    currentIndex: profilesComboBox.highlightedIndex

                                    ScrollIndicator.vertical: ScrollIndicator {
                                        contentItem: StyledRect {
                                            implicitWidth: 4
                                            radius: Appearance.rounding.small
                                            color: Themes.withAlpha(Themes.m3Colors.m3Primary, 0.1)
                                        }
                                    }
                                }

                                enter: Transition {
                                    NAnim {
                                        property: "opacity"
                                        from: 0.0
                                        to: 1.0
                                    }
                                    NAnim {
                                        property: "scale"
                                        from: 0.9
                                        to: 1.0
                                    }
                                }

                                exit: Transition {
                                    NAnim {
                                        property: "scale"
                                        from: 1.0
                                        to: 0.9
                                    }
                                    NAnim {
                                        property: "opacity"
                                        from: 1.0
                                        to: 0.0
                                    }
                                }
                            }

                            onActivated: index => {
                                const profile = Audio.models[index];
                                if (profile && profile.available === "yes") {
                                    Quickshell.execDetached({
                                        command: ["sh", "-c", `pw-cli set-param ${Audio.idPipewire} Profile '{ \"index\": ${profile.index}}'`]
                                    });
                                    Audio.activeProfileIndex = profile.index;
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
