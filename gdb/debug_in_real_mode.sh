#!/usr/bin/env bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to that directory
cd "$SCRIPT_DIR" || exit 1

# Now the script's working directory is the same as the script's directory
echo "Current directory: $(pwd)"

gdb -ix gdb_init_real_mode.gdb -ex 'set tdesc filename target.xml' -ex 'target remote localhost:1234' -ex 'break *0x7c00'

