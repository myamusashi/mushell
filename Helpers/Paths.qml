pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Configs

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`

    readonly property string rootDir: Quickshell.shellDir
    readonly property string configDir: Quickshell.env("XDG_CONFIG_DIR") || `${home}/.config`
    readonly property string shellDir: `${configDir}/shell`

    readonly property string cacheDir: Quickshell.env("XDG_CACHE_DIR") || `${home}/.cache`
    readonly property string currentWallpaperFile: `${cacheDir}/wall/path.txt`
    readonly property string currentWallpaper: wallpaperPath.text().trim()

    readonly property string wallpaperDir: Configs.wallpaper.wallpaperDir

    readonly property string recordDir: `${videos}/Shell`

    function pathToBreadcrumb(path) {
        if (!path || typeof path !== 'string')
            return '';

        let cleanPath = path;

        // Remove file:// protocol
        if (cleanPath.startsWith('file://'))
            cleanPath = cleanPath.substring(7);

        // Remove qrc:// protocol
        if (cleanPath.startsWith('qrc://'))
            cleanPath = cleanPath.substring(6);

        // Remove qrc:/ protocol
        if (cleanPath.startsWith('qrc:/'))
            cleanPath = cleanPath.substring(5);

        // Remove leading slashes (handles //, ///, etc.)
        cleanPath = cleanPath.replace(/^\/+/, '');

        // Split by forward slashes or backslashes
        const parts = cleanPath.split(/[\/\\]+/).filter(part => part.length > 0);

        return parts.join(' > ');
    }

    FileView {
        id: wallpaperPath

        path: `${root.cacheDir}/wall/path.txt`
        watchChanges: true
        onFileChanged: reload()
    }
}
