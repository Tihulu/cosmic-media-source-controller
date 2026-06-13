#!/usr/bin/env bash
set -euo pipefail

APP="tihulu-media-source-controller"
DAEMON="tihulu-media-key-daemon"
REPO_URL="${REPO_URL:-https://github.com/Tihulu/tihulu-media-source-controller.git}"
BRANCH="${BRANCH:-main}"
PREFIX="${PREFIX:-/usr}"
LOCAL_INSTALL="${LOCAL_INSTALL:-0}"
BINDIR="$PREFIX/bin"
DESKTOP_DIR="$PREFIX/share/applications"
DESKTOP_FILE="com.github.tihulu.TihuluMediaSourceController.desktop"
OLD_LOCAL_DESKTOP="/usr/local/share/applications/$DESKTOP_FILE"

log() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mWarning:\033[0m %s\n' "$*" >&2
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

install_dependencies() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing build and runtime dependencies"
    sudo apt-get update
    sudo apt-get install -y \
      build-essential \
      pkg-config \
      git \
      cargo \
      playerctl \
      python3-evdev \
      libnotify-bin \
      libx11-dev \
      libxi-dev \
      libxcursor-dev \
      libxrandr-dev \
      libxinerama-dev \
      libgl1-mesa-dev \
      libxkbcommon-dev \
      libwayland-dev
  else
    warn "Automatic dependency installation is only supported on apt-based systems."
    warn "Install these packages manually: git cargo playerctl python3-evdev libnotify-bin pkg-config libx11-dev libxi-dev libxcursor-dev libxrandr-dev libxinerama-dev libgl1-mesa-dev libxkbcommon-dev libwayland-dev"
  fi
}

is_project_root() {
  [ -f "Cargo.toml" ] && grep -q "name = \"$APP\"" Cargo.toml
}

install_user_service() {
  local user_dir="$HOME/.config/systemd/user"
  mkdir -p "$user_dir"
  cat > "$user_dir/$DAEMON.service" <<EOF
[Unit]
Description=Tihulu Media Key Daemon

[Service]
Type=simple
ExecStart=$BINDIR/$DAEMON
Restart=on-failure
RestartSec=2
Environment=TMSC_COMMAND=$BINDIR/$APP
Environment=TMSC_MEDIA_KEY_GRAB=0

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload || true
  systemctl --user enable --now "$DAEMON.service" || true
}

main() {
  install_dependencies

  need_cmd git
  need_cmd cargo
  need_cmd playerctl

  local workdir=""
  local cleanup_dir=""

  if [ "$LOCAL_INSTALL" = "1" ] && is_project_root; then
    workdir="$PWD"
    log "Using current source tree: $workdir"
  else
    cleanup_dir="$(mktemp -d)"
    workdir="$cleanup_dir/$APP"
    log "Cloning Tihulu Media Source Controller from GitHub"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$workdir"
  fi

  cd "$workdir"

  log "Building release binary"
  cargo build --release

  log "Installing binary to $BINDIR/$APP"
  sudo install -Dm755 "target/release/$APP" "$BINDIR/$APP"

  if [ -f "scripts/$DAEMON" ]; then
    log "Installing media-key daemon to $BINDIR/$DAEMON"
    sudo install -Dm755 "scripts/$DAEMON" "$BINDIR/$DAEMON"
  fi

  if [ -f "packaging/$DESKTOP_FILE" ]; then
    log "Installing COSMIC applet desktop entry to $DESKTOP_DIR/$DESKTOP_FILE"
    sudo install -Dm644 "packaging/$DESKTOP_FILE" "$DESKTOP_DIR/$DESKTOP_FILE"
  fi

  if [ -f "$OLD_LOCAL_DESKTOP" ] && [ "$PREFIX" = "/usr" ]; then
    log "Removing old /usr/local desktop entry"
    sudo rm -f "$OLD_LOCAL_DESKTOP"
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    sudo update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi

  log "Adding $USER to input group for media-key daemon access"
  sudo usermod -aG input "$USER" || true
  install_user_service

  if [ -n "$cleanup_dir" ]; then
    rm -rf "$cleanup_dir"
  fi

  log "Installation complete"
  echo "Run desktop GUI: $APP"
  echo "CLI example: $APP set spotify && $APP play-pause"
  echo "Media-key daemon: systemctl --user status $DAEMON.service"
  echo "Important: log out and back in once so the input group permission becomes active."
}

main "$@"
