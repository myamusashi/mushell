pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int month: 0
    property int year: 1970
    property Component delegate: null

    property int firstDayOfWeek: Qt.locale().firstDayOfWeek

    property real cellWidth: width / 7
    property int cellHeight: 34

    readonly property int rowCount: 6
    readonly property int columnCount: 7

    implicitWidth: cellWidth * columnCount
    implicitHeight: cellHeight * rowCount
    property Component popoverDelegate: null
    property var openPopoverDate: null

    function closePopover() {
        root.openPopoverDate = null;
    }

    function buildCells() {
        const cells = [];
        const firstOfMonth = new Date(root.year, root.month, 1);
        const firstDow = firstOfMonth.getDay();

        let lead = firstDow - root.firstDayOfWeek;
        if (lead < 0)
            lead += 7;

        const gridStart = new Date(root.year, root.month, 1 - lead);
        const today = new Date();

        for (let i = 0; i < root.rowCount * root.columnCount; i++) {
            const d = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + i);
            cells.push({
                date: d,
                month: d.getMonth(),
                year: d.getFullYear(),
                today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
            });
        }
        return cells;
    }

    property var cells: buildCells()

    onMonthChanged: {
        cells = buildCells();
        closePopover();
    }
    onYearChanged: {
        cells = buildCells();
        closePopover();
    }
    onFirstDayOfWeekChanged: cells = buildCells()

    Item {
        id: gridLayer
        anchors.fill: parent
        z: 0

        Repeater {
            id: cellRepeater
            model: root.cells
            delegate: root.delegate
        }
    }

    Item {
        id: popoverLayer
        anchors.fill: parent
        z: 10

        Loader {
            id: popoverLoader
            active: root.openPopoverDate !== null && root.popoverDelegate !== null
            sourceComponent: root.popoverDelegate

            readonly property int openIndex: {
                if (root.openPopoverDate === null)
                    return -1;
                const target = new Date(root.openPopoverDate);
                for (let i = 0; i < root.cells.length; i++) {
                    const c = root.cells[i];
                    if (c.date.getFullYear() === target.getFullYear() && c.date.getMonth() === target.getMonth() && c.date.getDate() === target.getDate())
                        return i;
                }
                return -1;
            }
            readonly property int openCol: openIndex >= 0 ? openIndex % root.columnCount : 0
            readonly property int openRow: openIndex >= 0 ? Math.floor(openIndex / root.columnCount) : 0

            x: openCol
            y: openRow * root.cellHeight + root.cellHeight
            width: root.cellWidth * root.columnCount

            onLoaded: {
                if (!item)
                    return;
                if (item.hasOwnProperty("cellDate"))
                    item.cellDate = root.openPopoverDate;
                if (item.hasOwnProperty("anchorWidth"))
                    item.anchorWidth = Qt.binding(() => root.cellWidth);
            }
        }
    }
}
