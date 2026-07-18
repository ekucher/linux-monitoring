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

log() { printf '[INFO] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }
run() {
    if (( DRY_RUN )); then
        printf '[DRY-RUN]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

usage() {
    cat <<'EOF'
Usage: sudo ./install.sh [options]

Options:
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
        --timer-interval) TIMER_INTERVAL="${2:?missing value}"; shift 2 ;;
        --modules) MODULES="${2:?missing value}"; shift 2 ;;
        --skip-packages) SKIP_PACKAGES=1; shift ;;
        --skip-agent-restart) SKIP_AGENT_RESTART=1; shift ;;
        --run-sensors-detect) RUN_SENSORS_DETECT=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --debug) DEBUG=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $1"; usage; exit 2 ;;
    esac
done

(( DEBUG )) && set -x

if (( EUID != 0 )); then
    error "Run as root."
    exit 1
fi

case ",${MODULES}," in
    *,smart,*|*,sensors,*) ;;
    *) error "No supported modules selected."; exit 2 ;;
esac

if (( ! SKIP_PACKAGES )); then
    packages=(jq)
    [[ ",${MODULES}," == *,smart,* ]] && packages+=(smartmontools)
    [[ ",${MODULES}," == *,sensors,* ]] && packages+=(lm-sensors)
    log "Installing packages: ${packages[*]}"
    run apt-get update
    run env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
fi

run install -d -o root -g root -m 0755 \
    /usr/local/lib/linux-monitoring/collectors \
    /var/lib/linux-monitoring \
    /etc/zabbix/zabbix_agent2.d

run install -o root -g root -m 0755 \
    "${PROJECT_DIR}/collectors/common.sh" \
    /usr/local/lib/linux-monitoring/collectors/common.sh

install_module() {
    local module="$1"
    log "Installing module: ${module}"

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
        "${PROJECT_DIR}/systemd/linux-monitoring-${module}.timer" \
        >"/tmp/linux-monitoring-${module}.timer.$$"
    run install -o root -g root -m 0644 \
        "/tmp/linux-monitoring-${module}.timer.$$" \
        "/etc/systemd/system/linux-monitoring-${module}.timer"
    rm -f "/tmp/linux-monitoring-${module}.timer.$$"
}

[[ ",${MODULES}," == *,smart,* ]] && install_module smart
[[ ",${MODULES}," == *,sensors,* ]] && install_module sensors

run install -o root -g root -m 0644 \
    "${PROJECT_DIR}/zabbix/linux-monitoring.conf" \
    /etc/zabbix/zabbix_agent2.d/linux-monitoring.conf

if (( RUN_SENSORS_DETECT )) && [[ ",${MODULES}," == *,sensors,* ]]; then
    if command -v sensors-detect >/dev/null 2>&1; then
        log "Running sensors-detect --auto"
        run sensors-detect --auto
    fi
fi

run systemctl daemon-reload

for module in smart sensors; do
    if [[ ",${MODULES}," == *,"${module}",* ]]; then
        run systemctl enable --now "linux-monitoring-${module}.timer"
        run systemctl start "linux-monitoring-${module}.service"
    fi
done

if (( ! SKIP_AGENT_RESTART )); then
    if systemctl list-unit-files zabbix-agent2.service >/dev/null 2>&1; then
        run systemctl restart zabbix-agent2
    else
        log "zabbix-agent2.service not found; alias installed but agent was not restarted."
    fi
fi

if (( ! DRY_RUN )); then
    for module in smart sensors; do
        if [[ ",${MODULES}," == *,"${module}",* ]]; then
            jq -e . "/var/lib/linux-monitoring/${module}.json" >/dev/null
            log "${module}.json is valid."
        fi
    done
fi

log "Installation completed."
