#!/bin/bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"

run_autoxray() {
  local domain="$1"
  export AUTOXRAY_NONINTERACTIVE=1
  export TESTXRAY_CERTBOT_HOOK
  log "Running autoXRAY (panel mode) for ${domain}..."
  bash "${INSTALL_ROOT}/vendor/autoXRAY/autoXRAY1.sh" --panel-mode "$domain"
  [[ -f "$AUTOXRAY_METADATA" ]] || die "Missing $AUTOXRAY_METADATA after autoXRAY"
}
