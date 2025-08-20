#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# --- remove Steam/Gamescope sessions ---
dnf5 -y remove gamescope-session gamescope-session-steam || true

# --- delete leftover “one-shot” session files (not owned by any pkg) ---
rm -f \
  /usr/share/wayland-sessions/plasma-steamos-wayland-oneshot.desktop \
  /usr/share/xsessions/plasma-steamos-oneshot.desktop || true

# Fix for a known issue, might not be needed at some point in the future
# https://github.com/ErikReider/SwayNotificationCenter/issues/581
dnf5 -y copr enable erikreider/SwayNotificationCenter
dnf5 -y install gtk4-layer-shell-1.1.1-1.fc42.x86_64
dnf5 -y copr disable erikreider/SwayNotificationCenter

# setup hyprland from COPR
dnf5 -y copr enable solopasha/hyprland
dnf5 -y install			\
	hyprland			\
	hyprpaper			\
	hyprpicker			\
	hypridle			\
	hyprlock			\
	hyprsunset			\
	hyprpolkitagent		\
	hyprsysteminfo		\
	hyprpanel			\
	qt6ct-kde			\
  swww \
	hyprland-qt-support	\
	hyprland-qtutils
dnf5 -y copr disable solopasha/hyprland

# this installs a package from fedora repos
dnf5 install -y \
    alacritty \
    bear \
    blueman \
    bridge-utils \
    cargo \
    clang \
    clang-tools-extra \
    doublecmd-qt6 \
    emacs \
    fontconfig-devel \
    freetype-devel \
    gnome-keyring \
    ImageMagick \
    kitty \
    libcurl-devel \
    libsecret \
    llvm \
    ncurses-devel \
    neovim \
    python3-neovim \
    ninja-build \
    pavucontrol-qt \
    python3.11 \
    python3.11-devel \
    readline-devel \
    ripgrep \
    rust \
    stow \
    virt-install \
    virt-manager \
    waybar \
    wofi \
    xdg-desktop-portal-hyprland \
    zathura \
    zathura-plugins-all

dnf5 -y copr enable codifryed/CoolerControl
dnf5 -y install coolercontrol coolercontrold
dnf5 -y copr disable codifryed/CoolerControl

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File
systemctl enable podman.socket
systemctl enable coolercontrold.service

# install script + user unit from your repo
install -Dm755 "ctx/files/scripts/post-install-user.sh" /usr/libexec/post-install-user.sh
install -Dm644 "ctx/files/systemd/user/post-install.service" /usr/lib/systemd/user/post-install.service

# enable for all users
systemctl --global enable post-install.service
