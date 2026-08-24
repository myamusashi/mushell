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

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)" || die "Failed to determine project root"
readonly PROJECT_ROOT

readonly INSTALL_DIR="/usr/local/share/quickshell"
readonly BIN_DIR="/usr/local/bin"
readonly FONT_DIR="/usr/local/share/fonts"
readonly QML_DIR="/usr/lib/qt6/qml"
readonly BUILD_DIR="/tmp/quickshell-build"

readonly M3SHAPES_REV="6875533e1b459cd096e2250f54ceaad5290afc49"
readonly ANOTHER_RIPPLE_REV="5037fd56226577c3f3d1da7db64bf5e72a476998"
readonly WL_SCREENREC_REV="23500cce9ed2aba6c9cbb40187bcda2f99d4f835"

check_root() {
	[[ $EUID -eq 0 ]] || die "System-wide installation requires root. Run with sudo."
}

check_distro() {
	command -v pacman &>/dev/null || die "This script is designed for Arch Linux and derivatives"
}

install_system_packages() {
	local -a missing=()
	local -r pkg_list=(
		base-devel git cmake ninja clang extra-cmake-modules patchelf pkgconf
		qt6-base qt6-declarative qt6-wayland qt6-svg qt6-graphs qt6-multimedia qt6-5compat qt6-shadertools qt6-tools
		rust pipewire ddcutil i2c-tools go wayland wayland-protocols
		findutils grep sed gawk util-linux libnotify wireplumber
		iw polkit wl-clipboard ffmpeg foot hyprland xdg-desktop-portal
		spirv-tools vulkan-headers cli11 cpptrace jemalloc libdrm mesa libxcb glib2
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

update_submodules() {
	local -r fzy_marker="$PROJECT_ROOT/Plugins/third_party/fzy/src/match.c"
	local -r mcu_marker="$PROJECT_ROOT/Plugins/third_party/material-color-utilities/cpp"

	[[ -f $fzy_marker && -d $mcu_marker ]] && {
		log "Git submodules already initialized"
		return 0
	}

	git -C "$PROJECT_ROOT" rev-parse --git-dir &>/dev/null ||
		die "Submodules missing and $PROJECT_ROOT is not a git repository — cannot fetch them"

	log "Initializing git submodules..."
	git -C "$PROJECT_ROOT" submodule update --init --recursive ||
		die "Failed to initialize git submodules"
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
		ttf-weather-icons app2unit ttf-material-symbols-variable-git
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
}

build_quickshell() {
	pacman -Qi quickshell &>/dev/null && {
		log "quickshell already installed"
		return 0
	}
	command -v makepkg &>/dev/null || die "makepkg not found — install pacman/base-devel"

	local -r aur_user="${SUDO_USER:-}"
	[[ -n $aur_user ]] || die "Building quickshell requires a non-root user. Run with sudo."

	local -r pkgdir="$PROJECT_ROOT/packaging/arch/quickshell"
	[[ -f $pkgdir/PKGBUILD ]] || die "PKGBUILD not found: $pkgdir/PKGBUILD"

	log "Building quickshell from PKGBUILD..."
	local -r build="$BUILD_DIR/quickshell"
	rm -rf "$build"
	mkdir -p "$build"
	cp "$pkgdir"/PKGBUILD "$build/"
	chown -R "$aur_user:$aur_user" "$build"

	pushd "$build" >/dev/null
	sudo -u "$aur_user" makepkg -f --noconfirm || die "Failed to build quickshell"
	popd >/dev/null

	local -a pkg_file
	pkg_file=("$build"/quickshell-*.pkg.tar.zst)
	[[ -f ${pkg_file[0]} ]] || die "quickshell package not found after build"

	log "Installing quickshell package..."
	pacman -U --noconfirm "${pkg_file[0]}" || die "Failed to install quickshell"
}

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
			local joined
			joined=$(
				IFS=,
				echo "${groups_to_add[*]}"
			)
			log "Adding $target_user to groups: ${groups_to_add[*]}"
			usermod -aG "$joined" "$target_user" || warn "Failed to add $target_user to groups: $joined"
			warn "Group changes take effect on next login — DDC/CI may fail until then"
		else
			log "User $target_user already in i2c and video groups"
		fi
	else
		warn "SUDO_USER not set — skipping group assignment. Add yourself to i2c and video groups manually."
	fi

	if compgen -G "/dev/i2c-*" >/dev/null 2>&1; then
		log "DDC/CI devices found: $(compgen -G "/dev/i2c-*" | tr '\n' ' ')"
	else
		warn "No /dev/i2c-* devices found — external monitor brightness control unavailable"
	fi
}

clone_or_checkout() {
	local -r repo_url=$1 dest=$2 rev=$3

	[[ -d $dest ]] || git clone "$repo_url" "$dest"

	git -C "$dest" checkout "$rev" 2>/dev/null || {
		git -C "$dest" fetch
		git -C "$dest" checkout "$rev"
	}
}

copy_qml_module() {
	local -r install_base=$1 dest=$2
	shift 2
	local -ra candidates=("$@")

	mkdir -p "$dest"
	local found=0
	for rel in "${candidates[@]}"; do
		local dir="$install_base/$rel"
		if [[ -d $dir ]]; then
			cp -r "$dir/"* "$dest/"
			found=1
		fi
	done
	((found)) || return 1
}

qt_module_libdirs() {
	local joined="" lib
	for mod in "$@"; do
		lib=$(pkg-config --variable=libdir "$mod") || die "pkg-config: $mod not found"
		joined="${joined:+$joined:}$lib"
	done
	echo "$joined"
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

	CC=clang CXX=clang++ cmake -S "$src" -B "$build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$install_base"
	ninja -C "$build"
	ninja -C "$build" install

	copy_qml_module "$install_base" "$QML_DIR/Vast" \
		usr/lib/qt6/qml/Vast usr/lib/qt-6/qml/Vast lib/qt6/qml/Vast lib/qt-6/qml/Vast Vast ||
		die "Vast install tree not found under $install_base"

	local qt_libs pw_lib ddc_lib wl_lib
	qt_libs=$(qt_module_libdirs Qt6Core Qt6Gui Qt6Qml Qt6Quick Qt6Sql Qt6Network)
	pw_lib=$(pkg-config --variable=libdir libpipewire-0.3) || die "libpipewire-0.3 not found via pkg-config"
	ddc_lib=$(pkg-config --variable=libdir ddcutil) || die "ddcutil not found via pkg-config"
	wl_lib=$(pkg-config --variable=libdir wayland-client) || die "wayland-client not found via pkg-config"
	local -r deps="$qt_libs:$pw_lib:$ddc_lib:$wl_lib"

	local so_file
	while IFS= read -r -d '' so_file; do
		patchelf --set-rpath "$(dirname "$so_file"):$QML_DIR/Vast/lib:$deps" "$so_file" ||
			warn "patchelf failed on $so_file"
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
	local -r install_base="$BUILD_DIR/m3shapes-install"

	clone_or_checkout "https://github.com/soramanew/m3shapes.git" "$src" "$M3SHAPES_REV"

	CC=clang CXX=clang++ cmake -S "$src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$install_base"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	copy_qml_module "$install_base" "$QML_DIR/M3Shapes" \
		M3Shapes usr/lib/qt6/qml/M3Shapes ||
		warn "m3shapes install tree not found under $install_base"

	if [[ -f $plugin ]]; then
		local qt_core_lib
		qt_core_lib=$(qt_module_libdirs Qt6Core)
		patchelf --set-rpath "$QML_DIR/M3Shapes:$qt_core_lib" "$plugin" || warn "patchelf failed on $plugin"
	fi
}

find_qsb() {
	local qsb
	qsb=$(command -v qsb 2>/dev/null || command -v qsb6 2>/dev/null || true)
	[[ -n $qsb ]] || qsb=$(find /usr/lib/qt6 /usr/lib/qt /opt/qt6 -name "qsb" -type f 2>/dev/null | head -1 || true)
	echo "$qsb"
}

compile_shader_stage() {
	local -r qsb=$1 src=$2 out=$3
	local -ra qsb_flags=(--glsl "450,330,300 es" --hlsl 50 --msl 12)

	[[ -f $src ]] || {
		warn "  Missing: $(basename "$src") — skipping"
		return 1
	}
	if [[ -f $out && $src -ot $out ]]; then
		log "  Up to date: $(basename "$out")"
		return 0
	fi

	if "$qsb" "${qsb_flags[@]}" -o "$out" "$src"; then
		log "  → $(basename "$out")"
		return 0
	else
		warn "  FAILED: $(basename "$out")"
		return 1
	fi
}

compile_shaders() {
	local -r shader_dir="$PROJECT_ROOT/Assets/shaders"
	local -r transition_dir="$shader_dir/transitions"

	local qsb
	qsb=$(find_qsb)
	[[ -n $qsb ]] || {
		warn "qsb not found — skipping shader compilation (qt6-shadertools required)"
		return 0
	}

	log "Compiling vertex shader..."
	compile_shader_stage "$qsb" "$shader_dir/ImageTransition.vert" "$shader_dir/ImageTransition.vert.qsb" || true

	if [[ -d $transition_dir ]]; then
		log "Compiling transition shaders..."
		local -ra transitions=(
			fade wipeDown hexTile circleExpand dissolve splitHorizontal
			slideUp pixelate diagonalWipe boxExpand roll
		)
		local failed=0
		for name in "${transitions[@]}"; do
			compile_shader_stage "$qsb" "$transition_dir/${name}.frag" "$transition_dir/${name}.frag.qsb" ||
				failed=$((failed + 1))
		done
		((failed == 0)) || warn "$failed transition shader(s) failed to compile"
	else
		warn "Transitions directory not found: $transition_dir — skipping"
	fi

	log "Compiling border progress, wavy, and wave form shaders..."
	local -ra shader_pairs=(borderProgress wavy waveForm)
	for name in "${shader_pairs[@]}"; do
		compile_shader_stage "$qsb" "$shader_dir/${name}.vert" "$shader_dir/${name}.vert.qsb" || true
		compile_shader_stage "$qsb" "$shader_dir/${name}.frag" "$shader_dir/${name}.frag.qsb" || true
	done
}

build_another_ripple() {
	local -r plugin="$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"
	[[ -f $plugin ]] && {
		log "AnotherRipple already installed"
		return 0
	}

	log "Building AnotherRipple..."
	local -r src="$BUILD_DIR/Another-Ripple"
	local -r install_base="$BUILD_DIR/anotherripple-install"

	clone_or_checkout "https://github.com/myamusashi/Another-Ripple.git" "$src" "$ANOTHER_RIPPLE_REV"

	local -r cmake_src="$src/AnotherRipple"
	[[ -d $cmake_src ]] || die "AnotherRipple subdirectory not found in repo: $cmake_src"

	CC=clang CXX=clang++ cmake -S "$cmake_src" -B "$src/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DCMAKE_INSTALL_PREFIX="$install_base" \
		-DINSTALL_QMLDIR="usr/lib/qt6/qml"
	ninja -C "$src/build"
	ninja -C "$src/build" install

	copy_qml_module "$install_base" "$QML_DIR/AnotherRipple" \
		usr/lib/qt6/qml/AnotherRipple usr/lib/qt-6/qml/AnotherRipple \
		lib/qt6/qml/AnotherRipple lib/qt-6/qml/AnotherRipple AnotherRipple ||
		warn "AnotherRipple install tree not found under $install_base"

	local qt_libs
	qt_libs=$(qt_module_libdirs Qt6Core Qt6Qml)
	for lib in \
		"$QML_DIR/AnotherRipple/libAnotherRipple.so" \
		"$QML_DIR/AnotherRipple/libAnotherRippleplugin.so"; do
		[[ -f $lib ]] && { patchelf --set-rpath "$QML_DIR/AnotherRipple:$qt_libs" "$lib" || warn "patchelf failed on $lib"; }
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

	log "Installing generate-colors-material to $BIN_DIR..."
	install -Dm755 "$PROJECT_ROOT/Assets/shell/generate_colors_material.py" "$BIN_DIR/generate-colors-material"

	chmod -R 755 "$INSTALL_DIR"
	chown -R root:root "$INSTALL_DIR"

	local -r shell_qml="$INSTALL_DIR/Qml/shell.qml"
	if [[ -f $shell_qml ]]; then
		sed -i 's/ShellRoot {/ShellRoot { settings.watchFiles: false/' "$shell_qml"
		grep -q 'settings.watchFiles: false' "$shell_qml" ||
			warn "Failed to patch $shell_qml — ShellRoot pattern not found"
	fi

	log "Setting global VAST_SHELL_DIRECTORY..."
	cat >/etc/profile.d/vast-shell.sh <<'EOF'
export VAST_SHELL_DIRECTORY="/usr/local/share/quickshell"
EOF
	chmod 644 /etc/profile.d/vast-shell.sh
}

setup_user_config() {
	local -r target_user="${SUDO_USER:-$USER}"
	local user_home
	user_home=$(getent passwd "$target_user" | cut -d: -f6)

	[[ -n $user_home ]] || {
		warn "Could not determine home directory for $target_user — skipping user config setup"
		return 0
	}

	local -r vast_config_dir="$user_home/.config/vast-shell"

	log "Setting up user configuration for $target_user..."

	mkdir -p "$vast_config_dir"
	cp -r "$PROJECT_ROOT/Data/"* "$vast_config_dir/"
	chown -R "$target_user:$target_user" "$vast_config_dir"
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
	if ! go build -ldflags="-s -w" -o "$binary" .; then
		warn "vastctl build failed"
		popd >/dev/null
		return 0
	fi
	popd >/dev/null

	local -r completions=(
		"bash:/usr/share/bash-completion/completions/vastctl"
		"fish:/usr/share/fish/vendor_completions.d/vastctl.fish"
		"zsh:/usr/share/zsh/site-functions/_vastctl"
		"nushell:/usr/share/nushell/completions/vastctl.nu"
	)
	for entry in "${completions[@]}"; do
		local shell_name=${entry%%:*} out_path=${entry#*:}
		mkdir -p "$(dirname "$out_path")"
		"$binary" completion "$shell_name" >"$out_path" || warn "Failed to generate $shell_name completion"
	done

	log "vastctl installed to $BIN_DIR"
}

cleanup_build_deps() {
	local -r build_deps=(
		base-devel cmake ninja clang extra-cmake-modules patchelf pkgconf
		qt6-shadertools qt6-tools rust git
		spirv-tools vulkan-headers cli11
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
	check_root
	check_distro

	trap 'rm -rf "$BUILD_DIR"' EXIT

	log "Creating directories..."
	mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$FONT_DIR/truetype" "$QML_DIR" "$BUILD_DIR"

	install_system_packages
	update_submodules
	setup_aur_helper
	install_aur_packages
	setup_i2c

	build_quickshell
	build_vast_plugin
	build_m3shapes
	build_another_ripple
	build_wl_screenrec
	build_vastctl
	compile_shaders
	compile_translations

	cleanup_build_deps

	install_quickshell_config
	setup_user_config
	create_wrapper

	log "System-wide installation complete!"
	log "Run 'shell' to start quickshell."
}

main "$@"
