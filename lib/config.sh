#!/usr/bin/env bash

lm_load_config() {
    local config_file="${1:-/etc/linux-monitoring/linux-monitoring.conf}"

    LM_CACHE_DIR="${LM_CACHE_DIR:-/var/lib/linux-monitoring}"
    LM_LOG_LEVEL="${LM_LOG_LEVEL:-INFO}"
    LM_TIMER_INTERVAL="${LM_TIMER_INTERVAL:-5m}"

    if [[ -r "${config_file}" ]]; then
        # shellcheck disable=SC1090
        source "${config_file}"
    fi

    export LM_CACHE_DIR LM_LOG_LEVEL LM_TIMER_INTERVAL
}
