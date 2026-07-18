#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

cat >"${TEMP_DIR}/sensors" <<'MOCK'
#!/usr/bin/env bash
case "${MOCK_SENSORS_MODE:-ok}" in
    ok)
        cat <<'JSON'
{
  "coretemp-isa-0000": {
    "Package id 0": {"temp1_input": 48.0},
    "Core 0": {"temp2_input": 43.0}
  },
  "nct6798-isa-0290": {
    "fan1": {"fan1_input": 920.0},
    "in0": {"in0_input": 1.056}
  }
}
JSON
        ;;
    empty)
        printf '{}\n'
        ;;
    invalid)
        printf 'not-json\n'
        ;;
    failed)
        printf 'mock sensors failure\n' >&2
        exit 1
        ;;
esac
MOCK
chmod +x "${TEMP_DIR}/sensors"

run_collector() {
    local mode="$1"
    MOCK_SENSORS_MODE="${mode}" \
        SENSORS_BIN="${TEMP_DIR}/sensors" \
        bash "${ROOT}/collectors/sensors.sh"
}

result="$(run_collector ok)"
jq -e '
    .schema_version == 2 and
    .collector == "sensors" and
    .status == "ok" and
    .command.exit_status == 0 and
    .reading_count == 4 and
    (.errors | length) == 0 and
    (.readings | map(.name) == (map(.name) | sort)) and
    (.readings[] | select(.metric == "temperature" and .unit == "C"))
' <<<"${result}" >/dev/null

result="$(run_collector empty)"
jq -e '
    .schema_version == 2 and
    .status == "empty" and
    .reading_count == 0 and
    (.errors | length) == 0
' <<<"${result}" >/dev/null

result="$(run_collector invalid)"
jq -e '
    .schema_version == 2 and
    .status == "error" and
    .reading_count == 0 and
    (.errors | length) == 1
' <<<"${result}" >/dev/null

result="$(run_collector failed)"
jq -e '
    .schema_version == 2 and
    .status == "error" and
    .command.exit_status == 1 and
    .reading_count == 0 and
    (.errors | length) == 1
' <<<"${result}" >/dev/null

printf '[PASS] Sensors collector schema v2 and error handling\n'
