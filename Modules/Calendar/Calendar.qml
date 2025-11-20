pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Components

LazyLoader {
    property bool isCalendarShow: false
    active: isCalendarShow

    component: PanelWindow {
        anchors {
            top: true
            right: true
        }

        property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
        property real monitorWidth: monitor.width / monitor.scale
        property real monitorHeight: monitor.height / monitor.scale
        implicitWidth: monitorWidth * 0.20
        implicitHeight: 350
        exclusiveZone: 1

        margins {
            right: 5
            left: (monitorWidth - implicitWidth) / 1
        }

        color: "transparent"

        StyledRect {
            id: container

            anchors.fill: parent

            color: Themes.m3Colors.background
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: root

                anchors.fill: parent

                anchors.margins: Appearance.margin.normal
                spacing: Appearance.spacing.normal

                property date currentDate: new Date()
                property int currentYear: currentDate.getFullYear()
                property int currentMonth: currentDate.getMonth()
                property int cellWidth: Math.floor((width - anchors.margins * 2) / 7.2)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: Appearance.spacing.normal

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.full
                        color: {
                            if (prevMArea.containsMouse && prevMArea.containsPress)
                                return Themes.withAlpha(Themes.m3Colors.primary, 0.12);
                            else if (prevMArea.containsMouse)
                                return Themes.withAlpha(Themes.m3Colors.primary, 0.08);
                            else
                                return "transparent";
                        }

                        MaterialIcon {
                            id: prevIcon

                            anchors.centerIn: parent
                            icon: "chevron_left"
                            font.pointSize: Appearance.fonts.large * 2
                            color: Themes.m3Colors.onPrimaryContainer
                        }

                        MArea {
                            id: prevMArea

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                root.currentMonth = root.currentMonth - 1;
                                if (root.currentMonth < 0) {
                                    root.currentMonth = 11;
                                    root.currentYear = root.currentYear - 1;
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const monthNames = Array.from({
                                "length": 12
                            }, (_, i) => Qt.locale().monthName(i, Qt.locale().LongFormat));
                            return monthNames[root.currentMonth] + " " + root.currentYear;
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: 600

                        color: Themes.m3Colors.onBackground
                        font.pixelSize: Appearance.fonts.large
                    }

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.full
                        color: {
                            if (nextMArea.containsMouse && nextMArea.containsPress)
                                return Themes.withAlpha(Themes.m3Colors.primary, 0.12);
                            else if (nextMArea.containsMouse)
                                return Themes.withAlpha(Themes.m3Colors.primary, 0.08);
                            else
                                return "transparent";
                        }

                        MaterialIcon {
                            id: nextIcon

                            anchors.centerIn: parent
                            icon: "chevron_right"
                            font.pointSize: Appearance.fonts.large * 2
                            color: Themes.m3Colors.primary
                        }

                        MArea {
                            id: nextMArea

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                root.currentMonth = root.currentMonth + 1;
                                if (root.currentMonth > 11) {
                                    root.currentMonth = 0;
                                    root.currentYear = root.currentYear + 1;
                                }
                            }
                        }
                    }
                }

                DayOfWeekRow {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    Layout.preferredHeight: 32

                    delegate: StyledRect {
                        id: daysOfWeekDelegate

                        required property var model

                        implicitWidth: root.cellWidth
                        implicitHeight: 32
                        color: "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: daysOfWeekDelegate.model.shortName
                            color: {
                                if (daysOfWeekDelegate.model.shortName === "Sun" || daysOfWeekDelegate.model.shortName === "Sat")
                                    return Themes.m3Colors.error;
                                else
                                    return Themes.m3Colors.onSurface;
                            }
                            font.pixelSize: Appearance.fonts.small * 1.2
                            font.weight: 600
                        }
                    }
                }

                MonthGrid {
                    id: monthGrid

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Appearance.spacing.small

                    property int cellWidth: root.cellWidth
                    property int cellHeight: Math.floor(height / 7)

                    month: root.currentMonth
                    year: root.currentYear

                    delegate: StyledRect {
                        id: dayItem

                        required property var model
                        property date cellDate: model.date
                        property int dayOfWeek: cellDate.getDay()

                        width: monthGrid.cellWidth
                        height: monthGrid.cellHeight

                        color: {
                            if (dayItem.model.today)
                                return Themes.m3Colors.primary;
                            else if (mouseArea.containsMouse && dayItem.model.month === root.currentMonth)
                                return Themes.m3Colors.surfaceVariant;

                            return "transparent";
                        }

                        radius: Appearance.rounding.small

                        implicitWidth: 40
                        implicitHeight: 40

                        MArea {
                            id: mouseArea

                            anchors.fill: parent

                            hoverEnabled: true

                            visible: dayItem.model.month === root.currentMonth
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {}
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: Qt.formatDate(dayItem.model.date, "d")
                            color: {
                                if (dayItem.model.today)
                                    return Themes.m3Colors.onPrimary;
                                else if (dayItem.dayOfWeek === 0 || dayItem.dayOfWeek === 6)
                                    return Themes.m3Colors.error;
                                else if (dayItem.model.month === root.currentMonth)
                                    return Themes.m3Colors.onSurface;
                                else {
                                    if (dayItem.dayOfWeek === 0 || dayItem.dayOfWeek === 6)
                                        return Themes.withAlpha(Themes.m3Colors.error, 0.2);
                                    else
                                        return Themes.withAlpha(Themes.m3Colors.onSurface, 0.2);
                                }
                            }
                            font.pixelSize: Appearance.fonts.small * 1.3
                            font.weight: {
                                if (dayItem.model.today)
                                    return 1000;
                                else if (dayItem.model.month === root.currentMonth)
                                    return 600;
                                else
                                    return 100;
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
