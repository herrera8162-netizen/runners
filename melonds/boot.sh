#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Main directory
export DIR_MELONDS="$SCRIPT_DIR"

# Use included libs
export LD_LIBRARY_PATH="$DIR_MELONDS/lib:$LD_LIBRARY_PATH"

# Start
# qt.conf next to the binary (Prefix=../, Plugins=plugins) makes Qt find its
# own bundled plugins automatically, same as RPCS3's AppImage layout - no
# QT_PLUGIN_PATH needed as long as bin/, lib/, plugins/, share/ stay intact.
"$DIR_MELONDS"/bin/melonDS "$@"
