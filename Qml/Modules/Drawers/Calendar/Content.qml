pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Widgets

ColumnLayout {
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
            HolidayModel.ensureYear(currentYear);
    })

    function buildMonthNames(): var {
        const locale = Qt.locale();
        return Array.from({
            length: 12
        }, (_, i) => locale.monthName(i));
    }

    onCurrentYearChanged: {
        if (Configs.generals.showHolidays)
            HolidayModel.ensureYear(currentYear);
    }

    Timer {
        id: dateTimer

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

            Header {
                id: calendarHeader

                monthNames: root.monthNames
                currentMonth: root.currentMonth
                currentYear: root.currentYear
                onPrevClicked: {
                    monthGrid.closePopover();
                    root.currentMonth = root.currentMonth - 1;
                    if (root.currentMonth < 0) {
                        root.currentMonth = 11;
                        root.currentYear = root.currentYear - 1;
                    }
                }
                onNextClicked: {
                    monthGrid.closePopover();
                    root.currentMonth = root.currentMonth + 1;
                    if (root.currentMonth > 11) {
                        root.currentMonth = 0;
                        root.currentYear = root.currentYear + 1;
                    }
                }
                onTitleClicked: {
                    monthGrid.closePopover();
                    root.showYearMonthPicker = !root.showYearMonthPicker;
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

                    delegate: DayCell {
                        currentMonth: root.currentMonth
                        cellWidth: monthGrid.cellWidth
                        cellHeight: monthGrid.cellHeight
                        openPopoverDate: monthGrid.openPopoverDate
                        onOpenPopoverRequested: date => monthGrid.openPopoverDate = date
                        onClosePopoverRequested: monthGrid.closePopover()
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

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
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
