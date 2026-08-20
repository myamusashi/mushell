pragma ComponentBehavior: Bound

import QtQuick
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

    readonly property int contentWidth: 640

    activeAsync: GlobalStates.isSettingsOpen
    component: FloatingWindow {
        color: GlobalStates.drawerColors
        title: "settings window"
        onClosed: GlobalStates.isSettingsOpen = false
        implicitWidth: 900
        implicitHeight: 600

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
                            {
                                icon: "settings",
                                label: qsTr("General")
                            },
                            {
                                icon: "palette",
                                label: qsTr("Appearance")
                            },
                            {
                                icon: "lock",
                                label: qsTr("Greeter")
                            },
                            {
                                icon: "table_rows",
                                label: qsTr("Top Bar")
                            },
                            {
                                icon: "wall_art",
                                label: qsTr("Wallpaper")
                            },
                            {
                                icon: "genres",
                                label: qsTr("Media Player")
                            },
                            {
                                icon: "cloud",
                                label: qsTr("Weather")
                            },
                            {
                                icon: "language",
                                label: qsTr("Language")
                            },
                            {
                                icon: "wifi",
                                label: qsTr("Network & Internet")
                            },
                            {
                                icon: "assignment",
                                label: qsTr("Clipboard")
                            },
                            {
                                icon: "notifications",
                                label: qsTr("Notification")
                            },
                            {
                                icon: "smartphone",
                                label: qsTr("KDE Connect")
                            },
                            {
                                icon: "screen_record",
                                label: qsTr("Screen Recorder")
                            },
                            {
                                icon: "hourglass",
                                label: qsTr("Idle")
                            }
                        ]
                        currentIndex: settingsLoader.currentPage
                        expanded: true
                        fabIcon: ""
                        backgroundColor: "transparent"

                        onActivated: function (index) {
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

                    Column {
                        anchors.fill: parent

                        Loader {
                            visible: settingsLoader.currentPage === 0
                            active: settingsLoader.currentPage === 0
                            width: parent.width
                            height: parent.height
                            sourceComponent: GeneralPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 1
                            active: settingsLoader.currentPage === 1
                            width: parent.width
                            height: parent.height
                            sourceComponent: AppearancePage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 2
                            active: settingsLoader.currentPage === 2
                            width: parent.width
                            height: parent.height
                            sourceComponent: GreeterPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 3
                            active: settingsLoader.currentPage === 3
                            width: parent.width
                            height: parent.height
                            sourceComponent: BarPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 4
                            active: settingsLoader.currentPage === 4
                            width: parent.width
                            height: parent.height
                            sourceComponent: WallpaperPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 5
                            active: settingsLoader.currentPage === 5
                            width: parent.width
                            height: parent.height
                            sourceComponent: MediaPlayerPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 6
                            active: settingsLoader.currentPage === 6
                            width: parent.width
                            height: parent.height
                            sourceComponent: WeatherPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 7
                            active: settingsLoader.currentPage === 7
                            width: parent.width
                            height: parent.height
                            sourceComponent: LanguagePage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 8
                            active: settingsLoader.currentPage === 8
                            width: parent.width
                            height: parent.height
                            sourceComponent: InternetPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 9
                            active: settingsLoader.currentPage === 9
                            width: parent.width
                            height: parent.height
                            sourceComponent: ClipboardPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 10
                            active: settingsLoader.currentPage === 10
                            width: parent.width
                            height: parent.height
                            sourceComponent: NotificationPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 11
                            active: settingsLoader.currentPage === 11
                            width: parent.width
                            height: parent.height
                            sourceComponent: KDEConnectPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 12
                            active: settingsLoader.currentPage === 12
                            width: parent.width
                            height: parent.height
                            sourceComponent: ScreenRecorderPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 13
                            active: settingsLoader.currentPage === 13
                            width: parent.width
                            height: parent.height
                            sourceComponent: IdlePage {}
                        }
                    }
                }
            }
        }
    }
}
