#!/usr/bin/env bash
set -Eeuo pipefail

log() {
    printf '[INFO] %s\n' "$*" >&2
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        error "Required command not found: $1"
        return 1
    }
}

write_json_atomic() {
    local destination="$1"
    local temporary="${destination}.tmp.$$"

    cat >"${temporary}"
    jq -e . "${temporary}" >/dev/null
    install -o root -g root -m 0644 "${temporary}" "${destination}"
    rm -f "${temporary}"
}
