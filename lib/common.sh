#!/bin/bash
# Shared helpers for testxray installer.
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
AUTOXRAY_METADATA="${AUTOXRAY_METADATA:-/etc/autoXRAY/panel-metadata.json}"
TESTXRAY_CREDENTIALS="${TESTXRAY_CREDENTIALS:-/etc/testxray/credentials.env}"
TESTXRAY_CERTBOT_HOOK="${TESTXRAY_CERTBOT_HOOK:-$INSTALL_ROOT/hooks/certbot-deploy.sh}"

log() { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }
die() { echo "==> ERROR: $*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Run as root."
}

check_os() {
  if [[ ! -f /etc/os-release ]]; then
    die "Unsupported OS (no /etc/os-release)."
  fi
  # shellcheck source=/dev/null
  source /etc/os-release
  case "${ID:-}" in
    debian)
      [[ "${VERSION_ID:-}" == "12" ]] || warn "Expected Debian 12, got ${VERSION_ID:-unknown}"
      ;;
    ubuntu)
      local major="${VERSION_ID%%.*}"
      [[ "$major" -ge 22 ]] 2>/dev/null || die "Ubuntu $VERSION_ID not supported (need 22.04+)"
      ;;
    *)
      die "Unsupported OS: ${ID:-unknown}. Use Debian 12 or Ubuntu 22.04+."
      ;;
  esac
}

ensure_deps() {
  log "Installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y \
    curl jq git python3 ca-certificates golang-go openssl \
    nginx certbot dnsutils
  systemctl enable --now nginx 2>/dev/null || true
  export TESTXRAY_DEPS_INSTALLED=1
}

ensure_dirs() {
  mkdir -p /etc/testxray /etc/autoXRAY
  chmod 700 /etc/testxray /etc/autoXRAY
}

rand_port() {
  shuf -i 20000-60000 -n 1
}

rand_path() {
  tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 18
}

rand_pass() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

server_ip() {
  local ip
  ip=$(curl -4 -fsS --max-time 5 https://api4.ipify.org 2>/dev/null) || true
  if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$ip"
    return
  fi
  hostname -I | awk '{print $1}'
}
