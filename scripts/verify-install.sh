#!/bin/bash
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
META="${AUTOXRAY_METADATA:-/etc/autoXRAY/panel-metadata.json}"
CREDS="${TESTXRAY_CREDENTIALS:-/etc/testxray/credentials.env}"

fail=0
ok() { echo "[OK] $*"; }
bad() { echo "[FAIL] $*"; fail=1; }

systemctl is-active --quiet x-ui && ok "x-ui running" || bad "x-ui not running"
systemctl is-active --quiet nginx && ok "nginx running" || bad "nginx not running"

if systemctl is-enabled xray 2>/dev/null | grep -q masked; then
  ok "xray.service masked"
elif ! systemctl is-active --quiet xray 2>/dev/null; then
  ok "standalone xray not active"
else
  bad "standalone xray still active — run: systemctl mask xray"
fi

ss -tln | grep -q ':443 ' && ok "port 443 listening" || bad "port 443 not listening"
ss -tln | grep -q ':8443 ' && ok "port 8443 listening" || bad "port 8443 not listening"
ss -tln | grep -q ':10443 ' && ok "port 10443 listening" || bad "port 10443 not listening"

[[ -f "$META" ]] && ok "panel-metadata.json" || bad "missing panel-metadata"
[[ -f "$CREDS" ]] && ok "credentials.env" || bad "missing credentials"

if command -v autoxray-api-seed >/dev/null && [[ -f "$CREDS" ]]; then
  autoxray-api-seed --verify-only --credentials "$CREDS" --state "$META" --install-dir "$INSTALL_ROOT" && ok "7 managed inbounds" || bad "inbound verify failed"
fi

exit "$fail"
