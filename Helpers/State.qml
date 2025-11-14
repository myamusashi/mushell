pragma Singleton

import QtQuick

QtObject {
    id: globalState

    property bool notificationPopup: false
    property bool dashboardShow: false
    property bool sessionShow: false
    property bool screenCaptureShow: false
    property bool appLauncherShow: false
}
