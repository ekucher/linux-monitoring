#!/usr/bin/env bash

lm_write_json_cache() {
    local destination="$1"
    local owner="${2:-root}"
    local group="${3:-root}"
    local mode="${4:-0644}"
    local directory
    local temporary

    directory="$(dirname -- "${destination}")"
    temporary="$(mktemp "${directory}/.$(basename -- "${destination}").tmp.XXXXXX")"

    trap 'rm -f "${temporary}"' RETURN

    cat >"${temporary}"
    jq -e . "${temporary}" >/dev/null
    install -o "${owner}" -g "${group}" -m "${mode}" "${temporary}" "${destination}"
}
