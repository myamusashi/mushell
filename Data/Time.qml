pragma Singleton

import Quickshell
import QtQuick

SystemClock {
	id: clock

	enabled: true
	precision: SystemClock.Seconds
}
