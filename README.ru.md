# testxray

**Одна команда** ставит [autoXRAY](https://github.com/xVRVx/autoXRAY) + [3x-ui](https://github.com/MHSanaei/3x-ui) и импортирует все inbound'ы в панель.

## Установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Koviand/testxray/main/install.sh) -- ваш.домен.com
```

Нужно: Debian 12 или Ubuntu 22.04+, root, A-запись домена на IP сервера.

Порядок установки:

1. **Зависимости** — apt (nginx, certbot, golang, …)
2. **3x-ui** — официальный установщик [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui)
3. **Подготовка autoXRAY** — nginx, TLS, WARP, ключи → `panel-metadata.json` (`--panel-mode`)
4. **INBOUND** — 7 шаблонов autoXRAY импортируются в панель через API
5. **Проверка** — порты, `xray.service` masked, таймер подписки

## После установки

В конце выводятся URL панели, логин и пароль.

- Учётные данные: `/etc/testxray/credentials.env`
- Лог импорта: `/var/log/testxray-seed.log`
- **Повторный запуск той же команды** продолжит/дополнит установку (уже сделанные шаги пропускаются)

## Параметры

```bash
bash <(curl -fsSL .../install.sh) -- домен.com --skip-certbot
bash <(curl -fsSL .../install.sh) -- домен.com --panel-port 2053 --panel-pass 'пароль'
```

`--skip-certbot` — не запрашивать новый LE-сертификат (если rate-limit или используется self-signed).

## Только импорт в панель

```bash
bash /usr/local/testxray/scripts/seed-panel.sh
```
