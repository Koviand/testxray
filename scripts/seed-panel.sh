#!/bin/bash
# Repair: re-import inbounds only (panel + metadata must exist).
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
export INSTALL_ROOT FORCE_SEED=1 TESTXRAY_BOOTSTRAPPED=1

# shellcheck source=../lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"
# shellcheck source=../lib/xui.sh
source "${INSTALL_ROOT}/lib/xui.sh"
# shellcheck source=../lib/seed.sh
source "${INSTALL_ROOT}/lib/seed.sh"

require_root
refresh_credentials_from_panel
build_api_seed
run_api_seed
bash "${INSTALL_ROOT}/scripts/verify-install.sh"
log "Done — check Inbounds in panel."
