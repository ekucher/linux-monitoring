# 4. Налаштування Zabbix

Agent aliases:

```ini
Alias=smart.cache.json:vfs.file.contents[/var/lib/linux-monitoring/smart.json]
Alias=sensors.cache.json:vfs.file.contents[/var/lib/linux-monitoring/sensors.json]
```

Файл:

```text
/etc/zabbix/zabbix_agent2.d/linux-monitoring.conf
```

Рекомендована схема:

- один master item на JSON;
- LLD — dependent;
- item prototypes — dependent;
- не запускати `smartctl` або `sensors` окремим item для кожного показника.

## Безпека

У `Server=` вкажіть лише IP Zabbix Server/Proxy і, за потреби, `127.0.0.1` для локальної діагностики.
