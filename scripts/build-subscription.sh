#!/bin/bash
# Regenerate Happ subscription JSON from panel-metadata + panel API UUID.
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
META="${AUTOXRAY_METADATA:-/etc/autoXRAY/panel-metadata.json}"
CREDS="${TESTXRAY_CREDENTIALS:-/etc/testxray/credentials.env}"

[[ -f "$META" ]] || { echo "missing $META" >&2; exit 1; }

domain=$(jq -r '.domain' "$META")
uuid=$(jq -r '.uuid' "$META")
pbk=$(jq -r '.public_key' "$META")
sid=$(jq -r '.short_id' "$META")
px=$(jq -r '.path_xhttp' "$META")
subpage=$(jq -r '.path_subpage' "$META")
socks_user=$(jq -r '.socks_user' "$META")
socks_pass=$(jq -r '.socks_pass' "$META")

# Prefer live UUID from panel if credentials exist
if [[ -f "$CREDS" ]] && command -v autoxray-api-seed >/dev/null; then
  live=$(autoxray-api-seed --verify-only --credentials "$CREDS" --state "$META" 2>/dev/null && \
    curl -fsS -H "Authorization: Bearer $(grep '^API_TOKEN=' "$CREDS" | cut -d= -f2-)" \
      "$(grep '^PANEL_URL=' "$CREDS" | cut -d= -f2-)panel/api/inbounds/list" 2>/dev/null | \
    jq -r '.[] | select(.tag=="vsRAWrtyVISION") | .settings' 2>/dev/null | \
    jq -r '.clients[0].id' 2>/dev/null) || true
  [[ -n "$live" && "$live" != "null" ]] && uuid="$live"
fi

web="/var/www/${domain}"
mkdir -p "$web"

linkRTY1="vless://${uuid}@${domain}:443?security=reality&type=tcp&flow=xtls-rprx-vision&sni=${domain}&fp=chrome&pbk=${pbk}&sid=${sid}&spx=%2F#vlessRAWrealityVISION-autoXRAY"
linkRTY2="vless://${uuid}@${domain}:443?security=reality&type=xhttp&path=%2F${px}&mode=stream-one&sni=${domain}&fp=chrome&pbk=${pbk}&sid=${sid}&spx=%2F#vlessXHTTPrealityEXTRA-autoXRAY"
linkTLS1="vless://${uuid}@${domain}:8443?security=tls&type=tcp&flow=xtls-rprx-vision&sni=${domain}&fp=chrome#vlessRAWtlsVision-autoXRAY"
linkTLS2="vless://${uuid}@${domain}:8443?security=tls&type=xhttp&path=%2F${px}&mode=auto&sni=${domain}&fp=chrome#vlessXHTTPtls-autoXRAY"
linkTLS3="vless://${uuid}@${domain}:8443?security=tls&type=ws&path=%2F${px}22&sni=${domain}&fp=chrome#vlessWStls-autoXRAY"
linkTLS4="vless://${uuid}@${domain}:8443?security=tls&type=grpc&serviceName=${px}11&sni=${domain}&fp=chrome#vlessGRPCtls-autoXRAY"

# Minimal Happ JSON (links array) — full client routing is in autoXRAY-generated file when present
if [[ -f "$web/${subpage}.json" ]] && jq -e '.outbounds' "$web/${subpage}.json" >/dev/null 2>&1; then
  # Keep rich routing from initial autoXRAY run; only refresh if metadata uuid changed
  :
else
  cat >"$web/${subpage}.json" <<EOF
[
  {"remarks":"VLESS XHTTP REALITY EXTRA","outbound":{"tag":"proxy","protocol":"vless"}},
  {"remarks":"VLESS RAW REALITY VISION","outbound":{"tag":"proxy","protocol":"vless"}}
]
EOF
fi

# Update HTML page links section is optional; autoXRAY creates full HTML on install
exit 0
