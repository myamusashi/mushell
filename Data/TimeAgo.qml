pragma Singleton

import Quickshell

Singleton {
    function timeAgoWithIfElse(date) {
        const seconds = Math.floor((new Date() - date) / 1000)
        const minutes = Math.floor(seconds / 60)
        const hours = Math.floor(minutes / 60)
        const days = Math.floor(hours / 24)

        if (seconds < 60) {
            if (seconds < 5) {
                return "just now"
            }
            return `${seconds} seconds ago`
        } else if (minutes < 60) {
            return minutes === 1 ? "1 minute ago" : `${minutes} minutes ago`
        } else if (hours < 24) {
            return hours === 1 ? "1 hour ago" : `${hours} hours ago`
        } else if (days < 30) {
            return days === 1 ? "1 day ago" : `${days} days ago`
        } else {
            return date.toLocaleString()
        }
    }
}
