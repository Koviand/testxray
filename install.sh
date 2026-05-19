#!/bin/bash
# testxray — autoXRAY + 3x-ui unified installer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${INSTALL_ROOT:-$SCRIPT_DIR}"
REPO_URL="${REPO_URL:-https://github.com/Koviand/testxray.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

DOMAIN=""
REINSTALL=0
AUTO_YES=0
FORCE_SEED=0
PANEL_USER="${PANEL_USER:-admin}"
PANEL_PASS="${PANEL_PASS:-}"
PANEL_PORT="${PANEL_PORT:-}"
WEB_BASE_PATH="${WEB_BASE_PATH:-}"

usage() {
  cat <<'EOF'
testxray — autoXRAY + 3x-ui (panel-managed Xray)

Usage:
  bash install.sh -- <domain>
  bash install.sh --reinstall -y -- <domain>
  bash install.sh -- <domain> --panel-port 2053 --web-base-path secret/
  bash install.sh -- <domain> --panel-user admin --panel-pass 'secret'
  bash install.sh -- <domain> --force

One-liner:
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/curl-install.sh)" -- example.com
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --) shift; continue ;;
      -h|--help) usage; exit 0 ;;
      -y|--yes) AUTO_YES=1; shift ;;
      --reinstall) REINSTALL=1; shift ;;
      --force) FORCE_SEED=1; shift ;;
      --panel-user) PANEL_USER="$2"; shift 2 ;;
      --panel-pass) PANEL_PASS="$2"; shift 2 ;;
      --panel-port) PANEL_PORT="$2"; shift 2 ;;
      --web-base-path) WEB_BASE_PATH="$2"; shift 2 ;;
      -*) die "Unknown option: $1" ;;
      *)
        [[ -z "$DOMAIN" ]] || die "Multiple domains?"
        DOMAIN="$1"
        shift
        ;;
    esac
  done
  [[ -n "$DOMAIN" ]] || { usage; die "Domain required."; }
}

main() {
  # shellcheck source=lib/common.sh
  source "${INSTALL_ROOT}/lib/common.sh"
  parse_args "$@"
  require_root
  check_os
  ensure_dirs
  ensure_deps

  chmod +x "${INSTALL_ROOT}"/lib/*.sh "${INSTALL_ROOT}"/hooks/*.sh "${INSTALL_ROOT}"/scripts/*.sh 2>/dev/null || true

  export INSTALL_ROOT TESTXRAY_CERTBOT_HOOK FORCE_SEED PANEL_USER PANEL_PASS PANEL_PORT WEB_BASE_PATH

  # shellcheck source=lib/setup-autoxray.sh
  source "${INSTALL_ROOT}/lib/setup-autoxray.sh"
  run_autoxray "$DOMAIN"

  # shellcheck source=lib/xui.sh
  source "${INSTALL_ROOT}/lib/xui.sh"
  if [[ "$REINSTALL" == "1" ]]; then
  systemctl stop x-ui 2>/dev/null || true
  fi
  install_xui_official
  configure_xui_settings
  wait_for_panel
  mask_standalone_xray

  if ! command -v go >/dev/null 2>&1; then
    apt-get install -y golang-go
  fi
  build_api_seed
  run_api_seed

  bash "${INSTALL_ROOT}/scripts/verify-install.sh" || die "verify-install failed"

  cp "${INSTALL_ROOT}/systemd/testxray-sync-sub.service" /etc/systemd/system/
  cp "${INSTALL_ROOT}/systemd/testxray-sync-sub.timer" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now testxray-sync-sub.timer

  local sub
  sub=$(jq -r '.path_subpage' "$AUTOXRAY_METADATA")
  echo ""
  log "Installation complete."
  echo "  Panel:    $(grep '^PANEL_URL=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  User:     $(grep '^PANEL_USER=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  Password: $(grep '^PANEL_PASS=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  Happ sub: https://${DOMAIN}/${sub}.json"
  echo "  Creds:    ${TESTXRAY_CREDENTIALS}"
}

main "$@"
