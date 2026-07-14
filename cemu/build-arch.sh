#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
#
# @description : Build the cemu distribution layer
######################################################################

#shellcheck disable=2016

set -e

function msg()
{
  echo "${FUNCNAME[1]}" "$@"
}

function fetch_cemu()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Fetch latest release
  read -r url_cemu < <(wget -qO - "https://api.github.com/repos/cemu-project/Cemu/releases/latest" \
    | jq -r '.assets[] | select(.name | test("x86_64\\.AppImage$")) | .browser_download_url')
  wget "$url_cemu"

  # Fetched file name
  appimage_cemu="$(basename "$url_cemu")"

  # Make executable
  chmod +x "$BUILD_DIR/$appimage_cemu"

  # Extract appimage
  "$BUILD_DIR/$appimage_cemu" --appimage-extract

  # Remove image
  rm "$BUILD_DIR/$appimage_cemu"

  # Move cemu dir
  mv "$BUILD_DIR"/squashfs-root/usr cemu

  # Export cemu dir location
  export CEMU_DIR="$BUILD_DIR"/cemu

  # Remove squashfs-root
  rm -rf ./squashfs-root
}

function compress_cemu()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"
  msg "${IMAGE:?IMAGE is undefined}"
  msg "${CEMU_DIR:?CEMU_DIR is undefined}"
  # Copy cemu runner
  cp "$SCRIPT_DIR"/boot.sh "$CEMU_DIR"/boot
  # Create layer dirs
  mkdir -p ./root/opt
  mkdir -p ./root/home/cemu/.config
  # Move cemu to layer dir
  mv "$CEMU_DIR" ./root/opt
  # Compress cemu
  "$IMAGE" fim-layer create ./root "$BUILD_DIR/cemu.layer"
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
  mv "$BUILD_DIR"/cemu.layer .

  # Create sha256sum
  sha256sum cemu.layer > cemu.layer.sha256sum
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

  # Fetch cemu
  fetch_cemu

  # Create novel layer
  compress_cemu

  package
}

main "$@"

# // cmd: !./%

#  vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
