#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Main directory
export DIR_DOLPHIN="$SCRIPT_DIR"

# Dolphin ships as a Flatpak (app + org.kde.Platform runtime), so unlike an
# AppImage's single self-contained lib/ dir, its shared libraries are spread
# across both the app's lib/ tree and the extracted runtime's lib/ tree, each
# with its own multiarch subdirectories. Discover them all instead of hardcoding
# a fixed list of subpaths.
LD_LIBRARY_PATH="$(find "$DIR_DOLPHIN/lib" "$DIR_DOLPHIN/runtime-lib" -name '*.so*' -exec dirname {} \; 2>/dev/null | sort -u | paste -sd: -)"
export LD_LIBRARY_PATH

# The runtime bundles its own glibc/ld.so build that the binary is linked
# against, so it must be invoked through the runtime's own dynamic linker
# rather than the host's.
exec "$DIR_DOLPHIN/runtime-lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" \
  --library-path "$LD_LIBRARY_PATH" \
  "$DIR_DOLPHIN/bin/dolphin-emu-nogui" "$@"
