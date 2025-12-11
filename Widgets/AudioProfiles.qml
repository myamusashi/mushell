pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ComboBox {
    id: profilesComboBox

    model: Audio.models
    textRole: "readable"
    implicitWidth: 250
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
            color: Colours.m3Colors.m3OnBackground
            visible: false
        }
    }

    contentItem: StyledText {
        leftPadding: Appearance.padding.normal
        rightPadding: profilesComboBox.indicator.width + profilesComboBox.spacing
        text: {
            for (var i = 0; i < Audio.models.length; i++)
            if (Audio.models[i].index == Audio.activeProfileIndex)
            return Audio.models[i].readable;

            return Audio.models[-1].readable;
        }
        font.weight: Font.DemiBold
        font.pixelSize: Appearance.fonts.large
        color: Colours.m3Colors.m3OnBackground
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
            color: itemDelegate.highlighted ? Colours.m3Colors.m3Primary : itemDelegate.hovered ? itemDelegate.modelData.available !== "yes" ? "transparent" : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.1) : "transparent"
        }

        contentItem: StyledText {
            text: itemDelegate.modelData.readable
            color: itemDelegate.modelData.available !== "yes" ? Colours.m3Colors.m3OutlineVariant : Colours.m3Colors.m3OnBackground
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
                context.fillStyle = Colours.m3Colors.m3OnBackground;
                context.fill();
            }
        }

        StyledRect {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: Appearance.rounding.large
            color: "transparent"

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
            color: Colours.m3Colors.m3SurfaceContainerLow
            radius: Appearance.rounding.small
        }

        contentItem: ScrollView {
            clip: true
            implicitHeight: itemColumn.implicitHeight

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical: ScrollBar {
                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: Appearance.rounding.small
                    color: "transparent"
                }
            }

            Column {
                id: itemColumn
                width: parent.width

                Repeater {
                    model: profilesComboBox.popup.visible ? profilesComboBox.delegateModel : null

                    delegate: ItemDelegate {
                        id: delegate
                        required property var modelData
                        required property int index
                        width: parent.width
                        padding: Appearance.padding.normal
                        highlighted: profilesComboBox.highlightedIndex === index
                        enabled: modelData.available === "yes"

                        background: StyledRect {
                            color: delegate.highlighted ? Colours.m3Colors.m3Primary : delegate.hovered ? (delegate.modelData.available !== "yes" ? "transparent" : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.1)) : "transparent"
                        }

                        contentItem: StyledText {
                            text: delegate.modelData.readable
                            color: delegate.modelData.available !== "yes" ? Colours.m3Colors.m3OutlineVariant : delegate.highlighted ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
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
                                        "command": ["sh", "-c", `pw-cli set-param ${Audio.idPipewire} Profile '{ \"index\": ${profile.index}}'`]
                                    });
            Audio.activeProfileIndex = profile.index;
        }
    }
}
