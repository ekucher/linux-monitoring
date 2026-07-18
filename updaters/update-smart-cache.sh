#!/usr/bin/env bash
set -Eeuo pipefail

COLLECTOR="/usr/local/lib/linux-monitoring/collectors/smart.sh"
CACHE="/var/lib/linux-monitoring/smart.json"
TEMP="${CACHE}.tmp.$$"

trap 'rm -f "${TEMP}"' EXIT
"${COLLECTOR}" >"${TEMP}"
jq -e . "${TEMP}" >/dev/null
install -o root -g root -m 0644 "${TEMP}" "${CACHE}"
