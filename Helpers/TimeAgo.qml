pragma Singleton

import Quickshell

Singleton {
    function timeAgoWithIfElse(date) {
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
}
