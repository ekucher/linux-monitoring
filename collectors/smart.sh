#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_command jq
require_command smartctl

hostname_value="$(hostname -s)"
generated_at="$(date --iso-8601=seconds)"

scan_json="$(smartctl --scan-open -j 2>/dev/null || true)"
if ! jq -e . >/dev/null 2>&1 <<<"${scan_json}"; then
    scan_json='{"devices":[]}'
fi

disks='[]'

while IFS=$'\t' read -r device dtype; do
    [[ -n "${device}" ]] || continue
    [[ -n "${dtype}" ]] || dtype="auto"

    raw="$(smartctl -a -j -d "${dtype}" "${device}" 2>/dev/null || true)"
    if ! jq -e . >/dev/null 2>&1 <<<"${raw}"; then
        continue
    fi

    disk="$(jq -c \
        --arg device "${device}" \
        --arg dtype "${dtype}" '
        def n(v): if v == null then 0 else v end;
        {
          device: $device,
          device_type: $dtype,
          model: (.model_name // .product // .scsi_model_name // "Unknown"),
          serial: (.serial_number // ""),
          firmware: (.firmware_version // ""),
          protocol: (.device.protocol // ""),
          smart_passed: (.smart_status.passed // false),
          smartctl_exit_status: (.smartctl.exit_status // 0),
          temperature_c: n(.temperature.current),
          power_on_hours: n(.power_on_time.hours),
          power_cycle_count: n(.power_cycle_count),
          wear_used_percent: n(.nvme_smart_health_information_log.percentage_used),
          media_errors: n(.nvme_smart_health_information_log.media_errors),
          unsafe_shutdowns: n(.nvme_smart_health_information_log.unsafe_shutdowns),
          critical_warning: n(.nvme_smart_health_information_log.critical_warning),
          ata_error_log_count: n(.ata_smart_error_log.summary.count),
          reallocated_sectors: n(
              [.ata_smart_attributes.table[]? |
               select((.id // 0) == 5) |
               (.raw.value // 0)] | first
          ),
          pending_sectors: n(
              [.ata_smart_attributes.table[]? |
               select((.id // 0) == 197) |
               (.raw.value // 0)] | first
          ),
          offline_uncorrectable: n(
              [.ata_smart_attributes.table[]? |
               select((.id // 0) == 198) |
               (.raw.value // 0)] | first
          )
        }' <<<"${raw}")"

    disks="$(jq -c --argjson disk "${disk}" '. + [$disk]' <<<"${disks}")"
done < <(
    jq -r '.devices[]? | [(.name // ""), (.type // "auto")] | @tsv' <<<"${scan_json}"
)

jq -n \
    --arg hostname "${hostname_value}" \
    --arg generated_at "${generated_at}" \
    --argjson disks "${disks}" '
    {
      schema_version: 1,
      collector: "smart",
      hostname: $hostname,
      generated_at: $generated_at,
      disk_count: ($disks | length),
      disks: $disks
    }'
