# testxray

Единый установщик **[autoXRAY](https://github.com/xVRVx/autoXRAY)** + **[3x-ui](https://github.com/MHSanaei/3x-ui)**.

autoXRAY настраивает nginx (selfsteal), сертификаты, WARP и генерирует секреты. **3x-ui** — единственный менеджер процесса Xray: inbound'ы импортируются через REST API панели.

## Требования

- Чистый **Debian 12** или **Ubuntu 22.04/24.04** (root)
- Домен с **A-записью** на IP сервера
- Порты: SSH, 80, 443, 8443, 10443, порт панели

## Установка одной командой

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/curl-install.sh)" -- ваш.домен.com
```

## Параметры

```bash
bash /usr/local/testxray/install.sh -- домен.com --panel-port 2053
bash /usr/local/testxray/install.sh -- домен.com --force
bash /usr/local/testxray/install.sh -- домен.com --skip-certbot
```

### Ошибка certbot / rate-limit Let's Encrypt

Если видите `too many certificates` — на сервере уже могут быть файлы в `/etc/letsencrypt/live/ваш.домен/`.
Обновите testxray и запустите снова (скрипт подхватит существующий cert), либо явно:

```bash
export SKIP_CERTBOT=1
bash /usr/local/testxray/install.sh -- testkovi.chickenkiller.com --skip-certbot
```

Проверка: `ls -la /etc/letsencrypt/live/ваш.домен/`

Если LE-сертификата нет (rate-limit), установка с `--skip-certbot` создаст **временный self-signed** cert (профили на 8443 с предупреждением; REALITY на 443 обычно работает).

Обновить копию на сервере (при расхождении git):

```bash
cd /usr/local/testxray && git fetch origin main && git reset --hard origin/main
bash install.sh -- ваш.домен.com --skip-certbot
```

## Важно

- После установки **`xray.service` замаскирован** — работает только Xray под `x-ui`.
- Профиль «VLESS XHTTP REALITY» — цепочка inbound'ов **443 REALITY** + **3333 XHTTP**; меняйте их согласованно в панели.
- Подписка Happ обновляется таймером `testxray-sync-sub.timer` (каждые 3 мин).

## Проверка

```bash
bash /usr/local/testxray/scripts/verify-install.sh
```

Подробный чеклист: [docs/e2e-checklist.md](docs/e2e-checklist.md).

## Удаление

```bash
bash /usr/local/testxray/uninstall.sh
x-ui uninstall
```
