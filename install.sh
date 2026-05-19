#!/usr/bin/env bash
set -euo pipefail

# Install helper files for this project.
#
# Usage after clone:
#   ROLE=dgx ./install.sh
#   ROLE=jetson ./install.sh
#
# Usage from GitHub raw URL:
#   curl -fsSL https://raw.githubusercontent.com/rennn0223/nemoclaw-dgx-cmdvel-bridge/main/install.sh | ROLE=dgx GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge bash
#   curl -fsSL https://raw.githubusercontent.com/rennn0223/nemoclaw-dgx-cmdvel-bridge/main/install.sh | ROLE=jetson GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge bash

ROLE="${ROLE:-}"
REPO_URL="${REPO_URL:-}"
GITHUB_REPO="${GITHUB_REPO:-}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-}"

if [[ -z "$ROLE" ]]; then
  echo "Set ROLE=dgx or ROLE=jetson" >&2
  exit 1
fi

if [[ -z "$INSTALL_DIR" ]]; then
  case "$ROLE" in
    dgx) INSTALL_DIR="$HOME" ;;
    jetson) INSTALL_DIR="$HOME" ;;
    *) echo "Unknown ROLE: $ROLE. Use ROLE=dgx or ROLE=jetson" >&2; exit 1 ;;
  esac
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

copy_from_current_dir() {
  local src_dir
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cp "$src_dir"/"$1" "$INSTALL_DIR"/
}

copy_from_repo() {
  local file="$1"
  if [[ -z "$REPO_URL" ]] && [[ -n "$GITHUB_REPO" ]]; then
    REPO_URL="https://github.com/$GITHUB_REPO.git"
  fi
  if [[ -z "$REPO_URL" ]]; then
    echo "When running install.sh through curl, set GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge or REPO_URL=https://github.com/rennn0223/nemoclaw-dgx-cmdvel-bridge.git" >&2
    echo "Example: curl -fsSL https://raw.githubusercontent.com/rennn0223/nemoclaw-dgx-cmdvel-bridge/main/install.sh | ROLE=dgx GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge bash" >&2
    exit 1
  fi
  if [[ ! -d "$TMP_DIR/repo" ]]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR/repo"
  fi
  cp "$TMP_DIR/repo/$file" "$INSTALL_DIR"/
}

copy_file() {
  local file="$1"
  if [[ -f "${BASH_SOURCE[0]}" ]] && [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$file" ]]; then
    copy_from_current_dir "$file"
  else
    copy_from_repo "$file"
  fi
}

mkdir -p "$INSTALL_DIR"

case "$ROLE" in
  dgx)
    copy_file dgx_cmd_vel_rest_api.py
    copy_file auto_lan.sh
    copy_file auto_tailscale.sh
    copy_file start_dgx_cmd_vel_pipeline.sh
    copy_file fastdds_super_tailscale.xml
    copy_file fastdds_tailscale.xml
    chmod +x "$INSTALL_DIR"/auto_lan.sh "$INSTALL_DIR"/auto_tailscale.sh "$INSTALL_DIR"/start_dgx_cmd_vel_pipeline.sh
    cat <<EOF
Installed DGX files to $INSTALL_DIR

LAN mode:
  cd $INSTALL_DIR
  ./auto_lan.sh

Tailscale mode:
  cd $INSTALL_DIR
  ./auto_tailscale.sh
EOF
    ;;
  jetson)
    copy_file wheeltec_bringup_lan.sh
    copy_file wheeltec_ros_lan_shell.sh
    copy_file wheeltec_bringup_tailscale.sh
    copy_file wheeltec_ros_tailscale_shell.sh
    copy_file fastdds_super_tailscale.xml
    chmod +x "$INSTALL_DIR"/wheeltec_bringup_lan.sh "$INSTALL_DIR"/wheeltec_ros_lan_shell.sh
    chmod +x "$INSTALL_DIR"/wheeltec_bringup_tailscale.sh "$INSTALL_DIR"/wheeltec_ros_tailscale_shell.sh
    cat <<EOF
Installed Jetson/Wheeltec files to $INSTALL_DIR

LAN mode:
  cd $INSTALL_DIR
  ./wheeltec_bringup_lan.sh

Tailscale mode:
  cd $INSTALL_DIR
  ./wheeltec_bringup_tailscale.sh
EOF
    ;;
esac
