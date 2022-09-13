#!/bin/bash

set -eu

# cd to script directory
cd "$(dirname "$(realpath "$0")")"

# ensure locally-installed programs are found (such as ksflatten)
export PATH="$PATH:$HOME/.local/bin"

# import bashlib and config
source _bashlib.sh
source _config.sh

# execute given script
source "$1"
