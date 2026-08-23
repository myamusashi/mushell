pragma Singleton

import Quickshell
import Quickshell.Io
import Vast.Translation

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias colors: adapter.colors
    property alias generals: adapter.generals
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather
    property alias language: adapter.language
    property alias mediaPlayer: adapter.mediaPlayer
    property alias clipboard: adapter.clipboard
    property alias notification: adapter.notification
    property alias kdeConnect: adapter.kdeConnect
    property alias screenRecorder: adapter.screenRecorder
    property alias audio: adapter.audio
    property alias idle: adapter.idle
    property alias search: adapter.search

    onLanguageChanged: TranslationManager.loadTranslation(root.language.language, Paths.translateFilePath)

    FileView {
        path: Paths.shellDir + "/configurations.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.log("Failed to read config files");
                ToastService.show(qsTr("Failed to read config files"), qsTr("Configuration"), "configure", 3000);
            }
        }
        onLoaded: TranslationManager.loadTranslation(root.language.language, Paths.translateFilePath)
        onAdapterUpdated: writeAdapter()
        onSaveFailed: err => {
            console.log("Failed to save config", FileViewError.toString(err));
            ToastService.show(qsTr("Failed to save config: %1").arg(FileViewError.toString(err)), qsTr("Configuration"), "configure", 3000);
        }

        JsonAdapter { // qmllint disable
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {}
            property ColorSystemConfig colors: ColorSystemConfig {}
            property ClipboardConfig clipboard: ClipboardConfig {}
            property GeneralConfig generals: GeneralConfig {}
            property WallpaperConfig wallpaper: WallpaperConfig {}
            property WeatherConfig weather: WeatherConfig {}
            property BarConfig bar: BarConfig {}
            property NotificationConfig notification: NotificationConfig {}
            property LocalizationConfig language: LocalizationConfig {}
            property MediaPlayerConfig mediaPlayer: MediaPlayerConfig {}
            property KDEConnectConfig kdeConnect: KDEConnectConfig {}
            property ScreenRecorderConfig screenRecorder: ScreenRecorderConfig {}
            property AudioConfig audio: AudioConfig {}
            property IdleConfig idle: IdleConfig {}
            property SearchConfig search: SearchConfig {}
        }
    }
}
