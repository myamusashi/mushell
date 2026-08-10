import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Menu

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Top Bar Configuration")

    SettingsCard {
        title: qsTr("Layout & Behavior")

        SettingRow {
            label: qsTr("Always Open Bar:")

            StyledSwitch {
                checked: Configs.bar.alwaysOpenBar
                onCheckedChanged: Configs.bar.alwaysOpenBar = checked
            }
        }

        SettingRow {
            label: qsTr("Compact Navigation Bar:")

            StyledSwitch {
                checked: Configs.bar.compact
                onCheckedChanged: Configs.bar.compact = checked
            }
        }

        SettingRow {
            label: qsTr("Bar Height:")

            StyledSlide {
                from: 20
                to: 100
                stepSize: 1
                value: Configs.bar.barHeight
                onMoved: Configs.bar.barHeight = value
                Layout.preferredWidth: 200
            }
        }
    }

    SettingsCard {
        title: qsTr("Workspace Display")

        SettingRow {
            label: qsTr("Workspace Indicator Style:")

            DropdownField {
                ToolTip.text: "Available values: 'dot', 'interactive'"
                model: [
                    {
                        display: "dot"
                    },
                    {
                        display: "interactive"
                    }
                ]
                Layout.preferredWidth: 200
                currentIndex: -1
                placeholderText: Configs.bar.workspacesIndicator
                isItemActive: (md, _) => md.display === Configs.bar.workspacesIndicator
                onActivated: index => Configs.bar.workspacesIndicator = model[index].display
            }
        }

        SettingRow {
            label: qsTr("Number of Visible Workspaces:")

            StyledSlide {
                from: 1
                to: 15
                stepSize: 1
                snapEnabled: true
                showValuePopup: true
                value: Configs.bar.visibleWorkspace
                onMoved: Configs.bar.visibleWorkspace = value
                Layout.preferredWidth: 200
            }
        }
    }
}
