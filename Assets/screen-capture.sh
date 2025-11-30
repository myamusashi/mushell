#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/screenshot"
VIDEO_DIR="$HOME/Videos/Shell"
THUMBNAIL_DIR="$HOME/.cache/thumbnails/normal"
RECORD_PID_FILE="/tmp/wl-screenrec.pid"

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$VIDEO_DIR"
mkdir -p "$THUMBNAIL_DIR"

IMG="$SCREENSHOT_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"
VID="$VIDEO_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"

create_thumbnail() {
	local file="$1"
	local output="$2"

	if [[ -z "$file" ]]; then
		echo "Error: File is empty"
		return 1
	fi

	if [ ! -f "$file" ]; then
		echo "Error: File $file does not exist"
		return 1
	fi

	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)

	if [[ -z "$duration" ]] || (($(echo "$duration < 1" | bc -l))); then
		echo "Error: Cannot get video duration or video too short"
		return 1
	fi

	timestamp=$(echo "$duration / 2" | bc -l)

	hours=$(printf "%02d" "$(echo "$timestamp / 3600" | bc)")
	minutes=$(printf "%02d" "$(echo "($timestamp % 3600) / 60" | bc)")
	seconds=$(printf "%02d" "$(echo "$timestamp % 60" | bc)")
	formatted_time="${hours}:${minutes}:${seconds}"

	ffmpeg -ss "$formatted_time" -i "$file" -vframes 1 -q:v 2 -vf "scale=256:-1" "$output" -y -v error 2>/dev/null

	if [ $? -eq 0 ] && [ -f "$output" ]; then
		echo "Thumbnail created: $output"
		return 0
	else
		echo "Error: Failed to create thumbnail"
		return 1
	fi
}

goto_link() {
	local file="$1"
	local thumb_path="$2"
	local show_notification="$3"

	if [ -z "$file" ]; then
		echo "ERROR: File variable is empty or not set"
		return 1
	fi
	if [ ! -f "$file" ]; then
		echo "ERROR: File $file does not exist"
		return 1
	fi

	if [ "$show_notification" = "true" ]; then
		if [ -n "$thumb_path" ] && [ -f "$thumb_path" ]; then
			ACTION=$(notify-send -a "screengrab" \
				--action="default=open link" \
				-i "$thumb_path" \
				"Capture Saved" \
				"${file}" \
				--wait)
		else
			ACTION=$(notify-send -a "screengrab" \
				--action="default=open link" \
				"Capture Saved" \
				"${file}" \
				--wait)
		fi
	else
		ACTION="default"
	fi

	case "$ACTION" in
	"default")
		if command -v foot >/dev/null 2>&1; then
			if command -v yazi >/dev/null 2>&1; then
				footclient yazi "$file" &
			else
				echo "ERROR: yazi command not found"
				xdg-open "$(dirname "$file")" &
			fi
		else
			echo "ERROR: foot command not found"
			xdg-open "$file" &
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

RECORD_PID_FILE="/tmp/wl-screenrec.pid"
RECORD_VIDEO_FILE="/tmp/wl-screenrec.video"

start_recording() {
	local geometry="$1"
	local output="$2"

	if [ -f "$RECORD_PID_FILE" ]; then
		notify-send -u critical -i dialog-warning -a "Screen Record" "Recording Active" "A recording is already in progress."
		return 1
	fi

	VID="$VIDEO_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"

	if [ -n "$geometry" ]; then
		wl-screenrec --codec hevc -g "$geometry" -f "$VID" &
	elif [ -n "$output" ]; then
		wl-screenrec --codec hevc -o "$output" -f "$VID" &
	else
		wl-screenrec --codec hevc -f "$VID" &
	fi

	echo $! >"$RECORD_PID_FILE"
	echo "$VID" >"$RECORD_VIDEO_FILE"
	notify-send -a "screenrecord" "Recording Started" "Press the same keybind again to stop recording."
}

stop_recording() {
	if [ -f "$RECORD_PID_FILE" ]; then
		PID=$(cat "$RECORD_PID_FILE")

		if [ -f "$RECORD_VIDEO_FILE" ]; then
			VID=$(cat "$RECORD_VIDEO_FILE")
		else
			notify-send -u critical -i dialog-error -a "Screen Record" "Recording Failed" "Cannot find video file path."
			rm "$RECORD_PID_FILE" 2>/dev/null
			return 1
		fi

		if ps -p "$PID" >/dev/null 2>&1; then
			kill -INT "$PID"
			wait "$PID" 2>/dev/null
			rm "$RECORD_PID_FILE"
			rm "$RECORD_VIDEO_FILE"

			sleep 1

			VIDEO_BASENAME=$(basename "$VID" .mp4)
			THUMB_PATH="$THUMBNAIL_DIR/${VIDEO_BASENAME}.png"

			# Buat thumbnail dan tampilkan SATU notifikasi saja
			if create_thumbnail "$VID" "$THUMB_PATH"; then
				notify-send -a "screenrecord" -i "$THUMB_PATH" "Recording Stopped" "Video saved to $VID"
			else
				notify-send -a "screenrecord" -i "video-x-generic" "Recording Stopped" "Video saved to $VID"
			fi

			# Panggil goto_link tanpa notifikasi (notifikasi sudah ditampilkan di atas)
			goto_link "$VID" "$THUMB_PATH" "false"
			return 0
		else
			rm "$RECORD_PID_FILE"
			rm "$RECORD_VIDEO_FILE" 2>/dev/null
			notify-send -u critical -i dialog-error -a "Screen Record" "Recording Failed" "No active recording found."
			return 1
		fi
	else
		notify-send -u critical -i dialog-error -a "Screen Record" "Recording Failed" "No active recording found."
		return 1
	fi
}

case "$1" in
"--screenshot-window")
	sleep 2
	output=$(hyprshot -m window -d -s -o "$HOME/Pictures/screenshot/" -f "$(date +%Y-%m-%d_%H-%M-%S).png")
	if ! [[ "$output" =~ "selection cancelled" ]]; then
		wl-copy <"$IMG"
		goto_link "$IMG" "$IMG" "true"
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot."
	fi
	;;

"--screenshot-selection")
	sleep 2
	grim -g "$(slurp)" "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link "$IMG" "$IMG" "true"
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot."
	fi
	;;

"--screenshot-eDP-1")
	sleep 2
	grim -c -o eDP-1 "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link "$IMG" "$IMG" "true"
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot on eDP-1."
	fi
	;;

"--screenshot-HDMI-A-2")
	sleep 2
	grim -c -o HDMI-A-2 "$IMG"
	if [ $? -eq 0 ]; then
		wl-copy <"$IMG"
		goto_link "$IMG" "$IMG" "true"
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
		goto_link "$IMG" "$IMG" "true"
	else
		notify-send -u critical -i dialog-error -a "Screen Capture" "Screenshot Failed" "Failed to take screenshot on both screens."
	fi
	;;

"--screenrecord-selection")
	if [ -f "$RECORD_PID_FILE" ]; then
		stop_recording
	else
		sleep 2
		GEOMETRY=$(slurp)
		if [ $? -eq 0 ]; then
			start_recording "$GEOMETRY" ""
		else
			notify-send -u critical -i dialog-error -a "Screen Record" "Recording Failed" "Selection cancelled."
		fi
	fi
	;;

"--screenrecord-eDP-1")
	if [ -f "$RECORD_PID_FILE" ]; then
		stop_recording
	else
		sleep 2
		start_recording "" "eDP-1"
	fi
	;;

"--screenrecord-HDMI-A-2")
	if [ -f "$RECORD_PID_FILE" ]; then
		stop_recording
	else
		sleep 2
		start_recording "" "HDMI-A-2"
	fi
	;;

"--screenrecord-both-screens")
	if [ -f "$RECORD_PID_FILE" ]; then
		stop_recording
	else
		sleep 2
		start_recording "" ""
	fi
	;;

"--stop-recording")
	stop_recording
	;;

*)
	echo "Usage: $0 {--screenshot-window|--screenshot-selection|--screenshot-eDP-1|--screenshot-HDMI-A-2|--screenshot-both-screens|--screenrecord-selection|--screenrecord-eDP-1|--screenrecord-HDMI-A-2|--screenrecord-both-screens|--stop-recording}"
	exit 1
	;;
esac
