# testxray

Unified installer for **[autoXRAY](https://github.com/xVRVx/autoXRAY)** + **[3x-ui](https://github.com/MHSanaei/3x-ui)**.

autoXRAY configures nginx (selfsteal), certificates, WARP, and generates secrets. **3x-ui** is the only runtime manager for Xray: inbounds are imported via the panel REST API.

## Requirements

- Clean **Debian 12** or **Ubuntu 22.04/24.04** (root)
- Domain with **A record** pointing to the server
- Ports: 22 (SSH), 80 (certbot), 443, 8443, 10443, panel port (random by default)

## Quick install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/curl-install.sh)" -- your.domain.com
```

## Options

```bash
bash /usr/local/testxray/install.sh -- your.domain.com --panel-port 2053 --web-base-path mypath/
bash /usr/local/testxray/install.sh -- your.domain.com --panel-user admin --panel-pass 'secret'
bash /usr/local/testxray/install.sh -- your.domain.com --force   # re-seed managed inbounds
```

## Architecture

| Component | Role |
|-----------|------|
| autoXRAY `--panel-mode` | nginx, certbot, WARP, Happ pages, `/etc/autoXRAY/panel-metadata.json` |
| 3x-ui (official install) | Panel + single Xray process |
| `autoxray-api-seed` | Imports 7 inbounds + routing template via API |
| `xray.service` | **masked** — do not use standalone Xray |

## Managed inbounds

| Tag | Port | Notes |
|-----|------|-------|
| `vsRAWrtyVISION` | 443 | REALITY → fallback 3333 |
| `vsXHTTPrty` | 3333 | Inner XHTTP (pair with REALITY) |
| `vsRAWtlsVISION` | 8443 | TLS stack |
| `vsXHTTPtls` | 8400 | |
| `vsGRPCtls` | 8411 | |
| `vsWSinternal` | `@vless-ws` | WS fallback |
| `socks5` | 10443 | Mixed proxy |

Edit clients and enable/disable inbounds in the panel UI. Keep **443 REALITY** and **3333 XHTTP** consistent when changing paths or UUIDs.

## Files on server

| Path | Purpose |
|------|---------|
| `/usr/local/testxray` | Installer bundle |
| `/etc/testxray/credentials.env` | Panel URL, user, API token |
| `/etc/autoXRAY/panel-metadata.json` | autoXRAY secrets |
| `/etc/x-ui/x-ui.db` | Panel database (source of truth) |

## Verify

```bash
bash /usr/local/testxray/scripts/verify-install.sh
```

See [docs/e2e-checklist.md](docs/e2e-checklist.md).

## Uninstall

```bash
bash /usr/local/testxray/uninstall.sh
x-ui uninstall   # panel separately
```

## Phase 2 (not in v1)

- RU→EU bridge scripts
- MTProto FakeTLS test profile
