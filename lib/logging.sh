#!/usr/bin/env bash

lm_log_level_number() {
    case "${1^^}" in
        DEBUG) printf '10\n' ;;
        INFO) printf '20\n' ;;
        WARNING) printf '30\n' ;;
        ERROR) printf '40\n' ;;
        *) printf '20\n' ;;
    esac
}

lm_log() {
    local level="${1^^}"
    shift

    local configured_level="${LM_LOG_LEVEL:-INFO}"
    local message_level_number
    local configured_level_number

    message_level_number="$(lm_log_level_number "${level}")"
    configured_level_number="$(lm_log_level_number "${configured_level}")"

    if ((message_level_number < configured_level_number)); then
        return 0
    fi

    printf '[%s] %s\n' "${level}" "$*" >&2
}

lm_debug() { lm_log DEBUG "$@"; }
lm_info() { lm_log INFO "$@"; }
lm_warning() { lm_log WARNING "$@"; }
lm_error() { lm_log ERROR "$@"; }
