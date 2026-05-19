#!/bin/bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"
# shellcheck source=lib/credentials.sh
source "${INSTALL_ROOT}/lib/credentials.sh"

build_api_seed() {
  log "Building autoxray-api-seed..."
  (cd "${INSTALL_ROOT}/tools/autoxray-api-seed" && go build -o /usr/local/bin/autoxray-api-seed .)
}

run_api_seed() {
  local extra=()
  [[ "${FORCE_SEED:-1}" == "1" ]] && extra+=(--force)
  [[ -f "$AUTOXRAY_METADATA" ]] || die "Missing $AUTOXRAY_METADATA"
  [[ -f "$TESTXRAY_CREDENTIALS" ]] || die "Missing $TESTXRAY_CREDENTIALS — install 3x-ui first"

  log "Refreshing panel credentials..."
  refresh_credentials_from_panel
  systemctl stop xray 2>/dev/null || true

  log "Importing 7 autoXRAY inbounds into 3x-ui..."
  if ! autoxray-api-seed \
    --credentials "$TESTXRAY_CREDENTIALS" \
    --state "$AUTOXRAY_METADATA" \
    --install-dir "$INSTALL_ROOT" \
    "${extra[@]}" 2>&1 | tee /var/log/testxray-seed.log; then
    die "Import failed — log: /var/log/testxray-seed.log"
  fi

  # shellcheck source=lib/xui.sh
  source "${INSTALL_ROOT}/lib/xui.sh"
  mask_standalone_xray
}
