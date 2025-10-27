
# Taruh file systemd dan script ini ke $HOME/.config/systemd/user/ untuk generate dynamic colors

###### matugen-watcher.path
```toml
[Install]
WantedBy=default.target

[Path]
PathChanged=%h/.cache/wall/path.txt
Unit=matugen-watcher.service

[Unit]
Description=Watch for wallpaper path changes
```

```toml
[Install]
WantedBy=default.target

[Service]
ExecStart=matugen-wrapper
RemainAfterExit=false
Type=oneshot

[Unit]
After=graphical-session.target
Description=Matugen wallpaper color scheme generator
```

```bash
#!/usr/bin/env bash
PATH_FILE="$HOME/.cache/wall/path.txt"

mkdir -p "$HOME/.cache/wall/"

if [ ! -f "$PATH_FILE" ]; then
  echo "Error: $PATH_FILE not found"
  exit 1
fi

WALLPAPER_PATH=$(cat "$PATH_FILE")

if [ ! -f "$WALLPAPER_PATH" ]; then
  echo "Error: Path for file wallpaper not found: $WALLPAPER_PATH"
  exit 1
fi

matugen image "$WALLPAPER_PATH" -t scheme-tonal-spot
```
