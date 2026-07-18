#!/usr/bin/env bash
set -Eeuo pipefail

LIB_DIR="/usr/local/lib/linux-monitoring/lib"
COLLECTOR="/usr/local/lib/linux-monitoring/collectors/smart.sh"

# shellcheck source=/usr/local/lib/linux-monitoring/lib/config.sh
source "${LIB_DIR}/config.sh"
# shellcheck source=/usr/local/lib/linux-monitoring/lib/cache.sh
source "${LIB_DIR}/cache.sh"
# shellcheck source=/usr/local/lib/linux-monitoring/lib/logging.sh
source "${LIB_DIR}/logging.sh"

lm_load_config
CACHE="${LM_CACHE_DIR}/smart.json"

lm_debug "Updating SMART cache: ${CACHE}"
"${COLLECTOR}" | lm_write_json_cache "${CACHE}"
lm_info "SMART cache updated: ${CACHE}"
