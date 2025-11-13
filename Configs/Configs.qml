pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.Data

Singleton {
	id: root

	property alias general: adapter.general
	property alias wallpaper: adapter.wallpaper
	property alias weather: adapter.weather

	FileView {
		path: Paths.shellDir + "/configurations.json"
		watchChanges: true
		onFileChanged: reload()

		onLoaded: {
			try {
				JSON.parse(text());
				if (adapter.utilities.toasts.configLoaded)
				console.log("Config loaded");
			} catch (e) {
				console.log("Failed to loaded", e.message);
			}
		}

		onLoadFailed: err => {
			if (err !== FileViewError.FileNotFound)
			console.log("Failed to read config files");
		}

		onSaveFailed: err => console.log("Failed to save config", FileViewError.toString(err))

		JsonAdapter {
			id: adapter

			property General general: General {}
			property Wallpaper wallpaper: Wallpaper {}
			property Weather weather: Weather {}
		}
	}
}
