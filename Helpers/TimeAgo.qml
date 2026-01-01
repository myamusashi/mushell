pragma Singleton

import Quickshell

Singleton {
    function timeAgoWithIfElse(timestamp) {
        const date = new Date(timestamp);
        const seconds = Math.floor((new Date() - date) / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);

        if (seconds < 60) {
            if (seconds < 5)
                return "just now";

            return `${seconds} seconds ago`;
        } else if (minutes < 60)
            return minutes === 1 ? "1 minute ago" : `${minutes} minutes ago`;
        else if (hours < 24)
            return hours === 1 ? "1 hour ago" : `${hours} hours ago`;
        else if (days < 30)
            return days === 1 ? "1 day ago" : `${days} days ago`;
        else
            return date.toLocaleString();
    }

    function convertTo12Hour(time24) {
        if (!time24)
            return "";

        const timeStr = time24.includes(" ") ? time24.split(" ")[1] : time24;

        const parts = timeStr.split(":");
        if (parts.length < 2)
            return timeStr;

        let hours = parseInt(parts[0]);
        const minutes = parts[1];

        const period = hours >= 12 ? "PM" : "AM";

        if (hours === 0) {
            hours = 12;
        } else if (hours > 12) {
            hours = hours - 12;
        }

        return hours + ":" + minutes + " " + period;
    }

    function convertTo12HourCompact(time24) {
        if (!time24)
            return "";

        const timeStr = time24.includes(" ") ? time24.split(" ")[1] : time24;

        const parts = timeStr.split(":");
        if (parts.length < 2)
            return timeStr;

        let hours = parseInt(parts[0]);
        const minutes = parts[1];

        const period = hours >= 12 ? "PM" : "AM";

        if (hours === 0) {
            hours = 12;
        } else if (hours > 12) {
            hours = hours - 12;
        }

        return hours + period;
    }

    // Format: "31 Dec 2025, 23:15"
    function formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        const options = {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        };
        return date.toLocaleString('en-GB', options);
    }

    // Format: "31/12/2025"
    function formatTimestampShort(timestamp) {
        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }

    // Format "31 Dec 2025, 11:15 PM"
    function formatTimestampWithTime(timestamp) {
        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const month = monthNames[date.getMonth()];
        const year = date.getFullYear();

        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const period = hours >= 12 ? "PM" : "AM";

        if (hours === 0) {
            hours = 12;
        } else if (hours > 12) {
            hours = hours - 12;
        }

        return `${day} ${month} ${year}, ${hours}:${minutes} ${period}`;
    }

    function formatTimestampRelative(timestamp) {
        const date = new Date(timestamp);
        return timeAgoWithIfElse(date);
    }

    // Format custom: "DD/MM/YYYY HH:mm"
    function formatTimestampCustom(timestamp, format) {
        const date = new Date(timestamp);

        const replacements = {
            'DD': String(date.getDate()).padStart(2, '0'),
            'MM': String(date.getMonth() + 1).padStart(2, '0'),
            'YYYY': date.getFullYear(),
            'YY': String(date.getFullYear()).slice(-2),
            'HH': String(date.getHours()).padStart(2, '0'),
            'mm': String(date.getMinutes()).padStart(2, '0'),
            'ss': String(date.getSeconds()).padStart(2, '0')
        };

        let result = format;
        for (const [key, value] of Object.entries(replacements)) {
            result = result.replace(key, value);
        }

        return result;
    }
}
