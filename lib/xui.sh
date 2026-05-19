#!/bin/bash
set -euo pipefail

# shellcheck source=lib/common.sh
source "${INSTALL_ROOT}/lib/common.sh"
# shellcheck source=lib/credentials.sh
source "${INSTALL_ROOT}/lib/credentials.sh"

XUI_FOLDER="${XUI_FOLDER:-/usr/local/x-ui}"
XUI_INSTALL_URL="${XUI_INSTALL_URL:-https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh}"

install_xui_official() {
  if [[ -x "${XUI_FOLDER}/x-ui" ]]; then
    log "3x-ui already installed at ${XUI_FOLDER}"
    return 0
  fi
  log "Installing official 3x-ui..."
  # n = random port; 4 = skip panel SSL; n = do not bind localhost only
  printf 'n\n4\nn\n' | bash <(curl -fsSL "$XUI_INSTALL_URL")
  systemctl enable x-ui >/dev/null 2>&1 || true
  systemctl start x-ui >/dev/null 2>&1 || true
  sleep 3
}

configure_xui_settings() {
  local user="${PANEL_USER:-admin}"
  local pass="${PANEL_PASS:-}"
  local port="${PANEL_PORT:-}"
  local base="${WEB_BASE_PATH:-}"

  [[ -n "$pass" ]] || pass=$(rand_pass)
  [[ -n "$port" ]] || port=$(rand_port)
  [[ -n "$base" ]] || base=$(rand_path)
  base="${base#/}"

  log "Configuring panel: port=${port} webBasePath=/${base}/"
  "${XUI_FOLDER}/x-ui" setting \
    -username "$user" \
    -password "$pass" \
    -port "$port" \
    -webBasePath "$base" \
    -listenIP 0.0.0.0

  systemctl restart x-ui
  sleep 4
  refresh_credentials_from_panel
  export PANEL_URL
  PANEL_URL=$(grep '^PANEL_URL=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)
}

wait_for_panel() {
  local i url
  url=$(grep '^PANEL_URL=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)
  for i in $(seq 1 30); do
    if curl -fsS -o /dev/null "${url}login" 2>/dev/null; then
      return 0
    fi
    sleep 2
  done
  die "Panel did not become reachable at ${url}"
}

mask_standalone_xray() {
  log "Masking standalone xray.service (panel owns Xray)..."
  systemctl stop xray 2>/dev/null || true
  systemctl disable xray 2>/dev/null || true
  systemctl mask xray 2>/dev/null || true
}

build_api_seed() {
  log "Building autoxray-api-seed..."
  (cd "${INSTALL_ROOT}/tools/autoxray-api-seed" && go build -o /usr/local/bin/autoxray-api-seed .)
}

run_api_seed() {
  local extra=()
  [[ "${FORCE_SEED:-0}" == "1" ]] && extra+=(--force)
  log "Refreshing panel credentials from live x-ui settings..."
  refresh_credentials_from_panel
  systemctl stop xray 2>/dev/null || true
  log "Seeding inbounds via panel API..."
  if ! autoxray-api-seed \
    --credentials "$TESTXRAY_CREDENTIALS" \
    --state "$AUTOXRAY_METADATA" \
    --install-dir "$INSTALL_ROOT" \
    "${extra[@]}" 2>&1 | tee /var/log/testxray-seed.log; then
    die "autoxray-api-seed failed — see /var/log/testxray-seed.log"
  fi
}
