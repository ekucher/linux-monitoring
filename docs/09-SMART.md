# SMART collector

## Джерело даних

Колектор використовує JSON-вивід `smartctl`:

```bash
smartctl --scan-open -j
smartctl -a -j -d <type> <device>
```

Для тестування або інтеграції з wrapper-скриптом команду можна перевизначити:

```bash
SMARTCTL_BIN=/path/to/smartctl collectors/smart.sh
```

## Підтримувані класи пристроїв

Поле `device_class` нормалізує типи, які повертає `smartctl`:

- `ata` — ATA/SATA та SAT;
- `scsi` — SCSI/SAS, MegaRAID/PERC через SCSI-представлення;
- `nvme` — NVMe;
- `usb` — USB bridge;
- `unknown` — тип не вдалося класифікувати.

Конкретний параметр `-d`, отриманий під час discovery, зберігається у `device_type`.

## Схема JSON

```json
{
  "schema_version": 2,
  "collector": "smart",
  "hostname": "pve1",
  "generated_at": "2026-07-18T19:00:00+03:00",
  "duration_ms": 125,
  "status": "ok",
  "errors": [],
  "discovery": {
    "discovered_count": 2,
    "collected_count": 2,
    "failed_count": 0,
    "smartctl": {
      "exit_status": 0
    }
  },
  "disk_count": 2,
  "disks": []
}
```

Статуси колектора:

- `ok` — усі виявлені пристрої опитані;
- `degraded` — хоча б один пристрій не відкрився або повернув невалідні дані;
- `empty` — discovery не знайшов пристроїв.

Масив `disks` і раніше наявні назви метрик збережені для сумісності з поточним шаблоном Zabbix.

## Exit status smartctl

`smartctl` повертає бітову маску. Колектор не трактує будь-який ненульовий код як помилку запуску.

| Біт | Значення | Поле |
|---:|---|---|
| 0 | помилка командного рядка | `command_line_error` |
| 1 | пристрій не відкрився | `device_open_failed` |
| 2 | SMART-команда завершилася помилкою | `smart_command_failed` |
| 3 | загальний SMART health failure | `health_failed` |
| 4 | prefail-атрибут досяг порогу | `prefail_attribute_failed` |
| 5 | у журналі помилок є записи | `error_log_contains_records` |
| 6 | журнал self-test містить помилки | `self_test_log_contains_errors` |
| 7 | ATA error log містить помилки | `ata_error_log_contains_errors` |

Біти 3–7 описують стан накопичувача, але не означають, що колектор не зміг отримати JSON. Біти 0–2 вважаються операційною помилкою збору.

## Основні метрики

Спільні:

- модель, серійний номер, firmware;
- протокол, ємність, rotation rate, form factor;
- SMART available/enabled/passed;
- температура, години роботи, кількість увімкнень.

ATA:

- reallocated sectors;
- reported uncorrectable;
- command timeout;
- current pending sectors;
- offline uncorrectable;
- UDMA CRC errors;
- ATA error log count.

NVMe:

- percentage used;
- available spare та threshold;
- critical warning;
- media errors;
- unsafe shutdowns;
- data units read/written.
