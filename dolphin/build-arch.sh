#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
#
# @description : Build the dolphin distribution layer
#
# Dolphin no longer publishes AppImages or GitHub Releases for Linux; its only
# official Linux distribution is a Flatpak (org.DolphinEmu.dolphin-emu). This
# script installs that flatpak into an isolated, throwaway HOME so it doesn't
# touch the build host's real flatpak installation, then relocates both the
# app's and its KDE runtime's files/ trees into a single self-contained
# directory (mirroring what an AppImage already gives the other runners for
# free), so the result runs standalone outside the flatpak sandbox.
######################################################################

set -e

function msg()
{
  echo "${FUNCNAME[1]}" "$@"
}

function fetch_dolphin()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Isolate flatpak's state under BUILD_DIR instead of the real user HOME
  export HOME="$BUILD_DIR/flatpak-home"
  mkdir -p "$HOME"

  # Add remotes (dolphin for the app, flathub for its org.kde.Platform runtime)
  flatpak remote-add --if-not-exists --user dolphin https://flatpak.dolphin-emu.org/releases.flatpakrepo
  flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo

  # Install app + runtime
  flatpak install --user -y --noninteractive dolphin org.DolphinEmu.dolphin-emu

  # Resolve the runtime ref the installed app actually depends on, rather than
  # hardcoding a runtime version that will go stale
  local runtime_ref
  runtime_ref="$(flatpak info --show-runtime org.DolphinEmu.dolphin-emu)"

  export DIR_APP_FILES
  DIR_APP_FILES="$(flatpak info --show-location org.DolphinEmu.dolphin-emu)/files"
  export DIR_RUNTIME_FILES
  DIR_RUNTIME_FILES="$(flatpak info --show-location "$runtime_ref")/files"
}

function compress_dolphin()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"
  msg "${IMAGE:?IMAGE is undefined}"
  msg "${DIR_APP_FILES:?DIR_APP_FILES is undefined}"
  msg "${DIR_RUNTIME_FILES:?DIR_RUNTIME_FILES is undefined}"

  # Assemble a self-contained /opt/dolphin: app files + runtime libs + boot wrapper
  mkdir -p ./root/opt/dolphin
  cp -r "$DIR_APP_FILES"/* ./root/opt/dolphin/
  mkdir -p ./root/opt/dolphin/runtime-lib
  cp -r "$DIR_RUNTIME_FILES"/lib/* ./root/opt/dolphin/runtime-lib/

  # Drop debug symbols, they aren't needed at runtime and are the bulk of the size
  rm -rf ./root/opt/dolphin/lib/debug ./root/opt/dolphin/runtime-lib/debug

  cp "$SCRIPT_DIR"/boot.sh ./root/opt/dolphin/boot
  chmod +x ./root/opt/dolphin/boot

  mkdir -p ./root/home/dolphin/.config

  # Compress dolphin
  "$IMAGE" fim-layer create ./root "$BUILD_DIR/dolphin.layer"
  # Remove uncompressed files
  rm -rf ./root
}

function package()
{
  msg "${SCRIPT_DIR:?SCRIPT_DIR is undefined}"
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  local dir_dist="$SCRIPT_DIR"/dist

  mkdir -p "$dir_dist" && cd "$dir_dist"

  # Move binaries to dist dir
  mv "$BUILD_DIR"/dolphin.layer .

  # Create sha256sum
  sha256sum dolphin.layer > dolphin.layer.sha256sum
}

function main()
{
  export IMAGE="$1"
  if ! [ -f "$IMAGE" ]; then
    echo "Please specify a regular file as the image path"
    exit 1
  fi

  # shellcheck disable=2155
  export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  export BUILD_DIR="$SCRIPT_DIR/build"

  # Re-create build dir
  rm -rf "$BUILD_DIR"; mkdir "$BUILD_DIR"; cd "$BUILD_DIR"

  # Fetch dolphin
  fetch_dolphin

  # Create novel layer
  compress_dolphin

  package
}

main "$@"

# // cmd: !./%

#  vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
