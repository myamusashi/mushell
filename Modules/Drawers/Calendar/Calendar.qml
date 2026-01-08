pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: container

    anchors {
        top: parent.top
        right: parent.right
    }

    property bool isCalendarShow: GlobalStates.isCalendarOpen
    property int cellWidth: Math.floor((width - anchors.margins * 2) / 7.2)

    implicitWidth: parent.width * 0.2
    implicitHeight: isCalendarShow ? 350 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on cellWidth {
        enabled: false
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isCalendarOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isCalendarOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    StyledRect {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        bottomLeftRadius: Appearance.rounding.large

        Loader {
            anchors.fill: parent
            active: window.modelData.name === Hypr.focusedMonitor.name && container.isCalendarShow
            asynchronous: true
            sourceComponent: ColumnLayout {
                id: root

                anchors.fill: parent
                anchors.margins: Appearance.margin.normal
                visible: container.isCalendarShow
                spacing: Appearance.spacing.normal

                readonly property var monthNames: {
                    const locale = Qt.locale();
                    return Array.from({
                        length: 12
                    }, (_, i) => locale.monthName(i));
                }
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
                        color: "transparent"

                        Icon {
                            id: prevIcon

                            anchors.centerIn: parent
                            icon: "chevron_left"
                            font.pointSize: Appearance.fonts.size.large * 2
                            color: Colours.m3Colors.m3OnPrimaryContainer
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
                        text: root.monthNames[root.currentMonth] + " " + root.currentYear
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: 600

                        color: Colours.m3Colors.m3OnBackground
                        font.pixelSize: Appearance.fonts.size.large
                    }

                    StyledRect {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: Appearance.rounding.full
                        color: "transparent"

                        Icon {
                            id: nextIcon

                            anchors.centerIn: parent
                            icon: "chevron_right"
                            font.pointSize: Appearance.fonts.size.large * 2
                            color: Colours.m3Colors.m3Primary
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
                                    return Colours.m3Colors.m3Error;
                                else
                                    return Colours.m3Colors.m3OnSurface;
                            }
                            font.pixelSize: Appearance.fonts.size.small * 1.2
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
                                return Colours.m3Colors.m3Primary;
                            else if (mouseArea.containsMouse && dayItem.model.month === root.currentMonth)
                                return Colours.m3Colors.m3SurfaceVariant;

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
                                    return Colours.m3Colors.m3OnPrimary;
                                else if (dayItem.dayOfWeek === 0 || dayItem.dayOfWeek === 6)
                                    return Colours.m3Colors.m3Error;
                                else if (dayItem.model.month === root.currentMonth)
                                    return Colours.m3Colors.m3OnSurface;
                                else {
                                    if (dayItem.dayOfWeek === 0 || dayItem.dayOfWeek === 6)
                                        return Colours.withAlpha(Colours.m3Colors.m3Error, 0.2);
                                    else
                                        return Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.2);
                                }
                            }
                            font.pixelSize: Appearance.fonts.size.small * 1.3
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
