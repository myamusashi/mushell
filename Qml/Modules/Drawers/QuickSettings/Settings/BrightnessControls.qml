pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    property string targetId: ""

    readonly property bool multiDisplay: Brightness.displays.length > 1
    readonly property var selectedDisplay: Brightness.displays.find(d => d.id === root.targetId) ?? null
    readonly property var targets: root.multiDisplay ? [
        {
            display: qsTr("All"),
            value: ""
        },
        ...Brightness.displays.map(d => ({
                    display: d.isInternal ? qsTr("Internal") : String(d.name).split(" ")[0],
                    value: d.id
                }))] : []
    readonly property int selectedIndex: root.targets.findIndex(t => t.value === root.targetId)

    spacing: Appearance.spacing.normal

    Connections {
        target: Brightness

        function onDisplaysChanged() {
            if (root.targetId !== "" && !root.selectedDisplay)
                root.targetId = "";
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 55
        radius: Appearance.rounding.small
        color: "transparent"
        border {
            width: 2
            color: Colours.m3Colors.m3Outline
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.small
            }

            StyledRect {
                id: targetChip

                visible: root.multiDisplay
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: chipRow.implicitWidth + Appearance.padding.normal * 1.5
                implicitHeight: 48

                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3SurfaceContainer

                Row {
                    id: chipRow

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.targets[root.selectedIndex]?.display ?? qsTr("All")
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurface
                    }

                    Item {
                        readonly property int size: 16

                        width: size
                        height: size
                        rotation: targetMenu.opened ? 180 : 0

                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on rotation {
                            NAnim {}
                        }

                        Icon {
                            anchors.centerIn: parent
                            icon: "keyboard_arrow_down"
                            font.pixelSize: Appearance.fonts.size.larger
                            color: Colours.m3Colors.m3OnSurfaceVariant
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: targetMenu.opened ? targetMenu.close() : targetMenu.open()
                }

                DropdownMenu {
                    id: targetMenu

                    anchorItem: targetChip
                    textRole: "display"
                    model: root.targets
                    currentIndex: root.selectedIndex
                    onActivated: index => root.targetId = root.targets[index].value
                }
            }

            StyledSlide {
                id: brightnessSlider

                Layout.fillWidth: true
                Layout.preferredHeight: 45

                icon: "brightness_5"
                iconSize: Appearance.fonts.size.large * 1.5
                to: Brightness.maxValue || 1

                value: brightnessSlider.pressed ? brightnessSlider.value : (root.selectedDisplay?.brightness ?? Brightness.value)
                onMoved: {
                    if (root.targetId === "")
                        Brightness.setBrightnessAll(brightnessSlider.value);
                    else
                        Brightness.setBrightnessForDisplay(root.targetId, brightnessSlider.value);
                }
            }
        }
    }

    ExtendedFloatingButton {
        readonly property color inactiveTextColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
        readonly property color inactiveButtonColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

        icon.name: "bedtime"
        icon.color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : inactiveTextColor
        textColor: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : inactiveTextColor
        color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3Primary : inactiveButtonColor
        text: qsTr("Night mode")

        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
    }
}
