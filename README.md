# testxray

**One command** installs [autoXRAY](https://github.com/xVRVx/autoXRAY) + [3x-ui](https://github.com/MHSanaei/3x-ui) with all inbounds imported into the panel.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- your.domain.com
```

Requirements: Debian 12 or Ubuntu 22.04+, root, domain A-record → server IP.

The installer will:

1. Deploy autoXRAY (nginx, certs, WARP, secrets)
2. Install 3x-ui (official release)
3. Import **7 inbounds** into the panel via API
4. Mask standalone `xray.service` (only panel manages Xray)

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
