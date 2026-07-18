#!/usr/bin/env bash
set -Eeuo pipefail

KEEP_CACHE=0

while (($#)); do
    case "$1" in
        --keep-cache) KEEP_CACHE=1; shift ;;
        -h|--help)
            echo "Usage: sudo ./uninstall.sh [--keep-cache]"
            exit 0
            ;;
        *) echo "[ERROR] Unknown option: $1" >&2; exit 2 ;;
    esac
done

if (( EUID != 0 )); then
    echo "[ERROR] Run as root." >&2
    exit 1
fi

for module in smart sensors; do
    systemctl disable --now "linux-monitoring-${module}.timer" 2>/dev/null || true
    systemctl stop "linux-monitoring-${module}.service" 2>/dev/null || true
    rm -f \
        "/etc/systemd/system/linux-monitoring-${module}.service" \
        "/etc/systemd/system/linux-monitoring-${module}.timer" \
        "/usr/local/sbin/update-linux-monitoring-${module}-cache.sh" \
        "/usr/local/lib/linux-monitoring/collectors/${module}.sh"
done

rm -f \
    /usr/local/lib/linux-monitoring/collectors/common.sh \
    /etc/zabbix/zabbix_agent2.d/linux-monitoring.conf

rmdir /usr/local/lib/linux-monitoring/collectors 2>/dev/null || true
rmdir /usr/local/lib/linux-monitoring 2>/dev/null || true

if (( ! KEEP_CACHE )); then
    rm -rf /var/lib/linux-monitoring
fi

systemctl daemon-reload
systemctl restart zabbix-agent2 2>/dev/null || true

echo "[INFO] linux-monitoring removed."
