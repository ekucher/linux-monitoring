# 1. Вступ

`linux-monitoring` — модульний набір локальних колекторів для Zabbix Agent 2.

## Потік даних

```text
smartctl / sensors
        |
        v
collector.sh
        |
        v
/var/lib/linux-monitoring/*.json
        |
        v
Zabbix Agent 2 Alias
        |
        v
Master item
        |
        v
LLD та dependent items
```

Колектори запускаються systemd timers, тому Zabbix не виконує важкі команди під час кожного опитування.
