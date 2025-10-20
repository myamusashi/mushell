pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
	id: root

	FileView {
		id: wallid
		path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.cache/wall/path.txt")

		watchChanges: true

		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
	}

	property string wallSrc: wallid.text()

	Variants {
		model: Quickshell.screens

		delegate: WlrLayershell {
			id: wall

			required property ShellScreen modelData

			anchors {
				left: true
				right: true
				top: true
				bottom: true
			}

			color: "transparent"
			screen: modelData
			layer: WlrLayer.Background
			focusable: false

			exclusiveZone: 1
			surfaceFormat.opaque: false

			Image {
				id: img

				antialiasing: true

				asynchronous: true

				mipmap: true
				smooth: true

				source: root.wallSrc.trim()

				fillMode: Image.PreserveAspectFit
				width: parent.width
				height: parent.height
			}
		}
	}
	IpcHandler {
		target: "img"

		function set(path: string): void {
			Quickshell.execDetached({
				command: ["sh", "-c", "echo " + path + " >" + Quickshell.env("HOME") + "/.cache/wall/path.txt"]
			});
		}
		function get(): string {
			return root.wallSrc.trim();
		}
	}
}
