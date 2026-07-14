#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Main directory
export DIR_CEMU="$SCRIPT_DIR"

# Use included libs
export LD_LIBRARY_PATH="$DIR_CEMU/lib:$LD_LIBRARY_PATH"

# Start
# Cemu uses GTK3, not Qt (confirmed via ldd - no qt.conf/bundled Qt plugins
# like RPCS3/melonDS/Azahar), so there's no plugin-path config file needed
# here beyond LD_LIBRARY_PATH.
"$DIR_CEMU"/bin/Cemu "$@"
