#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

SMARTCTL_BIN="${SMARTCTL_BIN:-smartctl}"

require_command jq
require_command "${SMARTCTL_BIN}"

hostname_value="$(hostname -s)"
generated_at="$(date --iso-8601=seconds)"
started_ns="$(date +%s%N)"

run_smartctl() {
    local output_file="$1"
    shift

    set +e
    "${SMARTCTL_BIN}" "$@" >"${output_file}" 2>/dev/null
    local rc=$?
    set -e

    return "${rc}"
}

smartctl_status_json() {
    local status="$1"

    jq -cn --argjson status "${status}" '
      {
        exit_status: $status,
        command_line_error: (($status & 1) != 0),
        device_open_failed: (($status & 2) != 0),
        smart_command_failed: (($status & 4) != 0),
        health_failed: (($status & 8) != 0),
        prefail_attribute_failed: (($status & 16) != 0),
        error_log_contains_records: (($status & 32) != 0),
        self_test_log_contains_errors: (($status & 64) != 0),
        ata_error_log_contains_errors: (($status & 128) != 0)
      }'
}

normalize_device_class() {
    local dtype="$1"
    local protocol="$2"

    case "${dtype,,}:${protocol,,}" in
        nvme*:* | *:nvme*) printf 'nvme\n' ;;
        scsi*:* | sat+megaraid*:* | megaraid*:* | *:scsi*) printf 'scsi\n' ;;
        sat*:* | ata*:* | *:ata*) printf 'ata\n' ;;
        usb*:* | *:usb*) printf 'usb\n' ;;
        *) printf 'unknown\n' ;;
    esac
}

scan_file="$(mktemp)"
trap 'rm -f "${scan_file}" "${device_file:-}"' EXIT

scan_rc=0
if ! run_smartctl "${scan_file}" --scan-open -j; then
    scan_rc=$?
fi

scan_json="$(cat "${scan_file}")"
if ! jq -e '.devices | type == "array"' >/dev/null 2>&1 <<<"${scan_json}"; then
    scan_json='{"devices":[]}'
fi

scan_status="$(smartctl_status_json "${scan_rc}")"
disks='[]'
errors='[]'
discovered_count="$(jq '.devices | length' <<<"${scan_json}")"
collected_count=0
failed_count=0

if ((scan_rc & 7)); then
    errors="$(
        jq -c \
            --arg message "smartctl device discovery returned status ${scan_rc}" \
            --argjson status "${scan_status}" \
            '. + [{scope: "discovery", message: $message, smartctl: $status}]' <<<"${errors}"
    )"
fi

while IFS=$'\t' read -r device dtype; do
    [[ -n "${device}" ]] || continue
    [[ -n "${dtype}" ]] || dtype="auto"

    device_file="$(mktemp)"
    device_rc=0
    if ! run_smartctl "${device_file}" -a -j -d "${dtype}" "${device}"; then
        device_rc=$?
    fi

    raw="$(cat "${device_file}")"
    rm -f "${device_file}"
    device_file=""

    if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"${raw}"; then
        ((failed_count += 1))
        errors="$(
            jq -c \
                --arg device "${device}" \
                --arg dtype "${dtype}" \
                --arg message "smartctl did not return valid JSON" \
                --argjson exit_status "${device_rc}" \
                '. + [{scope: "device", device: $device, device_type: $dtype, message: $message, smartctl_exit_status: $exit_status}]' <<<"${errors}"
        )"
        continue
    fi

    protocol="$(jq -r '.device.protocol // ""' <<<"${raw}")"
    device_class="$(normalize_device_class "${dtype}" "${protocol}")"
    status_json="$(smartctl_status_json "${device_rc}")"

    disk="$(
        jq -c \
            --arg device "${device}" \
            --arg dtype "${dtype}" \
            --arg device_class "${device_class}" \
            --argjson command_status "${status_json}" '
          def n(v): if v == null then 0 else v end;
          def attr(id):
            ([.ata_smart_attributes.table[]? | select((.id // 0) == id) | (.raw.value // 0)] | first) // 0;
          {
            device: $device,
            device_type: $dtype,
            device_class: $device_class,
            model: (.model_name // .product // .scsi_model_name // "Unknown"),
            family: (.model_family // ""),
            serial: (.serial_number // ""),
            firmware: (.firmware_version // ""),
            protocol: (.device.protocol // ""),
            capacity_bytes: n(.user_capacity.bytes),
            rotation_rate: n(.rotation_rate),
            form_factor: (.form_factor.name // ""),
            smart_available: (.smart_support.available // true),
            smart_enabled: (.smart_support.enabled // true),
            smart_passed: (.smart_status.passed // (if $command_status.health_failed then false else null end)),
            smartctl: $command_status,
            smartctl_exit_status: $command_status.exit_status,
            temperature_c: n(.temperature.current),
            power_on_hours: n(.power_on_time.hours),
            power_cycle_count: n(.power_cycle_count),
            wear_used_percent: n(.nvme_smart_health_information_log.percentage_used),
            available_spare_percent: n(.nvme_smart_health_information_log.available_spare),
            available_spare_threshold_percent: n(.nvme_smart_health_information_log.available_spare_threshold),
            media_errors: n(.nvme_smart_health_information_log.media_errors),
            unsafe_shutdowns: n(.nvme_smart_health_information_log.unsafe_shutdowns),
            critical_warning: n(.nvme_smart_health_information_log.critical_warning),
            data_units_read: n(.nvme_smart_health_information_log.data_units_read),
            data_units_written: n(.nvme_smart_health_information_log.data_units_written),
            ata_error_log_count: n(.ata_smart_error_log.summary.count),
            reallocated_sectors: attr(5),
            reported_uncorrectable_errors: attr(187),
            command_timeout: attr(188),
            current_pending_sectors: attr(197),
            pending_sectors: attr(197),
            offline_uncorrectable: attr(198),
            udma_crc_errors: attr(199)
          }' <<<"${raw}"
    )"

    disks="$(jq -c --argjson disk "${disk}" '. + [$disk]' <<<"${disks}")"
    ((collected_count += 1))

    if ((device_rc & 7)); then
        ((failed_count += 1))
        errors="$(
            jq -c \
                --arg device "${device}" \
                --arg dtype "${dtype}" \
                --arg message "smartctl collection returned status ${device_rc}" \
                --argjson status "${status_json}" \
                '. + [{scope: "device", device: $device, device_type: $dtype, message: $message, smartctl: $status}]' <<<"${errors}"
        )"
    fi
done < <(
    jq -r '.devices[]? | [(.name // ""), (.type // "auto")] | @tsv' <<<"${scan_json}"
)

finished_ns="$(date +%s%N)"
duration_ms=$(((finished_ns - started_ns) / 1000000))
status="ok"
if ((failed_count > 0)); then
    status="degraded"
elif ((discovered_count == 0)); then
    status="empty"
fi

jq -n \
    --arg hostname "${hostname_value}" \
    --arg generated_at "${generated_at}" \
    --arg status "${status}" \
    --argjson duration_ms "${duration_ms}" \
    --argjson discovered_count "${discovered_count}" \
    --argjson collected_count "${collected_count}" \
    --argjson failed_count "${failed_count}" \
    --argjson scan_status "${scan_status}" \
    --argjson errors "${errors}" \
    --argjson disks "${disks}" '
    {
      schema_version: 2,
      collector: "smart",
      hostname: $hostname,
      generated_at: $generated_at,
      duration_ms: $duration_ms,
      status: $status,
      errors: $errors,
      discovery: {
        discovered_count: $discovered_count,
        collected_count: $collected_count,
        failed_count: $failed_count,
        smartctl: $scan_status
      },
      disk_count: ($disks | length),
      disks: $disks
    }'