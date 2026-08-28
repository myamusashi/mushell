pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var modelData
    required property int index
    required property int currentMonth
    required property real cellWidth
    required property int cellHeight
    required property var openPopoverDate

    signal openPopoverRequested(var date)
    signal closePopoverRequested

    readonly property int gridColumn: index % 7
    readonly property int gridRow: Math.floor(index / 7)
    readonly property date cellDate: modelData.date
    readonly property int dayOfWeek: cellDate.getDay()
    readonly property bool isToday: modelData.today
    readonly property bool isCurrentMonth: modelData.month === root.currentMonth
    readonly property int dayFontWeight: isToday ? 1000 : (isCurrentMonth ? 600 : 100)
    readonly property bool isPopoverOpen: openPopoverDate !== null && new Date(openPopoverDate).toDateString() === cellDate.toDateString()

    property bool showHoliday: {
        if (!Configs.generals.showHolidays)
            return false;
        return HolidayModel.hasHoliday(cellDate);
    }

    property var holidayEntries: {
        if (!Configs.generals.showHolidays)
            return [];
        return HolidayModel.getHolidaysForDate(cellDate);
    }

    property string holidayLabel: {
        if (!Configs.generals.showHolidays)
            return "";
        return HolidayModel.nameForDate(cellDate);
    }

    x: gridColumn * root.cellWidth
    y: gridRow * root.cellHeight
    width: root.cellWidth
    height: root.cellHeight

    StyledRect {
        id: background

        anchors.fill: parent
        radius: Appearance.rounding.small
        color: {
            if (root.isPopoverOpen)
                return Colours.m3Colors.m3SurfaceContainerHigh;
            if (mouseArea.containsMouse && root.isCurrentMonth)
                return Colours.m3Colors.m3SurfaceVariant;
            return "transparent";
        }

        MArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            visible: root.isCurrentMonth
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.showHoliday && root.holidayLabel !== "") {
                    if (root.isPopoverOpen)
                        root.closePopoverRequested();
                    else
                        root.openPopoverRequested(root.cellDate);
                } else {
                    root.closePopoverRequested();
                }
            }
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: 1
        radius: Appearance.rounding.small - 1
        color: "transparent"
        border.color: root.isToday ? Colours.m3Colors.m3Primary : "transparent"
        border.width: root.isToday ? 1.5 : 0
        visible: root.isToday && !mouseArea.containsMouse
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 2
        spacing: 3

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.cellDate, "d")
            color: {
                if (root.isToday)
                    return Colours.m3Colors.m3Primary;
                const baseColor = (root.dayOfWeek === 0 || root.dayOfWeek === 6) ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface;
                return root.isCurrentMonth ? baseColor : Qt.alpha(baseColor, 0.2);
            }
            font.pixelSize: Appearance.fonts.size.small * 1.3
            font.weight: root.dayFontWeight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            visible: root.showHoliday

            Repeater {
                model: Math.min(root.holidayEntries.length, 3)

                StyledRect {
                    required property int index

                    implicitWidth: 5
                    implicitHeight: 5
                    radius: 2.5
                    color: {
                        const entry = root.holidayEntries[index];
                        if (entry && entry.type === "leave")
                            return Colours.m3Colors.m3Secondary;
                        return Colours.m3Colors.m3Tertiary;
                    }
                }
            }

            StyledText {
                text: root.holidayEntries.length > 3 ? "+" + (root.holidayEntries.length - 3) : ""
                font.pixelSize: Appearance.fonts.size.small * 0.65
                color: Colours.m3Colors.m3OnSurfaceVariant
                visible: text !== ""
            }
        }
    }
}
