pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Control {
    id: root

    property date selectedDate: new Date()
    property date viewingDate: new Date()
    property bool hasSelection: false

    signal dateSelected(date d)

    implicitWidth: 320
    implicitHeight: 420

    property int monthGridCellWidth: 0
    property int monthGridCellHeight: 0

    component TextInputMode: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Appearance.margin.large * 2
            spacing: Appearance.spacing.large

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Enter date (YYYY-MM-DD)")
                font.pixelSize: Appearance.fonts.size.medium
                color: Colours.m3Colors.m3OnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
            }

            StyledTextInput {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                placeHolderText: "YYYY-MM-DD"
                passwordMode: false

                onAccepted: {
                    const parts = text.split("-");
                    if (parts.length === 3) {
                        const y = parseInt(parts[0]);
                        const m = parseInt(parts[1]) - 1;
                        const d = parseInt(parts[2]);
                        const parsed = new Date(y, m, d);
                        if (!isNaN(parsed.getTime()) && parsed.getFullYear() === y && parsed.getMonth() === m && parsed.getDate() === d) {
                            root.selectedDate = parsed;
                            root.hasSelection = true;
                            root.viewingDate = parsed;
                            root.dateSelected(parsed);
                        }
                    }
                }
            }
        }
    }

    component GridMode: Item {
        id: gridRoot

        property date currentViewingDate: root.viewingDate
        property int year: currentViewingDate.getFullYear()
        property int month: currentViewingDate.getMonth()
        property var monthNames: buildMonthNames()
        property bool showYearMonthPicker: false

        Component.onCompleted: Qt.callLater(() => {
            monthNames = buildMonthNames();
            if (Configs.generals.showHolidays)
                HolidayModel.ensureYear(year);
        })

        function buildMonthNames(): var {
            const locale = Qt.locale();
            return Array.from({
                length: 12
            }, (_, i) => locale.monthName(i));
        }

        onYearChanged: {
            if (Configs.generals.showHolidays)
                HolidayModel.ensureYear(year);
        }

        Connections {
            target: Configs.generals
            function onShowHolidaysChanged() {
                if (Configs.generals.showHolidays)
                    HolidayModel.ensureYear(gridRoot.year);
            }
        }

        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.normal * 0.5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: Appearance.spacing.normal

                StyledRect {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Appearance.rounding.full
                    color: "transparent"

                    Icon {
                        anchors.centerIn: parent
                        icon: "chevron_left"
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurface
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.viewingDate = new Date(gridRoot.year, gridRoot.month - 1, 1);
                        }
                    }
                }

                MArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: gridRoot.showYearMonthPicker = !gridRoot.showYearMonthPicker

                    StyledRect {
                        anchors.fill: parent
                        color: gridRoot.showYearMonthPicker ? Colours.m3Colors.m3SurfaceVariant : "transparent"
                        radius: Appearance.rounding.small

                        StyledText {
                            anchors.centerIn: parent
                            text: gridRoot.monthNames[gridRoot.month] + " " + gridRoot.year
                            font.pixelSize: Appearance.fonts.size.large
                            font.weight: 600
                            color: Colours.m3Colors.m3OnSurface
                        }
                    }
                }

                StyledRect {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Appearance.rounding.full
                    color: "transparent"

                    Icon {
                        anchors.centerIn: parent
                        icon: "chevron_right"
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurface
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.viewingDate = new Date(gridRoot.year, gridRoot.month + 1, 1);
                        }
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: gridRoot.showYearMonthPicker ? 1 : 0

                ColumnLayout {
                    spacing: 2

                    DayOfWeekRow {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        delegate: StyledRect {
                            id: dayDelegate

                            required property var model

                            implicitWidth: gridRoot.width / 7
                            implicitHeight: 28
                            color: "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: dayDelegate.model.shortName
                                font.pixelSize: Appearance.fonts.size.small
                                color: {
                                    if (dayDelegate.model.shortName === "Sun" || dayDelegate.model.shortName === "Sat")
                                        return Colours.m3Colors.m3Error;
                                    return Colours.m3Colors.m3OnSurfaceVariant;
                                }
                                font.weight: 500
                            }
                        }
                    }

                    MonthGrid {
                        id: mgrid

                        readonly property real cellWidth: gridRoot.width / 7
                        readonly property real cellHeight: (gridRoot.height - 72) / 7

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        month: gridRoot.month
                        year: gridRoot.year

                        delegate: StyledRect {
                            id: cell

                            required property var model
                            property date cellDate: model.date
                            property int dayOfWeek: cellDate.getDay()
                            property bool isToday: cellDate.toISOString().split("T")[0] === new Date().toISOString().split("T")[0]
                            property bool isSelected: root.hasSelection && cellDate.toISOString().split("T")[0] === root.selectedDate.toISOString().split("T")[0]
                            property bool isInMonth: model.month === gridRoot.month
                            property bool showHolidayDot: {
                                if (!Configs.generals.showHolidays)
                                    return false;
                                return HolidayModel.hasHoliday(cellDate);
                            }
                            property var holidayEntries: {
                                if (!Configs.generals.showHolidays)
                                    return [];
                                return HolidayModel.getHolidaysForDate(cellDate);
                            }

                            width: mgrid.cellWidth
                            height: mgrid.cellHeight

                            color: {
                                if (isSelected)
                                    return Colours.m3Colors.m3Primary;
                                if (cellMouse.containsMouse && isInMonth)
                                    return Colours.m3Colors.m3SurfaceVariant;
                                return "transparent";
                            }

                            radius: Appearance.rounding.small

                            border {
                                color: {
                                    if (isSelected && isToday)
                                        return Colours.m3Colors.m3OnPrimary;
                                    if (isToday && !isSelected)
                                        return Colours.m3Colors.m3Primary;
                                    return "transparent";
                                }
                                width: (isToday && !isSelected) || (isSelected && isToday) ? 2 : 0
                            }

                            MArea {
                                id: cellMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                visible: cell.isInMonth
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedDate = cell.cellDate;
                                    root.hasSelection = true;
                                    root.dateSelected(cell.cellDate);
                                }
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: (parent.height - holidayDots.height - implicitHeight - 2) / 2
                                text: Qt.formatDate(cell.cellDate, "d")
                                color: {
                                    if (cell.isSelected)
                                        return Colours.m3Colors.m3OnPrimary;
                                    if (cell.isToday)
                                        return Colours.m3Colors.m3Primary;
                                    const baseColor = (cell.dayOfWeek === 0 || cell.dayOfWeek === 6) ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface;
                                    return cell.isInMonth ? baseColor : Qt.alpha(baseColor, 0.2);
                                }
                                font.pixelSize: Appearance.fonts.size.small * 1.2
                                font.weight: cell.isSelected || cell.isToday ? 700 : (cell.isInMonth ? 500 : 100)
                            }

                            RowLayout {
                                id: holidayDots

                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.height / 2 + 2
                                spacing: 2
                                visible: cell.showHolidayDot

                                Repeater {
                                    model: Math.min(cell.holidayEntries.length, 3)

                                    StyledRect {
                                        required property int index

                                        implicitWidth: 4
                                        implicitHeight: 4
                                        radius: 2
                                        color: {
                                            const h = cell.holidayEntries[index];
                                            if (h && h.type === "leave")
                                                return Colours.m3Colors.m3Secondary;
                                            return Colours.m3Colors.m3Tertiary;
                                        }
                                    }
                                }

                                StyledText {
                                    text: cell.holidayEntries.length > 3 ? "+" + (cell.holidayEntries.length - 3) : ""
                                    font.pixelSize: Appearance.fonts.size.small * 0.65
                                    color: cell.isSelected ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurfaceVariant
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }

                YearMonthPicker {
                    currentYear: gridRoot.year
                    currentMonth: gridRoot.month

                    onMonthPicked: function (m) {
                        root.viewingDate = new Date(currentYear, m, 1);
                        gridRoot.showYearMonthPicker = false;
                    }
                    onYearPicked: function (y) {
                        root.viewingDate = new Date(y, currentMonth, 1);
                        gridRoot.showYearMonthPicker = false;
                    }
                }
            }
        }
    }

    background: StyledRect {
        color: Colours.m3Colors.m3SurfaceContainerLow
        radius: Appearance.rounding.large
        clip: true

        Elevation {
            anchors.fill: parent
            level: 2
            radius: parent.radius
        }
    }

    contentItem: ColumnLayout {
        id: contentCol

        spacing: 0

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Colours.m3Colors.m3PrimaryContainer
            radius: Appearance.rounding.large
            bottomLeftRadius: 0
            bottomRightRadius: 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.margin.large
                spacing: Appearance.spacing.normal

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: root.hasSelection ? root.selectedDate.toLocaleDateString(Qt.locale(), "dddd") : qsTr("Pick a date")
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnPrimaryContainer
                        font.weight: 600
                    }

                    StyledText {
                        text: root.hasSelection ? root.selectedDate.toLocaleDateString(Qt.locale(), Locale.LongFormat) : ""
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        color: Colours.m3Colors.m3OnPrimaryContainer
                        font.weight: 700
                    }
                }

                StyledRect {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Appearance.rounding.full
                    color: "transparent"

                    Icon {
                        anchors.centerIn: parent
                        icon: modeStack.currentIndex === 0 ? "edit" : "calendar_month"
                        font.pixelSize: Appearance.fonts.size.large * 1.2
                        color: Colours.m3Colors.m3OnPrimaryContainer
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modeStack.currentIndex = modeStack.currentIndex === 0 ? 1 : 0
                    }
                }
            }
        }

        StackLayout {
            id: modeStack

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            GridMode {}
            TextInputMode {}
        }
    }
}
