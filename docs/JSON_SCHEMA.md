# JSON schema

## SMART

Кореневі поля:

- `schema_version`
- `collector`
- `hostname`
- `generated_at`
- `disk_count`
- `disks[]`

## Sensors

Кореневі поля:

- `schema_version`
- `collector`
- `hostname`
- `generated_at`
- `reading_count`
- `readings[]`

Кожен sensor reading:

```json
{
  "chip": "coretemp-isa-0000",
  "feature": "Package id 0",
  "sensor_key": "temp1_input",
  "name": "coretemp-isa-0000:Package id 0:temp1_input",
  "value": 47.0,
  "metric": "temperature",
  "unit": "C"
}
```

Назви не нормалізуються жорстко, тому шаблон має використовувати LLD на основі `name`, `metric` та `unit`.
