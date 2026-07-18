# linux-monitoring 2.0.0

Модульний набір колекторів для Zabbix Agent 2.

Поточні модулі:

- **SMART** — стан SATA/SAS/NVMe накопичувачів через `smartctl`.
- **Sensors** — температури, вентилятори, напруги, потужність та інші сенсори через `lm-sensors`.

Кожен модуль працює незалежно:

```text
collector -> JSON cache -> Zabbix Agent Alias -> master item -> dependent items
```

## Швидкий старт на новому Debian/Proxmox сервері

```bash
sudo apt update
sudo apt install -y unzip zabbix-agent2 zabbix-get

unzip linux-monitoring-v2.0.0.zip
cd linux-monitoring-v2.0.0

sudo ./install.sh
```

Після встановлення перевірте:

```bash
systemctl status linux-monitoring-smart.timer --no-pager
systemctl status linux-monitoring-sensors.timer --no-pager

jq . /var/lib/linux-monitoring/smart.json
jq . /var/lib/linux-monitoring/sensors.json

zabbix_agent2 -t smart.cache.json
zabbix_agent2 -t sensors.cache.json
```

Детальна покрокова інструкція:

- [Вимоги](docs/02-Requirements.md)
- [Розгортання на новому сервері](docs/03-Installation.md)
- [Налаштування Zabbix](docs/04-Zabbix-Configuration.md)
- [Перевірка](docs/05-Verification.md)
- [Діагностика](docs/08-Troubleshooting.md)

## Параметри інсталятора

```text
--timer-interval VALUE    інтервал таймерів, стандартно 5m
--modules LIST            smart,sensors або smart
--skip-packages           не встановлювати пакети
--skip-agent-restart      не перезапускати zabbix-agent2
--run-sensors-detect      запустити sensors-detect --auto
--dry-run                 показати дії без внесення змін
--debug                   трасування Bash
```

Приклади:

```bash
sudo ./install.sh --modules smart,sensors --timer-interval 5m
sudo ./install.sh --modules smart
sudo ./install.sh --run-sensors-detect
```

> `sensors-detect --auto` не запускається автоматично, щоб не змінювати перелік модулів ядра без явної згоди адміністратора.
