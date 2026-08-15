import Quickshell.Io

import qs.Core.Utils

JsonObject {
    property bool isDarkMode: true
    property bool useStaticColors: false
    property bool useMaterialColor: false
    property string staticColorsPath: Paths.shellDir + "/colors.json"
    property string toWhiteColor: Paths.shellDir + "/light-colors.json"
    property string toDarkColor: Paths.shellDir + "/dark-colors.json"
    property string scheme: "tonal-spot"
}
