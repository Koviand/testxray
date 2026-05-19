#!/bin/bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"

run_autoxray() {
  local domain="$1"
  export AUTOXRAY_NONINTERACTIVE=1
  export TESTXRAY_CERTBOT_HOOK
  export TESTXRAY_DEPS_INSTALLED="${TESTXRAY_DEPS_INSTALLED:-1}"
  export SKIP_CERTBOT="${SKIP_CERTBOT:-0}"
  log "Running autoXRAY (panel mode) for ${domain}..."
  bash "${INSTALL_ROOT}/vendor/autoXRAY/autoXRAY1.sh" --panel-mode "$domain"
  [[ -f "$AUTOXRAY_METADATA" ]] || die "Missing $AUTOXRAY_METADATA after autoXRAY"
  # shellcheck source=lib/xui.sh
  source "${INSTALL_ROOT}/lib/xui.sh"
  mask_standalone_xray
}
