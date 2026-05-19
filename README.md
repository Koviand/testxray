# testxray

**One command** installs [autoXRAY](https://github.com/xVRVx/autoXRAY) + [3x-ui](https://github.com/MHSanaei/3x-ui) with all inbounds imported into the panel.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- your.domain.com
```

Requirements: Debian 12 or Ubuntu 22.04+, root, domain A-record → server IP.

The installer will:

1. Install system dependencies (nginx, certbot, golang, …)
2. Install **3x-ui** from the [official MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) `install.sh`
3. Deploy autoXRAY infrastructure (nginx TLS, WARP, `panel-metadata.json`)
4. Import **7 autoXRAY inbounds** into the panel via API (adapted templates)
5. Mask standalone `xray.service` (only the panel manages Xray)

## After install

- Panel URL, login and password are printed at the end
- Credentials: `/etc/testxray/credentials.env`
- Re-run the **same command** to resume or update (skips completed steps)

## Options

```bash
bash <(curl -fsSL .../install.sh) -- domain.com --skip-certbot
bash <(curl -fsSL .../install.sh) -- domain.com --panel-port 2053 --panel-pass 'secret'
bash <(curl -fsSL .../install.sh) -- domain.com --reinstall
```

## Repair inbounds only

```bash
bash /usr/local/testxray/scripts/seed-panel.sh
```
