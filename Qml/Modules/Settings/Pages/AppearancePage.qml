pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Components.Button

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Dialog.FileDialog

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    CardRevealer {
        id: cardRevealer

        container: contentColumn
        target: pageFlickable
    }

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    Flickable {
        id: pageFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentColumn.implicitHeight + (Appearance.margin.large * 2)
        clip: true
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: contentColumn

            width: parent.width - (Appearance.margin.large * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.margin.large
            spacing: Appearance.spacing.large

            StyledText {
                text: qsTr("Appearance & Theming")
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.bold: true
                color: Colours.m3Colors.m3OnSurface
                Layout.bottomMargin: Appearance.margin.normal
            }

            SettingsCard {
                title: qsTr("Color System")

                GridLayout {
                    columns: 3

                    SettingRow {
                        label: qsTr("Dark Mode:")
                        StyledSwitch {
                            checked: Configs.colors.isDarkMode
                            onCheckedChanged: Configs.colors.isDarkMode = checked
                        }
                    }

                    SettingRow {
                        label: qsTr("Use Static Colors:")
                        StyledSwitch {
                            checked: Configs.colors.useStaticColors
                            onCheckedChanged: Configs.colors.useStaticColors = checked
                        }
                    }

                    SettingRow {
                        label: qsTr("Use Material Colors:")
                        StyledSwitch {
                            checked: Configs.colors.useMaterialColor
                            onCheckedChanged: Configs.colors.useMaterialColor = checked
                        }
                    }
                }

                FilePathRow {
                    label: qsTr("Static Colors Path:")
                    configValue: Configs.colors.staticColorsPath
                    onConfigChanged: value => Configs.colors.staticColorsPath = value
                }

                SettingRow {
                    label: qsTr("Material Scheme:")

                    SplitButton {
                        readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.colors.scheme)

                        model: ["vibrant", "tonal-spot", "expressive", "monochrome", "rainbow", "fruit-salad", "neutral", "fidelity", "content"].map(name => ({
                                    display: name
                                }))
                        textRole: "display"
                        icon.name: "format_color_fill"
                        currentIndex: selectedIndex
                        text: model[selectedIndex]?.display ?? Configs.colors.scheme

                        onMenuItemActivated: index => Configs.colors.scheme = model[index].display
                    }
                }
            }

            SettingsCard {
                title: qsTr("Typography System")

                GridLayout {
                    columns: 2

                    SettingRow {
                        label: qsTr("Sans Serif Font:")
                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.sans
                            onConfigChanged: value => Appearance.fonts.family.sans = value
                        }
                    }

                    SettingRow {
                        label: qsTr("Monospace Font:")
                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.mono
                            onConfigChanged: value => Appearance.fonts.family.mono = value
                        }
                    }

                    SettingRow {
                        label: qsTr("Material Icon Font:")
                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.material
                            onConfigChanged: value => Appearance.fonts.family.material = value
                        }
                    }

                    SettingRow {
                        label: qsTr("Font Size Scale:")
                        StyledSlide {
                            from: 0.1
                            to: 2.0
                            stepSize: 0.1
                            popupDecimals: 1
                            snapEnabled: true
                            showValuePopup: true
                            value: Appearance.fonts.size.scale
                            onMoved: Appearance.fonts.size.scale = value
                            Layout.preferredWidth: 200
                        }
                    }
                }
            }

            SettingsCard {
                title: qsTr("Shapes & Layout")

                GridLayout {
                    columns: 2

                    SettingRow {
                        label: qsTr("UI Corner Roundness (Normal):")
                        StyledSlide {
                            from: 0
                            to: 50
                            stepSize: 1
                            value: Appearance.rounding.normal
                            onMoved: Appearance.rounding.normal = value
                            Layout.preferredWidth: 200
                        }
                    }

                    SettingRow {
                        label: qsTr("Element Spacing (Normal):")
                        StyledSlide {
                            from: 0
                            to: 50
                            stepSize: 1
                            value: Appearance.spacing.normal
                            onMoved: Appearance.spacing.normal = value
                            Layout.preferredWidth: 200
                        }
                    }

                    SettingRow {
                        label: qsTr("Padding (Normal):")
                        StyledSlide {
                            from: 0
                            to: 50
                            stepSize: 1
                            value: Appearance.padding.normal
                            onMoved: Appearance.padding.normal = value
                            Layout.preferredWidth: 200
                        }
                    }

                    SettingRow {
                        label: qsTr("Margin (Normal):")
                        StyledSlide {
                            from: 0
                            to: 50
                            stepSize: 1
                            value: Appearance.margin.normal
                            onMoved: Appearance.margin.normal = value
                            Layout.preferredWidth: 200
                        }
                    }
                }
            }

            SettingsCard {
                title: qsTr("Motion & Animation")

                SettingRow {
                    label: qsTr("Animation Durations Scale:")
                    StyledSlide {
                        from: 1
                        to: 5
                        stepSize: 1
                        showValuePopup: true
                        snapEnabled: true
                        value: Appearance.animations.durations.scale
                        onMoved: Appearance.animations.durations.scale = value
                        Layout.preferredWidth: 200
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                implicitHeight: Appearance.margin.large
            }
        }
    }

    component FilePathRow: RowLayout {
        id: filePathRow

        property string label
        property string configValue
        property var nameFilters: ["*.json"]
        signal configChanged(string value)
        Layout.fillWidth: true

        StyledText {
            text: filePathRow.label
            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        StyledTextInput {
            id: pathField

            implicitWidth: 350
            onEditingFinished: filePathRow.configChanged(text)
            toggleButtonVisible: false
            Component.onCompleted: text = filePathRow.configValue

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pathField.forceActiveFocus();
                    fileDialog.openFileDialog();
                }
            }
        }

        FileDialog {
            id: fileDialog

            nameFilters: filePathRow.nameFilters
            showHidden: true
            onFileSelected: path => filePathRow.configChanged(path)
        }
    }

    component FontPicker: Item {
        id: fontPicker

        property alias searchField: searchField.placeHolderText
        property string configValue
        signal configChanged(string value)

        implicitHeight: 48
        implicitWidth: 250

        property string searchText: ""
        property var filteredModel: {
            const query = searchText.toLowerCase();
            const result = [];
            for (let i = 0; i < Fontlist.fontListModel.count; i++) {
                const item = Fontlist.fontListModel.get(i);
                if (!query || item.name.toLowerCase().includes(query))
                    result.push(item);
            }
            return result;
        }

        StyledTextInput {
            id: searchField

            anchors.fill: parent
            placeHolderText: qsTr("Search font...")
            onTextChanged: {
                fontPicker.searchText = text;
                if (!popup.visible)
                    popup.open();
            }
            onActiveFocusChanged: {
                if (activeFocus && !popup.visible)
                    popup.open();
            }
            toggleButtonVisible: false
            Component.onCompleted: text = fontPicker.configValue
        }

        Popup {
            id: popup

            y: searchField.height + 4
            width: searchField.width
            implicitHeight: Math.min(listView.contentHeight + 16, 280)
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: StyledRect {
                color: Colours.m3Colors.m3SurfaceContainerLow
                radius: Appearance.rounding.large
                Elevation {
                    anchors.fill: parent
                    z: -1
                    level: 2
                    radius: parent.radius
                }
            }

            contentItem: ListView {
                id: listView

                clip: true
                model: fontPicker.filteredModel
                cacheBuffer: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: StyledRect {
                        implicitWidth: 4
                        radius: 2
                        color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    }
                }

                header: Item {
                    height: 8
                }
                footer: Item {
                    height: 8
                }

                delegate: ItemDelegate {
                    id: fontDelegate

                    required property var modelData
                    required property int index

                    readonly property bool itemActive: modelData.name === fontPicker.configValue

                    width: listView.width
                    height: 52
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 0
                    bottomPadding: 0

                    background: StyledRect {
                        radius: Appearance.rounding.large
                        color: fontDelegate.itemActive ? Colours.m3Colors.m3TertiaryContainer : fontDelegate.highlighted ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08) : "transparent"
                    }

                    contentItem: StyledText {
                        text: fontDelegate.modelData.name
                        font.family: fontDelegate.itemActive || fontDelegate.highlighted ? fontDelegate.modelData.name : ""
                        font.pixelSize: Appearance.fonts.size.normal
                        color: Colours.m3Colors.m3OnSurface
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        fontPicker.configChanged(modelData.name);
                        searchField.text = modelData.name;
                        fontPicker.searchText = "";
                        popup.close();
                    }
                }
            }
        }
    }
}
