# Changelog

## Unreleased

- Додано спільні runtime-бібліотеки для конфігурації, логування та атомарного запису JSON cache.
- Додано файл `/etc/linux-monitoring/linux-monitoring.conf` із параметрами cache, log level і timer interval.
- SMART та Sensors updater переведено на спільне ядро.
- Додано автоматичні тести core runtime.

## 2.0.0 — 2026-07-18

- Повністю відтворено модульну структуру проєкту.
- Додано SMART collector.
- Додано Sensors collector на базі `lm-sensors`.
- Додано окремі systemd service/timer для кожного модуля.
- Додано Zabbix Agent 2 aliases.
- Додано покрокову інструкцію розгортання на новому сервері.
- Додано upgrade/uninstall сценарії.
- Додано базові тести синтаксису, структури та JSON.
