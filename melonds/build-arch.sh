#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
#
# @description : Build the melonds distribution layer
######################################################################

#shellcheck disable=2016

set -e

function msg()
{
  echo "${FUNCNAME[1]}" "$@"
}

function fetch_melonds()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Fetch latest release; melonDS ships its Linux x86_64 AppImage zipped
  # (unlike RPCS3's bare .AppImage asset), so pick that asset specifically
  # instead of assuming assets[0]
  read -r url_melonds < <(wget -qO - "https://api.github.com/repos/melonDS-emu/melonDS/releases/latest" \
    | jq -r '.assets[] | select(.name | test("appimage-x86_64\\.zip$")) | .browser_download_url')
  wget "$url_melonds"

  # Fetched file name
  zip_melonds="$(basename "$url_melonds")"

  # Unzip to get the AppImage out
  unzip "$zip_melonds"
  rm "$zip_melonds"

  # Only one .AppImage should be present
  appimage_melonds="$(find . -maxdepth 1 -name '*.AppImage')"

  # Make executable
  chmod +x "$appimage_melonds"

  # Extract appimage
  "$BUILD_DIR/$appimage_melonds" --appimage-extract

  # Remove image
  rm "$appimage_melonds"

  # Move melonds dir
  mv "$BUILD_DIR"/squashfs-root/usr melonds

  # Export melonds dir location
  export MELONDS_DIR="$BUILD_DIR"/melonds

  # Remove squashfs-root
  rm -rf ./squashfs-root
}

function compress_melonds()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"
  msg "${IMAGE:?IMAGE is undefined}"
  msg "${MELONDS_DIR:?MELONDS_DIR is undefined}"
  # Copy melonds runner
  cp "$SCRIPT_DIR"/boot.sh "$MELONDS_DIR"/boot
  # Create layer dirs
  mkdir -p ./root/opt
  mkdir -p ./root/home/melonds/.config
  # Move melonds to layer dir
  mv "$MELONDS_DIR" ./root/opt
  # Compress melonds
  "$IMAGE" fim-layer create ./root "$BUILD_DIR/melonds.layer"
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
  mv "$BUILD_DIR"/melonds.layer .

  # Create sha256sum
  sha256sum melonds.layer > melonds.layer.sha256sum
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

  # Fetch melonds
  fetch_melonds

  # Create novel layer
  compress_melonds

  package
}

main "$@"

# // cmd: !./%

#  vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
