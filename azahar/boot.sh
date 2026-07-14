#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Main directory
export DIR_AZAHAR="$SCRIPT_DIR"

# Use included libs
export LD_LIBRARY_PATH="$DIR_AZAHAR/lib:$LD_LIBRARY_PATH"

# Start
# qt.conf next to the binary (Prefix=../, Plugins=plugins) makes Qt find its
# own bundled plugins automatically, same as RPCS3/melonDS's AppImage layout.
"$DIR_AZAHAR"/bin/azahar "$@"
