#!/bin/bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"

ensure_xray_in_path() {
  local xui_bin="${XUI_FOLDER:-/usr/local/x-ui}/bin"
  if [[ -d "$xui_bin" ]]; then
    export PATH="${xui_bin}:${PATH}"
  fi
  command -v xray >/dev/null 2>&1 || die "xray binary not found — install 3x-ui first"
}

run_autoxray() {
  local domain="$1"
  ensure_xray_in_path
  export AUTOXRAY_NONINTERACTIVE=1
  export TESTXRAY_CERTBOT_HOOK
  export TESTXRAY_SKIP_APT=1
  export SKIP_CERTBOT="${SKIP_CERTBOT:-0}"
  log "Running autoXRAY (panel mode) for ${domain}..."
  bash "${INSTALL_ROOT}/vendor/autoXRAY/autoXRAY1.sh" --panel-mode "$domain"
  [[ -f "$AUTOXRAY_METADATA" ]] || die "Missing $AUTOXRAY_METADATA after autoXRAY"
}
