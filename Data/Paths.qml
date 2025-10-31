pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	readonly property string home: Quickshell.env("HOME")
	readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
	readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`

	readonly property string configDir: Quickshell.env("XDG_CONFIG_DIR") || `${home}/.config`
	readonly property string shellDir: `${configDir}/shell`

	readonly property string cacheDir: Quickshell.env("XDG_CACHE_DIR") || `${home}/.cache`
	readonly property string currentWallpaper: `${cacheDir}/wall/path.txt`

	readonly property string wallpaperDir: `${pictures}/wallpapers` || `${pictures}/Wallpapers`

	readonly property string recordDir: `${videos}/Shell`
}
