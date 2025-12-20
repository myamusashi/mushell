pragma Singleton

import Quickshell
import Quickshell.Io

import qs.Helpers

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias colors: adapter.colors
    property alias generals: adapter.generals
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather
    property alias widgets: adapter.widgets

    FileView {
        path: Paths.shellDir + "/configurations.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.log("Failed to read config files");
        }
        onSaveFailed: err => console.log("Failed to save config", FileViewError.toString(err))

        JsonAdapter {
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {}
            property ColorSystemConfig colors: ColorSystemConfig {}
            property GeneralConfig generals: GeneralConfig {}
            property WallpaperConfig wallpaper: WallpaperConfig {}
            property WeatherConfig weather: WeatherConfig {}
            property var widgets: [
                {
                    "icon": "screenshot_frame",
                    "title": "Screenshot",
                    "action": `${Quickshell.shellDir}/Assets/screen-capture.sh --screenshot-selection`,
                    "condition": true
                },
                {
                    "icon": "screen_record",
                    "title": "Screen record",
                    "action": `${Quickshell.shellDir}/Assets/screen-capture.sh --screenrecord-selection`,
                    "condition": true
                },
                {
                    "icon": "content_paste",
                    "title": "Clipboard",
                    "action": "kitty --class clipse -e clipse",
                    "condition": true
                }
            ]
        }
    }
}
