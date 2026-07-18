# 2. Вимоги

## Підтримувані системи

Основна ціль:

- Debian 12/13
- Proxmox VE на базі Debian
- Ubuntu Server з systemd та `apt`

## Обов'язково

- root або sudo
- systemd
- Zabbix Agent 2
- доступ Zabbix Server/Proxy до TCP 10050
- `jq`

## Для SMART

- `smartmontools`
- прямий доступ ОС до дисків або коректний тип RAID/HBA пристрою

## Для Sensors

- `lm-sensors`
- відповідні модулі ядра: `coretemp`, `k10temp`, `nct6775` тощо

Не всі плати експортують вентилятори або напруги. Відсутність показника не є помилкою колектора.
