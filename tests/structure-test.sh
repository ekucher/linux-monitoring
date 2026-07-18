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
    systemd/linux-monitoring-smart.service
    systemd/linux-monitoring-sensors.service
    zabbix/linux-monitoring.conf
    docs/03-Installation.md
)

for path in "${required[@]}"; do
    test -e "${ROOT}/${path}" || {
        echo "[FAIL] Missing: ${path}" >&2
        exit 1
    }
    echo "[PASS] ${path}"
done
