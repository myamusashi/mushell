#!/usr/bin/env bash

set -euo pipefail

readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die() {
	error "$*"
	exit 1
}

INSTALL_DIR=""
BIN_DIR=""
FONT_DIR=""
QML_DIR=""
BUILD_DIR=""
PROJECT_ROOT=""
M3SHAPES_REV=""
ANOTHER_RIPPLE_REV=""

init_globals() {
	INSTALL_DIR="/usr/local/share/quickshell"
	BIN_DIR="/usr/local/bin"
	FONT_DIR="/usr/local/share/fonts"
	QML_DIR="/usr/lib/qt6/qml"
	BUILD_DIR="/tmp/quickshell-build"
	PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)" || die "Failed to determine project root"
	M3SHAPES_REV="1c8e6751febf230d7f94bf8015eaeb643bb4521e"
	ANOTHER_RIPPLE_REV="main"
	WL_SCREENREC_REV="cc280b238ab99cdeefa70afcceaf09a1f98fe982"

	readonly INSTALL_DIR BIN_DIR FONT_DIR QML_DIR BUILD_DIR PROJECT_ROOT M3SHAPES_REV ANOTHER_RIPPLE_REV WL_SCREENREC_REV
}

check_root() {
	[[ $EUID -eq 0 ]] || die "System-wide installation requires root. Run with sudo."
}

check_distro() {
	command -v pacman &>/dev/null || die "This script is designed for Arch Linux and derivatives"
}

install_system_packages() {
	local -a missing=()
	# ddcutil added — required for external monitor brightness via DDC/CI
	# i2c-tools added — provides i2cdetect for debugging
	# wayland added — libwayland-client + wayland-scanner for the clipboard
	#   manager's native ext_data_control_v1 binding (protocol XML is vendored
	#   in Plugins/Vast/Clipboard/protocols, so wayland-protocols is not
	#   required).
	local -r pkg_list=(
		base-devel git cmake ninja extra-cmake-modules patchelf pkgconf
		qt6-base qt6-declarative qt6-svg qt6-graphs qt6-multimedia qt6-5compat qt6-shadertools qt6-tools
		rust pipewire ddcutil i2c-tools go wayland
		findutils grep sed gawk util-linux libnotify wireplumber
		iw polkit wl-clipboard ffmpeg foot hyprland xdg-desktop-portal
	)

	log "Checking system dependencies..."
	for pkg in "${pkg_list[@]}"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done

	if ((${#missing[@]})); then
		log "Installing ${#missing[@]} system packages..."
		pacman -S --needed --noconfirm "${missing[@]}"
	else
		log "All system packages already installed"
	fi
}

setup_aur_helper() {
	command -v yay &>/dev/null && return 0

	log "Installing yay AUR helper..."
	local -r aur_user="${SUDO_USER:-nobody}"

	git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
	chown -R "$aur_user:$aur_user" "$BUILD_DIR/yay"

	pushd "$BUILD_DIR/yay" >/dev/null
	if [[ -n ${SUDO_USER:-} ]]; then
		sudo -u "$SUDO_USER" makepkg -si --noconfirm
	else
		warn "SUDO_USER not set. Attempting to build as nobody..."
		sudo -u nobody makepkg -si --noconfirm || die "Failed to build yay"
	fi
	popd >/dev/null
}

install_aur_packages() {
	local -r aur_user="${SUDO_USER:-}"
	local -a missing=()
	local -r pkg_list=(
		google-breakpad matugen-bin ttf-weather-icons
		app2unit ttf-material-symbols-variable-git quickshell-git
	)

	log "Checking AUR packages..."
	for pkg in "${pkg_list[@]}"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done

	((${#missing[@]})) || {
		log "All AUR packages already installed"
		return 0
	}
	[[ -n $aur_user ]] || die "AUR builds require a non-root user. Run with sudo."

	sudo -u "$aur_user" yay -S --needed --noconfirm "${missing[@]}"

	log "Installing wl-screenrec from fork..."
	build_wl_screenrec
}

# ensures the current user is in the i2c and video groups,
# and that i2c-dev is loaded now + persisted across reboots.
setup_i2c() {
	local -r target_user="${SUDO_USER:-}"

	[[ -d /run/udev ]] || {
		warn "No udev detected — skipping i2c setup"
		return 0
	}

	if ! lsmod | grep -q "^i2c_dev"; then
		log "Loading i2c-dev kernel module..."
		modprobe i2c-dev || warn "modprobe i2c-dev failed — DDC/CI may not work this session"
	else
		log "i2c-dev already loaded"
	fi

	if [[ ! -f /etc/modules-load.d/i2c-dev.conf ]]; then
		log "Persisting i2c-dev via /etc/modules-load.d..."
		echo "i2c-dev" >/etc/modules-load.d/i2c-dev.conf
	fi

	local -r udev_rule="/etc/udev/rules.d/45-ddcutil-i2c.rules"
	if [[ ! -f $udev_rule ]]; then
		log "Installing udev rule for DDC/CI access..."
		cat >"$udev_rule" <<'EOF'
KERNEL=="i2c-[0-9]*", TAG+="uaccess", GROUP="i2c", MODE="0660"
EOF
		udevadm control --reload-rules 2>/dev/null || warn "udevadm reload failed — skipping"
		udevadm trigger --subsystem-match=i2c 2>/dev/null || true
	fi

	if [[ -n $target_user ]]; then
		local -a groups_to_add=()
		id -nG "$target_user" | grep -qw "i2c" || groups_to_add+=("i2c")
		id -nG "$target_user" | grep -qw "video" || groups_to_add+=("video")

		if ((${#groups_to_add[@]})); then
			log "Adding $target_user to groups: ${groups_to_add[*]}"
			usermod -aG "$(
				IFS=,
				echo "${groups_to_add[*]}"
			)" "$target_user"
			warn "Group changes take effect on next login — DDC/CI may fail until then"
		else
			log "User $target_user already in i2c and video groups"
		fi
	else
		warn "SUDO_USER not set — skipping group assignment. Add yourself to i2c and video groups manually."
	fi

	if compgen -G "/dev/i2c-*" >/dev/null 2>&1; then
		log "DDC/CI devices found: $(ls /dev/i2c-* | tr '\n' ' ')"
	else
		warn "No /dev/i2c-* devices found — external monitor brightness control unavailable"
	fi
}

build_vast_plugin() {
	local -r core_so="$QML_DIR/Vast/lib/libvast-core.so"
	[[ -f $core_so ]] && {
		log "Vast plugins already installed"
		return 0
	}

	local -r src="$PROJECT_ROOT/Plugins"
	[[ -d $src ]] || {
		warn "Plugins not found, skipping"
		return 0
	}

	log "Building Vast Qt plugins..."
	local -r build="$BUILD_DIR/Vast-build"
	local -r install_base="$BUILD_DIR/Vast-install"

	cmake -S "$src" -B "$build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$install_base"
	ninja -C "$build"
	ninja -C "$build" install

	mkdir -p "$QML_DIR/Vast"
	local found=0
	for dir in \
		"$install_base/usr/lib/qt6/qml/Vast" \
		"$install_base/usr/lib/qt-6/qml/Vast" \
		"$install_base/lib/qt6/qml/Vast" \
		"$install_base/lib/qt-6/qml/Vast" \
		"$install_base/Vast"; do
		if [[ -d $dir ]]; then
			cp -r "$dir/"* "$QML_DIR/Vast/"
			found=1
			break
		fi
	done
	((found)) || die "Vast install tree not found under $install_base"

	# The Vast namespace is split into per-domain QML modules
	# (Vast.Audio, Vast.Clipboard, ...). Backing targets live in
	# Vast/lib, plugins in Vast/<Module>/. Patch an rpath on every
	# shared object so they can find each other and the Qt deps.
	local qt_libs pw_lib ddc_lib wl_lib
	qt_libs=""
	for mod in Qt6Core Qt6Gui Qt6Qml Qt6Quick Qt6Sql Qt6Network; do
		local lib
		lib=$(pkg-config --variable=libdir "$mod" 2>/dev/null || true)
		[[ -n $lib && -z $qt_libs ]] && qt_libs="$lib"
		[[ -n $lib ]] && qt_libs="$qt_libs:$lib"
	done
	pw_lib=$(pkg-config --variable=libdir libpipewire-0.3)
	ddc_lib=$(pkg-config --variable=libdir ddcutil)
	wl_lib=$(pkg-config --variable=libdir wayland-client)
	local deps="$qt_libs:$pw_lib:$ddc_lib:$wl_lib"

	local so_file
	while IFS= read -r -d '' so_file; do
		patchelf --set-rpath "$(dirname "$so_file"):$QML_DIR/Vast/lib:$deps" "$so_file" 2>/dev/null || true
	done < <(find "$QML_DIR/Vast" -name '*.so' -print0)

	[[ -f $core_so ]] || warn "Vast plugin .so not found after install — check build output"
}

build_m3shapes() {
	local -r plugin="$QML_DIR/M3Shapes/libm3shapesplugin.so"
	[[ -f $plugin ]] && {
		log "m3shapes already installed"
		return 0
	}

	log "Building m3shapes..."
	local -r src="$BUILD_DIR/m3shapes"

	[[ -d $src ]] || git clone https://github.com/myamusashi/m3shapes.git "$src"
	git -C "$src" checkout "$M3SHAPES_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$M3SHAPES_REV"
	}

	cmake -S "$src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/m3shapes-install"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	mkdir -p "$QML_DIR/M3Shapes"
	local install_base="$BUILD_DIR/m3shapes-install"
	[[ -d $install_base/M3Shapes ]] && cp -r "$install_base/M3Shapes/"* "$QML_DIR/M3Shapes/"
	[[ -d $install_base/usr/lib/qt6/qml/M3Shapes ]] && cp -r "$install_base/usr/lib/qt6/qml/M3Shapes/"* "$QML_DIR/M3Shapes/"

	if [[ -f $plugin ]]; then
		local qt_core_lib
		qt_core_lib=$(pkg-config --variable=libdir Qt6Core)
		patchelf --set-rpath "$QML_DIR/M3Shapes:$qt_core_lib" "$plugin" 2>/dev/null || true
	fi
}

compile_shaders() {
	local -r shader_dir="$PROJECT_ROOT/Assets/shaders"
	local -r transition_dir="$shader_dir/transitions"
	local -r vert_src="$shader_dir/ImageTransition.vert"
	local -r vert_out="$shader_dir/ImageTransition.vert.qsb"

	local qsb
	qsb=$(command -v qsb 2>/dev/null || command -v qsb6 2>/dev/null || true)
	[[ -n $qsb ]] || qsb=$(find /usr/lib/qt6 /usr/lib/qt /opt/qt6 -name "qsb" -type f 2>/dev/null | head -1 || true)
	[[ -n $qsb ]] || {
		warn "qsb not found — skipping shader compilation \(qt6-shadertools required\)"
		return 0
	}

	local -r qsb_flags=(--glsl "450,330,300 es" --hlsl 50 --msl 12)

	local -ra transitions=(
		fade wipeDown hexTile circleExpand dissolve splitHorizontal
		slideUp pixelate diagonalWipe boxExpand roll
	)

	if [[ ! -f $vert_src ]]; then
		warn "Vertex shader not found: $vert_src"
	elif [[ ! -f $vert_out || $vert_src -nt $vert_out ]]; then
		log "Compiling vertex shader..."
		"$qsb" "${qsb_flags[@]}" -o "$vert_out" "$vert_src" ||
			die "Failed to compile vertex shader: $vert_src"
		log "  → $(basename "$vert_out")"
	else
		log "Vertex shader up to date"
	fi

	[[ -d $transition_dir ]] || {
		warn "Transitions directory not found: $transition_dir — skipping"
		return 0
	}

	log "Compiling transition shaders..."
	local failed=0
	for name in "${transitions[@]}"; do
		local src="$transition_dir/${name}.frag"
		local out="$transition_dir/${name}.frag.qsb"

		[[ -f $src ]] || {
			warn "  Missing: ${name}.frag — skipping"
			continue
		}
		[[ -f $out && $src -ot $out ]] && {
			log "  Up to date: ${name}.frag.qsb"
			continue
		}

		if "$qsb" "${qsb_flags[@]}" -o "$out" "$src"; then
			log "  → ${name}.frag.qsb"
		else
			warn "  FAILED: ${name}.frag.qsb"
			((failed++)) || true
		fi
	done

	((failed == 0)) || warn "$failed shader failed to compile"

	log "Compiling border progress shaders..."
	local -r border_vert_src="$shader_dir/borderProgress.vert"
	local -r border_vert_out="$shader_dir/borderProgress.vert.qsb"
	local -r border_frag_src="$shader_dir/borderProgress.frag"
	local -r border_frag_out="$shader_dir/borderProgress.frag.qsb"

	if [[ -f $border_vert_src ]]; then
		if [[ ! -f $border_vert_out || $border_vert_src -nt $border_vert_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$border_vert_out" "$border_vert_src" &&
				log "  → borderProgress.vert.qsb" ||
				warn "  FAILED: borderProgress.vert.qsb"
		else
			log "  Up to date: borderProgress.vert.qsb"
		fi
	fi

	if [[ -f $border_frag_src ]]; then
		if [[ ! -f $border_frag_out || $border_frag_src -nt $border_frag_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$border_frag_out" "$border_frag_src" &&
				log "  → borderProgress.frag.qsb" ||
				warn "  FAILED: borderProgress.frag.qsb"
		else
			log "  Up to date: borderProgress.frag.qsb"
		fi
	fi

	log "Compiling wavy and wave form..."
	local -r wavy_vert_src="$shader_dir/wavy.vert"
	local -r wavy_vert_out="$shader_dir/wavy.vert.qsb"
	local -r wavy_frag_src="$shader_dir/wavy.frag"
	local -r wavy_frag_out="$shader_dir/wavy.frag.qsb"
	local -r waveForm_vert_src="$shader_dir/waveForm.vert"
	local -r waveForm_vert_out="$shader_dir/waveForm.vert.qsb"
	local -r waveForm_frag_src="$shader_dir/waveForm.frag"
	local -r waveForm_frag_out="$shader_dir/waveForm.frag.qsb"

	if [[ -f $wavy_vert_src ]]; then
		if [[ ! -f $wavy_vert_out || $wavy_vert_src -nt $wavy_vert_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$wavy_vert_out" "$wavy_vert_src" &&
				log "  → wavy.vert.qsb" ||
				warn "  FAILED: wavy.vert.qsb"
		else
			log "  Up to date: wavy.vert.qsb"
		fi
	fi

	if [[ -f $wavy_frag_src ]]; then
		if [[ ! -f $wavy_frag_out || $wavy_frag_src -nt $wavy_frag_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$wavy_frag_out" "$wavy_frag_src" &&
				log "  → wavy.frag.qsb" ||
				warn "  FAILED: wavy.frag.qsb"
		else
			log "  Up to date: wavy.frag.qsb"
		fi
	fi

	if [[ -f $waveForm_vert_src ]]; then
		if [[ ! -f $waveForm_vert_out || $waveForm_vert_src -nt $waveForm_vert_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$waveForm_vert_out" "$waveForm_vert_src" &&
				log "  → waveForm.vert.qsb" ||
				warn "  FAILED: waveForm.vert.qsb"
		else
			log "  Up to date: waveForm.vert.qsb"
		fi
	fi

	if [[ -f $waveForm_frag_src ]]; then
		if [[ ! -f $waveForm_frag_out || $waveForm_frag_src -nt $waveForm_frag_out ]]; then
			"$qsb" "${qsb_flags[@]}" -o "$waveForm_frag_out" "$waveForm_frag_src" &&
				log "  → waveForm.frag.qsb" ||
				warn "  FAILED: waveForm.frag.qsb"
		else
			log "  Up to date: waveForm.frag.qsb"
		fi
	fi
}

build_another_ripple() {
	local -r plugin="$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"
	[[ -f $plugin ]] && {
		log "AnotherRipple already installed"
		return 0
	}

	log "Building AnotherRipple..."
	local -r src="$BUILD_DIR/Another-Ripple"

	[[ -d $src ]] || git clone https://github.com/myamusashi/Another-Ripple.git "$src"
	git -C "$src" checkout "$ANOTHER_RIPPLE_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$ANOTHER_RIPPLE_REV"
	}

	local -r cmake_src="$src/AnotherRipple"
	[[ -d $cmake_src ]] || die "AnotherRipple subdirectory not found in repo: $cmake_src"

	cmake -S "$cmake_src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DCMAKE_INSTALL_PREFIX="$BUILD_DIR/anotherripple-install" \
		-DINSTALL_QMLDIR="usr/lib/qt6/qml"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	mkdir -p "$QML_DIR/AnotherRipple"
	local install_base="$BUILD_DIR/anotherripple-install"
	for dir in \
		"$install_base/usr/lib/qt6/qml/AnotherRipple" \
		"$install_base/usr/lib/qt-6/qml/AnotherRipple" \
		"$install_base/lib/qt6/qml/AnotherRipple" \
		"$install_base/lib/qt-6/qml/AnotherRipple" \
		"$install_base/AnotherRipple"; do
		[[ -d $dir ]] && cp -r "$dir/"* "$QML_DIR/AnotherRipple/"
	done

	local qt_core_lib qt_qml_lib
	qt_core_lib=$(pkg-config --variable=libdir Qt6Core)
	qt_qml_lib=$(pkg-config --variable=libdir Qt6Qml)

	for lib in \
		"$QML_DIR/AnotherRipple/libAnotherRipple.so" \
		"$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"; do
		[[ -f $lib ]] && patchelf --set-rpath "$QML_DIR/AnotherRipple:$qt_core_lib:$qt_qml_lib" "$lib" 2>/dev/null || true
	done

	[[ -f $plugin ]] || warn "AnotherRipple plugin not found after installation"
}

compile_translations() {
	[[ -d $PROJECT_ROOT/translations ]] || return 0

	local lrelease_bin
	lrelease_bin=$(command -v /usr/lib/qt6/bin/lrelease 2>/dev/null ||
		command -v lrelease 2>/dev/null ||
		true)

	[[ -n $lrelease_bin ]] || {
		warn "lrelease not found — install qt6-tools: pacman -S qt6-tools"
		return 0
	}

	log "Compiling translations with $(basename "$lrelease_bin")..."
	"$lrelease_bin" "$PROJECT_ROOT/translations/"*.ts 2>/dev/null || true
}

install_quickshell_config() {
	log "Installing quickshell configuration..."
	rm -rf "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"

	find "$PROJECT_ROOT" -mindepth 1 -maxdepth 1 ! -name "build" -exec cp -r {} "$INSTALL_DIR/" \; 2>/dev/null || true

	[[ -d $PROJECT_ROOT/Assets ]] && cp -r "$PROJECT_ROOT/Assets" "$INSTALL_DIR/"

	chmod -R 755 "$INSTALL_DIR"
	chown -R root:root "$INSTALL_DIR"

	if [[ -f $INSTALL_DIR/Qml/shell.qml ]]; then
		sed -i 's/ShellRoot {/ShellRoot { settings.watchFiles: false/' "$INSTALL_DIR/Qml/shell.qml"
	fi

	log "Setting global VAST_SHELL_DIRECTORY..."
	cat >/etc/profile.d/vast-shell.sh <<'EOF'
export VAST_SHELL_DIRECTORY="/usr/local/share/quickshell"
EOF
	chmod 644 /etc/profile.d/vast-shell.sh
}

setup_user_config() {
	local -r target_user="${SUDO_USER:-$USER}"
	local -r user_home=$(getent passwd "$target_user" | cut -d: -f6)

	[[ -n $user_home ]] || {
		warn "Could not determine home directory for $target_user — skipping user config setup"
		return 0
	}

	local -r vast_config_dir="$user_home/.config/vast-shell"
	local -r matugen_config_dir="$user_home/.config/matugen"

	log "Setting up user configuration for $target_user..."

	# Create directories
	mkdir -p "$vast_config_dir" "$matugen_config_dir"

	# Copy vast-shell data
	cp -r "$PROJECT_ROOT/Data/"* "$vast_config_dir/"

	# Setup matugen config
	if [[ ! -f "$matugen_config_dir/config.toml" ]]; then
		if [[ -f "$PROJECT_ROOT/Data/matugen/matugen.toml" ]]; then
			cp "$PROJECT_ROOT/Data/matugen/matugen.toml" "$matugen_config_dir/config.toml"
			# Replace placeholder paths in matugen config
			sed -i "s|/home/<user>|$user_home|g" "$matugen_config_dir/config.toml"
			# Fix input_path after flattening Data/ contents into vast-shell config dir
			sed -i "s|vast-shell/Data/matugen/|vast-shell/matugen/|g" "$matugen_config_dir/config.toml"
		fi
	fi

	# Fix ownership
	chown -R "$target_user:$target_user" "$vast_config_dir" "$matugen_config_dir"
}

create_wrapper() {
	log "Creating wrapper script..."
	cat >"$BIN_DIR/shell" <<'EOF'
#!/bin/bash
export QUICKSHELL_CONFIG_DIR="/usr/local/share/quickshell"
export QT_QPA_FONTDIR="/usr/local/share/fonts"
export QML2_IMPORT_PATH="/usr/lib/qt6/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin${HOME:+:$HOME/.local/bin}${PATH:+:$PATH}"
export PATH="$PATH:/opt/bin:/usr/games:/usr/local/games"
export PATH="$PATH:/var/lib/flatpak/exports/bin${HOME:+:$HOME/.local/share/flatpak/exports/bin}"
[[ -d /snap/bin ]] && export PATH="$PATH:/snap/bin"
exec quickshell -p "$QUICKSHELL_CONFIG_DIR/Qml" "$@"
EOF
	chmod +x "$BIN_DIR/shell"
}

build_wl_screenrec() {
	local -r binary="/usr/local/bin/wl-screenrec"
	[[ -f $binary ]] && {
		log "wl-screenrec already installed"
		return 0
	}

	log "Building wl-screenrec from fork..."
	local -r src="$BUILD_DIR/wl-screenrec"

	[[ -d $src ]] || git clone https://github.com/myamusashi/wl-screenrec.git "$src"
	git -C "$src" checkout "$WL_SCREENREC_REV" 2>/dev/null || {
		git -C "$src" fetch
		git -C "$src" checkout "$WL_SCREENREC_REV"
	}

	pushd "$src" >/dev/null
	cargo build --release || warn "wl-screenrec build failed — screen recording unavailable"
	[[ -f target/release/wl-screenrec ]] && install -Dm755 target/release/wl-screenrec "$binary"
	popd >/dev/null

	[[ -f $binary ]] || warn "wl-screenrec binary not found after build"
}

build_vastctl() {
	local -r binary="$BIN_DIR/vastctl"
	[[ -f $binary ]] && {
		log "vastctl already installed"
		return 0
	}
	command -v go &>/dev/null || {
		warn "Go not found — skipping vastctl build. Install go: pacman -S go"
		return 0
	}

	log "Building vastctl..."
	pushd "$PROJECT_ROOT/vastctl" >/dev/null
	go mod tidy
	go build -ldflags="-s -w" -o "$binary" . || {
		warn "vastctl build failed"
		popd >/dev/null
		return 0
	}
	popd >/dev/null

	# shell completions
	mkdir -p /usr/share/bash-completion/completions
	"$binary" completion bash > /usr/share/bash-completion/completions/vastctl

	mkdir -p /usr/share/fish/vendor_completions.d
	"$binary" completion fish > /usr/share/fish/vendor_completions.d/vastctl.fish

	mkdir -p /usr/share/zsh/site-functions
	"$binary" completion zsh > /usr/share/zsh/site-functions/_vastctl

	mkdir -p /usr/share/nushell/completions
	"$binary" completion nushell > /usr/share/nushell/completions/vastctl.nu

	log "vastctl installed to $BIN_DIR"
}

cleanup_build_deps() {
	local -r build_deps=(
		base-devel cmake ninja extra-cmake-modules patchelf pkgconf
		qt6-shadertools qt6-tools rust git
	)

	local -a to_remove=()
	for pkg in "${build_deps[@]}"; do
		pacman -Qi "$pkg" &>/dev/null && to_remove+=("$pkg")
	done

	if ((${#to_remove[@]})); then
		log "Removing build-time dependencies: ${to_remove[*]}"
		pacman -Rns --noconfirm "${to_remove[@]}" || warn "Failed to remove some build dependencies"
	fi
}

main() {
	init_globals
	check_root
	check_distro

	log "Creating directories..."
	mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

	install_system_packages
	setup_aur_helper
	install_aur_packages
	setup_i2c
	build_vast_plugin
	build_m3shapes
	build_another_ripple
	build_vastctl
	compile_shaders
	compile_translations
	cleanup_build_deps
	install_quickshell_config
	setup_user_config
	create_wrapper
	
	rm -rf "$BUILD_DIR"

	log "System-wide installation complete!"
	log "Run 'shell' to start quickshell."
}

main "$@"
