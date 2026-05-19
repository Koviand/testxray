#!/bin/bash
# Certbot deploy hook — reload nginx certs and restart 3x-ui (not standalone xray).
set -euo pipefail

DOMAIN="${RENEWED_LINEAGE##*/}"
if [[ -z "$DOMAIN" && -f /etc/autoXRAY/panel-metadata.json ]]; then
  DOMAIN=$(jq -r '.domain' /etc/autoXRAY/panel-metadata.json)
fi

if [[ -n "$DOMAIN" && -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
  cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /var/lib/xray/cert/fullchain.pem
  cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /var/lib/xray/cert/privkey.pem
  chmod 744 /var/lib/xray/cert/privkey.pem /var/lib/xray/cert/fullchain.pem
fi

systemctl reload nginx 2>/dev/null || true
systemctl restart x-ui 2>/dev/null || true

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"
if [[ -x "$INSTALL_ROOT/scripts/build-subscription.sh" ]]; then
  bash "$INSTALL_ROOT/scripts/build-subscription.sh" || true
fi
