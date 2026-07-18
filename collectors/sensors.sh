#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_command jq
require_command sensors

hostname_value="$(hostname -s)"
generated_at="$(date --iso-8601=seconds)"

raw="$(sensors -j 2>/dev/null || true)"
if ! jq -e . >/dev/null 2>&1 <<<"${raw}"; then
    raw='{}'
fi

# lm-sensors JSON differs between drivers and hardware. Instead of relying on
# chip-specific names, flatten every numeric *_input value into a uniform list.
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
            name: (
              [
                ($p[0] | tostring),
                (($p[1] // "") | tostring),
                ($p[-1] | tostring)
              ] | join(":")
            ),
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
      ]' <<<"${raw}"
)"

jq -n \
    --arg hostname "${hostname_value}" \
    --arg generated_at "${generated_at}" \
    --argjson readings "${readings}" '
    {
      schema_version: 1,
      collector: "sensors",
      hostname: $hostname,
      generated_at: $generated_at,
      reading_count: ($readings | length),
      readings: $readings
    }'
