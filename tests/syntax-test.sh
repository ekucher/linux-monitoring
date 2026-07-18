#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

find "${ROOT}" -type f -name '*.sh' -print0 |
    while IFS= read -r -d '' file; do
        bash -n "${file}"
        printf '[PASS] bash -n %s\n' "${file#${ROOT}/}"
    done
