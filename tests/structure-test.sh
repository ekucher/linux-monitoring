#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
    VERSION
    README.md
    install.sh
    uninstall.sh
    collectors/smart.sh
    collectors/sensors.sh
    lib/cache.sh
    lib/config.sh
    lib/logging.sh
    config/linux-monitoring.conf
    systemd/linux-monitoring-smart.service
    systemd/linux-monitoring-smart.timer
    systemd/linux-monitoring-sensors.service
    systemd/linux-monitoring-sensors.timer
    zabbix/linux-monitoring.conf
    docs/03-Installation.md
    docs/09-SMART.md
    tests/core-test.sh
    tests/smart-test.sh
    tests/sensors-test.sh
    tests/installer-test.sh
)

for path in "${required[@]}"; do
    test -e "${ROOT}/${path}" || {
        echo "[FAIL] Відсутній файл: ${path}" >&2
        exit 1
    }
    echo "[PASS] ${path}"
done

mapfile -t template_files < <(find "${ROOT}/zabbix/templates" -maxdepth 1 -type f -name '*.yaml' -print 2>/dev/null | sort)
if ((${#template_files[@]} == 0)); then
    echo '[FAIL] У zabbix/templates відсутні YAML-шаблони.' >&2
    exit 1
fi

for path in "${template_files[@]}"; do
    echo "[PASS] ${path#${ROOT}/}"
done
