#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# shellcheck source=../lib/config.sh
source "${ROOT}/lib/config.sh"
# shellcheck source=../lib/cache.sh
source "${ROOT}/lib/cache.sh"
# shellcheck source=../lib/logging.sh
source "${ROOT}/lib/logging.sh"

config_file="${TEMP_DIR}/linux-monitoring.conf"
cat >"${config_file}" <<EOF
LM_CACHE_DIR=${TEMP_DIR}/cache
LM_LOG_LEVEL=DEBUG
LM_TIMER_INTERVAL=10m
EOF

lm_load_config "${config_file}"

[[ "${LM_CACHE_DIR}" == "${TEMP_DIR}/cache" ]]
[[ "${LM_LOG_LEVEL}" == "DEBUG" ]]
[[ "${LM_TIMER_INTERVAL}" == "10m" ]]

mkdir -p "${LM_CACHE_DIR}"
printf '{"status":"ok"}\n' |
    lm_write_json_cache \
        "${LM_CACHE_DIR}/test.json" \
        "$(id -un)" \
        "$(id -gn)"

jq -e '.status == "ok"' "${LM_CACHE_DIR}/test.json" >/dev/null

if printf 'not-json\n' |
    lm_write_json_cache \
        "${LM_CACHE_DIR}/invalid.json" \
        "$(id -un)" \
        "$(id -gn)"; then
    echo '[FAIL] Invalid JSON was accepted.' >&2
    exit 1
fi

[[ ! -e "${LM_CACHE_DIR}/invalid.json" ]]
[[ "$(lm_log_level_number DEBUG)" == "10" ]]
[[ "$(lm_log_level_number ERROR)" == "40" ]]

printf '[PASS] Core configuration, cache and logging helpers\n'
