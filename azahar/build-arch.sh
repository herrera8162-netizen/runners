#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
#
# @description : Build the azahar distribution layer
######################################################################

#shellcheck disable=2016

set -e

function msg()
{
  echo "${FUNCNAME[1]}" "$@"
}

function fetch_azahar()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Fetch latest release; azahar ships both a plain X11 AppImage and a
  # Wayland-specific one - use the plain one for broadest X11/XWayland
  # compatibility inside the container.
  read -r url_azahar < <(wget -qO - "https://api.github.com/repos/azahar-emu/azahar/releases/latest" \
    | jq -r '.assets[] | select(.name == "azahar.AppImage") | .browser_download_url')
  wget "$url_azahar"

  # Fetched file name
  appimage_azahar="$(basename "$url_azahar")"

  # Make executable
  chmod +x "$BUILD_DIR/$appimage_azahar"

  # Extract appimage
  "$BUILD_DIR/$appimage_azahar" --appimage-extract

  # Remove image
  rm "$BUILD_DIR/$appimage_azahar"

  # Move azahar dir
  mv "$BUILD_DIR"/squashfs-root/usr azahar

  # Export azahar dir location
  export AZAHAR_DIR="$BUILD_DIR"/azahar

  # Remove squashfs-root
  rm -rf ./squashfs-root
}

function compress_azahar()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"
  msg "${IMAGE:?IMAGE is undefined}"
  msg "${AZAHAR_DIR:?AZAHAR_DIR is undefined}"
  # Copy azahar runner
  cp "$SCRIPT_DIR"/boot.sh "$AZAHAR_DIR"/boot
  # Create layer dirs
  mkdir -p ./root/opt
  mkdir -p ./root/home/azahar/.config
  # Move azahar to layer dir
  mv "$AZAHAR_DIR" ./root/opt
  # Compress azahar
  "$IMAGE" fim-layer create ./root "$BUILD_DIR/azahar.layer"
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
  mv "$BUILD_DIR"/azahar.layer .

  # Create sha256sum
  sha256sum azahar.layer > azahar.layer.sha256sum
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

  # Fetch azahar
  fetch_azahar

  # Create novel layer
  compress_azahar

  package
}

main "$@"

# // cmd: !./%

#  vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
