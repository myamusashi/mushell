pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
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

            SplitButton {
                id: splitButton

                Layout.alignment: Qt.AlignVCenter
                model: root.targets
                textRole: "display"
                currentIndex: root.selectedIndex
                icon.name: "tv_displays"
                text: root.targets[root.selectedIndex]?.display ?? qsTr("All")
                onMenuItemActivated: index => root.targetId = root.targets[index].value
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

    FloatingButton {
        icon.name: "bedtime"
        icon.color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
        color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3Primary, 0.3)

        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
    }
}
