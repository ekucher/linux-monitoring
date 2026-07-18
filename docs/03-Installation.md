# 3. Покрокове розгортання на новому сервері

Нижче наведений повний сценарій для Debian 13 або Proxmox VE.

## Крок 1. Увійти під root

```bash
sudo -i
```

## Крок 2. Перевірити ім'я та IP сервера

```bash
hostname -s
hostname -I
```

Ім'я повинно збігатися з полем **Host name** у Zabbix, якщо агент використовує active checks.

## Крок 3. Оновити індекс пакетів

```bash
apt update
```

## Крок 4. Встановити Zabbix Agent 2

Коли репозиторій Zabbix уже підключено:

```bash
apt install -y zabbix-agent2 zabbix-get
systemctl enable --now zabbix-agent2
```

Перевірка:

```bash
systemctl is-active zabbix-agent2
```

Очікувано:

```text
active
```

## Крок 5. Налаштувати сервер Zabbix

Відкрийте:

```bash
nano /etc/zabbix/zabbix_agent2.conf
```

Мінімальний приклад:

```ini
Server=10.10.200.51,127.0.0.1
ServerActive=10.10.200.51
Hostname=pve4
```

Після зміни:

```bash
zabbix_agent2 -t agent.ping
systemctl restart zabbix-agent2
```

## Крок 6. Розпакувати проєкт

ZIP:

```bash
unzip linux-monitoring-v2.0.0.zip
cd linux-monitoring-v2.0.0
```

TAR.GZ:

```bash
tar -xzf linux-monitoring-v2.0.0.tar.gz
cd linux-monitoring-v2.0.0
```

## Крок 7. Перевірити контрольну суму

Коли файл `linux-monitoring-v2.0.0.SHA256SUMS` лежить поруч:

```bash
sha256sum -c linux-monitoring-v2.0.0.SHA256SUMS
```

## Крок 8. Запустити інсталятор

```bash
chmod +x install.sh
./install.sh
```

Інсталятор:

1. встановить `jq`, `smartmontools`, `lm-sensors`;
2. скопіює колектори;
3. створить Zabbix aliases;
4. встановить systemd services/timers;
5. одразу створить JSON caches;
6. перезапустить Zabbix Agent 2.

## Крок 9. Опціонально виконати sensors-detect

На звичайному сервері:

```bash
sensors-detect --auto
systemctl restart systemd-modules-load.service 2>/dev/null || true
sensors
```

Або під час встановлення:

```bash
./install.sh --run-sensors-detect
```

На Proxmox перед завантаженням додаткових модулів ядра перегляньте результат `sensors-detect`.

## Крок 10. Перевірити таймери

```bash
systemctl status linux-monitoring-smart.timer --no-pager
systemctl status linux-monitoring-sensors.timer --no-pager
systemctl list-timers 'linux-monitoring-*'
```

## Крок 11. Перевірити JSON

```bash
jq . /var/lib/linux-monitoring/smart.json
jq . /var/lib/linux-monitoring/sensors.json
```

## Крок 12. Перевірити ключі агента

```bash
zabbix_agent2 -t smart.cache.json
zabbix_agent2 -t sensors.cache.json
```

Очікуваний тип:

```text
[t|{...}]
```

## Крок 13. Перевірити з Zabbix Server

```bash
zabbix_get -s SERVER_IP -k smart.cache.json | jq .
zabbix_get -s SERVER_IP -k sensors.cache.json | jq .
```

Замініть `SERVER_IP` на IP нового сервера, де встановлено agent.

## Крок 14. Імпортувати шаблони

У веб-інтерфейсі Zabbix:

```text
Data collection -> Templates -> Import
```

Імпортуйте YAML із:

```text
zabbix/templates/
```

Потім прив'яжіть шаблони до хоста.

## Крок 15. Дочекатися LLD

Після першого отримання master item Zabbix створить dependent items. За потреби натисніть **Execute now** для master item та discovery rule.
