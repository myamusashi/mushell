#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/screenshot"

mkdir -p "$SCREENSHOT_DIR"

IMG="$SCREENSHOT_DIR/$(date +%Y-%m-%d_%H-%m-%s).png"

goto_link() {
	if [ -z "$IMG" ]; then
		echo "ERROR: IMG variable is empty or not set"
		return 1
	fi

	if [ ! -f "$IMG" ]; then
		echo "ERROR: File $IMG does not exist"
		return 1
	fi

	ACTION=$(notify-send -a "screengrab" \
		--action="default=open link" \
		-i "$IMG" \
		"Screenshot Taken" \
		"${IMG}" \
		--wait)

	case "$ACTION" in
	"default")
		if command -v foot >/dev/null 2>&1; then
			if command -v yazi >/dev/null 2>&1; then
				footclient yazi "$IMG" &
			else
				echo "ERROR: yazi command not found"
				xdg-open "$(dirname "$IMG")" &
			fi
		else
			echo "ERROR: foot command not found"
			xdg-open "$IMG" &
		fi
		;;
	"")
		echo "No action taken (notification dismissed or timeout)"
		;;
	*)
		echo "Unexpected action: '$ACTION'"
		;;
	esac
}

case "$1" in
"--screenshot-window")
	sleep 3
	output=$(hyprshot -m window -d -s -o "$HOME/Pictures/screenshot/" -f "$(date +%Y-%m-%d_%H-%m-%s).png")
	if ! [[ "$output" =~ "selection cancelled" ]]; then
		wl-copy <"$IMG"
		goto_link
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot."
	fi
	exit
	;;
"--screenshot-selection")
	sleep 3
	grim -g "$(slurp)" "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot."
	fi
	exit
	;;
"--screenshot-eDP-1")
	sleep 2
	grim -c -o eDP-1 "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot on eDP-1."
	fi

	;;
"--screenshot-HDMI-A-2")
	sleep 2
	grim -c -o HDMI-A-2 "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot on HDMI-A-2."
	fi

	;;
"--screenshot-both-screens")
	sleep 2
	grim -c -o eDP-1 "${IMG//.png/-eDP-1.png}"
	GRIM_EDP=$?
	grim -c -o HDMI-A-2 "${IMG//.png/-HDMI-A-2.png}"
	GRIM_HDMI=$?

	if [ $GRIM_EDP -eq 0 ] && [ $GRIM_HDMI -eq 0 ]; then
		montage "${IMG//.png/-eDP-1.png}" "${IMG//.png/-HDMI-A-2.png}" -tile 2x1 -geometry +0+0 "$IMG"
		wl-copy <"$IMG"
		rm "${IMG//.png/-eDP-1.png}" "${IMG//.png/-HDMI-A-2.png}"
		goto_link
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot on both screens."
	fi

	;;
*)
	# User cancelled or no selection
	exit 0
	;;
esac
