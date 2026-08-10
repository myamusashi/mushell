pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Components.Base.NavigationRail
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "./Pages"

LazyLoader {
    id: settingsLoader

    property int currentPage: 0

    // Content area keeps a constant width so the pages flex when the
    // navigation rail expands/collapses; only the rail width changes.
    readonly property int contentWidth: 640

    activeAsync: GlobalStates.isSettingsOpen
    component: FloatingWindow {
        color: "transparent"
        onClosed: GlobalStates.isSettingsOpen = false

        // Window width is explicit and constant: the rail's animation is
        // absorbed by the pages column, which therefore resizes on toggle.
        implicitWidth: Appearance.margin.large * 2 + Appearance.spacing.large * 2 + 1 + navRail.expandedWidth + settingsLoader.contentWidth

        Rectangle {
            anchors.fill: parent
            color: GlobalStates.drawerColors
            radius: Appearance.rounding.large
            clip: true

            Elevation {
                anchors.fill: parent
                level: 3
                radius: parent.radius
            }

            // Pure anchor geometry (no Layouts): the rail's width change must
            // not pass through Layout pixel-quantization for a smooth resize.
            Item {
                anchors.fill: parent
                anchors.margins: Appearance.margin.large

                Rectangle {
                    id: sidebarArea

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: navRail.implicitWidth
                    color: "transparent"

                    StyledText {
                        id: sidebarTitle

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.margin.normal
                        font.bold: true
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        color: Colours.m3Colors.m3OnSurface
                        opacity: navRail.expanded ? 1 : 0

                        Behavior on opacity {
                            NAnim {}
                        }
                    }

                    NavigationRail {
                        id: navRail

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: sidebarTitle.bottom
                        anchors.topMargin: Appearance.spacing.small
                        anchors.bottom: parent.bottom

                        model: [
                            { icon: "settings", label: qsTr("General") },
                            { icon: "palette", label: qsTr("Appearance") },
                            { icon: "table_rows", label: qsTr("Top Bar") },
                            { icon: "wall_art", label: qsTr("Wallpaper") },
                            { icon: "genres", label: qsTr("Media Player") },
                            { icon: "cloud", label: qsTr("Weather") },
                            { icon: "language", label: qsTr("Language") },
                            { icon: "wifi", label: qsTr("Network & Internet") },
                            { icon: "assignment", label: qsTr("Clipboard") },
                            { icon: "notifications", label: qsTr("Notification") },
                            { icon: "smartphone", label: qsTr("KDE Connect") },
                            { icon: "screen_record", label: qsTr("Screen Recorder") },
                            { icon: "hourglass", label: qsTr("Idle") }
                        ]
                        currentIndex: settingsLoader.currentPage
                        expanded: true
                        fabIcon: ""
                        backgroundColor: "transparent"

                        onActivated: function(index) {
                            settingsLoader.currentPage = index;
                        }
                    }
                }

                Rectangle {
                    id: sidebarDivider

                    anchors.left: sidebarArea.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Colours.m3Colors.m3OutlineVariant
                }

                Rectangle {
                    id: contentArea

                    anchors.left: sidebarDivider.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    color: "transparent"

                    StackLayout {
                        id: stackLayout

                        anchors.fill: parent
                        currentIndex: settingsLoader.currentPage

                        Loader {
                            active: stackLayout.currentIndex === 0
                            sourceComponent: GeneralPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 1
                            sourceComponent: AppearancePage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 2
                            sourceComponent: BarPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 3
                            sourceComponent: WallpaperPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 4
                            sourceComponent: MediaPlayerPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 5
                            sourceComponent: WeatherPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 6
                            sourceComponent: LanguagePage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 7
                            sourceComponent: InternetPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 8
                            sourceComponent: ClipboardPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 9
                            sourceComponent: NotificationPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 10
                            sourceComponent: KDEConnectPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 11
                            sourceComponent: ScreenRecorderPage {}
                        }
                        Loader {
                            active: stackLayout.currentIndex === 12
                            sourceComponent: IdlePage {}
                        }
                    }
                }
            }
        }
    }
}
