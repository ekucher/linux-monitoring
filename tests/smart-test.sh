#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

cat >"${TEMP_DIR}/smartctl" <<'SMARTCTL'
#!/usr/bin/env bash
set -u

if [[ " $* " == *" --scan-open "* ]]; then
    cat <<'JSON'
{
  "devices": [
    {"name": "/dev/sda", "type": "sat"},
    {"name": "/dev/nvme0", "type": "nvme"},
    {"name": "/dev/sdb", "type": "sat"}
  ]
}
JSON
    exit 0
fi

case "${*: -1}" in
    /dev/sda)
        cat <<'JSON'
{
  "device": {"protocol": "ATA"},
  "model_name": "Example SATA SSD",
  "serial_number": "ATA123",
  "firmware_version": "1.0",
  "user_capacity": {"bytes": 1000204886016},
  "rotation_rate": 0,
  "smart_support": {"available": true, "enabled": true},
  "smart_status": {"passed": true},
  "temperature": {"current": 31},
  "power_on_time": {"hours": 1234},
  "power_cycle_count": 20,
  "ata_smart_error_log": {"summary": {"count": 0}},
  "ata_smart_attributes": {
    "table": [
      {"id": 5, "raw": {"value": 2}},
      {"id": 197, "raw": {"value": 3}},
      {"id": 198, "raw": {"value": 4}},
      {"id": 199, "raw": {"value": 5}}
    ]
  }
}
JSON
        exit 0
        ;;
    /dev/nvme0)
        cat <<'JSON'
{
  "device": {"protocol": "NVMe"},
  "model_name": "Example NVMe",
  "serial_number": "NVME123",
  "firmware_version": "2.0",
  "user_capacity": {"bytes": 2000398934016},
  "smart_status": {"passed": false},
  "temperature": {"current": 44},
  "power_on_time": {"hours": 500},
  "power_cycle_count": 10,
  "nvme_smart_health_information_log": {
    "critical_warning": 1,
    "temperature": 317,
    "available_spare": 95,
    "available_spare_threshold": 10,
    "percentage_used": 7,
    "data_units_read": 100,
    "data_units_written": 200,
    "unsafe_shutdowns": 2,
    "media_errors": 1
  }
}
JSON
        exit 8
        ;;
    /dev/sdb)
        printf 'not-json\n'
        exit 2
        ;;
esac

exit 1
SMARTCTL
chmod +x "${TEMP_DIR}/smartctl"

output="$(SMARTCTL_BIN="${TEMP_DIR}/smartctl" bash "${ROOT}/collectors/smart.sh")"

jq -e '
  .schema_version == 2 and
  .collector == "smart" and
  .status == "degraded" and
  .discovery.discovered_count == 3 and
  .discovery.collected_count == 2 and
  .discovery.failed_count == 1 and
  .disk_count == 2 and
  (.errors | length) == 1
' >/dev/null <<<"${output}"

jq -e '
  .disks[] |
  select(.serial == "ATA123") |
  .device_class == "ata" and
  .smart_passed == true and
  .reallocated_sectors == 2 and
  .pending_sectors == 3 and
  .offline_uncorrectable == 4 and
  .udma_crc_errors == 5
' >/dev/null <<<"${output}"

jq -e '
  .disks[] |
  select(.serial == "NVME123") |
  .device_class == "nvme" and
  .smart_passed == false and
  .smartctl.health_failed == true and
  .smartctl.exit_status == 8 and
  .wear_used_percent == 7 and
  .media_errors == 1
' >/dev/null <<<"${output}"

printf '[PASS] SMART collector fixtures and exit-status handling\n'
