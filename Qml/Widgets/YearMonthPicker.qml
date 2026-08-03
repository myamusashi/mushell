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

    property int currentYear
    property int currentMonth
    property int startYear: currentYear - 10

    signal monthPicked(int month)
    signal yearPicked(int year)

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.normal * 0.5

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Appearance.rounding.full
                color: "transparent"

                Icon {
                    anchors.centerIn: parent
                    icon: "chevron_left"
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startYear = Math.max(1900, root.startYear - 10)
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.startYear + " \u2013 " + (root.startYear + 9)
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.fonts.size.medium
                color: Colours.m3Colors.m3OnSurface
                font.weight: 600
            }

            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Appearance.rounding.full
                color: "transparent"

                Icon {
                    anchors.centerIn: parent
                    icon: "chevron_right"
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startYear += 10
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 5
            rows: 2
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 10

                delegate: StyledRect {
                    id: yearDelegate

                    required property int index
                    readonly property int yr: root.startYear + index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.small

                    color: yr === root.currentYear ? Colours.m3Colors.m3PrimaryContainer : "transparent"

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.yearPicked(yearDelegate.yr)
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: yearDelegate.yr
                        font.pixelSize: Appearance.fonts.size.medium
                        color: yearDelegate.yr === root.currentYear ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                        font.weight: yearDelegate.yr === root.currentYear ? 700 : 400
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            rows: 3
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 12

                delegate: StyledRect {
                    id: monthDelegate

                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.small
                    color: {
                        if (index === root.currentMonth)
                            return Colours.m3Colors.m3PrimaryContainer;
                        return "transparent";
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.monthPicked(monthDelegate.index)
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Qt.locale().monthName(monthDelegate.index, Locale.ShortFormat)
                        font.pixelSize: Appearance.fonts.size.small
                        color: {
                            if (monthDelegate.index === root.currentMonth)
                                return Colours.m3Colors.m3OnPrimaryContainer;
                            return Colours.m3Colors.m3OnSurface;
                        }
                        font.weight: monthDelegate.index === root.currentMonth ? 600 : 400
                    }
                }
            }
        }
    }
}
