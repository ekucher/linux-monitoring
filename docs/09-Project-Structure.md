# 9. Структура проєкту

```text
collectors/     формують JSON у stdout
updaters/       атомарно записують cache
systemd/        services та timers
zabbix/         aliases і шаблони
docs/           документація
tests/          локальні перевірки
```

Колектор не повинен знати про Zabbix. Він лише повертає стабільний JSON.
