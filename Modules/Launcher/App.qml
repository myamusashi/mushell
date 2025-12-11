pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

import QtCore
StyledRect {
	id: root

    property int currentIndex: 1
    property bool isLauncherOpen: GlobalStates.isLauncherOpen
    property var launchHistory: []

    GlobalShortcut {
        name: "appLauncher"
        onPressed: root.isLauncherOpen = !root.isLauncherOpen
    }

    Component.onCompleted: {
        loadLaunchHistory();
	}

	Settings {
		id: settings
	}

    function loadLaunchHistory(): void {
        const stored = settings.value("launchHistory", "[]");
        try {
            launchHistory = JSON.parse(stored);
        } catch (e) {
            launchHistory = [];
        }
    }

    function saveLaunchHistory(): void {
        settings.setValue("launchHistory", JSON.stringify(launchHistory));
    }

    function updateLaunchHistory(entry: DesktopEntry): void {
        const appId = entry.id || entry.name;
        const now = Date.now();

        let found = false;
        for (let i = 0; i < launchHistory.length; i++) {
            if (launchHistory[i].id === appId) {
                launchHistory[i].timestamp = now;
                launchHistory[i].count = (launchHistory[i].count || 0) + 1;
                found = true;
                break;
            }
        }

        if (!found) {
            launchHistory.push({
                id: appId,
                timestamp: now,
                count: 1
            });
        }

        if (launchHistory.length > 50) {
            launchHistory.sort((a, b) => b.timestamp - a.timestamp);
            launchHistory = launchHistory.slice(0, 50);
        }

        saveLaunchHistory();
    }

    function getRecencyScore(entry: DesktopEntry): real {
        const appId = entry.id || entry.name;
        const now = Date.now();

        for (let i = 0; i < launchHistory.length; i++) {
            if (launchHistory[i].id === appId) {
                const age = now - launchHistory[i].timestamp;
                const dayInMs = 86400000;

                // Exponential decay: high score for recent launches, decays over 7 days
                const recencyScore = Math.exp(-age / (dayInMs * 7));

                // Frequency bonus (normalized)
                const frequencyScore = Math.min(launchHistory[i].count / 10, 1);

                // Combined score: 70% recency, 30% frequency
                return recencyScore * 0.7 + frequencyScore * 0.3;
            }
        }

        return 0;
    }

    // Thx caelestia
    function launch(entry: DesktopEntry): void {
        updateLaunchHistory(entry);

        entry.runInTerminal ? Quickshell.execDetached({
            "command": ["app2unit", "--", "foot", `${Quickshell.shellDir}/Assets/wrap_term_launch.sh`, ...entry.command],
            "workingDirectory": entry.workingDirectory
        }) : Quickshell.execDetached({
            "command": ["app2unit", "--", ...entry.command],
            "workingDirectory": entry.workingDirectory
        });
    }

    radius: 0
    topLeftRadius: Appearance.rounding.normal
    topRightRadius: Appearance.rounding.normal
    color: Colours.m3Colors.m3Surface
    implicitWidth: Hypr.focusedMonitor.width * 0.3
    implicitHeight: isLauncherOpen ? Hypr.focusedMonitor.height * 0.5 : 0
    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }
    Loader {
        anchors.fill: parent
        active: root.isLauncherOpen
        asynchronous: true
        sourceComponent: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal
            focus: root.isLauncherOpen
            onFocusChanged: {
                if (focus && root.isLauncherOpen)
                    search.forceActiveFocus();
            }
            StyledTextField {
				id: search

                Layout.fillWidth: true
                Layout.preferredHeight: 60
                placeholderText: "  Search"
                font.family: Appearance.fonts.family.sans
                focus: true
                font.pixelSize: Appearance.fonts.size.large * 1.2
                color: Colours.m3Colors.m3OnBackground
                placeholderTextColor: Colours.m3Colors.m3OnSurfaceVariant
                onTextChanged: {
                    root.currentIndex = 0;
                    listView.positionViewAtBeginning();
                }
                Keys.onPressed: function (event) {
                    switch (event.key) {
                    case Qt.Key_Return:
                    case Qt.Key_Tab:
                    case Qt.Key_Enter:
                        if (listView.count > 0) {
                            listView.focus = true;
                            event.accepted = true;
                        }
                        break;
                    case Qt.Key_Escape:
                        root.isLauncherOpen = false;
                        event.accepted = true;
                        break;
                    case Qt.Key_Down:
                        if (listView.count > 0) {
                            listView.focus = true;
                            event.accepted = true;
                        }
                        break;
                    }
                }
            }
            ListView {
				id: listView

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ScriptModel {
                    values: Fuzzy.fuzzySearch(DesktopEntries.applications.values, search.text, "name", 0.55, root.getRecencyScore)
                }
                clip: true
                spacing: 8
                cacheBuffer: 100
                reuseItems: true
                highlightMoveDuration: 150
                highlightMoveVelocity: -1
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                delegate: ItemDelegate {
					id: delegateItem

                    required property DesktopEntry modelData
                    required property int index
                    width: listView.width
                    height: 80
                    contentItem: RowLayout {
                        spacing: Appearance.spacing.normal
                        StyledRect {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            Layout.leftMargin: Appearance.padding.normal
                            color: root.color
                            border.width: listView.currentIndex === delegateItem.index ? 3 : 1
                            border.color: listView.currentIndex === delegateItem.index && !search.focus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                            IconImage {
                                anchors.centerIn: parent
                                width: 48
                                height: 48
                                source: Quickshell.iconPath(delegateItem.modelData.icon) || ""
                                asynchronous: true
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.rightMargin: Appearance.padding.normal
                            spacing: 2
                            StyledLabel {
                                Layout.fillWidth: true
                                text: delegateItem.modelData.name || ""
                                font.pixelSize: Appearance.fonts.size.large
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                color: Colours.m3Colors.m3OnSurface
                            }
                            StyledLabel {
                                Layout.fillWidth: true
                                text: delegateItem.modelData.comment
                                font.pixelSize: Appearance.fonts.size.small
                                elide: Text.ElideRight
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                opacity: 0.7
                            }
                        }
                    }
                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.launch(delegateItem.modelData);
                            root.isLauncherOpen = false;
                        }
                        onEntered: listView.currentIndex = delegateItem.index
                    }
                    Keys.onPressed: function (event) {
                        switch (event.key) {
                        case Qt.Key_Tab:
                            search.focus = true;
                            event.accepted = true;
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.launch(delegateItem.modelData);
                            root.isLauncherOpen = false;
                            event.accepted = true;
                            break;
                        case Qt.Key_Escape:
                            root.isLauncherOpen = false;
                            event.accepted = true;
                            break;
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: listView.count === 0 && search.text !== ""
                    text: "No applications found"
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                }
            }
        }
    }
}
