#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${ROOT}/install.sh"

bash -n "${INSTALLER}"

grep -Fq 'Підтримуються лише Debian 13 або Proxmox VE 8.' "${INSTALLER}"
grep -Fq 'Потрібен Zabbix Agent 2 версії 7.4.x.' "${INSTALLER}"
grep -Fq 'mktemp -d /tmp/linux-monitoring-install.XXXXXX' "${INSTALLER}"
grep -Fq 'systemd-analyze timespan' "${INSTALLER}"
grep -Fq 'Непідтримуваний модуль:' "${INSTALLER}"
grep -Fq 'module_selected smart && printf' "${INSTALLER}"
grep -Fq 'module_selected sensors && printf' "${INSTALLER}"
grep -Fq 'zabbix_agent2 -T -c /etc/zabbix/zabbix_agent2.conf' "${INSTALLER}"

if grep -Eq '/tmp/linux-monitoring-\$\{module\}\.timer\.\$\$' "${INSTALLER}"; then
    echo '[FAIL] Інсталятор використовує передбачуваний тимчасовий файл.' >&2
    exit 1
fi

printf '[PASS] Installer production safeguards\n'
