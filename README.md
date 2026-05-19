# testxray

**One command** installs [autoXRAY](https://github.com/xVRVx/autoXRAY) + [3x-ui](https://github.com/MHSanaei/3x-ui) with all inbounds imported into the panel.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- your.domain.com
```

Requirements: Debian 12 or Ubuntu 22.04+, root, domain A-record → server IP.

The installer runs in this order:

1. **Dependencies** — apt packages (nginx, certbot, golang, …)
2. **3x-ui** — official [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) `install.sh`
3. **autoXRAY prep** — nginx, TLS, WARP, keys → `panel-metadata.json` (`--panel-mode`)
4. **INBOUND import** — 7 autoXRAY templates into the panel via API
5. **Verify** — ports, masked `xray.service`, subscription timer

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
