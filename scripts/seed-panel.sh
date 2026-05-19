#!/bin/bash
# Re-import autoXRAY inbounds into 3x-ui (repair / manual seed).
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"
# shellcheck source=lib/credentials.sh
source "${INSTALL_ROOT}/lib/credentials.sh"

[[ -f "$AUTOXRAY_METADATA" ]] || die "Missing $AUTOXRAY_METADATA — run autoXRAY first."
[[ -f "$TESTXRAY_CREDENTIALS" ]] || die "Missing $TESTXRAY_CREDENTIALS — install 3x-ui first."

export FORCE_SEED="${FORCE_SEED:-1}"
# shellcheck source=lib/xui.sh
source "${INSTALL_ROOT}/lib/xui.sh"

refresh_credentials_from_panel
systemctl stop xray 2>/dev/null || true
systemctl mask xray 2>/dev/null || true

if ! command -v autoxray-api-seed >/dev/null; then
  build_api_seed
fi

run_api_seed
bash "${INSTALL_ROOT}/scripts/verify-install.sh"
log "Seed complete. Open panel → Inbounds to verify 7 autoXRAY entries."
