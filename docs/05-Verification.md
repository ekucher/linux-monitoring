# 5. Перевірка

## Сервіси

```bash
systemctl is-enabled linux-monitoring-smart.timer
systemctl is-active linux-monitoring-smart.timer
systemctl is-enabled linux-monitoring-sensors.timer
systemctl is-active linux-monitoring-sensors.timer
```

Очікувано:

```text
enabled
active
enabled
active
```

## Ручний запуск

```bash
systemctl start linux-monitoring-smart.service
systemctl start linux-monitoring-sensors.service
```

`Type=oneshot`, тому після успішного виконання service може бути `inactive (dead)` — це нормально.

## Журнали

```bash
journalctl -u linux-monitoring-smart.service -n 50 --no-pager
journalctl -u linux-monitoring-sensors.service -n 50 --no-pager
```

## Стислий SMART результат

```bash
jq '{
  hostname,
  disk_count,
  disks: [.disks[] | {
    device,
    model,
    smart_passed,
    temperature_c,
    wear_used_percent,
    media_errors
  }]
}' /var/lib/linux-monitoring/smart.json
```

## Стислий Sensors результат

```bash
jq '{
  hostname,
  reading_count,
  readings
}' /var/lib/linux-monitoring/sensors.json
```
