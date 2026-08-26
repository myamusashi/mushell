pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base.NavigationRail
import qs.Components.Button
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "./Components"
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
        minimumSize: Qt.size(1100, 600)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.large
            clip: true

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

                    NavigationRail {
                        id: navRail

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        model: [
                            {
                                label: qsTr("General"),
                                items: [
                                    {
                                        icon: "settings",
                                        label: qsTr("General")
                                    },
                                    {
                                        icon: "language",
                                        label: qsTr("Language")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Appearance"),
                                items: [
                                    {
                                        icon: "palette",
                                        label: qsTr("Appearance")
                                    },
                                    {
                                        icon: "wall_art",
                                        label: qsTr("Wallpaper")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Modules"),
                                items: [
                                    {
                                        icon: "table_rows",
                                        label: qsTr("Top Bar")
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
                                        icon: "notifications",
                                        label: qsTr("Notification")
                                    },
                                    {
                                        icon: "assignment",
                                        label: qsTr("Clipboard")
                                    },
                                    {
                                        icon: "screen_record",
                                        label: qsTr("Screen Recorder")
                                    },
                                    {
                                        icon: "volume_up",
                                        label: qsTr("Audio")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Connectivity"),
                                items: [
                                    {
                                        icon: "wifi",
                                        label: qsTr("Network & Internet")
                                    },
                                    {
                                        icon: "smartphone",
                                        label: qsTr("KDE Connect")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Session"),
                                items: [
                                    {
                                        icon: "lock_person",
                                        label: qsTr("Greeter")
                                    },
                                    {
                                        icon: "hourglass",
                                        label: qsTr("Idle")
                                    }
                                ]
                            }
                        ]
                        currentIndex: settingsLoader.currentPage
                        expanded: true
                        actionButtonIcon: ""
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

                    ColumnLayout {
                        id: pagesColumn
                        anchors.fill: parent

                        function revealCard(cardTitle: string) {
                            const kids = pagesColumn.children;

                            for (let i = 0; i < kids.length; i++) {
                                if (!(kids[i] instanceof Loader) || !kids[i].active || !kids[i].item || !kids[i].item.revealCard)
                                    continue;

                                kids[i].item.revealCard(cardTitle);
                                return;
                            }
                        }

                        // z-lift so the search results popup overlays page content.
                        RowLayout {
                            Layout.fillWidth: true
                            z: 2
                            spacing: Appearance.spacing.normal

                            FloatingButton {
                                id: expandToggle

                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter
                                backgroundRadius: Appearance.rounding.small
                                icon.name: navRail.expanded ? "menu_open" : "menu"
                                icon.color: Colours.m3Colors.m3SurfaceVariant
                                icon.size: Appearance.fonts.size.larger
                                onClicked: navRail.expanded = !navRail.expanded
                            }

                            SettingsSearchField {
                                id: settingsSearchField

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                onActivated: (page, card) => {
                                    settingsLoader.currentPage = page;
                                    Qt.callLater(() => pagesColumn.revealCard(card));
                                }
                            }
                        }

                        Loader {
                            visible: settingsLoader.currentPage === 0
                            active: settingsLoader.currentPage === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: GeneralPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 1
                            active: settingsLoader.currentPage === 1
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: LanguagePage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 2
                            active: settingsLoader.currentPage === 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: AppearancePage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 3
                            active: settingsLoader.currentPage === 3
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: WallpaperPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 4
                            active: settingsLoader.currentPage === 4
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: BarPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 5
                            active: settingsLoader.currentPage === 5
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: MediaPlayerPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 6
                            active: settingsLoader.currentPage === 6
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: WeatherPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 7
                            active: settingsLoader.currentPage === 7
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: NotificationPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 8
                            active: settingsLoader.currentPage === 8
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: ClipboardPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 9
                            active: settingsLoader.currentPage === 9
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: ScreenRecorderPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 10
                            active: settingsLoader.currentPage === 10
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: VolumePage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 11
                            active: settingsLoader.currentPage === 11
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: InternetPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 12
                            active: settingsLoader.currentPage === 12
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: KDEConnectPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 13
                            active: settingsLoader.currentPage === 13
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: GreeterPage {}
                        }
                        Loader {
                            visible: settingsLoader.currentPage === 14
                            active: settingsLoader.currentPage === 14
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: IdlePage {}
                        }
                    }
                }
            }
        }
    }
}
