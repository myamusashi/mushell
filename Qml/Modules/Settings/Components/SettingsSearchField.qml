pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Search

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    signal activated(int page, string card)

    property var results: []
    property int selectedIndex: -1
    readonly property string query: searchField.text.trim()

    z: 2
    implicitHeight: searchField.implicitHeight

    readonly property var entries: [
        {
            page: 0,
            pageLabel: "General",
            card: "Window & Focus",
            terms: ["Follow Focus Monitor", "Transparent Mode", "Transparency Alpha", "Album Cover Blur", "Charging Indicator Spread", "Outer Border", "Holidays Calendar"]
        },
        {
            page: 0,
            pageLabel: "General",
            card: "Default Applications",
            terms: ["Terminal", "File Explorer", "Image Viewer", "Video Viewer", "Audio Settings"]
        },
        {
            page: 1,
            pageLabel: "Language",
            card: "Locale Preference",
            terms: ["Current Language"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Color System",
            terms: ["Dark Mode", "Static Colors Path", "Material Colors", "Material Scheme"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Typography System",
            terms: ["Sans Serif Font", "Monospace Font", "Material Icon Font", "Font Size Scale"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Shapes & Layout",
            terms: ["Corner Roundness", "Element Spacing", "Padding", "Margin"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Motion & Animation",
            terms: ["Animation Durations Scale"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Depth Wallpaper",
            terms: ["Enable Depth Wallpaper", "Auto-process On Wallpaper Change"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Pick Wallpaper File",
            terms: ["Select A Wallpaper Image File"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Wallpaper Picker",
            terms: []
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Image Sourcing",
            terms: ["Enable Wallpaper", "Live Preview", "Directory Path", "Loaded Wallpaper Count"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Transitions & Performance",
            terms: ["Transition Animation Mode", "Low Performance Priority", "Transition Duration"]
        },
        {
            page: 4,
            pageLabel: "Top Bar",
            card: "Layout & Behavior",
            terms: ["Always Open Bar", "Compact Navigation Bar", "Bar Height"]
        },
        {
            page: 4,
            pageLabel: "Top Bar",
            card: "Workspace Display",
            terms: ["Workspace Indicator Style", "Number of Visible Workspaces"]
        },
        {
            page: 5,
            pageLabel: "Media Player",
            card: "Player Preferences",
            terms: ["Lyrics", "Dynamic Colors From Cover Art", "Slider Type"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Geographic Data",
            terms: ["Latitude", "Longitude"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Astronomy API",
            terms: ["WeatherAPI Key"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Sync & Overview",
            terms: ["Quick Summary Widget"]
        },
        {
            page: 7,
            pageLabel: "Notification",
            card: "Notification Limits",
            terms: ["Maximum Notifications", "Maximum Notification Age"]
        },
        {
            page: 8,
            pageLabel: "Clipboard",
            card: "General Settings",
            terms: ["Enable Clipboard", "Image Previews", "Vim Keybinds", "Keep Clipboard Open After Copy"]
        },
        {
            page: 8,
            pageLabel: "Clipboard",
            card: "Preview Dimensions",
            terms: ["Preview Width", "Preview Height"]
        },
        {
            page: 9,
            pageLabel: "Screen Recorder",
            card: "Recording",
            terms: ["Frame Rate", "Bitrate", "Video Codec", "Audio Codec", "Power Mode", "Show Cursor", "Replay Buffer"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Playback",
            terms: ["Per App Volume", "System Sounds", "Application Volume", "Media Title"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Output Devices",
            terms: ["Speaker", "Headphone", "Default Output", "Device Volume"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Input Devices",
            terms: ["Microphone", "Default Input", "Mic Volume"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Configuration",
            terms: ["Audio Profile", "Card Profile", "Off", "Pro Audio"]
        },
        {
            page: 11,
            pageLabel: "Network & Internet",
            card: "Hotspot",
            terms: ["Hotspot Sharing", "User Hotspot", "Hotspot Password", "Hotspot Interface", "Bandwidth"]
        },
        {
            page: 11,
            pageLabel: "Network & Internet",
            card: "Wi-Fi",
            terms: ["Enable Wi-Fi"]
        },
        {
            page: 12,
            pageLabel: "KDE Connect",
            card: "Device Discovery",
            terms: ["Enable Polling"]
        },
        {
            page: 12,
            pageLabel: "KDE Connect",
            card: "Local Device",
            terms: ["Device ID"]
        },
        {
            page: 12,
            pageLabel: "KDE Connect",
            card: "Paired Devices",
            terms: []
        },
        {
            page: 12,
            pageLabel: "KDE Connect",
            card: "Available Devices",
            terms: []
        },
        {
            page: 13,
            pageLabel: "Greeter",
            card: "Greeter Wallpaper",
            terms: ["Wallpaper Type", "Upload Wallpaper", "Preview"]
        },
        {
            page: 14,
            pageLabel: "Idle",
            card: "Idle Management",
            terms: ["Enable Idle Detection"]
        },
        {
            page: 14,
            pageLabel: "Idle",
            card: "Timeouts",
            terms: []
        }
    ]

    function runSearch() {
        if (root.query.length === 0) {
            root.results = [];
            root.selectedIndex = -1;
            return;
        }

        // fzy scores grow with needle length, so the floor is per query character.
        const minScore = root.query.length * SearchEngine.appThreshold;
        const scored = [];

        for (const entry of root.entries) {
            let best = 0;
            for (const text of [entry.card].concat(entry.terms)) {
                const s = SearchEngine.score(root.query, text);
                if (s > best)
                    best = s;
            }
            if (best >= minScore)
                scored.push([best, entry]);
        }

        scored.sort((a, b) => b[0] - a[0]);
        root.results = scored.slice(0, 8).map(item => item[1]);
        root.selectedIndex = root.results.length > 0 ? 0 : -1;
    }

    function clear() {
        searchField.text = "";
        root.results = [];
        root.selectedIndex = -1;
    }

    function activate(entry) {
        root.activated(entry.page, entry.card);
        root.clear();
    }

    Timer {
        id: searchDebounce

        interval: 200
        onTriggered: root.runSearch()
    }

    RowLayout {
        id: searchBox

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        Icon {
            icon: "search"
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        StyledTextInput {
            id: searchField

            Layout.fillWidth: true
            placeHolderText: qsTr("Search settings…")
            toggleButtonVisible: false
            autoFocus: false

            onTextChanged: searchDebounce.restart()
            onAccepted: {
                if (root.selectedIndex >= 0 && root.selectedIndex < root.results.length)
                    root.activate(root.results[root.selectedIndex]);
            }
            onKeyPressed: event => {
                switch (event.key) {
                case Qt.Key_Escape:
                    if (root.query.length > 0 || root.results.length > 0) {
                        event.accepted = true;
                        root.clear();
                    }
                    break;
                case Qt.Key_Down:
                    event.accepted = true;
                    if (root.selectedIndex < root.results.length - 1)
                        root.selectedIndex++;
                    break;
                case Qt.Key_Up:
                    event.accepted = true;
                    if (root.selectedIndex > 0)
                        root.selectedIndex--;
                    break;
                }
            }
        }
    }

    Rectangle {
        id: resultsPopup

        visible: root.results.length > 0
        anchors.top: parent.bottom
        anchors.topMargin: Appearance.spacing.small
        width: parent.width
        implicitHeight: resultsColumn.implicitHeight + (Appearance.margin.normal * 2)
        radius: Appearance.rounding.normal
        color: Colours.m3Colors.m3SurfaceContainerHigh
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1

        ColumnLayout {
            id: resultsColumn

            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.smaller

            Repeater {
                model: root.results

                delegate: Rectangle {
                    id: resultDelegate

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: resultRow.implicitHeight + (Appearance.margin.normal * 2)
                    radius: Appearance.rounding.small
                    color: resultDelegate.index === root.selectedIndex ? Colours.m3Colors.m3SurfaceContainerHighest : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.activate(resultDelegate.modelData)
                        onEntered: root.selectedIndex = resultDelegate.index
                    }

                    ColumnLayout {
                        id: resultRow

                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: 2

                        HighlightText {
                            Layout.fillWidth: true
                            fullText: resultDelegate.modelData.card
                            searchText: root.query
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: resultDelegate.modelData.pageLabel
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.small
                            color: Colours.m3Colors.m3OnSurfaceVariant
                        }
                    }
                }
            }
        }
    }
}
