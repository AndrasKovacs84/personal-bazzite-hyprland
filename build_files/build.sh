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
dnf5 -y install gtk4-layer-shell
dnf5 -y copr disable erikreider/SwayNotificationCenter

dnf5 -y copr enable dejan/lazygit
dnf5 -y install lazygit
dnf5 -y copr disable dejan/lazygit

# setup hyprland from COPR
dnf5 -y copr enable solopasha/hyprland
pkgs=(
  hyprland
  hyprpaper
  hyprpicker
  hypridle
  hyprlock
  hyprsunset
  # hyprpolkitagent
  # hyprsysteminfo
  # hyprpanel
  hyprshot
  # qt6ct-kde
  swww
  # hyprland-qt-support
  # hyprland-qtutils
)

dnf5 -y install "${pkgs[@]}"
dnf5 -y copr disable solopasha/hyprland

dnf5 -y copr enable zhangyi6324/noctalia-shell
    dnf5 install -y cliphist gpu-screen-recorder matugen noctalia-shell quickshell
dnf5 -y copr disable zhangyi6324/noctalia-shell

# this installs a package from fedora repos
dnf5 install -y \
    alacritty \
    bear \
    blueman \
    bridge-utils \
    cargo \
    cava \
    clang \
    clang-tools-extra \
    doublecmd-qt6 \
    emacs \
    fontconfig-devel \
    freetype-devel \
    fuzzel \
    gnome-keyring \
    gnome-keyring-pam \
    ImageMagick \
    kitty \
    libcurl-devel \
    libsecret \
    '*/libsoup-2.4.so.1' \
    '*/libwebkit2gtk-4.0.so.37' \
    llvm \
    meson \
    ncurses-devel \
    neovim \
    niri \
    python3-neovim \
    ninja-build \
    pavucontrol-qt \
    python3.11 \
    python3.11-devel \
    readline-devel \
    ripgrep \
    rust \
    splix \
    stow \
    virt-install \
    virt-manager \
    waybar \
    wlsunset \
    wofi \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    xwayland-satellite \
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

# Install personal wlogout fork
VERSION=$(curl -s https://api.github.com/repos/AndrasKovacs84/wlogout/releases/latest | grep tag_name | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
ZIP_URL="https://github.com/AndrasKovacs84/wlogout/releases/download/${VERSION}/wlogout.zip"

TMP_DIR=$(mktemp -d)
INSTALL_BIN_DIR="/usr/bin"
INSTALL_ASSETS_DIR="/usr/share/wlogout/icons"

# Download and install
echo "Downloading wlogout ${VERSION}..."
curl -L -o "${TMP_DIR}/wlogout.zip" "${ZIP_URL}"

echo "Unpacking..."
unzip -q "${TMP_DIR}/wlogout.zip" -d "${TMP_DIR}"

chmod +x "${TMP_DIR}/wlogout"
mv "${TMP_DIR}/wlogout" "${INSTALL_BIN_DIR}"
echo "Installed wlogout to ${INSTALL_BIN_DIR}"

mkdir -p "${INSTALL_ASSETS_DIR}"
cp -r "${TMP_DIR}/assets/"* "${INSTALL_ASSETS_DIR}"
echo "Installed icons to ${INSTALL_ASSETS_DIR}"

rm -rf "${TMP_DIR}"

# enable for all users
systemctl --global enable post-install.service

# ------------------------------------------------------------------
# niri portals override:
# - keep GNOME portal (screencast)
# - force FileChooser to GTK (avoid Nautilus dependency)
# ------------------------------------------------------------------
install -d /etc/xdg/xdg-desktop-portal

cat > /etc/xdg/xdg-desktop-portal/niri-portals.conf <<'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
EOF
