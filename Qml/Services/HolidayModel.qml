pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils

Singleton {
    id: root

    property var holidaysByDate: ({})
    property bool loaded: false
    property bool loading: false
    property int cachedYear: 0

    signal dataChanged

    function isoDate(date: var): string {
        if (typeof date === "string")
            return date;
        const y = date.getFullYear();
        const m = String(date.getMonth() + 1).padStart(2, "0");
        const d = String(date.getDate()).padStart(2, "0");
        return y + "-" + m + "-" + d;
    }

    function getHolidaysForDate(date: var): var {
        if (!loaded)
            return [];
        return holidaysByDate[isoDate(date)] || [];
    }

    function hasHoliday(date: var): bool {
        return getHolidaysForDate(date).length > 0;
    }

    function nameForDate(date: var): string {
        const entries = getHolidaysForDate(date);
        if (entries.length === 0)
            return "";
        return entries.map(function (e) {
            return e.name;
        }).join(", ");
    }

    function ensureYear(year: int): void {
        if (loaded && cachedYear === year)
            return;
        if (loading)
            return;

        try {
            const raw = fileView.text();
            if (raw && raw.trim()) {
                const json = JSON.parse(raw);
                if (json && json[String(year)] && json[String(year)].length > 0) {
                    applyData(json, year);
                    return;
                }
            }
        } catch (e) {}

        loading = true;
        const req = new XMLHttpRequest();
        req.timeout = 15000;

        req.onreadystatechange = function () {
            if (req.readyState !== XMLHttpRequest.DONE)
                return;
            if (req.status === 200) {
                try {
                    const json = JSON.parse(req.responseText);
                    if (json.success && json.data && json.data.length > 0) {
                        let existing = {};
                        try {
                            const raw = fileView.text();
                            if (raw && raw.trim())
                                existing = JSON.parse(raw);
                        } catch (e) {}
                        existing[String(year)] = json.data;
                        writeCache(existing);
                        applyData(existing, year);
                        return;
                    }
                } catch (e) {}
            }
            loading = false;
        };

        req.onerror = function () {
            loading = false;
        };
        req.ontimeout = function () {
            loading = false;
        };
        req.open("GET", "https://tanggalmerah.upset.dev/api/holidays?year=" + year);
        req.send();
    }

    function applyData(json: var, year: int): void {
        const map = {};
        for (const y in json) {
            const entries = json[y];
            if (!Array.isArray(entries))
                continue;
            for (const entry of entries) {
                if (!map[entry.date])
                    map[entry.date] = [];
                map[entry.date].push(entry);
            }
        }
        holidaysByDate = map;
        loaded = true;
        cachedYear = year;
        loading = false;
        dataChanged();
    }

    function writeCache(json: var): void {
        fileView.setText(JSON.stringify(json, null, 0));
    }

    FileView {
        id: fileView

        path: Paths.cacheDir + "/holidays/holidays.json"
        onLoaded: {
            try {
                const raw = text();
                if (raw && raw.trim()) {
                    const json = JSON.parse(raw);
                    const now = new Date();
                    applyData(json, now.getFullYear());
                }
            } catch (e) {}
        }
        onLoadFailed: function (err) {
            try {
                setText("{}");
            } catch (e) {}
        }
    }
}
