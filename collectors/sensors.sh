#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

SENSORS_BIN="${SENSORS_BIN:-sensors}"

require_command jq
require_command "${SENSORS_BIN}"

hostname_value="$(hostname -s)"
generated_at="$(date --iso-8601=seconds)"
started_ns="$(date +%s%N)"
output_file="$(mktemp)"
error_file="$(mktemp)"
trap 'rm -f "${output_file}" "${error_file}"' EXIT

set +e
"${SENSORS_BIN}" -j >"${output_file}" 2>"${error_file}"
sensors_rc=$?
set -e

raw="$(cat "${output_file}")"
errors='[]'
status="ok"

if ((sensors_rc != 0)); then
    status="error"
    errors="$(
        jq -cn \
            --arg message "sensors -j returned status ${sensors_rc}" \
            --argjson exit_status "${sensors_rc}" \
            '[{scope: "collector", message: $message, exit_status: $exit_status}]'
    )"
    raw='{}'
elif ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"${raw}"; then
    status="error"
    errors='[{"scope":"collector","message":"sensors -j did not return a JSON object"}]'
    raw='{}'
fi

readings="$(
    jq -c '
      [
        paths(numbers) as $p
        | select(($p[-1] | type) == "string")
        | select(($p[-1] | endswith("_input")))
        | {
            chip: ($p[0] | tostring),
            feature: (($p[1] // "") | tostring),
            sensor_key: ($p[-1] | tostring),
            name: ([($p[0] | tostring), (($p[1] // "") | tostring), ($p[-1] | tostring)] | join(":")),
            value: getpath($p),
            metric: (
              if ($p[-1] | startswith("temp")) then "temperature"
              elif ($p[-1] | startswith("fan")) then "fan"
              elif ($p[-1] | startswith("in")) then "voltage"
              elif ($p[-1] | startswith("power")) then "power"
              elif ($p[-1] | startswith("curr")) then "current"
              elif ($p[-1] | startswith("humidity")) then "humidity"
              else "other"
              end
            ),
            unit: (
              if ($p[-1] | startswith("temp")) then "C"
              elif ($p[-1] | startswith("fan")) then "rpm"
              elif ($p[-1] | startswith("in")) then "V"
              elif ($p[-1] | startswith("power")) then "W"
              elif ($p[-1] | startswith("curr")) then "A"
              elif ($p[-1] | startswith("humidity")) then "%"
              else ""
              end
            )
          }
      ] | sort_by(.name)' <<<"${raw}"
)"

reading_count="$(jq 'length' <<<"${readings}")"
if [[ "${status}" == "ok" ]] && ((reading_count == 0)); then
    status="empty"
fi

finished_ns="$(date +%s%N)"
duration_ms=$(((finished_ns - started_ns) / 1000000))

jq -n \
    --arg hostname "${hostname_value}" \
    --arg generated_at "${generated_at}" \
    --arg status "${status}" \
    --argjson duration_ms "${duration_ms}" \
    --argjson exit_status "${sensors_rc}" \
    --argjson errors "${errors}" \
    --argjson readings "${readings}" '
    {
      schema_version: 2,
      collector: "sensors",
      hostname: $hostname,
      generated_at: $generated_at,
      duration_ms: $duration_ms,
      status: $status,
      errors: $errors,
      command: {
        exit_status: $exit_status
      },
      reading_count: ($readings | length),
      readings: $readings
    }'
