#!/bin/bash
# testxray one-liner bootstrap — clone and run install.sh from disk.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Koviand/testxray.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
INSTALL_ROOT="${INSTALL_ROOT:-/usr/local/testxray}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y git curl
fi

if [[ -d "$INSTALL_ROOT/.git" ]]; then
  git -C "$INSTALL_ROOT" fetch origin "$REPO_BRANCH" --depth 1 2>/dev/null || true
  git -C "$INSTALL_ROOT" reset --hard "origin/${REPO_BRANCH}" 2>/dev/null || {
    echo "git reset failed; re-cloning ${INSTALL_ROOT}..." >&2
    rm -rf "$INSTALL_ROOT"
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_ROOT"
  }
else
  rm -rf "$INSTALL_ROOT"
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_ROOT"
fi

chmod +x "$INSTALL_ROOT"/install.sh "$INSTALL_ROOT"/uninstall.sh 2>/dev/null || true
chmod +x "$INSTALL_ROOT"/lib/*.sh "$INSTALL_ROOT"/hooks/*.sh "$INSTALL_ROOT"/scripts/*.sh 2>/dev/null || true
exec "$INSTALL_ROOT/install.sh" "$@"
