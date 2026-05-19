#!/bin/bash
# Write /etc/testxray/credentials.env
set -euo pipefail

write_credentials() {
  local url="$1" user="$2" pass="$3" token="${4:-}" base_path="${5:-}"
  mkdir -p /etc/testxray
  cat >"$TESTXRAY_CREDENTIALS" <<EOF
# testxray panel credentials — chmod 600
PANEL_URL=${url}
PANEL_USER=${user}
PANEL_PASS=${pass}
API_TOKEN=${token}
WEB_BASE_PATH=${base_path}
EOF
  chmod 600 "$TESTXRAY_CREDENTIALS"
}

panel_url_from_settings() {
  local ip port base show
  show=$(${XUI_FOLDER:-/usr/local/x-ui}/x-ui setting -show true)
  ip=$(server_ip)
  port=$(echo "$show" | grep -Eo 'port: .+' | awk '{print $2}')
  base=$(echo "$show" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
  base="${base#/}"
  base="${base%/}"
  if [[ -n "$base" ]]; then
    echo "http://${ip}:${port}/${base}/"
  else
    echo "http://${ip}:${port}/"
  fi
}

refresh_credentials_from_panel() {
  read_setting_user_pass
  local url token bp
  url=$(panel_url_from_settings)
  token=$(read_api_token)
  bp=$(echo "$url" | sed -E 's#https?://[^/]+##' )
  [[ "$bp" == "/" ]] && bp=""
  write_credentials "$url" "$PANEL_USER" "$PANEL_PASS" "$token" "$bp"
}

read_setting_user_pass() {
  local show
  show=$(${XUI_FOLDER:-/usr/local/x-ui}/x-ui setting -show true)
  PANEL_USER=$(echo "$show" | grep -Eo 'username: .+' | awk '{print $2}')
  PANEL_PASS=$(echo "$show" | grep -Eo 'password: .+' | awk '{print $2}')
}

read_api_token() {
  ${XUI_FOLDER:-/usr/local/x-ui}/x-ui setting -getApiToken true 2>/dev/null | grep -Eo 'apiToken: .+' | awk '{print $2}' || true
}
