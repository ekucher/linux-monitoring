# 8. Діагностика

## `zabbix_get`: connection reset by peer

Перевірте:

```bash
grep -E '^(Server|ListenIP|ListenPort)=' /etc/zabbix/zabbix_agent2.conf
```

IP Zabbix Server має входити до `Server=`.

## SMART JSON має `disk_count: 0`

```bash
smartctl --scan-open
smartctl --scan-open -j | jq .
```

Для RAID/HBA може бути потрібний спеціальний `-d`, наприклад `sat`, `scsi`, `megaraid,N`.

## Sensors JSON має `reading_count: 0`

```bash
sensors
sensors -j | jq .
lsmod | grep -E 'coretemp|k10temp|nct|it87'
```

За потреби:

```bash
sensors-detect --auto
```

Не всі VM або серверні плати надають hardware sensors гостьовій ОС.

## Service failed

```bash
systemctl status linux-monitoring-smart.service --no-pager
journalctl -u linux-monitoring-smart.service -n 100 --no-pager
```

Аналогічно для `sensors`.

## Unsupported item

```bash
zabbix_agent2 -t smart.cache.json
zabbix_agent2 -t sensors.cache.json
```

Також перевірте валідність JSON:

```bash
jq -e . /var/lib/linux-monitoring/smart.json
jq -e . /var/lib/linux-monitoring/sensors.json
```
