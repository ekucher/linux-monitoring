#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TIMER_INTERVAL="5m"
MODULES="smart,sensors"
SKIP_PACKAGES=0
SKIP_AGENT_RESTART=0
RUN_SENSORS_DETECT=0
DRY_RUN=0
DEBUG=0
TEMP_DIR=""

log() { printf '[INFO] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }
run() {
    if ((DRY_RUN)); then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}
cleanup() {
    [[ -n "${TEMP_DIR}" ]] && rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

usage() {
    cat <<'EOF'
Використання: sudo ./install.sh [параметри]

Параметри:
  --timer-interval VALUE
  --modules LIST
  --skip-packages
  --skip-agent-restart
  --run-sensors-detect
  --dry-run
  --debug
  -h, --help
EOF
}

while (($#)); do
    case "$1" in
        --timer-interval)
            TIMER_INTERVAL="${2:?не вказано значення}"
            shift 2
            ;;
        --modules)
            MODULES="${2:?не вказано значення}"
            shift 2
            ;;
        --skip-packages)
            SKIP_PACKAGES=1
            shift
            ;;
        --skip-agent-restart)
            SKIP_AGENT_RESTART=1
            shift
            ;;
        --run-sensors-detect)
            RUN_SENSORS_DETECT=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            error "Невідомий параметр: $1"
            usage
            exit 2
            ;;
    esac
done

((DEBUG)) && set -x

if ((EUID != 0)); then
    error "Запустіть інсталятор від root."
    exit 1
fi

validate_platform() {
    local supported=0

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == "13" ]]; then
            supported=1
        fi
    fi

    if command -v pveversion >/dev/null 2>&1 && pveversion | grep -Eq '^pve-manager/8\.'; then
        supported=1
    fi

    if ((supported == 0)); then
        error "Підтримуються лише Debian 13 або Proxmox VE 8."
        exit 1
    fi

    if ! command -v zabbix_agent2 >/dev/null 2>&1; then
        error "Не знайдено zabbix_agent2. Спочатку встановіть Zabbix Agent 2 7.4."
        exit 1
    fi

    if ! zabbix_agent2 -V 2>&1 | head -n 1 | grep -Eq ' 7\.4\.'; then
        error "Потрібен Zabbix Agent 2 версії 7.4.x."
        exit 1
    fi
}

parse_modules() {
    local value
    local module
    local -A seen=()
    SELECTED_MODULES=()

    IFS=',' read -r -a values <<<"${MODULES}"
    ((${#values[@]} > 0)) || {
        error "Не вибрано жодного модуля."
        exit 2
    }

    for value in "${values[@]}"; do
        module="${value//[[:space:]]/}"
        case "${module}" in
            smart | sensors) ;;
            *)
                error "Непідтримуваний модуль: ${module:-<порожньо>}"
                exit 2
                ;;
        esac
        if [[ -z "${seen[${module}]:-}" ]]; then
            SELECTED_MODULES+=("${module}")
            seen["${module}"]=1
        fi
    done
}

module_selected() {
    local expected="$1"
    local module
    for module in "${SELECTED_MODULES[@]}"; do
        [[ "${module}" == "${expected}" ]] && return 0
    done
    return 1
}

validate_timer_interval() {
    if ! systemd-analyze timespan "${TIMER_INTERVAL}" >/dev/null 2>&1; then
        error "Некоректний інтервал systemd timer: ${TIMER_INTERVAL}"
        exit 2
    fi
}

validate_platform
parse_modules
validate_timer_interval
TEMP_DIR="$(mktemp -d /tmp/linux-monitoring-install.XXXXXX)"

if ((!SKIP_PACKAGES)); then
    packages=(jq)
    module_selected smart && packages+=(smartmontools)
    module_selected sensors && packages+=(lm-sensors)
    log "Встановлення пакетів: ${packages[*]}"
    run apt-get update
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
fi

run install -d -o root -g root -m 0755 \
    /usr/local/lib/linux-monitoring/collectors \
    /usr/local/lib/linux-monitoring/lib \
    /var/lib/linux-monitoring \
    /etc/linux-monitoring \
    /etc/zabbix/zabbix_agent2.d

run install -o root -g root -m 0755 \
    "${PROJECT_DIR}/collectors/common.sh" \
    /usr/local/lib/linux-monitoring/collectors/common.sh

for library in "${PROJECT_DIR}"/lib/*.sh; do
    run install -o root -g root -m 0644 \
        "${library}" \
        "/usr/local/lib/linux-monitoring/lib/$(basename -- "${library}")"
done

if [[ ! -e /etc/linux-monitoring/linux-monitoring.conf ]]; then
    run install -o root -g root -m 0644 \
        "${PROJECT_DIR}/config/linux-monitoring.conf" \
        /etc/linux-monitoring/linux-monitoring.conf
else
    log "Збережено чинний /etc/linux-monitoring/linux-monitoring.conf"
fi

install_module() {
    local module="$1"
    local timer_file="${TEMP_DIR}/linux-monitoring-${module}.timer"
    log "Встановлення модуля: ${module}"

    run install -o root -g root -m 0755 \
        "${PROJECT_DIR}/collectors/${module}.sh" \
        "/usr/local/lib/linux-monitoring/collectors/${module}.sh"
    run install -o root -g root -m 0755 \
        "${PROJECT_DIR}/updaters/update-${module}-cache.sh" \
        "/usr/local/sbin/update-linux-monitoring-${module}-cache.sh"
    run install -o root -g root -m 0644 \
        "${PROJECT_DIR}/systemd/linux-monitoring-${module}.service" \
        "/etc/systemd/system/linux-monitoring-${module}.service"

    sed "s/^OnUnitActiveSec=.*/OnUnitActiveSec=${TIMER_INTERVAL}/" \
        "${PROJECT_DIR}/systemd/linux-monitoring-${module}.timer" >"${timer_file}"
    run install -o root -g root -m 0644 \
        "${timer_file}" \
        "/etc/systemd/system/linux-monitoring-${module}.timer"
}

remove_unselected_module() {
    local module="$1"
    module_selected "${module}" && return 0

    run systemctl disable --now "linux-monitoring-${module}.timer" 2>/dev/null || true
    run rm -f \
        "/etc/systemd/system/linux-monitoring-${module}.service" \
        "/etc/systemd/system/linux-monitoring-${module}.timer" \
        "/usr/local/sbin/update-linux-monitoring-${module}-cache.sh" \
        "/usr/local/lib/linux-monitoring/collectors/${module}.sh"
}

for module in "${SELECTED_MODULES[@]}"; do
    install_module "${module}"
done
for module in smart sensors; do
    remove_unselected_module "${module}"
done

alias_file="${TEMP_DIR}/linux-monitoring.conf"
printf '# linux-monitoring aliases\n' >"${alias_file}"
module_selected smart && printf 'Alias=smart.cache.json:vfs.file.contents[/var/lib/linux-monitoring/smart.json]\n' >>"${alias_file}"
module_selected sensors && printf 'Alias=sensors.cache.json:vfs.file.contents[/var/lib/linux-monitoring/sensors.json]\n' >>"${alias_file}"
run install -o root -g root -m 0644 "${alias_file}" /etc/zabbix/zabbix_agent2.d/linux-monitoring.conf

if ((RUN_SENSORS_DETECT)) && module_selected sensors; then
    if command -v sensors-detect >/dev/null 2>&1; then
        log "Запуск sensors-detect --auto"
        run sensors-detect --auto
    else
        error "Не знайдено sensors-detect."
        exit 1
    fi
fi

run systemctl daemon-reload
for module in "${SELECTED_MODULES[@]}"; do
    run systemctl enable --now "linux-monitoring-${module}.timer"
    run systemctl start "linux-monitoring-${module}.service"
done

if ((!SKIP_AGENT_RESTART)); then
    run zabbix_agent2 -T -c /etc/zabbix/zabbix_agent2.conf
    run systemctl restart zabbix-agent2
fi

if ((!DRY_RUN)); then
    for module in "${SELECTED_MODULES[@]}"; do
        jq -e . "/var/lib/linux-monitoring/${module}.json" >/dev/null
        log "${module}.json є валідним JSON."
    done
fi

log "Встановлення завершено."
