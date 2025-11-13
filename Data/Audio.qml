pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
	id: root

	function getIcon(node: PwNode): string {
		return (node.isSink) ? getSinkIcon(node) : getSourceIcon(node);
	}

	function getSinkIcon(node: PwNode): string {
		return (node.audio.muted) ? "volume_off" : (node.audio.volume > 0.5) ? "volume_up" : (
																				   node.audio.volume > 0.01) ? "volume_down" : "volume_mute";
	}

	function getSourceIcon(node: PwNode): string {
		return (node.audio.muted) ? "mic_off" : "mic";
	}

	function toggleMute(node: PwNode) {
		node.audio.muted = !node.audio.muted;
	}

	function wheelAction(event: WheelEvent, node: PwNode) {
		if (event.angleDelta.y < 0)
			node.audio.volume -= 0.01;
		else
			node.audio.volume += 0.01;

		if (node.audio.volume > 1.3)
			node.audio.volume = 1.3;

		if (node.audio.volume < 0)
			node.audio.volume = 0.0;
	}
}
