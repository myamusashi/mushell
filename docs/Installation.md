# Installation

[Back to README](../README.md)

## NixOS (Flakes)

Add vast-shell to your flake inputs:

```nix
inputs.vast-shell = {
  url = "github:myamusashi/vast-shell";
};
```

Then you can either add the package directly, or use the NixOS module:

**Option 1 — Add the package directly:**

```nix
environment.systemPackages = [
  inputs.vast-shell.packages.${system}.default
];
```

**Option 2 — Use the NixOS module (recommended):**

```nix
{
  imports = [ inputs.vast-shell.nixosModules.default ];

  programs.quickshell-shell = {
    enable = true;

    # Optional: install extra packages accessible to the shell
    extraPackages = with pkgs; [ spotify ];

    # Optional: disable font installation if you manage fonts separately
    installFonts = false;
  };
}
```

The module registers a systemd user service (`quickshell-shell.service`) that auto-starts with your graphical session, and automatically installs required fonts (`material-symbols`, `weather-icons`).

---

## Arch Linux

> [!IMPORTANT]
> Requires Arch Linux or an Arch-based distro. Run with `sudo`.

```bash
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
```

The script installs all dependencies, builds the plugins, compiles shaders, and sets up the shell. Once complete, start it with:

```bash
shell
```

### Dependencies

**Build**

| Package | Purpose |
|---|---|
| `cmake`, `qt6-shadertools`, `qt6-tools` | Build system, shader compiler (`qsb`), translation compiler (`lrelease`) |
| `qt6-base`, `qt6-declarative`, `qt6-multimedia` | Qt6 build-time libraries |
| `wayland` | Provides `libwayland-client` + `wayland-scanner` for the clipboard manager's native `ext_data_control_v1` binding |

**Runtime**

| Category | Packages |
|---|---|
| Shell | `quickshell-git`, `hyprland`, `foot`, `polkit` |
| Qt6 | `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-5compat`, `qt6-graphs`, `kf6-qtmultimedia` |
| Media | `ffmpeg`, `wireplumber`, `wl-clipboard`, `wl-screenrec` |
| Network / Notifications | `iw`, `libnotify` |
| Fonts | `ttf-material-symbols-variable-git`, `ttf-weather-icons`, `google-sans-flex` (optional), `Hack` (optional) |
| Utils | `findutils`, `grep`, `gawk`, `sed`, `util-linux` |
| AI / Depth Wallpaper | `python-rembg` |
| Other | `app2unit` |

> [!IMPORTANT]
> **Brightness control (ddcutil):** Controlling external monitor brightness requires non-root access to I2C devices. `archInstall.sh` handles this automatically. For manual setup, load the `i2c-dev` module, apply the appropriate udev rules (see `setup_i2c` in `archInstall.sh`), and add your user to the `i2c` and `video` groups.

---

## Other Distros

> [!WARNING]
> Package names below were accurate at time of writing but **may be outdated**. Always verify against your distro's official package index. PRs to keep this list updated are welcome.
>
> **`rembg`** is not available in most distro repositories. Install it via `pip install rembg` (requires Python 3.9+). NixOS users get it automatically via the flake definition.
>
> - **Fedora** → https://packages.fedoraproject.org
> - **openSUSE** → https://software.opensuse.org
> - **Gentoo** → https://packages.gentoo.org
> - **Void** → https://voidlinux.org/packages

The following packages must always be built from source, regardless of distro:

| Package | Source |
|---|---|
| `quickshell` | https://github.com/quickshell/quickshell |
| `materialyoucolor` | https://github.com/T-Dynamos/materialyoucolor-python |
| `app2unit` | https://github.com/valpackett/app2unit |
| `wl-screenrec` | https://github.com/russelltg/wl-screenrec |
| Material Symbols font | https://github.com/google/material-design-icons |
| Weather Icons font | https://github.com/erikflowers/weather-icons |

<details>
<summary>Fedora</summary>

```bash
# System & build
sudo dnf install git cmake ninja-build extra-cmake-modules patchelf pkgconf \
                 gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
                 qt6-qtmultimedia-devel qt6-qt5compat-devel \
                 qt6-qtshadertools-devel qt6-qttools-devel

# Runtime
sudo dnf install pipewire wireplumber iw libnotify polkit \
                 wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

> [!NOTE]
> `ffmpeg` requires [RPM Fusion](https://rpmfusion.org): `sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`
>
> `qt6-qtgraphs` is not yet packaged in Fedora — build from source if required.

</details>

<details>
<summary>openSUSE Tumbleweed</summary>

```bash
# System & build
sudo zypper install git cmake ninja extra-cmake-modules patchelf pkgconf \
                    gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo zypper install qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                    qt6-multimedia-devel qt6-5compat-devel \
                    qt6-shadertools-devel qt6-tools-devel

# Runtime
sudo zypper install pipewire wireplumber iw libnotify-tools polkit \
                    wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>

<details>
<summary>Gentoo</summary>

```bash
# System & build
sudo emerge -av dev-vcs/git dev-build/cmake dev-build/ninja \
                kde-frameworks/extra-cmake-modules dev-util/patchelf \
                dev-util/pkgconf dev-lang/rust dev-libs/wayland

# Qt6 (ensure USE="qt6" where applicable)
sudo emerge -av dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtsvg:6 \
                dev-qt/qtmultimedia:6 dev-qt/qt5compat:6 \
                dev-qt/qtshadertools:6 dev-qt/qttools:6

# Runtime
sudo emerge -av media-video/pipewire media-video/wireplumber net-wireless/iw \
                x11-libs/libnotify sys-auth/polkit \
                gui-apps/wl-clipboard media-video/ffmpeg gui-apps/foot \
                gui-wm/hyprland sys-apps/util-linux
```

</details>

<details>
<summary>Void Linux</summary>

```bash
# System & build
sudo xbps-install -S git cmake ninja extra-cmake-modules patchelf pkgconf \
                     base-devel rust cargo wayland-devel

# Qt6
sudo xbps-install -S qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                     qt6-multimedia-devel qt6-5compat-devel \
                     qt6-shadertools-devel qt6-tools

# Runtime
sudo xbps-install -S pipewire wireplumber iw libnotify polkit \
                     wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>
