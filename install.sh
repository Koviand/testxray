#!/bin/bash
# testxray — one-shot installer: autoXRAY + 3x-ui + panel import
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Koviand/testxray.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"

DOMAIN=""
REINSTALL=0
FORCE_SEED=1
SKIP_CERTBOT=0
PANEL_USER="${PANEL_USER:-admin}"
PANEL_PASS="${PANEL_PASS:-}"
PANEL_PORT="${PANEL_PORT:-}"
WEB_BASE_PATH="${WEB_BASE_PATH:-}"

usage() {
  cat <<'EOF'
testxray — autoXRAY + 3x-ui (single command)

  bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- DOMAIN

Options:
  --reinstall       redo autoXRAY infra + reset panel creds
  --skip-certbot    do not request Let's Encrypt (use existing or self-signed)
  --panel-port N    panel port (default: random)
  --web-base-path P panel URL path (default: random)
  --panel-user U    panel login (default: admin)
  --panel-pass P    panel password (default: random)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --) shift; continue ;;
      -h|--help) usage; exit 0 ;;
      --reinstall) REINSTALL=1; shift ;;
      --skip-certbot) SKIP_CERTBOT=1; shift ;;
      --no-force-seed) FORCE_SEED=0; shift ;;
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
  [[ -n "$DOMAIN" ]] || { usage; die "Domain required. Example: ... install.sh) -- example.com"; }
}

bootstrap_repo() {
  [[ "${TESTXRAY_BOOTSTRAPPED:-0}" == "1" ]] && return 0

  local self
  self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  local target="${INSTALL_ROOT}/install.sh"

  if [[ -f "$target" ]] && [[ "$(readlink -f "$self" 2>/dev/null || echo "$self")" == "$(readlink -f "$target" 2>/dev/null || echo "$target")" ]]; then
    export TESTXRAY_BOOTSTRAPPED=1
    return 0
  fi

  echo "==> Installing testxray to ${INSTALL_ROOT}..."
  if ! command -v git >/dev/null 2>&1; then
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y git curl
  fi

  if [[ -d "${INSTALL_ROOT}/.git" ]]; then
    git -C "$INSTALL_ROOT" fetch origin "$REPO_BRANCH" --depth 1 2>/dev/null || true
    git -C "$INSTALL_ROOT" reset --hard "origin/${REPO_BRANCH}" 2>/dev/null || true
  else
    rm -rf "$INSTALL_ROOT"
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_ROOT"
  fi

  chmod +x "${INSTALL_ROOT}"/install.sh "${INSTALL_ROOT}"/uninstall.sh 2>/dev/null || true
  chmod +x "${INSTALL_ROOT}"/lib/*.sh "${INSTALL_ROOT}"/hooks/*.sh "${INSTALL_ROOT}"/scripts/*.sh 2>/dev/null || true

  export TESTXRAY_BOOTSTRAPPED=1
  exec "$target" "$@"
}

auto_certbot_flags() {
  [[ "$SKIP_CERTBOT" == "1" ]] && return 0
  if [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
    log "Let's Encrypt cert exists — skip certbot request"
    SKIP_CERTBOT=1
    return 0
  fi
  if certbot certificates 2>/dev/null | grep -qE "(^| )${DOMAIN}( |$)"; then
    log "certbot already has ${DOMAIN} — skip new request"
    SKIP_CERTBOT=1
  fi
}

phase_autoxray() {
  if [[ -f "$AUTOXRAY_METADATA" ]] && [[ "$REINSTALL" != "1" ]]; then
    log "autoXRAY already configured (${AUTOXRAY_METADATA}) — skip"
    return 0
  fi
  # shellcheck source=lib/setup-autoxray.sh
  source "${INSTALL_ROOT}/lib/setup-autoxray.sh"
  run_autoxray "$DOMAIN"
}

phase_panel() {
  # shellcheck source=lib/xui.sh
  source "${INSTALL_ROOT}/lib/xui.sh"
  if [[ "$REINSTALL" == "1" ]]; then
    systemctl stop x-ui 2>/dev/null || true
  fi
  install_xui_official
  if [[ -f "$TESTXRAY_CREDENTIALS" ]] && [[ "$REINSTALL" != "1" ]] && [[ -z "$PANEL_PASS" ]] && [[ -z "$PANEL_PORT" ]]; then
    log "Panel already configured — refresh credentials only"
    refresh_credentials_from_panel
  else
    configure_xui_settings
  fi
  wait_for_panel
  mask_standalone_xray
}

phase_seed() {
  # shellcheck source=lib/seed.sh
  source "${INSTALL_ROOT}/lib/seed.sh"
  build_api_seed
  run_api_seed
}

phase_finalize() {
  bash "${INSTALL_ROOT}/scripts/verify-install.sh" || die "Verification failed"

  cp "${INSTALL_ROOT}/systemd/testxray-sync-sub.service" /etc/systemd/system/
  cp "${INSTALL_ROOT}/systemd/testxray-sync-sub.timer" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now testxray-sync-sub.timer 2>/dev/null || true

  local sub
  sub=$(jq -r '.path_subpage' "$AUTOXRAY_METADATA")
  echo ""
  echo "=============================================="
  echo "  testxray — installation complete"
  echo "=============================================="
  echo "  Panel:     $(grep '^PANEL_URL=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  Login:     $(grep '^PANEL_USER=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  Password:  $(grep '^PANEL_PASS=' "$TESTXRAY_CREDENTIALS" | cut -d= -f2-)"
  echo "  Happ sub:  https://${DOMAIN}/${sub}.json"
  echo "  Inbounds:  7 (autoXRAY tags in panel)"
  echo "  Log seed:  /var/log/testxray-seed.log"
  echo "=============================================="
}

main() {
  bootstrap_repo "$@"

  # shellcheck source=lib/common.sh
  source "${INSTALL_ROOT}/lib/common.sh"
  parse_args "$@"
  require_root
  check_os
  ensure_dirs
  ensure_deps

  chmod +x "${INSTALL_ROOT}"/lib/*.sh "${INSTALL_ROOT}"/hooks/*.sh "${INSTALL_ROOT}"/scripts/*.sh 2>/dev/null || true

  export INSTALL_ROOT TESTXRAY_CERTBOT_HOOK FORCE_SEED SKIP_CERTBOT
  export PANEL_USER PANEL_PASS PANEL_PORT WEB_BASE_PATH REINSTALL

  auto_certbot_flags

  log "=== [1/4] autoXRAY (nginx, cert, WARP) ==="
  phase_autoxray

  log "=== [2/4] 3x-ui panel ==="
  phase_panel

  log "=== [3/4] Import inbounds to panel ==="
  phase_seed

  log "=== [4/4] Verify ==="
  phase_finalize
}

main "$@"
