#!/bin/bash
# Legacy entry — same as install.sh (kept for old links).
set -euo pipefail
exec bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) "$@"
