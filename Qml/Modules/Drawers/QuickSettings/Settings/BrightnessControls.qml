pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Menu
import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    property string targetId: ""

    readonly property bool multiDisplay: Brightness.displays.length > 1
    readonly property var selectedDisplay: Brightness.displays.find(d => d.id === root.targetId) ?? null

    spacing: Appearance.spacing.normal
    Connections {
        target: Brightness

        function onDisplaysChanged() {
            if (root.targetId !== "" && !root.selectedDisplay)
                root.targetId = "";
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        DropdownField {
            id: targetSelector

            visible: root.multiDisplay
            Layout.fillWidth: true
            implicitHeight: 36
            textRole: "display"
            valueRole: "value"
            model: root.multiDisplay ? [
                {
                    display: qsTr("All monitors"),
                    value: ""
                },
                ...Brightness.displays.map(d => ({
                            display: d.name,
                            value: d.id
                        }))] : []
            currentValue: root.targetId
            placeholderText: qsTr("All monitors")
            onActivated: index => root.targetId = targetSelector.model[index].value
        }

        StyledSlide {
            id: brightnessSlider

            Layout.fillWidth: true
            Layout.preferredHeight: 48

            icon: root.targetId === "" ? "brightness_5" : "monitor"
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
