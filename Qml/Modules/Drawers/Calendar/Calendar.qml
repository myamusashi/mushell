pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Widgets

Item {
    id: container

    anchors {
        top: parent.top
        right: parent.right
        rightMargin: Configs.generals.outerBorderSize
    }

    readonly property bool isCalendarShow: GlobalStates.isCalendarOpen
    property real cellWidth: (width - Appearance.margin.normal * 2) / 7

    implicitWidth: parent.width * 0.2
    implicitHeight: isCalendarShow ? 300 : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    CornerPair {
        location1: Qt.TopLeftCorner
        location2: Qt.BottomRightCorner
        extensionSide1: Qt.Horizontal
        extensionSide2: Qt.Vertical
        active: GlobalStates.isCalendarOpen
    }

    WrapperRectangle {
        anchors.fill: parent
        margin: Appearance.margin.normal
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Appearance.rounding.large

        Loader {
            id: contentLoader

            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && container.isCalendarShow // qmllint disable
            asynchronous: true
            sourceComponent: CalendarLayout {}
        }
    }

    component CalendarLayout: ColumnLayout {
        id: root

        property date currentDate: new Date()
        property int currentYear: currentDate.getFullYear()
        property int currentMonth: currentDate.getMonth()
        property var monthNames: buildMonthNames()
        property bool showYearMonthPicker: false

        spacing: Appearance.spacing.normal

        Component.onCompleted: Qt.callLater(() => {
            monthNames = buildMonthNames();
            if (Configs.generals.showHolidays)
                HolidayModel.ensureYear(root.currentYear);
        })

        function buildMonthNames(): var {
            const locale = Qt.locale();
            return Array.from({
                length: 12
            }, (_, i) => locale.monthName(i));
        }

        onCurrentYearChanged: {
            if (Configs.generals.showHolidays)
                HolidayModel.ensureYear(root.currentYear);
        }

        Timer {
            interval: 60000
            running: true
            repeat: true
            triggeredOnStart: false
            onTriggered: {
                const now = new Date();
                if (now.getDate() !== root.currentDate.getDate())
                    root.currentDate = now;
            }
        }

        Connections {
            target: Configs.generals
            function onShowHolidaysChanged() {
                if (Configs.generals.showHolidays)
                    HolidayModel.ensureYear(root.currentYear);
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                id: calendarContent
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.full
                        color: "transparent"

                        Icon {
                            anchors.centerIn: parent
                            icon: "chevron_left"
                            font.pixelSize: Appearance.fonts.size.large * 2
                            color: Colours.m3Colors.m3OnPrimaryContainer
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                monthGrid.closePopover();
                                root.currentMonth = root.currentMonth - 1;
                                if (root.currentMonth < 0) {
                                    root.currentMonth = 11;
                                    root.currentYear = root.currentYear - 1;
                                }
                            }
                        }
                    }

                    StyledText {
                        id: headerLabel

                        Layout.fillWidth: true
                        text: root.monthNames[root.currentMonth] + " " + root.currentYear
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: 600
                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large

                        MArea {
                            width: headerLabel.contentWidth
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                monthGrid.closePopover();
                                root.showYearMonthPicker = !root.showYearMonthPicker;
                            }
                        }
                    }

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.full
                        color: "transparent"

                        Icon {
                            anchors.centerIn: parent
                            icon: "chevron_right"
                            font.pixelSize: Appearance.fonts.size.large * 2
                            color: Colours.m3Colors.m3Primary
                        }

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                monthGrid.closePopover();
                                root.currentMonth = root.currentMonth + 1;
                                if (root.currentMonth > 11) {
                                    root.currentMonth = 0;
                                    root.currentYear = root.currentYear + 1;
                                }
                            }
                        }
                    }
                }

                CustomDayOfWeekRow {
                    id: dayOfWeekRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    delegate: Item {
                        id: dayOfWeekItem

                        required property var modelData
                        width: dayOfWeekRow.cellWidth
                        height: dayOfWeekRow.height

                        StyledText {
                            anchors.centerIn: parent
                            text: dayOfWeekItem.modelData.shortName
                            color: {
                                if (dayOfWeekItem.modelData.shortName === "Sun" || dayOfWeekItem.modelData.shortName === "Sat")
                                    return Colours.m3Colors.m3Error;
                                return Colours.m3Colors.m3OnSurface;
                            }
                            font.pixelSize: Appearance.fonts.size.small * 1.2
                            font.weight: 600
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: false

                    CustomMonthGrid {
                        id: monthGrid
                        anchors.fill: parent

                        cellHeight: 34
                        month: root.currentMonth
                        year: root.currentYear

                        delegate: Item {
                            id: dayCell

                            required property var modelData
                            required property int index

                            readonly property int gridColumn: index % 7
                            readonly property int gridRow: Math.floor(index / 7)

                            x: gridColumn * monthGrid.cellWidth
                            y: gridRow * monthGrid.cellHeight
                            width: monthGrid.cellWidth
                            height: monthGrid.cellHeight

                            property date cellDate: modelData.date
                            property int dayOfWeek: cellDate.getDay()
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

                            readonly property bool isToday: modelData.today
                            readonly property bool isCurrentMonth: modelData.month === root.currentMonth
                            readonly property int dayFontWeight: isToday ? 1000 : (isCurrentMonth ? 600 : 100)

                            readonly property bool isPopoverOpen: monthGrid.openPopoverDate !== null && new Date(monthGrid.openPopoverDate).toDateString() === dayCell.cellDate.toDateString()

                            StyledRect {
                                id: background
                                anchors.fill: parent
                                radius: Appearance.rounding.small
                                color: {
                                    if (dayCell.isPopoverOpen)
                                        return Colours.m3Colors.m3SurfaceContainerHigh;
                                    if (mouseArea.containsMouse && dayCell.isCurrentMonth)
                                        return Colours.m3Colors.m3SurfaceVariant;
                                    return "transparent";
                                }

                                MArea {
                                    id: mouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    visible: dayCell.isCurrentMonth
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (dayCell.showHoliday && dayCell.holidayLabel !== "") {
                                            monthGrid.openPopoverDate = dayCell.isPopoverOpen ? null : dayCell.cellDate;
                                        } else {
                                            monthGrid.closePopover();
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Appearance.rounding.small - 1
                                color: "transparent"
                                border {
                                    color: dayCell.isToday ? Colours.m3Colors.m3Primary : "transparent"
                                    width: dayCell.isToday ? 1.5 : 0
                                }
                                visible: dayCell.isToday && !mouseArea.containsMouse
                            }

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 2
                                spacing: 3

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Qt.formatDate(dayCell.cellDate, "d")
                                    color: {
                                        if (dayCell.isToday)
                                            return Colours.m3Colors.m3Primary;
                                        const baseColor = (dayCell.dayOfWeek === 0 || dayCell.dayOfWeek === 6) ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface;
                                        return dayCell.isCurrentMonth ? baseColor : Qt.alpha(baseColor, 0.2);
                                    }
                                    font.pixelSize: Appearance.fonts.size.small * 1.3
                                    font.weight: dayCell.dayFontWeight
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                RowLayout {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 3
                                    visible: dayCell.showHoliday

                                    Repeater {
                                        model: Math.min(dayCell.holidayEntries.length, 3)

                                        StyledRect {
                                            required property int index

                                            implicitWidth: 5
                                            implicitHeight: 5
                                            radius: 2.5
                                            color: {
                                                const entry = dayCell.holidayEntries[index];
                                                if (entry && entry.type === "leave")
                                                    return Colours.m3Colors.m3Secondary;
                                                return Colours.m3Colors.m3Tertiary;
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: dayCell.holidayEntries.length > 3 ? "+" + (dayCell.holidayEntries.length - 3) : ""
                                        font.pixelSize: Appearance.fonts.size.small * 0.65
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                        visible: text !== ""
                                    }
                                }
                            }
                        }

                        popoverDelegate: StyledRect {
                            id: popover

                            property var cellDate

                            readonly property var holidayEntries: cellDate ? HolidayModel.getHolidaysForDate(cellDate) : []
                            readonly property string holidayName: cellDate ? HolidayModel.nameForDate(cellDate) : ""

                            implicitHeight: popoverLabel.implicitHeight + 12
                            radius: Appearance.rounding.small
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            clip: true

                            border.color: Qt.alpha(Colours.m3Colors.m3Primary, 0.3)
                            border.width: 1

                            Behavior on implicitHeight {
                                NAnim {
                                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }

                            StyledText {
                                id: popoverLabel

                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                    margins: 8
                                }
                                text: popover.holidayName
                                font.pixelSize: Appearance.fonts.size.medium
                                color: Colours.m3Colors.m3OnSurface
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                            }

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monthGrid.closePopover()
                            }
                        }
                    }
                }
            }

            YearMonthPicker {
                anchors.fill: parent
                visible: root.showYearMonthPicker
                z: 10

                currentYear: root.currentYear
                currentMonth: root.currentMonth

                background: StyledRect {
                    color: GlobalStates.drawerColors
                    radius: Appearance.rounding.medium // qmllint disable
                }

                onMonthPicked: function (month) {
                    root.currentMonth = month;
                    root.showYearMonthPicker = false;
                }
                onYearPicked: function (year) {
                    root.currentYear = year;
                    root.showYearMonthPicker = false;
                }
            }
        }
    }
}
