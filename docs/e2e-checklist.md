# E2E checklist (testxray v1)

Target: clean VPS, Debian 12 or Ubuntu 22.04/24.04, root, domain A-record → server IP.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- your.domain.com
```

Expected phase order in installer output:

1. Dependencies (apt: nginx, certbot, golang, …)
2. 3x-ui panel (official `MHSanaei/3x-ui` install script)
3. autoXRAY (nginx, cert, WARP, metadata)
4. Import 7 inbounds into panel
5. Verify

## Verify

- [ ] `systemctl is-active x-ui` — active
- [ ] `systemctl is-active nginx` — active
- [ ] `systemctl is-enabled xray` shows `masked`
- [ ] `ss -tln | grep -E ':443 |:8443 |:10443 '` — ports open
- [ ] Panel opens at URL from installer output; login works
- [ ] Inbounds page shows 7 entries with tags `vsWSinternal` … `socks5`
- [ ] `bash /usr/local/testxray/scripts/verify-install.sh` exits 0
- [ ] `journalctl -u x-ui -n 50` — no Xray config errors
- [ ] Happ: `https://domain/<subpage>.json` loads
- [ ] Client: VLESS RAW REALITY VISION connects
- [ ] Client: VLESS XHTTP REALITY (443 → inner XHTTP) connects
- [ ] Disable `vsXHTTPrty` in panel → XHTTP REALITY profile fails (expected)
- [ ] Re-enable inbound → works again
- [ ] Reboot VPS → services up, verify script passes
- [ ] `systemctl list-timers testxray-sync-sub.timer` — active

## Regression notes

- Changing UUID on `vsRAWrtyVISION` client updates panel; update Happ subscription after timer or run `build-subscription.sh`.
- Do not run standalone `autoXRAY1.sh` without `--panel-mode` on same host.
