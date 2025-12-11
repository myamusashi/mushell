import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    visible: Record.isRecordingControlOpen
    color: "transparent"

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;

        if (hours > 0)
            return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

        return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }

    RowLayout {
        anchors.centerIn: parent

        MaterialIcon {
            icon: "screen_record"
            font.pixelSize: 24
            color: Colours.m3Colors.m3OnPrimary
        }

        StyledText {
            text: root.formatTime(Record.recordingSeconds)
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
        }
    }
}
