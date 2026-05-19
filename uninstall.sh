#!/bin/bash
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"

echo "Stopping testxray timer..."
systemctl disable --now testxray-sync-sub.timer 2>/dev/null || true
rm -f /etc/systemd/system/testxray-sync-sub.{service,timer}
systemctl daemon-reload 2>/dev/null || true

echo "Removing testxray install dir (optional)..."
read -rp "Delete ${INSTALL_ROOT}? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  rm -rf "$INSTALL_ROOT"
fi

echo "Panel and autoXRAY infra are NOT removed automatically."
echo "  x-ui uninstall: x-ui uninstall"
echo "  autoXRAY: see https://github.com/xVRVx/autoXRAY#как-удалить-скрипт"
