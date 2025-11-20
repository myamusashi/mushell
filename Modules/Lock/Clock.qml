import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

import qs.Configs
import qs.Components

ColumnLayout {
    id: root

    property var currentDate: new Date()

    function getDayName(index) {
        const days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
        return days[index]
    }

    function getMonthName(index) {
        const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Des"]
        return months[index]
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentDate = new Date()
    }

    StyledRect {
        id: clockContainer

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 340 + hours.width
        Layout.preferredHeight: 340

        color: Themes.withAlpha(Themes.m3Colors.surfaceContainerHighest, 0.15)
        radius: width / 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Themes.withAlpha(Themes.m3Colors.shadow, 0.4)
            shadowBlur: 0.8
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        StyledRect {
            anchors.fill: parent
            anchors.margins: 3
            color: "transparent"
            radius: parent.radius - 3
            border.width: 1
            border.color: Themes.withAlpha(Themes.m3Colors.primary, 0.2)
        }

        StyledRect {
            anchors.fill: parent
            anchors.margins: 2
            color: Themes.withAlpha(Themes.m3Colors.surfaceBright, 0.05)
            radius: parent.radius - 2

            border.width: 2
            border.color: Themes.withAlpha(Themes.m3Colors.outlineVariant, 0.3)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            StyledLabel {
                id: hours

                font.pixelSize: Appearance.fonts.extraLarge * 5
                font.family: Appearance.fonts.familySans
                font.weight: Font.Medium
                color: Themes.m3Colors.onSurface
                renderType: Text.NativeRendering
                text: {
                    const hours = root.currentDate.getHours().toString(
                                    ).padStart(2, '0')
                    const minutes = root.currentDate.getMinutes().toString(
                                      ).padStart(2, '0')
                    return `${hours}:${minutes}`
                }
                Layout.alignment: Qt.AlignHCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Themes.withAlpha(Themes.m3Colors.scrim, 0.3)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 2
                }
            }

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 70
                Layout.preferredHeight: 36

                color: Themes.withAlpha(Themes.m3Colors.primaryContainer, 0.15)
                radius: 18

                border.width: 1
                border.color: Themes.withAlpha(Themes.m3Colors.primary, 0.2)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Themes.withAlpha(Themes.m3Colors.shadow, 0.25)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 2
                }

                StyledLabel {
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.fonts.medium * 1.6
                    font.family: Appearance.fonts.familyMono
                    font.weight: Font.Medium
                    color: Themes.m3Colors.onSurface
                    renderType: Text.NativeRendering
                    text: root.currentDate.getSeconds().toString().padStart(2,
                                                                            '0')
                }
            }
        }
    }

    Item {
        Layout.preferredHeight: 28
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: dayStyledLabel.width + 24
            Layout.preferredHeight: 40

            color: Themes.withAlpha(Themes.m3Colors.surfaceContainerHigh, 0.6)
            radius: 20

            border.width: 1
            border.color: Themes.withAlpha(Themes.m3Colors.outline, 0.2)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Themes.withAlpha(Themes.m3Colors.shadow, 0.4)
                shadowBlur: 0.8
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
            }

            StyledLabel {
                id: dayStyledLabel
                anchors.centerIn: parent
                font.pixelSize: Appearance.fonts.medium * 2.2
                font.family: Appearance.fonts.familySans
                font.weight: Font.Medium
                color: Themes.m3Colors.onSurface
                renderType: Text.NativeRendering
                text: root.getDayName(root.currentDate.getDay())
            }
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: dateStyledLabel.width + 20
            Layout.preferredHeight: 36

            color: Themes.withAlpha(Themes.m3Colors.surfaceContainer, 0.6)
            radius: 18

            border.width: 1
            border.color: Themes.withAlpha(Themes.m3Colors.outlineVariant, 0.15)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Themes.withAlpha(Themes.m3Colors.shadow, 0.4)
                shadowBlur: 0.8
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
            }

            StyledLabel {
                id: dateStyledLabel

                anchors.centerIn: parent
                font.pixelSize: Appearance.fonts.medium * 1.8
                font.family: Appearance.fonts.familySans
                font.weight: Font.Normal
                color: Themes.m3Colors.onSurface
                renderType: Text.NativeRendering
                text: `${root.currentDate.getDate()} ${root.getMonthName(
                          root.currentDate.getMonth())}`
            }
        }
    }
}
