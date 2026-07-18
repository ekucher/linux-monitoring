# Changelog

## Unreleased

- Додано спільні runtime-бібліотеки для конфігурації, логування та атомарного запису JSON cache.
- Додано файл `/etc/linux-monitoring/linux-monitoring.conf` із параметрами cache, log level і timer interval.
- SMART та Sensors updater переведено на спільне ядро.
- Додано автоматичні тести core runtime.
- SMART collector переведено на schema version 2 зі службовими полями `status`, `duration_ms`, `errors` і `discovery`.
- Додано коректне декодування всіх бітів exit status `smartctl`.
- Додано нормалізацію класів ATA, SCSI/SAS, NVMe та USB-пристроїв.
- Розширено набір ATA та NVMe метрик без зміни масиву `disks` і чинних ключів.
- Додано детерміновані fixture-тести для ATA, NVMe, SMART health failure та помилки відкриття пристрою.

## 2.0.0 — 2026-07-18

- Повністю відтворено модульну структуру проєкту.
- Додано SMART collector.
- Додано Sensors collector на базі `lm-sensors`.
- Додано окремі systemd service/timer для кожного модуля.
- Додано Zabbix Agent 2 aliases.
- Додано покрокову інструкцію розгортання на новому сервері.
- Додано upgrade/uninstall сценарії.
- Додано базові тести синтаксису, структури та JSON.
